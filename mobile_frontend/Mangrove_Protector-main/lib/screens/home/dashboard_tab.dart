import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangrove_protector/providers/auth_provider.dart';
import 'package:mangrove_protector/providers/tree_provider.dart';
import 'package:mangrove_protector/providers/illegal_activity_provider.dart';
import 'package:mangrove_protector/providers/reward_provider.dart';
import 'package:mangrove_protector/models/illegal_activity_model.dart';
import 'package:mangrove_protector/utils/app_theme.dart';
import 'package:mangrove_protector/widgets/stat_card.dart';
import 'package:mangrove_protector/widgets/recent_activity_list.dart';
import 'package:mangrove_protector/screens/map/activities_map_screen.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final treeProvider = Provider.of<TreeProvider>(context, listen: false);
      final illegalActivityProvider = Provider.of<IllegalActivityProvider>(context, listen: false);
      final rewardProvider = Provider.of<RewardProvider>(context, listen: false);

      if (authProvider.currentUser != null) {
        // Load user's data
        await treeProvider.loadUserTrees(authProvider.currentUser!.id);
        await illegalActivityProvider.loadActivities();
        await rewardProvider.loadUserRewards(authProvider.currentUser!.id);
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
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
    final illegalActivityProvider = Provider.of<IllegalActivityProvider>(context);
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

    final userActivities = illegalActivityProvider.getActivitiesByUser(user.id);
    final totalReports = userActivities.length;
    final pendingReports = userActivities.where((a) => a.status == ReportStatus.pending).length;
    final resolvedReports = userActivities.where((a) => a.status == ReportStatus.resolved).length;
    final verifiedReports = userActivities.where((a) => a.isVerified).length;
    final availablePoints = rewardProvider.getAvailablePoints(user.id);

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Text(
                'Welcome, ${user.nickname}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Community: ${authProvider.currentCommunity?.name ?? 'Unknown'}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              
              // Stats grid
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StatCard(
                    title: 'Total Reports',
                    value: totalReports.toString(),
                    icon: Icons.report,
                    color: AppTheme.primaryColor,
                  ),
                  StatCard(
                    title: 'Pending Reports',
                    value: pendingReports.toString(),
                    icon: Icons.pending,
                    color: Colors.orange,
                  ),
                  StatCard(
                    title: 'Resolved Reports',
                    value: resolvedReports.toString(),
                    icon: Icons.check_circle,
                    color: AppTheme.secondaryColor,
                  ),
                  StatCard(
                    title: 'Verified Reports',
                    value: verifiedReports.toString(),
                    icon: Icons.verified,
                    color: Colors.blue,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Points card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.stars,
                          size: 30,
                          color: AppTheme.accentColor,
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              availablePoints.toString(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to rewards tab
                          // Use a more direct approach to navigate
                          Navigator.of(context).pushNamed('/rewards');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Redeem'),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Map section
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ActivitiesMapScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.map,
                            size: 30,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'View Activities Map',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'See all reported illegal activities on a map',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Recent activity
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              RecentActivityList(userId: user.id),
            ],
          ),
        ),
      ),
    );
  }
}
