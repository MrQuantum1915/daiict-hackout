class User {
  final String id;
  final String? publicKey;
  final bool hasBackedUpPrivateKey;
  final int points;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    this.publicKey,
    this.hasBackedUpPrivateKey = false,
    this.points = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      publicKey: json['publicKey'],
      hasBackedUpPrivateKey: json['hasBackedUpPrivateKey'] ?? false,
      points: json['points'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'publicKey': publicKey,
      'hasBackedUpPrivateKey': hasBackedUpPrivateKey,
      'points': points,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? publicKey,
    bool? hasBackedUpPrivateKey,
    int? points,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      publicKey: publicKey ?? this.publicKey,
      hasBackedUpPrivateKey: hasBackedUpPrivateKey ?? this.hasBackedUpPrivateKey,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

