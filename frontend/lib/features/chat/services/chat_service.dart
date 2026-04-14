import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/chat_accept_errors.dart';
import '../../../core/errors/send_chat_request_result.dart';
import '../models/chat_models.dart';

// ─────────────────────────── Internal exception ──────────────────────────────

/// Thrown inside a Firestore transaction to surface a specific result code.
/// Caught by [ChatService.sendRequest] before it reaches the caller.
class _RequestResultException implements Exception {
  const _RequestResultException(this.result);
  final SendChatRequestResult result;
}

// ─────────────────────────── Chat Service (Firestore) ────────────────────────

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _myUid => _auth.currentUser?.uid;

  // Theo firestore.rules: collection "conversations" (không phải "chats")
  CollectionReference<Map<String, dynamic>> get _convCol =>
      _db.collection('conversations');
  CollectionReference<Map<String, dynamic>> get _requestsCol =>
      _db.collection('chat_requests');
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _db.collection('users');

  /// Tạo deterministic ID từ 2 UID theo thứ tự lexicographic.
  /// Phải khớp với hàm validConversationId() trong firestore.rules.
  String _sortedId(String a, String b) =>
      a.compareTo(b) <= 0 ? '${a}_$b' : '${b}_$a';

  // ── Chat list stream ──────────────────────────────────────────────────────

  /// Real-time stream of active chats for [uid].
  Stream<List<ChatModel>> chatListStream(String uid) {
    return _convCol
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => _chatFromDoc(doc, uid))
            .whereType<ChatModel>()
            .toList());
  }

  // ── Incoming request stream ───────────────────────────────────────────────

  /// Real-time stream of pending chat requests sent TO [uid].
  Stream<List<ChatRequestModel>> incomingRequestsStream(String uid) {
    return _requestsCol
        .where('receiverId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map(_requestFromDoc)
            .whereType<ChatRequestModel>()
            .toList());
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  /// Loads messages for [chatId] ordered oldest → newest.
  Future<List<MessageModel>> getMessages(String chatId,
      {int page = 1}) async {
    if (page > 1) return [];
    final snap = await _convCol
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limitToLast(50)
        .get();
    return snap.docs.map(_messageFromDoc).toList();
  }

  /// Real-time stream of NEW messages for [chatId] after subscription time.
  Stream<MessageModel> incomingMessagesStream(String chatId) {
    final since = Timestamp.fromDate(DateTime.now());
    return _convCol
        .doc(chatId)
        .collection('messages')
        .where('timestamp', isGreaterThan: since)
        .orderBy('timestamp')
        .snapshots()
        .expand((snap) => snap.docChanges
            .where((c) => c.type == DocumentChangeType.added)
            .map((c) => _messageFromDoc(c.doc)));
  }

  /// Sends a text message and updates the conversation's lastMessage.
  /// Rules: message doc cần có senderId, content, timestamp, type, isRead.
  ///
  /// [partnerId]: if provided, increments their unread count by 1.
  Future<MessageModel> sendMessage(
    String chatId,
    String content, {
    String? partnerId,
  }) async {
    final uid = _myUid ?? 'me';
    final ref = _convCol.doc(chatId).collection('messages').doc();
    final now = FieldValue.serverTimestamp();
    await ref.set({
      'senderId': uid,
      'content': content,
      'timestamp': now,
      'type': 'text',
      'isRead': false,
    });
    final updates = <String, dynamic>{
      'lastMessage': content,
      'lastMessageAt': now,
      'unreadCounts.$uid': 0, // Reset own unread when sending
    };
    if (partnerId != null && partnerId.isNotEmpty) {
      updates['unreadCounts.$partnerId'] = FieldValue.increment(1);
    }
    await _convCol.doc(chatId).update(updates);
    return MessageModel(
      id: ref.id,
      senderId: uid,
      content: content,
      timestamp: DateTime.now(),
    );
  }

  /// Sends a location message.
  ///
  /// [partnerId]: if provided, increments their unread count by 1.
  Future<MessageModel> sendLocationMessage(
    String chatId,
    LocationData location, {
    String? partnerId,
  }) async {
    final uid = _myUid ?? 'me';
    final ref = _convCol.doc(chatId).collection('messages').doc();
    final now = FieldValue.serverTimestamp();
    final content = '${location.typeEmoji} ${location.name}';
    await ref.set({
      'senderId': uid,
      'content': content,
      'timestamp': now,
      'type': 'location',
      'isRead': false,
      'locationData': {
        'name': location.name,
        'lat': location.lat,
        'lng': location.lng,
        'address': location.address,
        'typeEmoji': location.typeEmoji,
      },
    });
    final updates = <String, dynamic>{
      'lastMessage': content,
      'lastMessageAt': now,
      'unreadCounts.$uid': 0,
    };
    if (partnerId != null && partnerId.isNotEmpty) {
      updates['unreadCounts.$partnerId'] = FieldValue.increment(1);
    }
    await _convCol.doc(chatId).update(updates);
    return MessageModel(
      id: ref.id,
      senderId: uid,
      content: content,
      timestamp: DateTime.now(),
      type: MessageType.location,
      locationData: location,
    );
  }

  // ── Partners ──────────────────────────────────────────────────────────────

  /// Search users in Firestore.
  ///
  /// Only returns profiles that were properly created via [saveOrUpdateProfile]
  /// — i.e. have a real [displayName] AND a non-placeholder [avatarInitial].
  /// Ghost / incomplete documents (seeder leftovers, partial writes) are excluded.
  Future<List<PartnerModel>> searchPartners({
    required Gender gender,
    required String language,
  }) async {
    final myUid = _myUid ?? '';
    final snap = await _usersCol.get();
    final seen = <String>{};
    return snap.docs
        .where((d) {
          if (d.id == myUid) return false;
          final data = d.data();
          // Require a real displayName.
          final name = data['displayName'] as String?;
          if (name == null || name.trim().isEmpty) return false;
          // Require a proper avatarInitial (not the '?' placeholder that means
          // the profile was never fully written by saveOrUpdateProfile).
          final initial = data['avatarInitial'] as String?;
          if (initial == null || initial == '?') return false;
          // Require at least one language field so filter works correctly.
          final native = data['nativeLanguage'] as String?;
          if (native == null || native.isEmpty) return false;
          return seen.add(d.id);
        })
        .map((d) => _partnerFromMap(d.id, d.data()))
        .where((p) {
          final genderOk = gender == Gender.any || p.gender == gender;
          final langOk = language == 'Any' || p.nativeLanguage == language;
          return genderOk && langOk;
        })
        .toList();
  }

  /// Full user snapshot for [chat_requests] payloads (receiver can render UI
  /// without re-querying `users`).
  Map<String, dynamic> _userInfoPayload(
    String uid,
    Map<String, dynamic>? raw,
  ) {
    final m = Map<String, dynamic>.from(raw ?? {});
    m['uid'] = uid;
    return m;
  }

  /// Sends a chat request from the current user to [partnerId].
  ///
  /// The document ID is [_sortedId](`myUid`, `partnerId`) — one doc per pair.
  ///
  /// Uses a [runTransaction] to atomically read the existing doc and write
  /// only when no conflicting state exists. If a race is detected the
  /// transaction throws [_RequestResultException] which is caught here and
  /// converted to the appropriate [SendChatRequestResult].
  Future<SendChatRequestResult> sendRequest(String partnerId) async {
    final myUid = _myUid;
    if (myUid == null) return SendChatRequestResult.notSignedIn;

    final requestId = _sortedId(myUid, partnerId);

    // Fetch user profiles outside the transaction — they are immutable for
    // this flow and do not need transactional consistency.
    final results = await Future.wait([
      _usersCol.doc(myUid).get(),
      _usersCol.doc(partnerId).get(),
    ]);
    final senderSnap = results[0];
    final receiverSnap = results[1];
    if (!receiverSnap.exists || receiverSnap.data() == null) {
      return SendChatRequestResult.partnerProfileMissing;
    }
    // Build sender info — auto-create the Firestore profile if it is missing
    // (e.g. first launch before saveOrUpdateProfile completes).
    final Map<String, dynamic> senderInfo;
    if (!senderSnap.exists || senderSnap.data() == null) {
      final authUser = _auth.currentUser;
      if (authUser == null) return SendChatRequestResult.notSignedIn;
      final rawName = (authUser.displayName?.trim().isNotEmpty == true
              ? authUser.displayName!
              : authUser.email?.split('@')[0]) ??
          'User';
      final autoProfile = <String, dynamic>{
        'uid': myUid,
        'displayName': rawName,
        'avatarInitial': rawName[0].toUpperCase(),
        'nativeLanguage': 'Vietnamese',
        'learningLanguage': 'Korean',
        'gender': 'other',
        'school': 'Keimyung University',
        'bio': "Hi, I'm using HiCampus!",
        'isOnline': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      };
      // Persist so future calls find the profile.
      await _usersCol.doc(myUid).set(autoProfile, SetOptions(merge: true));
      senderInfo = _userInfoPayload(myUid, autoProfile);
    } else {
      senderInfo = _userInfoPayload(myUid, senderSnap.data());
    }
    final receiverInfo = _userInfoPayload(partnerId, receiverSnap.data());
    final reqRef = _requestsCol.doc(requestId);

    try {
      await _db.runTransaction((txn) async {
        final snap = await txn.get(reqRef);
        if (snap.exists) {
          final st = snap.data()?['status'] as String? ?? '';
          switch (st) {
            case 'pending':
              final sender = snap.data()?['senderId'] as String? ?? '';
              throw _RequestResultException(sender == myUid
                  ? SendChatRequestResult.alreadyPending
                  : SendChatRequestResult.incomingPendingExists);
            case 'accepted':
              throw _RequestResultException(
                  SendChatRequestResult.alreadyAccepted);
            case 'declined':
              throw _RequestResultException(
                  SendChatRequestResult.previouslyDeclined);
          }
        }
        txn.set(reqRef, {
          'senderId': myUid,
          'receiverId': partnerId,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'senderInfo': senderInfo,
          'receiverInfo': receiverInfo,
        });
      });
    } on _RequestResultException catch (e) {
      return e.result;
    } catch (_) {
      return SendChatRequestResult.failed;
    }
    return SendChatRequestResult.sent;
  }

  // ── Accept / decline ──────────────────────────────────────────────────────

  /// Accepts [requestId] in a Firestore transaction and creates a conversation.
  ///
  /// Only [Transaction.get] on the request ref — do not read `conversations`
  /// inside the transaction. Room is created with [SetOptions.merge].
  /// Idempotent welcome: `messages/msg_welcome_$requestId`.
  /// Returns [conversationId] (sorted UID pair; same as [requestId]).
  Future<String> acceptRequest(String requestId) async {
    final myUid = _myUid;
    if (myUid == null) throw ChatAcceptException(ChatAcceptFailure.networkError);

    return _db.runTransaction<String>((txn) async {
      final reqRef = _requestsCol.doc(requestId);
      final reqSnap = await txn.get(reqRef);

      if (!reqSnap.exists) {
        throw ChatAcceptException(ChatAcceptFailure.requestNotFound);
      }
      final data = reqSnap.data()!;
      final status = data['status'] as String? ?? '';
      final senderId = data['senderId'] as String;
      final receiverId = data['receiverId'] as String;

      if (receiverId != myUid) {
        throw ChatAcceptException(ChatAcceptFailure.networkError);
      }

      if (status == 'accepted') {
        return _sortedId(senderId, receiverId);
      }
      if (status != 'pending') {
        throw ChatAcceptException(ChatAcceptFailure.requestNotPending);
      }

      final senderInfo =
          Map<String, dynamic>.from(data['senderInfo'] as Map? ?? {});
      final receiverInfo =
          Map<String, dynamic>.from(data['receiverInfo'] as Map? ?? {});

      txn.update(reqRef, {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      final convId = _sortedId(senderId, receiverId);
      final chatRef = _convCol.doc(convId);

      final participants = senderId.compareTo(receiverId) <= 0
          ? [senderId, receiverId]
          : [receiverId, senderId];

      txn.set(
        chatRef,
        {
          'participants': participants,
          'participantInfo': {
            senderId: senderInfo,
            receiverId: receiverInfo,
          },
          'lastMessage': '',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'unreadCounts': {
            participants[0]: 0,
            participants[1]: 0,
          },
          'status': 'active',
          'requestedBy': senderId,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final welcomeRef =
          chatRef.collection('messages').doc('msg_welcome_$requestId');
      txn.set(
        welcomeRef,
        {
          'senderId': 'system',
          'type': 'system',
          'content':
              'You are connected. Say hi and start practicing together!',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        },
        SetOptions(merge: true),
      );

      return convId;
    });
  }

  /// Declines [requestId].
  /// Rules chỉ cho phép status 'declined' (không phải 'rejected').
  Future<void> declineRequest(String requestId) async {
    await _requestsCol.doc(requestId).update({'status': 'declined'});
  }

  /// Resets unread count cho current user khi mở chat.
  Future<void> resetUnreadCount(String chatId) async {
    final uid = _myUid;
    if (uid == null) return;
    await _convCol.doc(chatId).update({'unreadCounts.$uid': 0});
  }

  // ── Connection pause / resume ─────────────────────────────────────────────

  /// Pauses the chat: no new messages until [reconnectConversation].
  Future<void> disconnectConversation(String chatId) async {
    final uid = _myUid;
    if (uid == null) return;
    await _convCol.doc(chatId).update({
      'status': 'disconnected',
      'disconnectedAt': FieldValue.serverTimestamp(),
      'disconnectedBy': uid,
    });
  }

  /// Resumes messaging for both participants.
  Future<void> reconnectConversation(String chatId) async {
    await _convCol.doc(chatId).update({
      'status': 'active',
      'disconnectedAt': FieldValue.delete(),
      'disconnectedBy': FieldValue.delete(),
    });
  }

  /// Emits `true` while the conversation is paused.
  Stream<bool> conversationDisconnectedStream(String chatId) {
    return _convCol.doc(chatId).snapshots().map((snap) {
      final s = snap.data()?['status'] as String? ?? 'active';
      return s == 'disconnected';
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  ChatModel? _chatFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc, String myUid) {
    try {
      final data = doc.data()!;
      final participants =
          List<String>.from(data['participants'] as List? ?? []);
      final partnerUid =
          participants.firstWhere((p) => p != myUid, orElse: () => '');
      if (partnerUid.isEmpty) return null;

      // Partner data từ participantInfo (field mới theo rules)
      final participantInfo =
          data['participantInfo'] as Map<String, dynamic>?;
      final partnerData =
          participantInfo?[partnerUid] as Map<String, dynamic>?;
      final partner = partnerData != null
          ? _partnerFromMap(partnerUid, partnerData)
          : PartnerModel(
              id: partnerUid,
              name: 'User',
              avatarInitial: '?',
              nativeLanguage: '',
              learningLanguage: '',
              school: '',
              bio: '',
              gender: Gender.any,
            );

      final unreadCounts =
          data['unreadCounts'] as Map<String, dynamic>? ?? {};
      final unread = (unreadCounts[myUid] as int?) ?? 0;
      // Dùng lastMessageAt (field mới theo rules)
      final lastMessageAt = data['lastMessageAt'] as Timestamp?;
      final convStatus = data['status'] as String? ?? 'active';

      return ChatModel(
        id: doc.id,
        partner: partner,
        lastMessage: data['lastMessage'] as String? ?? '',
        lastTime: lastMessageAt != null ? _timeAgo(lastMessageAt.toDate()) : '',
        unreadCount: unread,
        isDisconnected: convStatus == 'disconnected',
      );
    } catch (_) {
      return null;
    }
  }

  ChatRequestModel? _requestFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final data = doc.data()!;
      final senderId = data['senderId'] as String? ?? '';
      // Dùng senderInfo (thay cho senderData cũ)
      final senderInfo =
          data['senderInfo'] as Map<String, dynamic>? ?? {};
      return ChatRequestModel(
        id: doc.id,
        sender: _partnerFromMap(senderId, senderInfo),
        status: ChatRequestStatus.pending,
        timestamp:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  MessageModel _messageFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final typeStr = data['type'] as String? ?? 'text';
    final type = switch (typeStr) {
      'location' => MessageType.location,
      'system' => MessageType.system,
      _ => MessageType.text,
    };
    LocationData? locationData;
    if (type == MessageType.location) {
      final ld = data['locationData'] as Map<String, dynamic>?;
      if (ld != null) {
        locationData = LocationData(
          name: ld['name'] as String? ?? '',
          lat: (ld['lat'] as num).toDouble(),
          lng: (ld['lng'] as num).toDouble(),
          address: ld['address'] as String? ?? '',
          typeEmoji: ld['typeEmoji'] as String? ?? '📍',
        );
      }
    }
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      content: data['content'] as String? ?? '',
      timestamp:
          (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: type,
      locationData: locationData,
    );
  }

  PartnerModel _partnerFromMap(String uid, Map<String, dynamic> d) {
    return PartnerModel(
      id: uid,
      name: d['displayName'] as String? ?? 'Unknown',
      avatarInitial: d['avatarInitial'] as String? ?? '?',
      nativeLanguage: d['nativeLanguage'] as String? ?? '',
      learningLanguage: d['learningLanguage'] as String? ?? '',
      school: d['school'] as String? ?? '',
      bio: d['bio'] as String? ?? '',
      gender: _parseGender(d['gender']),
      isOnline: d['isOnline'] as bool? ?? false,
    );
  }

  Gender _parseGender(dynamic g) => switch (g?.toString()) {
        'male' => Gender.male,
        'female' => Gender.female,
        _ => Gender.any,
      };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
