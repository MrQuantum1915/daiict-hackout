import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mangrove_protector/providers/auth_provider.dart';
import 'package:mangrove_protector/providers/tree_provider.dart';
import 'package:mangrove_protector/providers/reward_provider.dart';
import 'package:mangrove_protector/models/reward_model.dart';
import 'package:mangrove_protector/utils/app_theme.dart';
import 'package:mangrove_protector/screens/tree/tree_verification_screen.dart';

class PlantTab extends StatefulWidget {
  const PlantTab({super.key});

  @override
  State<PlantTab> createState() => _PlantTabState();
}

class _PlantTabState extends State<PlantTab> {
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isLocationLoading = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    setState(() {
      _isLocationLoading = true;
      _locationError = null;
    });

    try {
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError =
              'Location services are disabled. Please enable GPS in your device settings.';
        });
        return;
      }

      final status = await Permission.location.status;
      if (status.isGranted) {
        await _getCurrentLocation();
      } else if (status.isDenied) {
        final result = await Permission.location.request();
        if (result.isGranted) {
          await _getCurrentLocation();
        } else {
          setState(() {
            _locationError =
                'Location permission is required to plant trees. Please grant location permission in app settings.';
          });
        }
      } else if (status.isPermanentlyDenied) {
        setState(() {
          _locationError =
              'Location permission is permanently denied. Please enable it in app settings.';
        });
      } else if (status.isRestricted) {
        setState(() {
          _locationError =
              'Location access is restricted. Please check your device settings.';
        });
      }
    } catch (e) {
      setState(() {
        _locationError = 'Error checking location permission: $e';
      });
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
      _locationError = null;
    });

    try {
      // Check location permission again before getting location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError =
                'Location permission denied. Cannot get current location.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Location permissions are permanently denied. Please enable them in app settings.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _currentPosition = position;
      });
    } on TimeoutException {
      setState(() {
        _locationError =
            'Location request timed out. Please try again or check your GPS signal.';
      });
    } catch (e) {
      setState(() {
        _locationError =
            'Error getting location: $e\nPlease check your GPS signal and try again.';
      });
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _submitPlanting() async {
    if (!_formKey.currentState!.validate() || _currentPosition == null) {
      if (_currentPosition == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Location is required')));
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final treeProvider = Provider.of<TreeProvider>(context, listen: false);
      final rewardProvider = Provider.of<RewardProvider>(
        context,
        listen: false,
      );

      if (authProvider.currentUser == null ||
          authProvider.currentCommunity == null) {
        throw Exception('User or community not found');
      }

      // Add tree
      final success = await treeProvider.addTree(
        userId: authProvider.currentUser!.id,
        communityId: authProvider.currentUser!.communityId,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        imageUrl: _imageFile?.path,
      );

      if (success) {
        // Create reward for planting
        await rewardProvider.createReward(
          userId: authProvider.currentUser!.id,
          communityId: authProvider.currentUser!.communityId,
          points: 10, // Points for planting a tree
          type: RewardType.planting,
          description: 'Planted a new mangrove tree',
        );

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tree planted successfully! You earned 10 points.'),
              backgroundColor: Colors.green,
            ),
          );

          // Reset form
          setState(() {
            _imageFile = null;
          });
          _formKey.currentState!.reset();
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to plant tree. Please try again.'),
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

  void _navigateToVerification() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TreeVerificationScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Plant a Mangrove Tree',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Document your tree planting to earn points',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                // Location section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Location',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isLocationLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (_locationError != null)
                          Column(
                            children: [
                              Text(
                                _locationError!,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _checkLocationPermission,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          )
                        else if (_currentPosition != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _getCurrentLocation,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh Location'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  foregroundColor: Colors.black87,
                                ),
                              ),
                            ],
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _getCurrentLocation,
                            icon: const Icon(Icons.my_location),
                            label: const Text('Get Current Location'),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Photo section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.photo_camera,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Photo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_imageFile != null)
                          Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _imageFile!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retake Photo'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  foregroundColor: Colors.black87,
                                ),
                              ),
                            ],
                          )
                        else
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.add_a_photo),
                              label: const Text('Take Photo'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitPlanting,
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            )
                            : const Text(
                              'Submit Planting',
                              style: TextStyle(fontSize: 16),
                            ),
                  ),
                ),
                const SizedBox(height: 16),

                // Verification section
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Verify a Tree',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan a QR code or enter a verification code to verify a tree planting',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _navigateToVerification,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Verify Tree'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
