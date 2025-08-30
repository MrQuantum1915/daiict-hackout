import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Data'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Privacy Matters',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _PrivacySection(
              icon: Icons.lock,
              title: 'End-to-End Encryption',
              description: 'All your data is encrypted on your device before being sent to our servers. '
                  'Only you can decrypt your personal information.',
            ),
            
            _PrivacySection(
              icon: Icons.visibility_off,
              title: 'Anonymous Reporting',
              description: 'Your identity is completely anonymous. We only collect location data and '
                  'incident details to help protect mangroves.',
            ),
            
            _PrivacySection(
              icon: Icons.device_hub,
              title: 'Local Key Storage',
              description: 'Your encryption keys are stored securely on your device and never shared '
                  'with our servers or any third parties.',
            ),
            
            _PrivacySection(
              icon: Icons.delete_forever,
              title: 'Data Retention',
              description: 'Your personal data is automatically deleted after 30 days. '
                  'Only anonymized incident data is retained for environmental protection.',
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'What We Collect',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _DataItem(
              icon: Icons.location_on,
              title: 'Location Data',
              description: 'GPS coordinates of reported incidents',
              isRequired: true,
            ),
            
            _DataItem(
              icon: Icons.camera_alt,
              title: 'Photos',
              description: 'Images of illegal activities (encrypted)',
              isRequired: true,
            ),
            
            _DataItem(
              icon: Icons.description,
              title: 'Report Details',
              description: 'Description and type of incident',
              isRequired: true,
            ),
            
            _DataItem(
              icon: Icons.device_unknown,
              title: 'Device Info',
              description: 'App version and device type for support',
              isRequired: false,
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'What We Don\'t Collect',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _DataItem(
              icon: Icons.person_off,
              title: 'Personal Information',
              description: 'Name, email, phone number, or any identifying details',
              isRequired: false,
              isNegative: true,
            ),
            
            _DataItem(
              icon: Icons.contact_phone,
              title: 'Contact Information',
              description: 'Address, social media accounts, or personal contacts',
              isRequired: false,
              isNegative: true,
            ),
            
            _DataItem(
              icon: Icons.history,
              title: 'Browsing History',
              description: 'Your internet activity or app usage patterns',
              isRequired: false,
              isNegative: true,
            ),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your Rights',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Request deletion of your data\n'
                    '• Export your data in encrypted format\n'
                    '• Opt out of data collection\n'
                    '• Contact us with privacy concerns',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Team',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Email: privacy@mangroveprotector.com\n'
                    'Response time: Within 48 hours',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PrivacySection({
    required this.icon,
    required this.title,
    required this.description,
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isRequired;
  final bool isNegative;

  const _DataItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.isRequired,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isNegative 
                    ? Colors.red.withOpacity(0.1)
                    : isRequired 
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: isNegative 
                    ? Colors.red
                    : isRequired 
                        ? Colors.orange
                        : Colors.grey,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isRequired) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Required',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
