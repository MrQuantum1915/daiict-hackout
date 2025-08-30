import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mangrove_protector/providers/illegal_activity_provider.dart';
import 'package:mangrove_protector/providers/auth_provider.dart';
import 'package:mangrove_protector/models/illegal_activity_model.dart';
import 'package:mangrove_protector/utils/app_theme.dart';

class ActivitiesMapScreen extends StatefulWidget {
  const ActivitiesMapScreen({super.key});

  @override
  State<ActivitiesMapScreen> createState() => _ActivitiesMapScreenState();
}

class _ActivitiesMapScreenState extends State<ActivitiesMapScreen> {
  final MapController _mapController = MapController();
  bool _isLoading = true;
  List<IllegalActivity> _activities = [];
  IllegalActivity? _selectedActivity;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final activityProvider = Provider.of<IllegalActivityProvider>(context, listen: false);
      
      await activityProvider.loadActivities();
      
      if (authProvider.currentCommunity != null) {
        _activities = activityProvider.getActivitiesByCommunity(
          authProvider.currentCommunity!.id,
        );
      } else {
        _activities = activityProvider.activities;
      }
    } catch (e) {
      debugPrint('Error loading activities: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getActivityTypeColor(IllegalActivityType type) {
    switch (type) {
      case IllegalActivityType.illegalCutting:
        return Colors.red;
      case IllegalActivityType.wasteDumping:
        return Colors.orange;
      case IllegalActivityType.pollution:
        return Colors.purple;
      case IllegalActivityType.encroachment:
        return Colors.brown;
      case IllegalActivityType.other:
        return Colors.grey;
    }
  }

  IconData _getActivityTypeIcon(IllegalActivityType type) {
    switch (type) {
      case IllegalActivityType.illegalCutting:
        return Icons.forest;
      case IllegalActivityType.wasteDumping:
        return Icons.delete;
      case IllegalActivityType.pollution:
        return Icons.water_drop;
      case IllegalActivityType.encroachment:
        return Icons.home;
      case IllegalActivityType.other:
        return Icons.warning;
    }
  }

  String _getActivityTypeDisplayName(IllegalActivityType type) {
    switch (type) {
      case IllegalActivityType.illegalCutting:
        return 'Illegal Tree Cutting';
      case IllegalActivityType.wasteDumping:
        return 'Waste Dumping';
      case IllegalActivityType.pollution:
        return 'Pollution';
      case IllegalActivityType.encroachment:
        return 'Land Encroachment';
      case IllegalActivityType.other:
        return 'Other';
    }
  }

  String _getStatusDisplayName(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.underInvestigation:
        return 'Under Investigation';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.dismissed:
        return 'Dismissed';
    }
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.underInvestigation:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.dismissed:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Calculate center point if activities exist
    LatLng centerPoint = const LatLng(0, 0);
    if (_activities.isNotEmpty) {
      double avgLat = _activities.map((a) => a.latitude).reduce((a, b) => a + b) / _activities.length;
      double avgLng = _activities.map((a) => a.longitude).reduce((a, b) => a + b) / _activities.length;
      centerPoint = LatLng(avgLat, avgLng);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Illegal Activities Map'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivities,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: centerPoint,
                initialZoom: _activities.isEmpty ? 10.0 : 12.0,
                onTap: (_, __) {
                  setState(() {
                    _selectedActivity = null;
                  });
                },
              ),
              children: [
                // OpenStreetMap tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mangrove_protector',
                ),
                // Activity markers
                MarkerLayer(
                  markers: _activities.map((activity) {
                    return Marker(
                      point: LatLng(activity.latitude, activity.longitude),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedActivity = activity;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _getActivityTypeColor(activity.activityType),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _getActivityTypeIcon(activity.activityType),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // Activity details panel
          if (_selectedActivity != null)
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getActivityTypeColor(_selectedActivity!.activityType).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getActivityTypeIcon(_selectedActivity!.activityType),
                          color: _getActivityTypeColor(_selectedActivity!.activityType),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getActivityTypeDisplayName(_selectedActivity!.activityType),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(_selectedActivity!.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getStatusColor(_selectedActivity!.status),
                                ),
                              ),
                              child: Text(
                                _getStatusDisplayName(_selectedActivity!.status),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getStatusColor(_selectedActivity!.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedActivity = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedActivity!.description,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reported: ${_formatDate(_selectedActivity!.reportedDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      if (_selectedActivity!.isVerified)
                        Row(
                          children: [
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.green[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_location),
        tooltip: 'Report New Activity',
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 