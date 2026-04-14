import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────── Enums ───────────────────────────

enum Gender { male, female, any }

enum RequestStatus { none, pending, accepted, rejected }

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

  /// Firebase UID of the sender.
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;

  /// Non-null when [type] == [MessageType.location].
  final LocationData? locationData;

  /// True while the message is awaiting Firestore confirmation (optimistic).
  /// Bubble renders at reduced opacity until this becomes false.
  final bool isPending;

  bool get isMe =>
      senderId == FirebaseAuth.instance.currentUser?.uid;

  /// Returns a copy with [isPending] cleared and [id]/[timestamp] updated.
  MessageModel confirmedWith({required String id, required DateTime timestamp}) =>
      MessageModel(
        id: id,
        senderId: senderId,
        content: content,
        timestamp: timestamp,
        isRead: isRead,
        type: type,
        locationData: locationData,
        isPending: false,
      );
}

// ─────────────────────────── Chat Request ───────────────────────────

enum ChatRequestStatus { pending, accepted, rejected }

class ChatRequestModel {
  const ChatRequestModel({
    required this.id,
    required this.sender,
    required this.status,
    required this.timestamp,
  });

  final String id;
  final PartnerModel sender;
  final ChatRequestStatus status;
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
    this.isDisconnected = false,
  });

  final String id;
  final PartnerModel partner;
  final String lastMessage;
  final String lastTime;
  final int unreadCount;

  /// false = request sent but not yet accepted
  final bool isActive;

  /// true when [Firestore conversation `status`] is `disconnected` (paused; can reconnect).
  final bool isDisconnected;
}
