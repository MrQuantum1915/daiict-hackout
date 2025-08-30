import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:mangrove_protector/models/illegal_activity_model.dart';
import 'package:mangrove_protector/services/supabase_service.dart';

class IllegalActivityProvider with ChangeNotifier {
  List<IllegalActivity> _activities = [];
  bool _isLoading = false;
  final Uuid _uuid = const Uuid();

  List<IllegalActivity> get activities => [..._activities];
  bool get isLoading => _isLoading;

  Future<void> loadUserReports(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _activities = await SupabaseService.getUserReports(userId);
    } catch (e) {
      debugPrint('Error loading user reports: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addActivity({
    required String userId,
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
      final report = IllegalActivity(
        id: _uuid.v4(),
        userId: userId,
        activityType: activityType,
        description: description,
        latitude: latitude,
        longitude: longitude,
        imageUrl: imageUrl,
        status: 'Submitted',
        reportedDate: now,
        createdAt: now,
        updatedAt: now,
      );

      // Submit report to server (this handles encryption and AI validation)
      final savedReport = await SupabaseService.createReport(report);
      
      // Add to local list
      _activities.insert(0, savedReport);
      
      return true;
    } catch (e) {
      debugPrint('Error adding activity: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateActivityStatus({
    required String reportId,
    required String status,
    String? adminNotes,
  }) async {
    try {
      final reportIndex = _activities.indexWhere((activity) => activity.id == reportId);
      if (reportIndex == -1) return false;

      final report = _activities[reportIndex];
      final updatedReport = report.copyWith(
        status: status,
        adminNotes: adminNotes,
        updatedAt: DateTime.now(),
      );

      // Update in Supabase
      final savedReport = await SupabaseService.updateReport(updatedReport);
      
      // Update local list
      _activities[reportIndex] = savedReport;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error updating activity status: $e');
      return false;
    }
  }

  Future<bool> updateAIScore({
    required String reportId,
    required double aiScore,
    required String aiExplanation,
  }) async {
    try {
      final reportIndex = _activities.indexWhere((activity) => activity.id == reportId);
      if (reportIndex == -1) return false;

      final report = _activities[reportIndex];
      final updatedReport = report.copyWith(
        aiScore: aiScore,
        aiExplanation: aiExplanation,
        updatedAt: DateTime.now(),
      );

      // Update in Supabase
      final savedReport = await SupabaseService.updateReport(updatedReport);
      
      // Update local list
      _activities[reportIndex] = savedReport;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error updating AI score: $e');
      return false;
    }
  }

  void clearActivities() {
    _activities.clear();
    notifyListeners();
  }

  // Get activities by status
  List<IllegalActivity> getActivitiesByStatus(String status) {
    return _activities.where((activity) => activity.status == status).toList();
  }

  // Get pending activities count
  int getPendingActivitiesCount() {
    return _activities.where((activity) => 
      activity.status == 'Submitted' || 
      activity.status == 'Pending NGO Verification'
    ).length;
  }

  // Get approved activities count
  int getApprovedActivitiesCount() {
    return _activities.where((activity) => activity.status == 'Approved').length;
  }

  // Get total activities count
  int getTotalActivitiesCount() {
    return _activities.length;
  }
} 