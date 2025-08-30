import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:mangrove_protector/models/reward_model.dart';
import 'package:mangrove_protector/services/supabase_service.dart';

class RewardProvider with ChangeNotifier {
  List<Reward> _rewards = [];
  final List<RewardItem> _rewardItems = [];
  bool _isLoading = false;
  final Uuid _uuid = const Uuid();

  List<Reward> get rewards => [..._rewards];
  List<RewardItem> get rewardItems => [..._rewardItems];
  bool get isLoading => _isLoading;

  Future<void> loadUserRewards(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _rewards = await SupabaseService.getUserRewards(userId);
    } catch (e) {
      debugPrint('Error loading user rewards: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createReward({
    required String userId,
    required int points,
    required RewardType type,
    String? description,
    String? relatedEntityId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final reward = Reward(
        id: _uuid.v4(),
        userId: userId,
        points: points,
        type: type,
        description: description,
        relatedEntityId: relatedEntityId,
        status: RewardStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      // Save reward to Supabase
      final savedReward = await SupabaseService.createReward(reward);
      _rewards.add(savedReward);
      
      return true;
    } catch (e) {
      debugPrint('Error creating reward: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateRewardStatus({
    required String rewardId,
    required RewardStatus status,
    String? adminNotes,
  }) async {
    try {
      final rewardIndex = _rewards.indexWhere((r) => r.id == rewardId);
      if (rewardIndex == -1) return false;

      final reward = _rewards[rewardIndex];
      final updatedReward = reward.copyWith(
        status: status,
        adminNotes: adminNotes,
        updatedAt: DateTime.now(),
      );

      // Update in Supabase
      final savedReward = await SupabaseService.updateReward(updatedReward);

      // Update local list
      _rewards[rewardIndex] = savedReward;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error updating reward status: $e');
      return false;
    }
  }

  Future<bool> redeemReward(String rewardId) async {
    try {
      final rewardIndex = _rewards.indexWhere((r) => r.id == rewardId);
      if (rewardIndex == -1) return false;

      final reward = _rewards[rewardIndex];
      if (reward.status != RewardStatus.approved) return false;

      final updatedReward = reward.copyWith(
        status: RewardStatus.redeemed,
        redeemedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Update in Supabase
      final savedReward = await SupabaseService.updateReward(updatedReward);

      // Update local list
      _rewards[rewardIndex] = savedReward;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error redeeming reward: $e');
      return false;
    }
  }

  // Get rewards by status
  List<Reward> getRewardsByStatus(RewardStatus status) {
    return _rewards.where((reward) => reward.status == status).toList();
  }

  // Get total points earned
  int getTotalPointsEarned(String userId) {
    return _rewards
        .where((reward) => reward.userId == userId && reward.status == RewardStatus.approved)
        .fold(0, (sum, reward) => sum + reward.points);
  }

  // Get pending rewards count
  int getPendingRewardsCount(String userId) {
    return _rewards
        .where((reward) => reward.userId == userId && reward.status == RewardStatus.pending)
        .length;
  }

  // Clear rewards
  void clearRewards() {
    _rewards.clear();
    notifyListeners();
  }
}

