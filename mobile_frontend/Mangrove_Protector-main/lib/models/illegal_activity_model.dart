enum IllegalActivityType {
  illegalCutting,
  wasteDumping,
  pollution,
  encroachment,
  other
}

enum ReportStatus {
  pending,
  underInvestigation,
  resolved,
  dismissed
}

class IllegalActivity {
  final String id;
  final String userId;
  final String communityId;
  final IllegalActivityType activityType;
  final String description;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final ReportStatus status;
  final DateTime reportedDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? adminNotes;
  final String? resolutionNotes;

  IllegalActivity({
    required this.id,
    required this.userId,
    required this.communityId,
    required this.activityType,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.status = ReportStatus.pending,
    required this.reportedDate,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
    this.verifiedBy,
    this.verifiedAt,
    this.adminNotes,
    this.resolutionNotes,
  });

  factory IllegalActivity.fromJson(Map<String, dynamic> json) {
    return IllegalActivity(
      id: json['id'],
      userId: json['userId'],
      communityId: json['communityId'],
      activityType: IllegalActivityType.values.firstWhere(
        (e) => e.toString() == 'IllegalActivityType.${json['activityType']}',
        orElse: () => IllegalActivityType.other,
      ),
      description: json['description'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      imageUrl: json['imageUrl'],
      status: ReportStatus.values.firstWhere(
        (e) => e.toString() == 'ReportStatus.${json['status']}',
        orElse: () => ReportStatus.pending,
      ),
      reportedDate: DateTime.parse(json['reportedDate']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isVerified: json['isVerified'] ?? false,
      verifiedBy: json['verifiedBy'],
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'])
          : null,
      adminNotes: json['adminNotes'],
      resolutionNotes: json['resolutionNotes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'communityId': communityId,
      'activityType': activityType.toString().split('.').last,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'status': status.toString().split('.').last,
      'reportedDate': reportedDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isVerified': isVerified,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'adminNotes': adminNotes,
      'resolutionNotes': resolutionNotes,
    };
  }

  IllegalActivity copyWith({
    String? id,
    String? userId,
    String? communityId,
    IllegalActivityType? activityType,
    String? description,
    double? latitude,
    double? longitude,
    String? imageUrl,
    ReportStatus? status,
    DateTime? reportedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? adminNotes,
    String? resolutionNotes,
  }) {
    return IllegalActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      communityId: communityId ?? this.communityId,
      activityType: activityType ?? this.activityType,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      reportedDate: reportedDate ?? this.reportedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
    );
  }
} 