import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:mangrove_protector/models/illegal_activity_model.dart';
import 'package:mangrove_protector/services/database_service.dart';

class IllegalActivityProvider with ChangeNotifier {
  List<IllegalActivity> _activities = [];
  bool _isLoading = false;
  final DatabaseService _databaseService = DatabaseService();
  final Uuid _uuid = const Uuid();

  List<IllegalActivity> get activities => _activities;
  bool get isLoading => _isLoading;

  // Get activities by user
  List<IllegalActivity> getActivitiesByUser(String userId) {
    return _activities.where((activity) => activity.userId == userId).toList();
  }

  // Get activities by community
  List<IllegalActivity> getActivitiesByCommunity(String communityId) {
    return _activities.where((activity) => activity.communityId == communityId).toList();
  }

  // Get pending activities (for admins)
  List<IllegalActivity> getPendingActivities() {
    return _activities.where((activity) => activity.status == ReportStatus.pending).toList();
  }

  // Load activities from database
  Future<void> loadActivities() async {
    _isLoading = true;
    notifyListeners();

    try {
      _activities = await _databaseService.getAllIllegalActivities();
    } catch (e) {
      debugPrint('Error loading activities: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new illegal activity report
  Future<bool> addActivity({
    required String userId,
    required String communityId,
    required IllegalActivityType activityType,
    required String description,
    required double latitude,
    required double longitude,
    String? imageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final activity = IllegalActivity(
        id: _uuid.v4(),
        userId: userId,
        communityId: communityId,
        activityType: activityType,
        description: description,
        latitude: latitude,
        longitude: longitude,
        imageUrl: imageUrl,
        reportedDate: now,
        createdAt: now,
        updatedAt: now,
      );

      // Save to database
      await _databaseService.insertIllegalActivity(activity);

      // Add to local list
      _activities.add(activity);

      return true;
    } catch (e) {
      debugPrint('Error adding activity: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update activity status (for admins)
  Future<bool> updateActivityStatus({
    required String activityId,
    required ReportStatus status,
    String? adminNotes,
    String? resolutionNotes,
  }) async {
    try {
      final activityIndex = _activities.indexWhere((a) => a.id == activityId);
      if (activityIndex == -1) return false;

      final activity = _activities[activityIndex];
      final updatedActivity = activity.copyWith(
        status: status,
        adminNotes: adminNotes,
        resolutionNotes: resolutionNotes,
        updatedAt: DateTime.now(),
      );

      // Update in database
      await _databaseService.updateIllegalActivity(updatedActivity);

      // Update in local list
      _activities[activityIndex] = updatedActivity;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error updating activity status: $e');
      return false;
    }
  }

  // Verify activity (for admins)
  Future<bool> verifyActivity({
    required String activityId,
    required String verifiedBy,
  }) async {
    try {
      final activityIndex = _activities.indexWhere((a) => a.id == activityId);
      if (activityIndex == -1) return false;

      final activity = _activities[activityIndex];
      final updatedActivity = activity.copyWith(
        isVerified: true,
        verifiedBy: verifiedBy,
        verifiedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Update in database
      await _databaseService.updateIllegalActivity(updatedActivity);

      // Update in local list
      _activities[activityIndex] = updatedActivity;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error verifying activity: $e');
      return false;
    }
  }

  // Get activity by ID
  IllegalActivity? getActivityById(String id) {
    try {
      return _activities.firstWhere((activity) => activity.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get statistics
  Map<String, int> getActivityStatistics() {
    final stats = <String, int>{};
    
    for (final activity in _activities) {
      final type = activity.activityType.toString().split('.').last;
      stats[type] = (stats[type] ?? 0) + 1;
    }
    
    return stats;
  }

  // Get status statistics
  Map<String, int> getStatusStatistics() {
    final stats = <String, int>{};
    
    for (final activity in _activities) {
      final status = activity.status.toString().split('.').last;
      stats[status] = (stats[status] ?? 0) + 1;
    }
    
    return stats;
  }
} 