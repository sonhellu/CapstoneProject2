import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/chat_accept_errors.dart';
import '../../../core/errors/send_chat_request_result.dart';
import '../models/chat_models.dart';

// ─────────────────────────── Internal exception ──────────────────────────────

class _RequestResultException implements Exception {
  const _RequestResultException(this.result);
  final SendChatRequestResult result;
}

// ─────────────────────────── Chat Service ────────────────────────────────────

/// Single-instance Firestore gateway for all chat operations.
///
/// ## State Machine
/// ```
/// none ──► pending ──► active ──► disconnected
///     ↑                               │
///     └───────────────────────────────┘  (sendRequest → pending again)
/// ```
/// Decline = delete the chat_requests doc → returns to `none`.
class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _myUid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _convCol =>
      _db.collection('conversations');
  CollectionReference<Map<String, dynamic>> get _requestsCol =>
      _db.collection('chat_requests');
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _db.collection('users');

  /// Deterministic doc ID for a user pair — sorted lexicographically.
  /// Must stay in sync with `sortedId()` in firestore.rules.
  String _sortedId(String a, String b) =>
      a.compareTo(b) <= 0 ? '${a}_$b' : '${b}_$a';

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Real-time list of active conversations for [uid].
  Stream<List<ChatModel>> chatListStream(String uid) {
    return _convCol
        .where('participants', arrayContains: uid)
        .where('status', isEqualTo: 'active')
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => _chatFromDoc(doc, uid))
            .whereType<ChatModel>()
            .toList());
  }

  /// Real-time list of pending incoming requests for [uid].
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

  static const kPageSize = 30;

  /// Loads one page of messages for [chatId], oldest → newest.
  ///
  /// - [before] — cursor returned from the previous call (load-older pagination).
  /// - [since]  — only return messages newer than this timestamp. Used after a
  ///              reconnect to give the chat room a fresh-start feel without
  ///              deleting history.
  ///
  /// Returns `(messages, cursor)`. If the list is empty the caller should set
  /// `hasMoreOlder = false`.
  Future<(List<MessageModel>, DocumentSnapshot<Map<String, dynamic>>?)>
      getMessages(
    String chatId, {
    DocumentSnapshot<Map<String, dynamic>>? before,
    DateTime? since,
  }) async {
    var q = _convCol
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(kPageSize);

    // Filter out messages before the last reconnect (soft history wipe).
    if (since != null) {
      q = q.where('timestamp',
          isGreaterThan: Timestamp.fromDate(since));
    }
    if (before != null) q = q.startAfterDocument(before);

    final snap = await q.get();
    if (snap.docs.isEmpty) return (const <MessageModel>[], null);

    final cursor = snap.docs.last; // oldest doc in descending query
    final msgs = snap.docs.reversed.map(_messageFromDoc).toList();
    return (msgs, cursor);
  }

  /// Real-time stream of NEW messages arriving after subscription time.
  Stream<MessageModel> incomingMessagesStream(String chatId,
      {DateTime? since}) {
    // Use the later of `now` and `lastClearedAt` so reconnected chats never
    // surface history via the live stream either.
    final cutoff = since != null && since.isAfter(DateTime.now())
        ? since
        : DateTime.now();
    return _convCol
        .doc(chatId)
        .collection('messages')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoff))
        .orderBy('timestamp')
        .snapshots()
        .expand((snap) => snap.docChanges
            .where((c) => c.type == DocumentChangeType.added)
            .map((c) => _messageFromDoc(c.doc)));
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  /// Sends a text message via [WriteBatch] (atomic message + metadata update).
  Future<MessageModel> sendMessage(
    String chatId,
    String content, {
    String? partnerId,
  }) async {
    final uid = _myUid ?? 'me';
    final ref = _convCol.doc(chatId).collection('messages').doc();
    final now = FieldValue.serverTimestamp();

    final updates = <String, dynamic>{
      'lastMessage': content,
      'lastMessageAt': now,
      'unreadCounts.$uid': 0,
    };
    if (partnerId != null && partnerId.isNotEmpty) {
      updates['unreadCounts.$partnerId'] = FieldValue.increment(1);
    }

    final batch = _db.batch();
    batch.set(ref, {
      'senderId': uid,
      'content': content,
      'timestamp': now,
      'type': 'text',
      'isRead': false,
    });
    batch.update(_convCol.doc(chatId), updates);
    await batch.commit();

    return MessageModel(
      id: ref.id,
      senderId: uid,
      content: content,
      timestamp: DateTime.now(),
    );
  }

  /// Sends a location message via [WriteBatch].
  Future<MessageModel> sendLocationMessage(
    String chatId,
    LocationData location, {
    String? partnerId,
  }) async {
    final uid = _myUid ?? 'me';
    final ref = _convCol.doc(chatId).collection('messages').doc();
    final now = FieldValue.serverTimestamp();
    final content = '${location.typeEmoji} ${location.name}';

    final updates = <String, dynamic>{
      'lastMessage': content,
      'lastMessageAt': now,
      'unreadCounts.$uid': 0,
    };
    if (partnerId != null && partnerId.isNotEmpty) {
      updates['unreadCounts.$partnerId'] = FieldValue.increment(1);
    }

    final batch = _db.batch();
    batch.set(ref, {
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
    batch.update(_convCol.doc(chatId), updates);
    await batch.commit();

    return MessageModel(
      id: ref.id,
      senderId: uid,
      content: content,
      timestamp: DateTime.now(),
      type: MessageType.location,
      locationData: location,
    );
  }

  // ── Partner search ────────────────────────────────────────────────────────

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
          final name = data['displayName'] as String?;
          if (name == null || name.trim().isEmpty) return false;
          final initial = data['avatarInitial'] as String?;
          if (initial == null || initial == '?') return false;
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

  // ── Request lifecycle ─────────────────────────────────────────────────────

  /// Sends a connection request to [partnerId].
  ///
  /// State transitions handled:
  /// - `none`         → create doc, status = pending.
  /// - `disconnected` → reset all fields, status = pending (reconnect).
  /// - `pending`      → block (already pending or incoming exists).
  /// - `active`       → block (already connected).
  Future<SendChatRequestResult> sendRequest(String partnerId) async {
    final myUid = _myUid;
    if (myUid == null) return SendChatRequestResult.notSignedIn;

    final requestId = _sortedId(myUid, partnerId);

    // Fetch profiles outside the transaction — read-only, no contention.
    final results = await Future.wait([
      _usersCol.doc(myUid).get(),
      _usersCol.doc(partnerId).get(),
    ]);
    final senderSnap = results[0];
    final receiverSnap = results[1];

    if (!receiverSnap.exists || receiverSnap.data() == null) {
      return SendChatRequestResult.partnerProfileMissing;
    }

    final Map<String, dynamic> senderInfo;
    if (!senderSnap.exists || senderSnap.data() == null) {
      // Auto-create a minimal profile so the receiver can render the card.
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

        if (!snap.exists) {
          // State: none → pending.
          txn.set(reqRef, {
            'senderId': myUid,
            'receiverId': partnerId,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
            'senderInfo': senderInfo,
            'receiverInfo': receiverInfo,
          });
          return;
        }

        final status = snap.data()?['status'] as String? ?? '';
        switch (status) {
          case 'pending':
            final sender = snap.data()?['senderId'] as String? ?? '';
            throw _RequestResultException(sender == myUid
                ? SendChatRequestResult.alreadyPending
                : SendChatRequestResult.incomingPendingExists);

          case 'active':
            throw _RequestResultException(
                SendChatRequestResult.alreadyAccepted);

          case 'disconnected':
            // State: disconnected → pending (reconnect).
            // Reset ALL request fields so old data is not shown.
            final prevSender =
                snap.data()?['senderId'] as String? ?? '';
            final prevReceiver =
                snap.data()?['receiverId'] as String? ?? '';
            final newReceiverId =
                prevSender == myUid ? prevReceiver : prevSender;
            txn.update(reqRef, {
              'status': 'pending',
              'senderId': myUid,
              'receiverId': newReceiverId,
              'createdAt': FieldValue.serverTimestamp(),
              'senderInfo': senderInfo,
              'receiverInfo': receiverInfo,
              // Clear disconnect metadata.
              'disconnectedBy': FieldValue.delete(),
              'disconnectedAt': FieldValue.delete(),
            });
            return;

          default:
            throw _RequestResultException(SendChatRequestResult.failed);
        }
      });
    } on _RequestResultException catch (e) {
      return e.result;
    } catch (_) {
      return SendChatRequestResult.failed;
    }
    return SendChatRequestResult.sent;
  }

  /// Accepts [requestId].
  ///
  /// Uses a Transaction with ALL reads before writes (Firestore requirement).
  ///
  /// - New connection  → creates the conversation doc + welcome message.
  /// - Reconnect       → reactivates existing conversation, sets [lastClearedAt]
  ///                     so the UI presents an empty room (history preserved
  ///                     server-side but hidden client-side via timestamp filter).
  ///
  /// Returns the conversation ID (== requestId == sortedId pair).
  Future<String> acceptRequest(String requestId) async {
    final myUid = _myUid;
    if (myUid == null) {
      throw ChatAcceptException(ChatAcceptFailure.networkError);
    }

    // ── Transaction: ALL reads first, then ALL writes ─────────────────────
    final result = await _db.runTransaction<(String, bool)>((txn) async {
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
        throw ChatAcceptException(ChatAcceptFailure.requestNotPending);
      }
      if (status == 'active') {
        // Idempotent — already accepted.
        return (_sortedId(senderId, receiverId), false);
      }
      if (status != 'pending') {
        throw ChatAcceptException(ChatAcceptFailure.requestNotPending);
      }

      final senderInfo =
          Map<String, dynamic>.from(data['senderInfo'] as Map? ?? {});
      final receiverInfo =
          Map<String, dynamic>.from(data['receiverInfo'] as Map? ?? {});

      final convId = _sortedId(senderId, receiverId);
      final chatRef = _convCol.doc(convId);

      final participants = senderId.compareTo(receiverId) <= 0
          ? [senderId, receiverId]
          : [receiverId, senderId];

      // ── Reads complete — now buffer writes ──────────────────────────────
      final convSnap = await txn.get(chatRef);

      // 1. Promote chat_request to active.
      txn.update(reqRef, {
        'status': 'active',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      if (!convSnap.exists) {
        // 2a. New conversation.
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
        return (convId, true); // true = write welcome message after commit
      }

      // 2b. Reconnect — reactivate + mark a clean-slate timestamp so the UI
      //     shows an empty room (history stays in Firestore).
      txn.set(
        chatRef,
        {
          'participantInfo': {
            senderId: senderInfo,
            receiverId: receiverInfo,
          },
          'unreadCounts': {
            participants[0]: 0,
            participants[1]: 0,
          },
          'status': 'active',
          'requestedBy': senderId,
          'lastClearedAt': FieldValue.serverTimestamp(),
          'disconnectedAt': FieldValue.delete(),
          'disconnectedBy': FieldValue.delete(),
        },
        SetOptions(merge: true),
      );
      return (convId, false);
    });

    final convId = result.$1;

    // ── Welcome message (written after transaction commits) ───────────────
    // The conversation doc now exists so the message rule can verify
    // chat_requests.receiverId == uid().
    if (result.$2) {
      await _convCol
          .doc(convId)
          .collection('messages')
          .doc('msg_welcome_$requestId')
          .set(
        {
          'senderId': 'system',
          'type': 'system',
          'content': 'You are connected. Say hi and start practicing!',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        },
        SetOptions(merge: true),
      );
    }

    return convId;
  }

  /// Declines [requestId] — **deletes** the chat_requests doc so the pair
  /// returns to the `none` state and either user can send a fresh request.
  Future<void> declineRequest(String requestId) async {
    await _requestsCol.doc(requestId).delete();
  }

  // ── Disconnect ────────────────────────────────────────────────────────────

  /// Disconnects the current user from [chatId].
  ///
  /// Sets both the conversation and the chat_request to `disconnected` so:
  /// - The conversation disappears from both users' [chatListStream].
  /// - The pair can later reconnect via [sendRequest] / [acceptRequest].
  ///
  /// Uses a Transaction so both documents are updated atomically and the
  /// unreadCounts reset uses the actual participant UIDs from the doc.
  Future<void> disconnectPartner(String chatId) async {
    final myUid = _myUid;
    if (myUid == null) return;

    await _db.runTransaction((txn) async {
      final convRef = _convCol.doc(chatId);
      final reqRef = _requestsCol.doc(chatId);

      // ── Reads first ────────────────────────────────────────────────────
      final convSnap = await txn.get(convRef);
      final reqSnap = await txn.get(reqRef);

      if (!convSnap.exists) return;
      final parts =
          List<String>.from(convSnap.data()!['participants'] as List? ?? []);
      if (!parts.contains(myUid)) return;

      // ── Writes ─────────────────────────────────────────────────────────
      txn.update(convRef, {
        'status': 'disconnected',
        'disconnectedAt': FieldValue.serverTimestamp(),
        'disconnectedBy': myUid,
        'unreadCounts.${parts[0]}': 0,
        'unreadCounts.${parts[1]}': 0,
      });

      if (reqSnap.exists) {
        final reqStatus = reqSnap.data()?['status'] as String? ?? '';
        // Allow idempotent disconnect to handle concurrent disconnect race.
        if (reqStatus == 'active' || reqStatus == 'disconnected') {
          txn.update(reqRef, {
            'status': 'disconnected',
            'disconnectedBy': myUid,
            'disconnectedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }

  // ── Unread ────────────────────────────────────────────────────────────────

  Future<void> resetUnreadCount(String chatId) async {
    final uid = _myUid;
    if (uid == null) return;
    await _convCol.doc(chatId).update({'unreadCounts.$uid': 0});
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _userInfoPayload(
      String uid, Map<String, dynamic>? raw) {
    final m = Map<String, dynamic>.from(raw ?? {});
    m['uid'] = uid;
    return m;
  }

  ChatModel? _chatFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc, String myUid) {
    try {
      final data = doc.data()!;
      final participants =
          List<String>.from(data['participants'] as List? ?? []);
      final partnerUid =
          participants.firstWhere((p) => p != myUid, orElse: () => '');
      if (partnerUid.isEmpty) return null;

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
      final lastMessageAt = data['lastMessageAt'] as Timestamp?;
      final lastClearedAt = (data['lastClearedAt'] as Timestamp?)?.toDate();

      return ChatModel(
        id: doc.id,
        partner: partner,
        lastMessage: data['lastMessage'] as String? ?? '',
        lastTime:
            lastMessageAt != null ? _timeAgo(lastMessageAt.toDate()) : '',
        unreadCount: unread,
        status: _parseConversationStatus(data['status'] as String?),
        lastClearedAt: lastClearedAt,
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
      final senderInfo =
          data['senderInfo'] as Map<String, dynamic>? ?? {};
      return ChatRequestModel(
        id: doc.id,
        sender: _partnerFromMap(senderId, senderInfo),
        status: _parseRequestStatus(data['status'] as String?),
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

  PartnerModel _partnerFromMap(String uid, Map<String, dynamic> d) =>
      PartnerModel(
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

  Gender _parseGender(dynamic g) => switch (g?.toString()) {
        'male' => Gender.male,
        'female' => Gender.female,
        _ => Gender.any,
      };

  ChatSyncStatus _parseConversationStatus(String? s) => switch (s) {
        'disconnected' => ChatSyncStatus.disconnected,
        'active' => ChatSyncStatus.active,
        _ => ChatSyncStatus.active,
      };

  ChatSyncStatus _parseRequestStatus(String? s) => switch (s) {
        'active' => ChatSyncStatus.active,
        'disconnected' => ChatSyncStatus.disconnected,
        'pending' => ChatSyncStatus.pending,
        _ => ChatSyncStatus.none,
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
