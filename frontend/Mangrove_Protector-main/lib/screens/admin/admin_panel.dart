import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangrove_protector/providers/auth_provider.dart';
import 'package:mangrove_protector/providers/tree_provider.dart';
import 'package:mangrove_protector/providers/reward_provider.dart';
import 'package:mangrove_protector/utils/app_theme.dart';
import 'package:mangrove_protector/screens/admin/verify_trees_screen.dart';
import 'package:mangrove_protector/screens/admin/manage_rewards_screen.dart';
import 'package:mangrove_protector/screens/admin/community_stats_screen.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  bool _isLoading = true;
  int _pendingVerifications = 0;
  int _pendingRewards = 0;
  int _communityMembers = 0;
  int _totalTrees = 0;

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
      setState(() {
        _pendingVerifications = treeProvider.trees
            .where((tree) => !tree.isVerified)
            .length;
        
        _pendingRewards = rewardProvider.getPendingRewards(authProvider.currentCommunity!.id).length;
        
        _communityMembers = members.length;
        
        _totalTrees = treeProvider.getCommunityTotalTrees(authProvider.currentCommunity!.id);
      });
    } catch (e) {
      debugPrint('Error loading admin data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToVerifyTrees() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VerifyTreesScreen()),
    );
  }

  void _navigateToManageRewards() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ManageRewardsScreen()),
    );
  }

  void _navigateToCommunityStats() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CommunityStatsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Check if user is admin
    if (!authProvider.isAdmin()) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('You do not have permission to access this page.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin welcome
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.admin_panel_settings,
                              size: 36,
                              color: Colors.amber[800],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Community Admin',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Manage ${authProvider.currentCommunity?.name ?? 'your community'}',
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
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Stats overview
                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Stats grid
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStatCard(
                        title: 'Pending Verifications',
                        value: _pendingVerifications.toString(),
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                      ),
                      _buildStatCard(
                        title: 'Pending Rewards',
                        value: _pendingRewards.toString(),
                        icon: Icons.card_giftcard,
                        color: Colors.purple,
                      ),
                      _buildStatCard(
                        title: 'Community Members',
                        value: _communityMembers.toString(),
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                      _buildStatCard(
                        title: 'Total Trees',
                        value: _totalTrees.toString(),
                        icon: Icons.nature,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Admin actions
                  const Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Verify trees
                  _buildActionCard(
                    title: 'Verify Trees',
                    description: 'Approve tree plantings and maintenance activities',
                    icon: Icons.check_circle,
                    color: AppTheme.primaryColor,
                    badge: _pendingVerifications > 0 ? _pendingVerifications.toString() : null,
                    onTap: _navigateToVerifyTrees,
                  ),
                  
                  // Manage rewards
                  _buildActionCard(
                    title: 'Manage Rewards',
                    description: 'Approve reward requests and add new reward items',
                    icon: Icons.card_giftcard,
                    color: Colors.purple,
                    badge: _pendingRewards > 0 ? _pendingRewards.toString() : null,
                    onTap: _navigateToManageRewards,
                  ),
                  
                  // Community stats
                  _buildActionCard(
                    title: 'Community Statistics',
                    description: 'View detailed statistics about your community',
                    icon: Icons.bar_chart,
                    color: Colors.blue,
                    onTap: _navigateToCommunityStats,
                  ),
                ],
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

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

