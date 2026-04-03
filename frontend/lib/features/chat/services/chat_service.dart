import 'dart:async';

import '../models/chat_models.dart';

// ─────────────────────────── Mock Data ───────────────────────────

const _mockPartners = [
  PartnerModel(
    id: 'u1',
    name: 'Kim Jisoo',
    avatarInitial: 'K',
    nativeLanguage: 'Korean',
    learningLanguage: 'Vietnamese',
    school: 'Keimyung University',
    bio: '안녕하세요! I want to learn Vietnamese and help you with Korean 🇰🇷',
    gender: Gender.female,
    isOnline: true,
  ),
  PartnerModel(
    id: 'u2',
    name: 'Park Junho',
    avatarInitial: 'P',
    nativeLanguage: 'Korean',
    learningLanguage: 'English',
    school: 'Keimyung University',
    bio: 'Looking for an English conversation partner. Coffee lover ☕',
    gender: Gender.male,
    isOnline: false,
  ),
  PartnerModel(
    id: 'u3',
    name: 'Tanaka Yuki',
    avatarInitial: 'T',
    nativeLanguage: 'Japanese',
    learningLanguage: 'Korean',
    school: 'Kyungpook National University',
    bio: 'Exchange student from Tokyo. Let\'s practice Korean together! 🇯🇵',
    gender: Gender.female,
    isOnline: true,
  ),
  PartnerModel(
    id: 'u4',
    name: 'Li Wei',
    avatarInitial: 'L',
    nativeLanguage: 'Chinese',
    learningLanguage: 'Korean',
    school: 'Yeungnam University',
    bio: '你好! Studying Korean and love K-dramas. Happy to exchange languages!',
    gender: Gender.male,
    isOnline: true,
  ),
  PartnerModel(
    id: 'u5',
    name: 'Aung Htet',
    avatarInitial: 'A',
    nativeLanguage: 'Myanmar',
    learningLanguage: 'English',
    school: 'Keimyung University',
    bio: 'Engineering student. Looking to improve my English speaking skills.',
    gender: Gender.male,
    isOnline: false,
  ),
  PartnerModel(
    id: 'u6',
    name: 'Nguyen Thi Lan',
    avatarInitial: 'N',
    nativeLanguage: 'Vietnamese',
    learningLanguage: 'Korean',
    school: 'Keimyung University',
    bio: 'Xin chào! TOPIK 4 level. Would love to practice with a native speaker 🌸',
    gender: Gender.female,
    isOnline: true,
  ),
];

final _mockChats = [
  ChatModel(
    id: 'c1',
    partner: _mockPartners[0],
    lastMessage: '안녕하세요! Nice to meet you 😊',
    lastTime: '2m ago',
    unreadCount: 3,
  ),
  ChatModel(
    id: 'c2',
    partner: _mockPartners[2],
    lastMessage: 'Sure! Let\'s meet at the library tomorrow.',
    lastTime: '1h ago',
    unreadCount: 0,
  ),
  ChatModel(
    id: 'c3',
    partner: _mockPartners[3],
    lastMessage: 'Can you help me with this Korean sentence?',
    lastTime: '3h ago',
    unreadCount: 1,
  ),
  ChatModel(
    id: 'c4',
    partner: _mockPartners[5],
    lastMessage: '오늘 수업 어땠어요?',
    lastTime: 'Yesterday',
    unreadCount: 0,
  ),
];

