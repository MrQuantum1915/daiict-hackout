import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mangrove_protector/providers/auth_provider.dart';
import 'package:mangrove_protector/providers/tree_provider.dart';
import 'package:mangrove_protector/providers/reward_provider.dart';
import 'package:mangrove_protector/models/reward_model.dart';
import 'package:mangrove_protector/services/qr_service.dart';
import 'package:mangrove_protector/utils/app_theme.dart';

class TreeVerificationScreen extends StatefulWidget {
  const TreeVerificationScreen({super.key});

  @override
  State<TreeVerificationScreen> createState() => _TreeVerificationScreenState();
}

class _TreeVerificationScreenState extends State<TreeVerificationScreen> {
  final _codeController = TextEditingController();
  final _qrService = QRService();
  bool _isScanning = true;
  bool _isVerifying = false;
  String? _scanError;
  String? _verificationResult;
  bool _verificationSuccess = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyQRCode(String qrData) async {
    if (_isVerifying) return;

    setState(() {
      _isScanning = false;
      _isVerifying = true;
      _scanError = null;
      _verificationResult = null;
      _verificationSuccess = false;
    });

    try {
      // Verify QR data
      final isValid = _qrService.verifyQRData(qrData);
      if (!isValid) {
        setState(() {
          _scanError = 'Invalid or expired QR code';
          _isVerifying = false;
        });
        return;
      }

      // Parse QR data
      final qrDataMap = _qrService.parseQRData(qrData);
      if (qrDataMap == null) {
        setState(() {
          _scanError = 'Could not parse QR code data';
          _isVerifying = false;
        });
        return;
      }

      final type = qrDataMap['type'] as String;
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final treeProvider = Provider.of<TreeProvider>(context, listen: false);
      final rewardProvider = Provider.of<RewardProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        throw Exception('User not found');
      }

      if (type == 'tree') {
        final treeId = qrDataMap['treeId'] as String;
        final userId = qrDataMap['userId'] as String;

        // Verify tree
        final success = await treeProvider.verifyTree(
          treeId: treeId,
          verifiedBy: authProvider.currentUser!.id,
        );

        if (success) {
          // Create reward for tree planter
          await rewardProvider.createReward(
            userId: userId,
            communityId: authProvider.currentUser!.communityId,
            points: 20, // Points for verified tree
            type: RewardType.verification,
            description: 'Tree verified by community member',
            relatedEntityId: treeId,
          );

          setState(() {
            _verificationResult = 'Tree verified successfully! The planter earned 20 points.';
            _verificationSuccess = true;
          });
        } else {
          setState(() {
            _verificationResult = 'Failed to verify tree. Please try again.';
          });
        }
      } else if (type == 'maintenance') {
        final maintenanceId = qrDataMap['maintenanceId'] as String;
        final treeId = qrDataMap['treeId'] as String;
        final userId = qrDataMap['userId'] as String;

        // Verify maintenance
        final success = await treeProvider.verifyMaintenance(
          maintenanceId: maintenanceId,
          treeId: treeId,
          verifiedBy: authProvider.currentUser!.id,
        );

        if (success) {
          // Create reward for maintenance
          await rewardProvider.createReward(
            userId: userId,
            communityId: authProvider.currentUser!.communityId,
            points: 10, // Points for verified maintenance
            type: RewardType.verification,
            description: 'Maintenance verified by community member',
            relatedEntityId: maintenanceId,
          );

          setState(() {
            _verificationResult = 'Maintenance verified successfully! The maintainer earned 10 points.';
            _verificationSuccess = true;
          });
        } else {
          setState(() {
            _verificationResult = 'Failed to verify maintenance. Please try again.';
          });
        }
      } else {
        setState(() {
          _scanError = 'Unknown QR code type';
        });
      }
    } catch (e) {
      setState(() {
        _scanError = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  Future<void> _verifyOfflineCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a verification code')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _scanError = null;
      _verificationResult = null;
      _verificationSuccess = false;
    });

    try {
      // Show dialog to select verification type
      final verificationType = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Verification Type'),
          content: const Text('What are you verifying?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('tree'),
              child: const Text('Tree Planting'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('maintenance'),
              child: const Text('Tree Maintenance'),
            ),
          ],
        ),
      );

      if (verificationType == null) {
        setState(() {
          _isVerifying = false;
        });
        return;
      }

