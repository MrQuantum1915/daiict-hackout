import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:mangrove_protector/services/database_service.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isOnline = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  final DatabaseService _databaseService = DatabaseService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  ConnectivityProvider() {
    _initConnectivity();
    _setupConnectivityListener();
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isOnline = false;
    }
    notifyListeners();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    final wasOffline = !_isOnline;
    
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      _isOnline = false;
    } else {
      // Additional check to ensure actual internet connectivity
      try {
        final response = await http.get(Uri.parse('https://www.google.com')).timeout(
          const Duration(seconds: 5),
          onTimeout: () => http.Response('Error', 408),
        );
        _isOnline = response.statusCode == 200;
      } catch (e) {
        _isOnline = false;
      }
    }
    
    notifyListeners();
    
    // If we just came back online, try to sync
    if (wasOffline && _isOnline) {
      syncData();
    }
  }

  Future<void> syncData() async {
    if (!_isOnline || _isSyncing) return;
    
    _isSyncing = true;
    notifyListeners();
    
    try {
      // Get pending sync items
      final pendingSyncItems = await _databaseService.getPendingSyncItems();
      
      if (pendingSyncItems.isEmpty) {
        _lastSyncTime = DateTime.now();
        _isSyncing = false;
        notifyListeners();
        return;
      }
      
      // Process each pending item
      for (final item in pendingSyncItems) {
        final success = await _syncItem(item);
        
        if (success) {
          // Mark as synced in local database
          await _databaseService.markAsSynced(item['id'] as int);
        } else {
          // If sync fails, stop and try again later
          break;
        }
      }
      
      _lastSyncTime = DateTime.now();
    } catch (e) {
      debugPrint('Error during sync: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<bool> _syncItem(Map<String, dynamic> item) async {
    // This is a placeholder for actual API calls
    // In a real implementation, you would send the data to your backend API
    
    try {
      final entityType = item['entityType'] as String;
      final operation = item['operation'] as String;
      final data = json.decode(item['data'] as String);
      
      // Simulate API call
      // In a real app, you would use http.post/put/delete to your API
      await Future.delayed(const Duration(milliseconds: 500));
      
      debugPrint('Synced $operation for $entityType: ${data['id']}');
      
      return true;
    } catch (e) {
      debugPrint('Error syncing item: $e');
      return false;
    }
  }

  Future<void> forceSync() async {
    if (!_isOnline) {
      await _initConnectivity();
    }
    
    if (_isOnline) {
      await syncData();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

