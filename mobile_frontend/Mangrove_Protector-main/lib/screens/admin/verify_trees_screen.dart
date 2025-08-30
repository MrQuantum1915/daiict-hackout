import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangrove_protector/providers/auth_provider.dart';
import 'package:mangrove_protector/providers/tree_provider.dart';
import 'package:mangrove_protector/providers/reward_provider.dart';
import 'package:mangrove_protector/models/tree_model.dart';
import 'package:mangrove_protector/models/reward_model.dart';
import 'package:mangrove_protector/utils/app_theme.dart';

class VerifyTreesScreen extends StatefulWidget {
  const VerifyTreesScreen({super.key});

  @override
  State<VerifyTreesScreen> createState() => _VerifyTreesScreenState();
}

class _VerifyTreesScreenState extends State<VerifyTreesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Tree> _unverifiedTrees = [];
  List<Maintenance> _unverifiedMaintenance = [];

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
      final treeProvider = Provider.of<TreeProvider>(context, listen: false);

      if (authProvider.currentUser == null || authProvider.currentCommunity == null) {
        throw Exception('User or community not found');
      }

      // Load community trees
      await treeProvider.loadCommunityTrees(authProvider.currentCommunity!.id);
      
      // Filter unverified trees
      _unverifiedTrees = treeProvider.trees
          .where((tree) => !tree.isVerified)
          .toList();
      
      // Filter unverified maintenance activities
      _unverifiedMaintenance = [];
      for (final tree in treeProvider.trees) {
        _unverifiedMaintenance.addAll(
          tree.maintenanceHistory
              .where((maintenance) => !maintenance.isVerified)
              .toList(),
        );
      }
    } catch (e) {
      debugPrint('Error loading verification data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyTree(Tree tree) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final treeProvider = Provider.of<TreeProvider>(context, listen: false);
      final rewardProvider = Provider.of<RewardProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        throw Exception('User not found');
      }

      // Verify tree
      final success = await treeProvider.verifyTree(
        treeId: tree.id,
        verifiedBy: authProvider.currentUser!.id,
      );

      if (success) {
        // Create reward for tree planter
        await rewardProvider.createReward(
          userId: tree.userId,
          communityId: authProvider.currentUser!.communityId,
          points: 20, // Points for verified tree
          type: RewardType.verification,
          description: 'Tree verified by community admin',
          relatedEntityId: tree.id,
        );

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tree verified successfully! The planter earned 20 points.'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Reload data
        await _loadData();
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to verify tree. Please try again.'),
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

  Future<void> _verifyMaintenance(Maintenance maintenance) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final treeProvider = Provider.of<TreeProvider>(context, listen: false);
      final rewardProvider = Provider.of<RewardProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        throw Exception('User not found');
      }

      // Verify maintenance
      final success = await treeProvider.verifyMaintenance(
        maintenanceId: maintenance.id,
        treeId: maintenance.treeId,
        verifiedBy: authProvider.currentUser!.id,
      );

      if (success) {
        // Create reward for maintenance
        await rewardProvider.createReward(
          userId: maintenance.userId,
          communityId: authProvider.currentUser!.communityId,
          points: 10, // Points for verified maintenance
          type: RewardType.verification,
          description: 'Maintenance verified by community admin',
          relatedEntityId: maintenance.id,
        );

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maintenance verified successfully! The maintainer earned 10 points.'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Reload data
        await _loadData();
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to verify maintenance. Please try again.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Trees'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Trees'),
            Tab(text: 'Maintenance'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Trees tab
                _buildTreesTab(),
                
                // Maintenance tab
                _buildMaintenanceTab(),
              ],
            ),
    );
  }

  Widget _buildTreesTab() {
    if (_unverifiedTrees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No trees pending verification',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All trees have been verified',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _unverifiedTrees.length,
      itemBuilder: (context, index) {
        final tree = _unverifiedTrees[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tree image
              if (tree.imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    tree.imageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  ),
                ),
              
              // Tree details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.nature,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Tree Planting',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: ${_getTreeStatusText(tree.status)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _getTreeStatusColor(tree.status),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Planted on: ${_formatDate(tree.plantedDate)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Location: ${tree.latitude.toStringAsFixed(6)}, ${tree.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _verifyTree(tree),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Verify Tree'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMaintenanceTab() {
    if (_unverifiedMaintenance.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No maintenance pending verification',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All maintenance activities have been verified',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _unverifiedMaintenance.length,
      itemBuilder: (context, index) {
        final maintenance = _unverifiedMaintenance[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Maintenance image
              if (maintenance.imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    maintenance.imageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  ),
                ),
              
              // Maintenance details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.healing,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Tree Maintenance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Description: ${maintenance.description}',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Date: ${_formatDate(maintenance.date)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tree ID: ${maintenance.treeId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _verifyMaintenance(maintenance),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Verify Maintenance'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

  Color _getTreeStatusColor(TreeStatus status) {
    switch (status) {
      case TreeStatus.planted:
        return Colors.blue;
      case TreeStatus.verified:
        return Colors.green;
      case TreeStatus.maintained:
        return Colors.orange;
      case TreeStatus.healthy:
        return Colors.green;
      case TreeStatus.unhealthy:
        return Colors.orange;
      case TreeStatus.dead:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

