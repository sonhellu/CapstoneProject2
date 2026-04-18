import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────── Enums ───────────────────────────

enum Gender { male, female, any }

enum RequestStatus { none, pending, accepted, rejected }

/// State machine for a user pair.
///
/// ```
/// none ──► pending ──► active ──► disconnected
///                 ↑                     │
///                 └─────────────────────┘  (reconnect)
/// ```
///
/// - [none]         chat_requests doc does not exist.
/// - [pending]      chat_requests.status == 'pending'.
/// - [active]       chat_requests.status == 'active'  /  conversations.status == 'active'.
/// - [disconnected] both docs have status == 'disconnected'.
enum ChatSyncStatus { none, pending, active, disconnected }

// ─────────────────────────── LocationData ───────────────────────────

class LocationData {
  const LocationData({
    required this.name,
    required this.lat,
    required this.lng,
    this.address = '',
    this.typeEmoji = '📍',
  });

  final String name;
  final double lat;
  final double lng;
  final String address;
  final String typeEmoji;
}

// ─────────────────────────── Partner ───────────────────────────

class PartnerModel {
  const PartnerModel({
    required this.id,
    required this.name,
    required this.avatarInitial,
    required this.nativeLanguage,
    required this.learningLanguage,
    required this.school,
    required this.bio,
    required this.gender,
    this.isOnline = false,
    this.requestStatus = RequestStatus.none,
  });

  final String id;
  final String name;
  final String avatarInitial;
  final String nativeLanguage;
  final String learningLanguage;
  final String school;
  final String bio;
  final Gender gender;
  final bool isOnline;
  final RequestStatus requestStatus;

  PartnerModel copyWith({RequestStatus? requestStatus}) => PartnerModel(
        id: id,
        name: name,
        avatarInitial: avatarInitial,
        nativeLanguage: nativeLanguage,
        learningLanguage: learningLanguage,
        school: school,
        bio: bio,
        gender: gender,
        isOnline: isOnline,
        requestStatus: requestStatus ?? this.requestStatus,
      );
}

// ─────────────────────────── Message ───────────────────────────

enum MessageType { text, system, location }

class MessageModel {
  const MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
    this.locationData,
    this.isPending = false,
  });

  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;

  /// Non-null when [type] == [MessageType.location].
  final LocationData? locationData;

  /// True while the message is awaiting Firestore confirmation (optimistic UI).
  final bool isPending;

  bool get isMe => senderId == FirebaseAuth.instance.currentUser?.uid;
}

// ─────────────────────────── Chat Request ───────────────────────────

class ChatRequestModel {
  const ChatRequestModel({
    required this.id,
    required this.sender,
    required this.status,
    required this.timestamp,
  });

  final String id;
  final PartnerModel sender;
  final ChatSyncStatus status;
  final DateTime timestamp;
}

// ─────────────────────────── Chat ───────────────────────────

class ChatModel {
  const ChatModel({
    required this.id,
    required this.partner,
    required this.lastMessage,
    required this.lastTime,
    this.unreadCount = 0,
    this.isActive = true,
    this.status = ChatSyncStatus.active,
    this.lastClearedAt,
  });

  final String id;
  final PartnerModel partner;
  final String lastMessage;
  final String lastTime;
  final int unreadCount;

  /// false = placeholder row navigated from accept (no existing conversation data).
  final bool isActive;

  /// Mirrors Firestore conversation `status`.
  final ChatSyncStatus status;

  /// Set to the server timestamp when a conversation is reconnected.
  /// [ChatService.getMessages] filters out messages older than this so the
  /// chat room appears empty after a reconnect.
  final DateTime? lastClearedAt;

  bool get isDisconnected => status == ChatSyncStatus.disconnected;
}
