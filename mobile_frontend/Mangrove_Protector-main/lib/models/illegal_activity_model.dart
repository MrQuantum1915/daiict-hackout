enum IllegalActivityType {
  illegalDumping,
  poaching,
  deforestation,
  pollution,
  construction,
  other
}

enum ReportStatus {
  submitted,
  pendingNgoVerification,
  approved,
  rejected,
  flagged
}

class IllegalActivity {
  final String id;
  final String userId;
  final IllegalActivityType activityType;
  final String description;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String status; // Changed to String to match database
  final DateTime reportedDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? adminNotes;
  final String? resolutionNotes;
  final double? aiScore;
  final String? aiExplanation;

  IllegalActivity({
    required this.id,
    required this.userId,
    required this.activityType,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.status = 'Submitted',
    required this.reportedDate,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
    this.verifiedBy,
    this.verifiedAt,
    this.adminNotes,
    this.resolutionNotes,
    this.aiScore,
    this.aiExplanation,
  });

  factory IllegalActivity.fromJson(Map<String, dynamic> json) {
    return IllegalActivity(
      id: json['id'],
      userId: json['userId'],
      activityType: IllegalActivityType.values.firstWhere(
        (e) => e.toString() == 'IllegalActivityType.${json['activityType']}',
        orElse: () => IllegalActivityType.other,
      ),
      description: json['description'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      imageUrl: json['imageUrl'],
      status: json['status'] ?? 'Submitted',
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
      aiScore: json['aiScore']?.toDouble(),
      aiExplanation: json['aiExplanation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'activityType': activityType.toString().split('.').last,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'status': status,
      'reportedDate': reportedDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isVerified': isVerified,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'adminNotes': adminNotes,
      'resolutionNotes': resolutionNotes,
      'aiScore': aiScore,
      'aiExplanation': aiExplanation,
    };
  }

  IllegalActivity copyWith({
    String? id,
    String? userId,
    IllegalActivityType? activityType,
    String? description,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? status,
    DateTime? reportedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? adminNotes,
    String? resolutionNotes,
    double? aiScore,
    String? aiExplanation,
  }) {
    return IllegalActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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
      aiScore: aiScore ?? this.aiScore,
      aiExplanation: aiExplanation ?? this.aiExplanation,
    );
  }
} 