import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangrove_protector/providers/auth_provider.dart';
import 'package:mangrove_protector/providers/reward_provider.dart';
import 'package:mangrove_protector/models/reward_model.dart';
import 'package:mangrove_protector/utils/app_theme.dart';

class ManageRewardsScreen extends StatefulWidget {
  const ManageRewardsScreen({super.key});

  @override
  State<ManageRewardsScreen> createState() => _ManageRewardsScreenState();
}

class _ManageRewardsScreenState extends State<ManageRewardsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Reward> _pendingRewards = [];
  List<RewardItem> _rewardItems = [];

  // Form controllers for adding new reward item
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsCostController = TextEditingController();
  final _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _pointsCostController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final rewardProvider = Provider.of<RewardProvider>(context, listen: false);

      if (authProvider.currentUser == null || authProvider.currentCommunity == null) {
        throw Exception('User or community not found');
      }

      // Load community rewards
      await rewardProvider.loadCommunityRewards(authProvider.currentCommunity!.id);
      
      // Load reward items
      await rewardProvider.loadRewardItems(authProvider.currentCommunity!.id);
      
      // Filter pending rewards
      _pendingRewards = rewardProvider.getPendingRewards(authProvider.currentCommunity!.id);
      
      // Get reward items
      _rewardItems = rewardProvider.rewardItems;
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

  Future<void> _approveReward(Reward reward) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final rewardProvider = Provider.of<RewardProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        throw Exception('User not found');
      }

      // Approve reward
      final success = await rewardProvider.approveReward(
        rewardId: reward.id,
        approvedBy: authProvider.currentUser!.id,
      );

      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reward approved successfully!'),
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
              content: Text('Failed to approve reward. Please try again.'),
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

  void _showAddRewardItemDialog() {
    // Reset form
    _nameController.clear();
    _descriptionController.clear();
    _pointsCostController.clear();
    _quantityController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Reward Item'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pointsCostController,
                  decoration: const InputDecoration(
                    labelText: 'Points Cost',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter points cost';
                    }
                    final pointsCost = int.tryParse(value);
                    if (pointsCost == null || pointsCost <= 0) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Available Quantity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter quantity';
                    }
                    final quantity = int.tryParse(value);
                    if (quantity == null || quantity <= 0) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.of(ctx).pop();
                _addRewardItem();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addRewardItem() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final rewardProvider = Provider.of<RewardProvider>(context, listen: false);

      if (authProvider.currentUser == null || authProvider.currentCommunity == null) {
        throw Exception('User or community not found');
      }

      // Create reward item
      final success = await rewardProvider.createRewardItem(
        communityId: authProvider.currentCommunity!.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        pointsCost: int.parse(_pointsCostController.text.trim()),
        availableQuantity: int.parse(_quantityController.text.trim()),
      );

      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reward item added successfully!'),
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
              content: Text('Failed to add reward item. Please try again.'),
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

  Future<void> _updateRewardItem(RewardItem item) async {
    // Set initial values
    _nameController.text = item.name;
    _descriptionController.text = item.description ?? '';
    _pointsCostController.text = item.pointsCost.toString();
    _quantityController.text = item.availableQuantity.toString();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Reward Item'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pointsCostController,
                  decoration: const InputDecoration(
                    labelText: 'Points Cost',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter points cost';
                    }
                    final pointsCost = int.tryParse(value);
                    if (pointsCost == null || pointsCost <= 0) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Available Quantity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter quantity';
                    }
                    final quantity = int.tryParse(value);
                    if (quantity == null || quantity < 0) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final rewardProvider = Provider.of<RewardProvider>(context, listen: false);

      // Update reward item
      final success = await rewardProvider.updateRewardItem(
        itemId: item.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        pointsCost: int.parse(_pointsCostController.text.trim()),
        availableQuantity: int.parse(_quantityController.text.trim()),
      );

      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reward item updated successfully!'),
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
              content: Text('Failed to update reward item. Please try again.'),
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
        title: const Text('Manage Rewards'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Pending Rewards'),
            Tab(text: 'Reward Items'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Pending rewards tab
                _buildPendingRewardsTab(),
                
                // Reward items tab
                _buildRewardItemsTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: _showAddRewardItemDialog,
              backgroundColor: AppTheme.accentColor,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildPendingRewardsTab() {
    if (_pendingRewards.isEmpty) {
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
              'No pending rewards',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All rewards have been processed',
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
      itemCount: _pendingRewards.length,
      itemBuilder: (context, index) {
        final reward = _pendingRewards[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _getRewardTypeIcon(reward.type),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getRewardTypeText(reward.type),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'User ID: ${reward.userId}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${reward.points} pts',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (reward.description != null) ...[
                  Text(
                    reward.description!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Date: ${_formatDate(reward.createdAt)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (reward.relatedEntityId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Related ID: ${reward.relatedEntityId}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Show reject confirmation dialog
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Reject Reward'),
                              content: const Text('Are you sure you want to reject this reward?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    // TODO: Implement reject reward
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Reject'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _approveReward(reward),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewardItemsTab() {
    if (_rewardItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No reward items yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add reward items for your community',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddRewardItemDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Reward Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rewardItems.length,
      itemBuilder: (context, index) {
        final item = _rewardItems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reward image or icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: item.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.card_giftcard,
                                size: 40,
                                color: AppTheme.accentColor,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.card_giftcard,
                          size: 40,
                          color: AppTheme.accentColor,
                        ),
                ),
                const SizedBox(width: 16),
                // Reward details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.stars,
                            size: 16,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.pointsCost} points',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Available: ${item.availableQuantity}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => _updateRewardItem(item),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                            ),
                            child: const Text('Edit'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              // Show deactivate confirmation dialog
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(item.isActive ? 'Deactivate Item' : 'Activate Item'),
                                  content: Text(
                                    item.isActive
                                        ? 'Are you sure you want to deactivate this reward item? It will no longer be available for redemption.'
                                        : 'Are you sure you want to activate this reward item? It will be available for redemption.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.of(ctx).pop();
                                        
                                        // Update item active status
                                        final rewardProvider = Provider.of<RewardProvider>(context, listen: false);
                                        await rewardProvider.updateRewardItem(
                                          itemId: item.id,
                                          isActive: !item.isActive,
                                        );
                                        
                                        // Reload data
                                        await _loadData();
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: item.isActive ? Colors.red : Colors.green,
                                      ),
                                      child: Text(item.isActive ? 'Deactivate' : 'Activate'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                              foregroundColor: item.isActive ? Colors.red : Colors.green,
                            ),
                            child: Text(item.isActive ? 'Deactivate' : 'Activate'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

