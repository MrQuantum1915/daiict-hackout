enum RewardType {
  planting,
  maintenance,
  verification,
  reporting,
  other
}

enum RewardStatus {
  pending,
  approved,
  rejected,
  redeemed
}

class Reward {
  final String id;
  final String userId;
  final String communityId;
  final int points;
  final RewardType type;
  final String? description;
  final String? relatedEntityId; // Tree ID or Maintenance ID
  final RewardStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? redeemedAt;

  Reward({
    required this.id,
    required this.userId,
    required this.communityId,
    required this.points,
    required this.type,
    this.description,
    this.relatedEntityId,
    this.status = RewardStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.approvedBy,
    this.approvedAt,
    this.redeemedAt,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'],
      userId: json['userId'],
      communityId: json['communityId'],
      points: json['points'],
      type: RewardType.values.firstWhere(
        (e) => e.toString() == 'RewardType.${json['type']}',
        orElse: () => RewardType.other,
      ),
      description: json['description'],
      relatedEntityId: json['relatedEntityId'],
      status: RewardStatus.values.firstWhere(
        (e) => e.toString() == 'RewardStatus.${json['status']}',
        orElse: () => RewardStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
      redeemedAt: json['redeemedAt'] != null
          ? DateTime.parse(json['redeemedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'communityId': communityId,
      'points': points,
      'type': type.toString().split('.').last,
      'description': description,
      'relatedEntityId': relatedEntityId,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'redeemedAt': redeemedAt?.toIso8601String(),
    };
  }

  Reward copyWith({
    String? id,
    String? userId,
    String? communityId,
    int? points,
    RewardType? type,
    String? description,
    String? relatedEntityId,
    RewardStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? redeemedAt,
  }) {
    return Reward(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      communityId: communityId ?? this.communityId,
      points: points ?? this.points,
      type: type ?? this.type,
      description: description ?? this.description,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      redeemedAt: redeemedAt ?? this.redeemedAt,
    );
  }
}

class RewardItem {
  final String id;
  final String communityId;
  final String name;
  final String? description;
  final String? imageUrl;
  final int pointsCost;
  final int availableQuantity;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  RewardItem({
    required this.id,
    required this.communityId,
    required this.name,
    this.description,
    this.imageUrl,
    required this.pointsCost,
    required this.availableQuantity,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  RewardItem copyWith({
    String? id,
    String? communityId,
    String? name,
    String? description,
    String? imageUrl,
    int? pointsCost,
    int? availableQuantity,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RewardItem(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      pointsCost: pointsCost ?? this.pointsCost,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory RewardItem.fromJson(Map<String, dynamic> json) {
    return RewardItem(
      id: json['id'],
      communityId: json['communityId'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      pointsCost: json['pointsCost'],
      availableQuantity: json['availableQuantity'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'communityId': communityId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'pointsCost': pointsCost,
      'availableQuantity': availableQuantity,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
