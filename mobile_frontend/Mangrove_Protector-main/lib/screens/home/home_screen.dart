import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangrove_protector/providers/auth_provider.dart';
import 'package:mangrove_protector/providers/connectivity_provider.dart';
import 'package:mangrove_protector/screens/home/dashboard_tab.dart';
import 'package:mangrove_protector/screens/home/report_activity_tab.dart';
import 'package:mangrove_protector/screens/home/rewards_tab.dart';
import 'package:mangrove_protector/screens/home/profile_tab.dart';
import 'package:mangrove_protector/screens/admin/admin_panel.dart';
import 'package:mangrove_protector/utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _tabs = [
    const DashboardTab(),
    const ReportActivityTab(),
    const RewardsTab(),
    const ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    // Force sync when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final connectivityProvider = Provider.of<ConnectivityProvider>(context, listen: false);
      connectivityProvider.forceSync();
    });
  }

  void _openAdminPanel() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminPanel()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final connectivityProvider = Provider.of<ConnectivityProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mangrove Protector',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          // Admin panel button (only for admins)
          if (authProvider.isAdmin())
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              onPressed: _openAdminPanel,
              tooltip: 'Admin Panel',
            ),
          // Sync status indicator
          IconButton(
            icon: Icon(
              connectivityProvider.isOnline
                  ? Icons.cloud_done
                  : Icons.cloud_off,
              color: connectivityProvider.isOnline
                  ? Colors.white
                  : Colors.white.withOpacity(0.6),
            ),
            onPressed: connectivityProvider.isOnline
                ? connectivityProvider.forceSync
                : null,
            tooltip: connectivityProvider.isOnline
                ? 'Online - Tap to sync'
                : 'Offline - Working in local mode',
          ),
        ],
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Rewards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      // Offline banner
      bottomSheet: !connectivityProvider.isOnline
          ? Container(
              width: double.infinity,
              color: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You are offline. Changes will sync when you reconnect.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

