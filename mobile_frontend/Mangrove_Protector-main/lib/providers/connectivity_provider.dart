import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class ConnectivityProvider with ChangeNotifier {
  bool _isOnline = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
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
      // TODO: Implement data sync with Supabase
      // For now, just update the sync time
      _lastSyncTime = DateTime.now();
    } catch (e) {
      debugPrint('Error during sync: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

