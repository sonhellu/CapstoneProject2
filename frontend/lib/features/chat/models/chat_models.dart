// ─────────────────────────── Enums ───────────────────────────

enum Gender { male, female, any }

enum RequestStatus { none, pending, accepted, rejected }

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

enum MessageType { text, system }

class MessageModel {
  const MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
  });

  final String id;

  /// 'me' or partner id
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;

  bool get isMe => senderId == 'me';
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
  });

  final String id;
  final PartnerModel partner;
  final String lastMessage;
  final String lastTime;
  final int unreadCount;

  /// false = request sent but not yet accepted
  final bool isActive;
}
