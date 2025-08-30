import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:mangrove_protector/models/tree_model.dart';
import 'package:mangrove_protector/services/database_service.dart';

class TreeProvider with ChangeNotifier {
  List<Tree> _trees = [];
  bool _isLoading = false;
  final DatabaseService _databaseService = DatabaseService();
  final Uuid _uuid = const Uuid();

  List<Tree> get trees => [..._trees];
  bool get isLoading => _isLoading;

  Future<void> loadUserTrees(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _trees = await _databaseService.getTreesByUser(userId);
    } catch (e) {
      debugPrint('Error loading user trees: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCommunityTrees(String communityId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _trees = await _databaseService.getTreesByCommunity(communityId);
    } catch (e) {
      debugPrint('Error loading community trees: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTree({
    required String userId,
    required String communityId,
    required double latitude,
    required double longitude,
    String? imageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final tree = Tree(
        id: _uuid.v4(),
        userId: userId,
        communityId: communityId,
        latitude: latitude,
        longitude: longitude,
        imageUrl: imageUrl,
        status: TreeStatus.planted,
        plantedDate: now,
        maintenanceHistory: [],
        createdAt: now,
        updatedAt: now,
        isVerified: false,
      );

      // Save tree to local database
      await _databaseService.insertTree(tree);

      // Add to sync queue for later synchronization
      await _databaseService.addToSyncQueue(
        'tree',
        tree.id,
        'create',
        json.encode(tree.toJson()),
      );

      _trees.add(tree);
      
      return true;
    } catch (e) {
      debugPrint('Error adding tree: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTreeStatus({
    required String treeId,
    required TreeStatus status,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Find tree in local list
      final treeIndex = _trees.indexWhere((t) => t.id == treeId);
      if (treeIndex == -1) {
        // Try to load from database
        final tree = await _databaseService.getTree(treeId);
        if (tree == null) {
          throw Exception('Tree not found');
        }
        
        final updatedTree = tree.copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );

        // Update tree in local database
        await _databaseService.updateTree(updatedTree);

        // Add to sync queue for later synchronization
        await _databaseService.addToSyncQueue(
          'tree',
          updatedTree.id,
          'update',
          json.encode(updatedTree.toJson()),
        );

        // If tree wasn't in local list, add it
        _trees.add(updatedTree);
      } else {
        // Update existing tree in list
        final updatedTree = _trees[treeIndex].copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );

        // Update tree in local database
        await _databaseService.updateTree(updatedTree);

        // Add to sync queue for later synchronization
        await _databaseService.addToSyncQueue(
          'tree',
          updatedTree.id,
          'update',
          json.encode(updatedTree.toJson()),
        );

        _trees[treeIndex] = updatedTree;
      }
      
      return true;
    } catch (e) {
      debugPrint('Error updating tree status: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyTree({
    required String treeId,
    required String verifiedBy,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Find tree in local list
      final treeIndex = _trees.indexWhere((t) => t.id == treeId);
      if (treeIndex == -1) {
        // Try to load from database
        final tree = await _databaseService.getTree(treeId);
        if (tree == null) {
          throw Exception('Tree not found');
        }
        
        final now = DateTime.now();
        final updatedTree = tree.copyWith(
          isVerified: true,
          verifiedBy: verifiedBy,
          verifiedAt: now,
          updatedAt: now,
        );

        // Update tree in local database
        await _databaseService.updateTree(updatedTree);

        // Add to sync queue for later synchronization
        await _databaseService.addToSyncQueue(
          'tree',
          updatedTree.id,
          'update',
          json.encode(updatedTree.toJson()),
        );

        // If tree wasn't in local list, add it
        _trees.add(updatedTree);
      } else {
        // Update existing tree in list
        final now = DateTime.now();
        final updatedTree = _trees[treeIndex].copyWith(
          isVerified: true,
          verifiedBy: verifiedBy,
          verifiedAt: now,
          updatedAt: now,
        );

        // Update tree in local database
        await _databaseService.updateTree(updatedTree);

        // Add to sync queue for later synchronization
        await _databaseService.addToSyncQueue(
          'tree',
          updatedTree.id,
          'update',
          json.encode(updatedTree.toJson()),
        );

        _trees[treeIndex] = updatedTree;
      }
      
      return true;
    } catch (e) {
      debugPrint('Error verifying tree: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMaintenance({
    required String treeId,
    required String userId,
    required String description,
    String? imageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final maintenance = Maintenance(
        id: _uuid.v4(),
        treeId: treeId,
        userId: userId,
        description: description,
        imageUrl: imageUrl,
        date: now,
        isVerified: false,
      );

      // Find tree in local list
      final treeIndex = _trees.indexWhere((t) => t.id == treeId);
      if (treeIndex == -1) {
        // Try to load from database
        final tree = await _databaseService.getTree(treeId);
        if (tree == null) {
          throw Exception('Tree not found');
        }
        
        final updatedMaintenanceHistory = [...tree.maintenanceHistory, maintenance];
        final updatedTree = tree.copyWith(
          maintenanceHistory: updatedMaintenanceHistory,
          status: TreeStatus.maintained,
          updatedAt: now,
        );

        // Save maintenance to local database
        await _databaseService.insertMaintenance(maintenance);

        // Update tree in local database
        await _databaseService.updateTree(updatedTree);

        // Add to sync queue for later synchronization
        await _databaseService.addToSyncQueue(
          'maintenance',
          maintenance.id,
          'create',
          json.encode(maintenance.toJson()),
        );

        // If tree wasn't in local list, add it
        _trees.add(updatedTree);
      } else {
        // Update existing tree in list
        final updatedMaintenanceHistory = [..._trees[treeIndex].maintenanceHistory, maintenance];
        final updatedTree = _trees[treeIndex].copyWith(
          maintenanceHistory: updatedMaintenanceHistory,
          status: TreeStatus.maintained,
          updatedAt: now,
        );

        // Save maintenance to local database
        await _databaseService.insertMaintenance(maintenance);

        // Update tree in local database
        await _databaseService.updateTree(updatedTree);

        // Add to sync queue for later synchronization
        await _databaseService.addToSyncQueue(
          'maintenance',
          maintenance.id,
          'create',
          json.encode(maintenance.toJson()),
        );

        _trees[treeIndex] = updatedTree;
      }
      
      return true;
    } catch (e) {
      debugPrint('Error adding maintenance: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyMaintenance({
    required String maintenanceId,
    required String treeId,
    required String verifiedBy,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Find tree in local list
      final treeIndex = _trees.indexWhere((t) => t.id == treeId);
      Tree? tree;
      
      if (treeIndex == -1) {
        // Try to load from database
        tree = await _databaseService.getTree(treeId);
        if (tree == null) {
          throw Exception('Tree not found');
        }
      } else {
        tree = _trees[treeIndex];
      }

      // Find maintenance in tree's maintenance history
      final maintenanceIndex = tree.maintenanceHistory.indexWhere((m) => m.id == maintenanceId);
      if (maintenanceIndex == -1) {
        throw Exception('Maintenance record not found');
      }

      final now = DateTime.now();
      final updatedMaintenance = tree.maintenanceHistory[maintenanceIndex].copyWith(
        isVerified: true,
        verifiedBy: verifiedBy,
        verifiedAt: now,
      );

      // Create updated maintenance history
      final updatedMaintenanceHistory = [...tree.maintenanceHistory];
      updatedMaintenanceHistory[maintenanceIndex] = updatedMaintenance;

      final updatedTree = tree.copyWith(
        maintenanceHistory: updatedMaintenanceHistory,
        updatedAt: now,
      );

      // Update maintenance in local database
      await _databaseService.insertMaintenance(updatedMaintenance);

      // Update tree in local database
      await _databaseService.updateTree(updatedTree);

      // Add to sync queue for later synchronization
      await _databaseService.addToSyncQueue(
        'maintenance',
        updatedMaintenance.id,
        'update',
        json.encode(updatedMaintenance.toJson()),
      );

      if (treeIndex == -1) {
        // If tree wasn't in local list, add it
        _trees.add(updatedTree);
      } else {
        // Update existing tree in list
        _trees[treeIndex] = updatedTree;
      }
      
      return true;
    } catch (e) {
      debugPrint('Error verifying maintenance: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Statistics methods
  int getTotalTreesPlanted(String userId) {
    return _trees.where((tree) => tree.userId == userId).length;
  }

  int getTotalTreesVerified(String userId) {
    return _trees.where((tree) => tree.userId == userId && tree.isVerified).length;
  }

  int getTotalMaintenanceActivities(String userId) {
    return _trees.fold(0, (sum, tree) {
      return sum + tree.maintenanceHistory.where((m) => m.userId == userId).length;
    });
  }

  double getSurvivalRate(String userId) {
    final userTrees = _trees.where((tree) => tree.userId == userId).toList();
    if (userTrees.isEmpty) return 0.0;
    
    final healthyTrees = userTrees.where((tree) => 
      tree.status == TreeStatus.healthy || 
      tree.status == TreeStatus.maintained ||
      tree.status == TreeStatus.verified
    ).length;
    
    return healthyTrees / userTrees.length;
  }

  // Community statistics
  int getCommunityTotalTrees(String communityId) {
    return _trees.where((tree) => tree.communityId == communityId).length;
  }

  int getCommunityVerifiedTrees(String communityId) {
    return _trees.where((tree) => 
      tree.communityId == communityId && tree.isVerified
    ).length;
  }

  double getCommunityHealthRate(String communityId) {
    final communityTrees = _trees.where((tree) => tree.communityId == communityId).toList();
    if (communityTrees.isEmpty) return 0.0;
    
    final healthyTrees = communityTrees.where((tree) => 
      tree.status == TreeStatus.healthy || 
      tree.status == TreeStatus.maintained ||
      tree.status == TreeStatus.verified
    ).length;
    
    return healthyTrees / communityTrees.length;
  }
}

