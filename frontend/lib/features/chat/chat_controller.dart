import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';

import '../../core/errors/chat_accept_errors.dart';
import '../auth/providers/auth_provider.dart';
import 'models/chat_models.dart';
import 'services/chat_service.dart';

/// Central place for chat Firestore streams and thin request helpers.
///
/// Uses a single Firestore subscription per stream, broadcasting via
/// [StreamController.broadcast] so multiple StreamBuilder widgets can
/// subscribe without creating duplicate Firestore listeners.
class ChatController extends ChangeNotifier {
  ChatController(this._auth) {
    _auth.addListener(_onAuthChanged);
    _bindStreams(force: true);
  }

  final AuthProvider _auth;
  String _boundUid = '';

  // Broadcast controllers — single Firestore listener each, many UI subscribers.
  final _incomingCtrl =
      StreamController<List<ChatRequestModel>>.broadcast();
  final _chatsCtrl = StreamController<List<ChatModel>>.broadcast();

  List<ChatModel> _latestChats = const [];

  // Emits each NEW incoming request once for the in-app banner.
  final _newRequestCtrl =
      StreamController<ChatRequestModel>.broadcast();
  Stream<ChatRequestModel> get newRequests => _newRequestCtrl.stream;

  final _seenRequestIds = <String>{};
  StreamSubscription<List<ChatRequestModel>>? _incomingSub;
  StreamSubscription<List<ChatModel>>? _chatsSub;

  // Public streams consumed by StreamBuilder widgets.
  Stream<List<ChatRequestModel>> get incomingRequests => _incomingCtrl.stream;
  Stream<List<ChatModel>> get chats => _chatsCtrl.stream;

  /// Total unread count across all active conversations — used for nav badge.
  int get totalUnread =>
      _latestChats.fold(0, (sum, c) => sum + c.unreadCount);

  String get currentUid => _auth.uid ?? '';

  void _onAuthChanged() => _bindStreams();

  void _bindStreams({bool force = false}) {
    final u = _auth.uid ?? '';
    if (!force && u == _boundUid) return;
    _boundUid = u;

    _incomingSub?.cancel();
    _chatsSub?.cancel();
    _seenRequestIds.clear();

    if (u.isEmpty) {
      _incomingCtrl.add(const []);
      _chatsCtrl.add(const []);
      _latestChats = const [];
      _updateBadge();
    } else {
      // Single Firestore listener → broadcast to UI + detect new requests.
      _incomingSub =
          ChatService.instance.incomingRequestsStream(u).listen((list) {
        _incomingCtrl.add(list);
        for (final req in list) {
          if (_seenRequestIds.add(req.id)) {
            _newRequestCtrl.add(req);
          }
        }
      });

      // Single Firestore listener → broadcast to UI + update app badge.
      _chatsSub = ChatService.instance.chatListStream(u).listen((list) {
        _latestChats = list;
        _chatsCtrl.add(list);
        _updateBadge();
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void _updateBadge() {
    if (kIsWeb) return;
    final count = totalUnread;
    if (count > 0) {
      FlutterAppBadger.updateBadgeCount(count);
    } else {
      FlutterAppBadger.removeBadge();
    }
  }

  // ── Accept / decline ──────────────────────────────────────────────────────

  /// Accepts a pending chat request.
  ///
  /// Retry policy:
  /// - If Firestore returns `aborted` (transaction contention), automatically
  ///   retries up to [_kMaxRetries] times with exponential back-off (200 ms,
  ///   400 ms) before surfacing a [ChatAcceptException].
  /// - Any other [FirebaseException] is mapped to [ChatAcceptException] with
  ///   an appropriate [ChatAcceptFailure].
  static const int _kMaxRetries = 2;

  Future<String> acceptRequest(String requestId) async {
    var attempt = 0;
    while (true) {
      try {
        return await ChatService.instance.acceptRequest(requestId);
      } on ChatAcceptException {
        rethrow;
      } on FirebaseException catch (e) {
        attempt++;
        if (e.code == 'aborted' && attempt <= _kMaxRetries) {
          await Future.delayed(Duration(milliseconds: 200 * attempt));
          continue;
        }
        final failure = e.code == 'aborted'
            ? ChatAcceptFailure.transactionAborted
            : ChatAcceptFailure.networkError;
        throw ChatAcceptException(failure);
      }
    }
  }

  Future<void> declineRequest(String requestId) =>
      ChatService.instance.declineRequest(requestId);

  @override
  void dispose() {
    _incomingSub?.cancel();
    _chatsSub?.cancel();
    _incomingCtrl.close();
    _chatsCtrl.close();
    _newRequestCtrl.close();
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