final _mockMessages = <String, List<MessageModel>>{
  'c1': [
    MessageModel(
      id: 'm1',
      senderId: 'u1',
      content: '안녕하세요! I saw your profile and I think we can help each other.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    MessageModel(
      id: 'm2',
      senderId: 'me',
      content: 'Hi! Yes, I\'m learning Korean. I can teach you Vietnamese!',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
    ),
    MessageModel(
      id: 'm3',
      senderId: 'u1',
      content: 'That sounds great! When are you free to practice?',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
    ),
    MessageModel(
      id: 'm4',
      senderId: 'me',
      content: 'I\'m free on weekday evenings after 6pm.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
    ),
    MessageModel(
      id: 'm5',
      senderId: 'u1',
      content: '안녕하세요! Nice to meet you 😊',
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ],
  'c2': [
    MessageModel(
      id: 'm1',
      senderId: 'u3',
      content: 'Hello! I found you through the language exchange feature.',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    ),
    MessageModel(
      id: 'm2',
      senderId: 'me',
      content: 'Hi Yuki! Nice to meet you.',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    MessageModel(
      id: 'm3',
      senderId: 'u3',
      content: 'Would you like to study together at the library?',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    MessageModel(
      id: 'm4',
      senderId: 'me',
      content: 'Sure! Let\'s meet at the library tomorrow.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ],
};

// ─────────────────────────── Simulated replies ───────────────────────────

const _autoReplies = [
  '그렇군요! 정말 재미있네요 😄',
  'That\'s so interesting! Tell me more.',
  'Sounds great! When can we meet?',
  '맞아요! 저도 그렇게 생각해요.',
  'Haha, I know what you mean! 😂',
  'Let\'s practice that tomorrow okay?',
  '화이팅! You\'re doing really well!',
  'Interesting perspective! I hadn\'t thought of that.',
];

// ─────────────────────────── Chat Service ───────────────────────────

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  // ── WebSocket simulation ──
  // In production: replace with WebSocketChannel from web_socket_channel package
  // and connect to ws://your-fastapi-server/ws/chat/{chatId}
  final _messageStreamCtrl = StreamController<MessageModel>.broadcast();

  /// Stream of incoming messages — subscribe in ChatDetailScreen.
  /// Production: this would be fed by WebSocket frames from FastAPI.
  Stream<MessageModel> get incomingMessages => _messageStreamCtrl.stream;

  Timer? _simulationTimer;

  void _startSimulation(String chatId, String partnerId) {
    _simulationTimer?.cancel();
    _simulationTimer = Timer(
      const Duration(seconds: 3),
      () {
        final reply = MessageModel(
          id: 'auto_${DateTime.now().millisecondsSinceEpoch}',
          senderId: partnerId,
          content: _autoReplies[
              DateTime.now().millisecondsSinceEpoch % _autoReplies.length],
          timestamp: DateTime.now(),
        );
        _messageStreamCtrl.add(reply);
      },
    );
  }

  void dispose() {
    _simulationTimer?.cancel();
    _messageStreamCtrl.close();
  }

  // ─────────────────── Mock API calls ───────────────────────────
  // Production: replace these with http.get/post calls to your FastAPI backend.

  /// GET /api/chats
  Future<List<ChatModel>> getChatList() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return List.from(_mockChats);
  }

  /// GET /api/chats/{id}/messages?page={page}
  Future<List<MessageModel>> getMessages(String chatId,
      {int page = 1}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final messages = _mockMessages[chatId] ?? [];
    // Simulate pagination — older messages on page 2+
    if (page == 2) {
      return [
        MessageModel(
          id: 'old1',
          senderId: 'me',
          content: '(older) Hi! Just found your profile.',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
        ),
        MessageModel(
          id: 'old2',
          senderId: messages.first.senderId,
          content: '(older) Hey! Nice to connect!',
          timestamp: DateTime.now().subtract(const Duration(days: 3, minutes: 1)),
        ),
      ];
    }
    return List.from(messages);
  }

  /// POST /api/messages
  Future<MessageModel> sendMessage(String chatId, String content) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final msg = MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'me',
      content: content,
      timestamp: DateTime.now(),
    );
    _mockMessages[chatId] ??= [];
    _mockMessages[chatId]!.add(msg);

    // Simulate partner replying after 3 seconds
    final chat = _mockChats.firstWhere((c) => c.id == chatId,
        orElse: () => _mockChats.first);
    _startSimulation(chatId, chat.partner.id);

    return msg;
  }

  /// GET /api/partners/search?gender=&language=
  Future<List<PartnerModel>> searchPartners({
    required Gender gender,
    required String language,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return _mockPartners.where((p) {
      final genderMatch =
          gender == Gender.any || p.gender == gender;
      final langMatch =
          language == 'Any' || p.learningLanguage == language;
      return genderMatch && langMatch;
    }).toList();
  }

  /// POST /api/partners/{id}/request
  Future<void> sendRequest(String partnerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    // Production: POST to backend, backend sends push notification to partner
  }
}
