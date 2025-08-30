import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangrove_protector/providers/auth_provider.dart';
import 'package:mangrove_protector/providers/tree_provider.dart';
import 'package:mangrove_protector/providers/reward_provider.dart';
import 'package:mangrove_protector/utils/app_theme.dart';

class CommunityStatsScreen extends StatefulWidget {
  const CommunityStatsScreen({super.key});

  @override
  State<CommunityStatsScreen> createState() => _CommunityStatsScreenState();
}

class _CommunityStatsScreenState extends State<CommunityStatsScreen> {
  bool _isLoading = true;
  int _totalMembers = 0;
  int _totalTrees = 0;
  int _verifiedTrees = 0;
  double _healthRate = 0.0;
  int _totalPoints = 0;
  int _redeemedPoints = 0;
  List<Map<String, dynamic>> _topPlanters = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final treeProvider = Provider.of<TreeProvider>(context, listen: false);
      final rewardProvider = Provider.of<RewardProvider>(context, listen: false);

      if (authProvider.currentUser == null || authProvider.currentCommunity == null) {
        throw Exception('User or community not found');
      }

      // Load community trees
      await treeProvider.loadCommunityTrees(authProvider.currentCommunity!.id);
      
      // Load community rewards
      await rewardProvider.loadCommunityRewards(authProvider.currentCommunity!.id);
      
      // Get community members
      final members = await authProvider.getUsersByCommunity(authProvider.currentCommunity!.id);
      
      // Calculate stats
      _totalMembers = members.length;
      _totalTrees = treeProvider.getCommunityTotalTrees(authProvider.currentCommunity!.id);
      _verifiedTrees = treeProvider.getCommunityVerifiedTrees(authProvider.currentCommunity!.id);
      _healthRate = treeProvider.getCommunityHealthRate(authProvider.currentCommunity!.id);
      
      // Calculate total and redeemed points
      _totalPoints = 0;
      _redeemedPoints = 0;
      for (final member in members) {
        _totalPoints += rewardProvider.getTotalPoints(member.id);
        _redeemedPoints += rewardProvider.getRedeemedPoints(member.id);
      }
      
      // Calculate top planters
      _topPlanters = [];
      for (final member in members) {
        final treesPlanted = treeProvider.getTotalTreesPlanted(member.id);
        if (treesPlanted > 0) {
          _topPlanters.add({
            'nickname': member.nickname,
            'treesPlanted': treesPlanted,
          });
        }
      }
      
      // Sort top planters by trees planted (descending)
      _topPlanters.sort((a, b) => b['treesPlanted'].compareTo(a['treesPlanted']));
      
      // Take top 5
      if (_topPlanters.length > 5) {
        _topPlanters = _topPlanters.sublist(0, 5);
      }
    } catch (e) {
      debugPrint('Error loading community stats: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Statistics'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Community info
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.group,
                                    size: 28,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        authProvider.currentCommunity?.name ?? 'Community',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Members: $_totalMembers',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (authProvider.currentCommunity?.description != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                authProvider.currentCommunity!.description!,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Tree statistics
                    const Text(
                      'Tree Statistics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Tree stats grid
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStatCard(
                          title: 'Total Trees',
                          value: _totalTrees.toString(),
                          icon: Icons.nature,
                          color: AppTheme.primaryColor,
                        ),
                        _buildStatCard(
                          title: 'Verified Trees',
                          value: _verifiedTrees.toString(),
                          icon: Icons.check_circle,
                          color: AppTheme.secondaryColor,
                        ),
                        _buildStatCard(
                          title: 'Verification Rate',
                          value: _totalTrees > 0
                              ? '${(_verifiedTrees / _totalTrees * 100).toStringAsFixed(1)}%'
                              : '0%',
                          icon: Icons.verified,
                          color: Colors.blue,
                        ),
                        _buildStatCard(
                          title: 'Health Rate',
                          value: '${(_healthRate * 100).toStringAsFixed(1)}%',
                          icon: Icons.favorite,
                          color: Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Reward statistics
                    const Text(
                      'Reward Statistics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Reward stats
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        _totalPoints.toString(),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.accentColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Total Points',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.grey[300],
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        _redeemedPoints.toString(),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Redeemed Points',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.grey[300],
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        (_totalPoints - _redeemedPoints).toString(),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Available Points',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_totalPoints > 0) ...[
                              const Text(
                                'Points Redemption Rate',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: _redeemedPoints / _totalPoints,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(_redeemedPoints / _totalPoints * 100).toStringAsFixed(1)}% of points redeemed',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Top planters
                    const Text(
                      'Top Planters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_topPlanters.isEmpty)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.nature_people,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No tree planting data yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _topPlanters.length,
                        itemBuilder: (context, index) {
                          final planter = _topPlanters[index];
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
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              title: Text(
                                planter['nickname'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${planter['treesPlanted']} trees',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 36,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

