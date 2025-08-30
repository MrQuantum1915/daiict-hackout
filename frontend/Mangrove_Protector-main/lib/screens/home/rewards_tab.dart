import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangrove_protector/providers/auth_provider.dart';
import 'package:mangrove_protector/providers/reward_provider.dart';
import 'package:mangrove_protector/models/reward_model.dart';
import 'package:mangrove_protector/utils/app_theme.dart';
import 'package:mangrove_protector/widgets/reward_item_card.dart';

class RewardsTab extends StatefulWidget {
  const RewardsTab({super.key});

  @override
  State<RewardsTab> createState() => _RewardsTabState();
}

class _RewardsTabState extends State<RewardsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final rewardProvider = Provider.of<RewardProvider>(context, listen: false);

      if (authProvider.currentUser != null && authProvider.currentCommunity != null) {
        // Load user's rewards
        await rewardProvider.loadUserRewards(authProvider.currentUser!.id);
        
        // Load reward items for the community
        await rewardProvider.loadRewardItems(authProvider.currentCommunity!.id);
      }
    } catch (e) {
      debugPrint('Error loading rewards data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final rewardProvider = Provider.of<RewardProvider>(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final user = authProvider.currentUser;
    if (user == null) {
      return const Center(
        child: Text('User not found. Please log in again.'),
      );
    }

    final availablePoints = rewardProvider.getAvailablePoints(user.id);
    final rewardItems = rewardProvider.rewardItems;

    return Column(
      children: [
        // Points card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.stars,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Points',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          availablePoints.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Use your points to redeem rewards for your community',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        
        // Tab bar
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Available Rewards'),
            Tab(text: 'My Rewards'),
          ],
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Available rewards tab
              RefreshIndicator(
                onRefresh: _refreshData,
                child: rewardItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.card_giftcard,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No rewards available yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check back later for community rewards',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: rewardItems.length,
                        itemBuilder: (context, index) {
                          final item = rewardItems[index];
                          return RewardItemCard(
                            rewardItem: item,
                            userPoints: availablePoints,
                            onRedeem: () => _redeemReward(item),
                          );
                        },
                      ),
              ),
              
              // My rewards tab
              RefreshIndicator(
                onRefresh: _refreshData,
                child: _buildMyRewardsTab(rewardProvider, user.id),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMyRewardsTab(RewardProvider rewardProvider, String userId) {
    final rewards = rewardProvider.rewards
        .where((r) => r.userId == userId)
        .toList();
    
    if (rewards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No rewards history yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Plant trees and maintain them to earn rewards',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    
    // Sort rewards by date (newest first)
    rewards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: _getRewardTypeIcon(reward.type),
            title: Text(
              _getRewardTypeText(reward.type),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(reward.description ?? ''),
                const SizedBox(height: 4),
                Text(
                  'Date: ${_formatDate(reward.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+${reward.points} pts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                _getStatusChip(reward.status),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _getRewardTypeIcon(RewardType type) {
    IconData iconData;
    Color iconColor;
    
    switch (type) {
      case RewardType.planting:
        iconData = Icons.nature;
        iconColor = AppTheme.primaryColor;
        break;
      case RewardType.maintenance:
        iconData = Icons.healing;
        iconColor = Colors.orange;
        break;
      case RewardType.verification:
        iconData = Icons.check_circle;
        iconColor = AppTheme.secondaryColor;
        break;
      case RewardType.reporting:
        iconData = Icons.report;
        iconColor = AppTheme.errorColor;
        break;
      case RewardType.other:
        iconData = Icons.stars;
        iconColor = Colors.purple;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  String _getRewardTypeText(RewardType type) {
    switch (type) {
      case RewardType.planting:
        return 'Tree Planting';
      case RewardType.maintenance:
        return 'Tree Maintenance';
      case RewardType.verification:
        return 'Verification';
      case RewardType.reporting:
        return 'Illegal Activity Report';
      case RewardType.other:
        return 'Other Activity';
    }
  }

  Widget _getStatusChip(RewardStatus status) {
    String label;
    Color color;
    
    switch (status) {
      case RewardStatus.pending:
        label = 'Pending';
        color = Colors.orange;
        break;
      case RewardStatus.approved:
        label = 'Approved';
        color = Colors.green;
        break;
      case RewardStatus.rejected:
        label = 'Rejected';
        color = Colors.red;
        break;
      case RewardStatus.redeemed:
        label = 'Redeemed';
        color = Colors.blue;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _redeemReward(RewardItem item) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final rewardProvider = Provider.of<RewardProvider>(context, listen: false);
    
    if (authProvider.currentUser == null) return;
    
    final availablePoints = rewardProvider.getAvailablePoints(authProvider.currentUser!.id);
    
    if (availablePoints < item.pointsCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough points to redeem this reward'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redeem Reward'),
        content: Text('Are you sure you want to redeem "${item.name}" for ${item.pointsCost} points?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Create a reward redemption request
      final success = await rewardProvider.createReward(
        userId: authProvider.currentUser!.id,
        communityId: authProvider.currentCommunity!.id,
        points: -item.pointsCost, // Negative points for redemption
        type: RewardType.other,
        description: 'Redeemed: ${item.name}',
      );
      
      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully redeemed "${item.name}"'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh data
          await _refreshData();
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to redeem reward. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

