class LocationReview {
  const LocationReview({
    required this.id,
    required this.pinId,
    required this.authorId,
    required this.authorName,
    required this.authorInitial,
    required this.rating,
    required this.body,
    required this.createdAt,
    this.isVerified = false,
  });

  final String id;
  final String pinId;
  final String authorId;
  final String authorName;
  final String authorInitial;
  final int rating;
  final String body;
  final DateTime createdAt;
  final bool isVerified;

  Map<String, dynamic> toJson() => {
    'id': id,
    'pinId': pinId,
    'authorId': authorId,
    'authorName': authorName,
    'authorInitial': authorInitial,
    'rating': rating,
    'body': body,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'isVerified': isVerified,
  };

  factory LocationReview.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'];
    return LocationReview(
      id: json['id'] as String? ?? '',
      pinId: json['pinId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Student',
      authorInitial: json['authorInitial'] as String? ?? 'S',
      rating: (json['rating'] as num?)?.toInt().clamp(1, 5).toInt() ?? 1,
      body: json['body'] as String? ?? '',
      createdAt: createdAtRaw is int
          ? DateTime.fromMillisecondsSinceEpoch(createdAtRaw)
          : DateTime.now(),
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }
}