      // Show dialog to enter entity ID
      final entityIdController = TextEditingController();
      final entityId = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(verificationType == 'tree' ? 'Tree ID' : 'Maintenance ID'),
          content: TextField(
            controller: entityIdController,
            decoration: InputDecoration(
              hintText: verificationType == 'tree' ? 'Enter tree ID' : 'Enter maintenance ID',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(entityIdController.text);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (entityId == null || entityId.isEmpty) {
        setState(() {
          _isVerifying = false;
        });
        return;
      }

      // Verify offline code
      final verificationData = _qrService.verifyOfflineCode(
        code,
        entityId,
        verificationType,
      );

      if (verificationData == null || verificationData['isValid'] != true) {
        setState(() {
          _scanError = 'Invalid verification code';
          _isVerifying = false;
        });
        return;
      }

      // Proceed with verification
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final treeProvider = Provider.of<TreeProvider>(context, listen: false);
      final rewardProvider = Provider.of<RewardProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        throw Exception('User not found');
      }

      // Show dialog to enter user ID
      final userIdController = TextEditingController();
      final userId = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('User ID'),
          content: TextField(
            controller: userIdController,
            decoration: const InputDecoration(
              hintText: 'Enter user ID of the planter/maintainer',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(userIdController.text);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (userId == null || userId.isEmpty) {
        setState(() {
          _isVerifying = false;
        });
        return;
      }

      if (verificationType == 'tree') {
        // Verify tree
        final success = await treeProvider.verifyTree(
          treeId: entityId,
          verifiedBy: authProvider.currentUser!.id,
        );

        if (success) {
          // Create reward for tree planter
          await rewardProvider.createReward(
            userId: userId,
            communityId: authProvider.currentUser!.communityId,
            points: 20, // Points for verified tree
            type: RewardType.verification,
            description: 'Tree verified by community member',
            relatedEntityId: entityId,
          );

          setState(() {
            _verificationResult = 'Tree verified successfully! The planter earned 20 points.';
            _verificationSuccess = true;
          });
        } else {
          setState(() {
            _verificationResult = 'Failed to verify tree. Please try again.';
          });
        }
      } else if (verificationType == 'maintenance') {
        // Show dialog to enter tree ID
        final treeIdController = TextEditingController();
        final treeId = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Tree ID'),
            content: TextField(
              controller: treeIdController,
              decoration: const InputDecoration(
                hintText: 'Enter tree ID for this maintenance',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(treeIdController.text);
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
        );

        if (treeId == null || treeId.isEmpty) {
          setState(() {
            _isVerifying = false;
          });
          return;
        }

        // Verify maintenance
        final success = await treeProvider.verifyMaintenance(
          maintenanceId: entityId,
          treeId: treeId,
          verifiedBy: authProvider.currentUser!.id,
        );

        if (success) {
          // Create reward for maintenance
          await rewardProvider.createReward(
            userId: userId,
            communityId: authProvider.currentUser!.communityId,
            points: 10, // Points for verified maintenance
            type: RewardType.verification,
            description: 'Maintenance verified by community member',
            relatedEntityId: entityId,
          );

          setState(() {
            _verificationResult = 'Maintenance verified successfully! The maintainer earned 10 points.';
            _verificationSuccess = true;
          });
        } else {
          setState(() {
            _verificationResult = 'Failed to verify maintenance. Please try again.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _scanError = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  void _resetScan() {
    setState(() {
      _isScanning = true;
      _scanError = null;
      _verificationResult = null;
      _verificationSuccess = false;
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Tree'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Scanner or result
          Expanded(
            child: _isScanning
                ? _buildScanner()
                : _buildVerificationResult(),
          ),
          
          // Manual code entry
          Container(
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
              children: [
                const Text(
                  'Or enter verification code manually',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          hintText: 'Enter code (e.g. ABCD-1234-T)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isVerifying ? null : _verifyOfflineCode,
                      child: _isVerifying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Verify'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && barcodes[0].rawValue != null) {
              _verifyQRCode(barcodes[0].rawValue!);
            }
          },
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
          ),
          child: Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SizedBox.shrink(),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Scan QR code to verify tree or maintenance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 2,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationResult() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _verificationSuccess ? Icons.check_circle : Icons.error,
            size: 80,
            color: _verificationSuccess ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 24),
          Text(
            _verificationSuccess ? 'Verification Successful' : 'Verification Failed',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _verificationSuccess ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _verificationResult ?? _scanError ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _resetScan,
            icon: const Icon(Icons.refresh),
            label: const Text('Scan Again'),
            style: ElevatedButton.styleFrom(
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
}
