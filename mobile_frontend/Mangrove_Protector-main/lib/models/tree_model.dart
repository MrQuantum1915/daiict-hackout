enum TreeStatus {
  planted,
  verified,
  maintained,
  healthy,
  unhealthy,
  dead
}

class Tree {
  final String id;
  final String userId;
  final String communityId;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final TreeStatus status;
  final DateTime plantedDate;
  final List<Maintenance> maintenanceHistory;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;
  final String? verifiedBy;
  final DateTime? verifiedAt;

  Tree({
    required this.id,
    required this.userId,
    required this.communityId,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    required this.status,
    required this.plantedDate,
    this.maintenanceHistory = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
    this.verifiedBy,
    this.verifiedAt,
  });

  factory Tree.fromJson(Map<String, dynamic> json) {
    return Tree(
      id: json['id'],
      userId: json['userId'],
      communityId: json['communityId'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      imageUrl: json['imageUrl'],
      status: TreeStatus.values.firstWhere(
        (e) => e.toString() == 'TreeStatus.${json['status']}',
        orElse: () => TreeStatus.planted,
      ),
      plantedDate: DateTime.parse(json['plantedDate']),
      maintenanceHistory: (json['maintenanceHistory'] as List?)
          ?.map((m) => Maintenance.fromJson(m))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isVerified: json['isVerified'] ?? false,
      verifiedBy: json['verifiedBy'],
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'communityId': communityId,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'status': status.toString().split('.').last,
      'plantedDate': plantedDate.toIso8601String(),
      'maintenanceHistory': maintenanceHistory.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isVerified': isVerified,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt?.toIso8601String(),
    };
  }

  Tree copyWith({
    String? id,
    String? userId,
    String? communityId,
    double? latitude,
    double? longitude,
    String? imageUrl,
    TreeStatus? status,
    DateTime? plantedDate,
    List<Maintenance>? maintenanceHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    String? verifiedBy,
    DateTime? verifiedAt,
  }) {
    return Tree(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      communityId: communityId ?? this.communityId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      plantedDate: plantedDate ?? this.plantedDate,
      maintenanceHistory: maintenanceHistory ?? this.maintenanceHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }
}

class Maintenance {
  final String id;
  final String treeId;
  final String userId;
  final String description;
  final String? imageUrl;
  final DateTime date;
  final bool isVerified;
  final String? verifiedBy;
  final DateTime? verifiedAt;

  Maintenance({
    required this.id,
    required this.treeId,
    required this.userId,
    required this.description,
    this.imageUrl,
    required this.date,
    this.isVerified = false,
    this.verifiedBy,
    this.verifiedAt,
  });

  Maintenance copyWith({
    String? id,
    String? treeId,
    String? userId,
    String? description,
    String? imageUrl,
    DateTime? date,
    bool? isVerified,
    String? verifiedBy,
    DateTime? verifiedAt,
  }) {
    return Maintenance(
      id: id ?? this.id,
      treeId: treeId ?? this.treeId,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      isVerified: isVerified ?? this.isVerified,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }

  factory Maintenance.fromJson(Map<String, dynamic> json) {
    return Maintenance(
      id: json['id'],
      treeId: json['treeId'],
      userId: json['userId'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      date: DateTime.parse(json['date']),
      isVerified: json['isVerified'] ?? false,
      verifiedBy: json['verifiedBy'],
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'treeId': treeId,
      'userId': userId,
      'description': description,
      'imageUrl': imageUrl,
      'date': date.toIso8601String(),
      'isVerified': isVerified,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt?.toIso8601String(),
    };
  }
}
