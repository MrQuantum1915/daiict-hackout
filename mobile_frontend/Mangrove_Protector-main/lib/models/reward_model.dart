enum RewardType {
  reporting,
  verification,
  milestone,
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
  final int points;
  final RewardType type;
  final String? description;
  final String? relatedEntityId; // Report ID or other entity ID
  final RewardStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? redeemedAt;
  final String? adminNotes;

  Reward({
    required this.id,
    required this.userId,
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
    this.adminNotes,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'],
      userId: json['userId'],
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
      adminNotes: json['adminNotes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
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
      'adminNotes': adminNotes,
    };
  }

  Reward copyWith({
    String? id,
    String? userId,
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
    String? adminNotes,
  }) {
    return Reward(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }
}

class RewardItem {
  final String id;
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
    required this.name,
    this.description,
    this.imageUrl,
    required this.pointsCost,
    required this.availableQuantity,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RewardItem.fromJson(Map<String, dynamic> json) {
    return RewardItem(
      id: json['id'],
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

  RewardItem copyWith({
    String? id,
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
}
