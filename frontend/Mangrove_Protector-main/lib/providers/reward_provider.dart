import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:mangrove_protector/models/reward_model.dart';
import 'package:mangrove_protector/services/database_service.dart';

class RewardProvider with ChangeNotifier {
  List<Reward> _rewards = [];
  List<RewardItem> _rewardItems = [];
  bool _isLoading = false;
  final DatabaseService _databaseService = DatabaseService();
  final Uuid _uuid = const Uuid();

  List<Reward> get rewards => [..._rewards];
  List<RewardItem> get rewardItems => [..._rewardItems];
  bool get isLoading => _isLoading;

  Future<void> loadUserRewards(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _rewards = await _databaseService.getRewardsByUser(userId);
    } catch (e) {
      debugPrint('Error loading user rewards: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCommunityRewards(String communityId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _rewards = await _databaseService.getRewardsByCommunity(communityId);
    } catch (e) {
      debugPrint('Error loading community rewards: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRewardItems(String communityId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _rewardItems = await _databaseService.getRewardItemsByCommunity(communityId);
    } catch (e) {
      debugPrint('Error loading reward items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createReward({
    required String userId,
    required String communityId,
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
        communityId: communityId,
        points: points,
        type: type,
        description: description,
        relatedEntityId: relatedEntityId,
        status: RewardStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      // Save reward to local database
      await _databaseService.insertReward(reward);

      // Add to sync queue for later synchronization
      await _databaseService.addToSyncQueue(
        'reward',
        reward.id,
        'create',
        json.encode(reward.toJson()),
      );

      _rewards.add(reward);
      
      return true;
    } catch (e) {
      debugPrint('Error creating reward: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveReward({
    required String rewardId,
    required String approvedBy,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Find reward in local list
      final rewardIndex = _rewards.indexWhere((r) => r.id == rewardId);
      if (rewardIndex == -1) {
        throw Exception('Reward not found');
      }

      final now = DateTime.now();
      final updatedReward = _rewards[rewardIndex].copyWith(
        status: RewardStatus.approved,
        approvedBy: approvedBy,
        approvedAt: now,
        updatedAt: now,
      );

      // Update reward in local database
      await _databaseService.updateReward(updatedReward);

      // Add to sync queue for later synchronization
      await _databaseService.addToSyncQueue(
        'reward',
        updatedReward.id,
        'update',
        json.encode(updatedReward.toJson()),
      );

      _rewards[rewardIndex] = updatedReward;
      
      return true;
    } catch (e) {
      debugPrint('Error approving reward: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> redeemReward({
    required String rewardId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Find reward in local list
      final rewardIndex = _rewards.indexWhere((r) => r.id == rewardId);
      if (rewardIndex == -1) {
        throw Exception('Reward not found');
      }

      // Check if reward is approved
      if (_rewards[rewardIndex].status != RewardStatus.approved) {
        throw Exception('Reward is not approved');
      }

      final now = DateTime.now();
      final updatedReward = _rewards[rewardIndex].copyWith(
        status: RewardStatus.redeemed,
        redeemedAt: now,
        updatedAt: now,
      );

      // Update reward in local database
      await _databaseService.updateReward(updatedReward);

      // Add to sync queue for later synchronization
      await _databaseService.addToSyncQueue(
        'reward',
        updatedReward.id,
        'update',
        json.encode(updatedReward.toJson()),
      );

      _rewards[rewardIndex] = updatedReward;
      
      return true;
    } catch (e) {
      debugPrint('Error redeeming reward: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createRewardItem({
    required String communityId,
    required String name,
    required int pointsCost,
    required int availableQuantity,
    String? description,
    String? imageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final rewardItem = RewardItem(
        id: _uuid.v4(),
        communityId: communityId,
        name: name,
        description: description,
        imageUrl: imageUrl,
        pointsCost: pointsCost,
        availableQuantity: availableQuantity,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      // Save reward item to local database
      await _databaseService.insertRewardItem(rewardItem);

      // Add to sync queue for later synchronization
      await _databaseService.addToSyncQueue(
        'reward_item',
        rewardItem.id,
        'create',
        json.encode(rewardItem.toJson()),
      );

      _rewardItems.add(rewardItem);
      
      return true;
    } catch (e) {
      debugPrint('Error creating reward item: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateRewardItem({
    required String itemId,
    String? name,
    String? description,
    String? imageUrl,
    int? pointsCost,
    int? availableQuantity,
    bool? isActive,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Find reward item in local list
      final itemIndex = _rewardItems.indexWhere((item) => item.id == itemId);
      if (itemIndex == -1) {
        throw Exception('Reward item not found');
      }

      final updatedItem = _rewardItems[itemIndex].copyWith(
        name: name,
        description: description,
        imageUrl: imageUrl,
        pointsCost: pointsCost,
        availableQuantity: availableQuantity,
        isActive: isActive,
        updatedAt: DateTime.now(),
      );

      // Update reward item in local database
      await _databaseService.updateRewardItem(updatedItem);

      // Add to sync queue for later synchronization
      await _databaseService.addToSyncQueue(
        'reward_item',
        updatedItem.id,
        'update',
        json.encode(updatedItem.toJson()),
      );

      _rewardItems[itemIndex] = updatedItem;
      
      return true;
    } catch (e) {
      debugPrint('Error updating reward item: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Statistics methods
  int getTotalPoints(String userId) {
    return _rewards
        .where((reward) => 
            reward.userId == userId && 
            reward.status == RewardStatus.approved)
        .fold(0, (sum, reward) => sum + reward.points);
  }

  int getRedeemedPoints(String userId) {
    return _rewards
        .where((reward) => 
            reward.userId == userId && 
            reward.status == RewardStatus.redeemed)
        .fold(0, (sum, reward) => sum + reward.points);
  }

  int getAvailablePoints(String userId) {
    return getTotalPoints(userId) - getRedeemedPoints(userId);
  }

  List<Reward> getPendingRewards(String communityId) {
    return _rewards
        .where((reward) => 
            reward.communityId == communityId && 
            reward.status == RewardStatus.pending)
        .toList();
  }
}

