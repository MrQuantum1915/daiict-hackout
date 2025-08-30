class User {
  final String id;
  final String nickname;
  final String communityId;
  final String? profileImage;
  final bool isAdmin;
  final int points;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.nickname,
    required this.communityId,
    this.profileImage,
    this.isAdmin = false,
    this.points = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nickname: json['nickname'],
      communityId: json['communityId'],
      profileImage: json['profileImage'],
      isAdmin: json['isAdmin'] ?? false,
      points: json['points'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'communityId': communityId,
      'profileImage': profileImage,
      'isAdmin': isAdmin,
      'points': points,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? nickname,
    String? communityId,
    String? profileImage,
    bool? isAdmin,
    int? points,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      communityId: communityId ?? this.communityId,
      profileImage: profileImage ?? this.profileImage,
      isAdmin: isAdmin ?? this.isAdmin,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

