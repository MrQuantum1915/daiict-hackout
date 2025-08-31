import 'package:flutter/material.dart';
import 'package:mangrove_protector/models/illegal_activity_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ReportDetailScreen extends StatelessWidget {
  final IllegalActivity report;

  const ReportDetailScreen({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _StatusIcon(status: report.status),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusText(report.status),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getStatusDescription(report.status),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Image Section
            if (report.imageUrl != null) ...[
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    report.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Activity Type
            _DetailSection(
              title: 'Activity Type',
              content: Text(_getActivityTypeText(report.activityType)),
              icon: Icons.category,
            ),
            
            // Description
            _DetailSection(
              title: 'Description',
              content: Text(report.description),
              icon: Icons.description,
            ),
            
            // AI Analysis
            if (report.aiScore != null) ...[
              _DetailSection(
                title: 'AI Analysis',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Confidence: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${(report.aiScore! * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (report.aiExplanation != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        report.aiExplanation!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
                icon: Icons.psychology,
              ),
            ],
            
            // Location
            _DetailSection(
              title: 'Location',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latitude: ${report.latitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    'Longitude: ${report.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              icon: Icons.location_on,
            ),
            
            // Map
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(report.latitude, report.longitude),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId(report.id),
                      position: LatLng(report.latitude, report.longitude),
                      infoWindow: InfoWindow(
                        title: _getActivityTypeText(report.activityType),
                        snippet: 'Reported on ${_formatDate(report.reportedDate)}',
                      ),
                    ),
                  },
                  zoomControlsEnabled: false,
                  myLocationEnabled: false,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Report Date
            _DetailSection(
              title: 'Reported Date',
              content: Text(_formatDate(report.reportedDate)),
              icon: Icons.schedule,
            ),
            
            // Verification Status
            if (report.isVerified) ...[
              _DetailSection(
                title: 'Verification',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✓ Verified',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (report.verifiedBy != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'By: ${report.verifiedBy}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    if (report.verifiedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${_formatDate(report.verifiedAt!)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
                icon: Icons.verified,
              ),
            ],
            
            // Admin Notes
            if (report.adminNotes != null && report.adminNotes!.isNotEmpty) ...[
              _DetailSection(
                title: 'Admin Notes',
                content: Text(report.adminNotes!),
                icon: Icons.note,
              ),
            ],
            
            // Resolution Notes
            if (report.resolutionNotes != null && report.resolutionNotes!.isNotEmpty) ...[
              _DetailSection(
                title: 'Resolution Notes',
                content: Text(report.resolutionNotes!),
                icon: Icons.check_circle,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getActivityTypeText(IllegalActivityType type) {
    switch (type) {
      case IllegalActivityType.illegalDumping:
        return 'Illegal Dumping';
      case IllegalActivityType.poaching:
        return 'Poaching';
      case IllegalActivityType.deforestation:
        return 'Deforestation';
      case IllegalActivityType.pollution:
        return 'Pollution';
      case IllegalActivityType.construction:
        return 'Construction';
      case IllegalActivityType.other:
        return 'Other';
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return 'Submitted';
      case 'pending ngo verification':
        return 'Pending NGO Verification';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'flagged':
        return 'Flagged';
      default:
        return status;
    }
  }

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return 'Your report has been submitted for review';
      case 'pending ngo verification':
        return 'Your report is being verified by NGOs';
      case 'approved':
        return 'Your report has been approved';
      case 'rejected':
        return 'Your report was rejected';
      case 'flagged':
        return 'Your report has been flagged for review';
      default:
        return 'Status: $status';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusIcon extends StatelessWidget {
  final String status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (status.toLowerCase()) {
      case 'submitted':
        icon = Icons.schedule;
        color = Colors.orange;
        break;
      case 'pending ngo verification':
        icon = Icons.search;
        color = Colors.blue;
        break;
      case 'approved':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'rejected':
      case 'flagged':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget content;
  final IconData icon;

  const _DetailSection({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            content is String
                ? Text(
                    content as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  )
                : content,
          ],
        ),
      ),
    );
  }
}
