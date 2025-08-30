import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangrove_protector/providers/tree_provider.dart';
import 'package:mangrove_protector/providers/reward_provider.dart';
import 'package:mangrove_protector/models/tree_model.dart';
import 'package:mangrove_protector/models/reward_model.dart';
import 'package:mangrove_protector/utils/app_theme.dart';

class RecentActivityList extends StatelessWidget {
  final String userId;

  const RecentActivityList({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final treeProvider = Provider.of<TreeProvider>(context);
    final rewardProvider = Provider.of<RewardProvider>(context);

    // Get user's trees
    final trees = treeProvider.trees
        .where((tree) => tree.userId == userId)
        .toList();

    // Get all maintenance activities
    final maintenanceActivities = <Maintenance>[];
    for (final tree in trees) {
      maintenanceActivities.addAll(tree.maintenanceHistory
          .where((m) => m.userId == userId));
    }

    // Get user's rewards
    final rewards = rewardProvider.rewards
        .where((reward) => reward.userId == userId)
        .toList();

    // Combine all activities
    final activities = <Map<String, dynamic>>[];

    // Add tree plantings
    for (final tree in trees) {
      activities.add({
        'type': 'planting',
        'data': tree,
        'date': tree.plantedDate,
      });
    }

    // Add maintenance activities
    for (final maintenance in maintenanceActivities) {
      activities.add({
        'type': 'maintenance',
        'data': maintenance,
        'date': maintenance.date,
      });
    }

    // Add rewards
    for (final reward in rewards) {
      activities.add({
        'type': 'reward',
        'data': reward,
        'date': reward.createdAt,
      });
    }

    // Sort by date (newest first)
    activities.sort((a, b) => b['date'].compareTo(a['date']));

    // Take only the 10 most recent activities
    final recentActivities = activities.take(10).toList();

    if (recentActivities.isEmpty) {
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
              'No activity yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Plant trees and maintain them to see your activity here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentActivities.length,
      itemBuilder: (context, index) {
        final activity = recentActivities[index];
        return _buildActivityItem(context, activity);
      },
    );
  }

  Widget _buildActivityItem(BuildContext context, Map<String, dynamic> activity) {
    final type = activity['type'] as String;
    final data = activity['data'];
    final date = activity['date'] as DateTime;

    IconData icon;
    Color iconColor;
    String title;
    String? subtitle;
    Widget? trailing;

    switch (type) {
      case 'planting':
        final tree = data as Tree;
        icon = Icons.nature;
        iconColor = AppTheme.primaryColor;
        title = 'Planted a mangrove tree';
        subtitle = 'Status: ${_getTreeStatusText(tree.status)}';
        trailing = tree.isVerified
            ? Icon(Icons.verified, color: Colors.green)
            : null;
        break;
      case 'maintenance':
        final maintenance = data as Maintenance;
        icon = Icons.healing;
        iconColor = Colors.orange;
        title = 'Maintained a tree';
        subtitle = maintenance.description;
        trailing = maintenance.isVerified
            ? Icon(Icons.verified, color: Colors.green)
            : null;
        break;
      case 'reward':
        final reward = data as Reward;
        icon = Icons.stars;
        iconColor = AppTheme.accentColor;
        title = 'Received ${reward.points} points';
        subtitle = reward.description;
        trailing = _getRewardStatusIcon(reward.status);
        break;
      default:
        icon = Icons.event;
        iconColor = Colors.grey;
        title = 'Unknown activity';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(
            icon,
            color: iconColor,
          ),
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle),
            ],
            const SizedBox(height: 4),
            Text(
              _formatDate(date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: trailing,
      ),
    );
  }

  String _getTreeStatusText(TreeStatus status) {
    switch (status) {
      case TreeStatus.planted:
        return 'Planted';
      case TreeStatus.verified:
        return 'Verified';
      case TreeStatus.maintained:
        return 'Maintained';
      case TreeStatus.healthy:
        return 'Healthy';
      case TreeStatus.unhealthy:
        return 'Unhealthy';
      case TreeStatus.dead:
        return 'Dead';
    }
  }

  Widget? _getRewardStatusIcon(RewardStatus status) {
    switch (status) {
      case RewardStatus.pending:
        return Icon(Icons.pending, color: Colors.orange);
      case RewardStatus.approved:
        return Icon(Icons.check_circle, color: Colors.green);
      case RewardStatus.rejected:
        return Icon(Icons.cancel, color: Colors.red);
      case RewardStatus.redeemed:
        return Icon(Icons.redeem, color: Colors.blue);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

