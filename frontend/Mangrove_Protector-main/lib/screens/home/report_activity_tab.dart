import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mangrove_protector/providers/auth_provider.dart';
import 'package:mangrove_protector/providers/illegal_activity_provider.dart';
import 'package:mangrove_protector/providers/reward_provider.dart';
import 'package:mangrove_protector/models/illegal_activity_model.dart';
import 'package:mangrove_protector/models/reward_model.dart';
import 'package:mangrove_protector/utils/app_theme.dart';
import 'package:mangrove_protector/screens/map/location_picker_screen.dart';

class ReportActivityTab extends StatefulWidget {
  const ReportActivityTab({super.key});

  @override
  State<ReportActivityTab> createState() => _ReportActivityTabState();
}

class _ReportActivityTabState extends State<ReportActivityTab> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  File? _imageFile;
  Position? _currentPosition;
  IllegalActivityType _selectedActivityType =
      IllegalActivityType.illegalCutting;
  bool _isLoading = false;
  bool _isLocationLoading = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
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
                'Location permission is required to report illegal activities. Please grant location permission in app settings.';
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
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

  Future<void> _submitReport() async {
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
      final activityProvider = Provider.of<IllegalActivityProvider>(
        context,
        listen: false,
      );
      final rewardProvider = Provider.of<RewardProvider>(
        context,
        listen: false,
      );

      if (authProvider.currentUser == null ||
          authProvider.currentCommunity == null) {
        throw Exception('User or community not found');
      }

      // Add illegal activity report
      final success = await activityProvider.addActivity(
        userId: authProvider.currentUser!.id,
        communityId: authProvider.currentUser!.communityId,
        activityType: _selectedActivityType,
        description: _descriptionController.text.trim(),
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        imageUrl: _imageFile?.path,
      );

      if (success) {
        // Create reward for reporting
        await rewardProvider.createReward(
          userId: authProvider.currentUser!.id,
          communityId: authProvider.currentUser!.communityId,
          points: 15, // Points for reporting illegal activity
          type: RewardType.reporting,
          description:
              'Reported ${_getActivityTypeDisplayName(_selectedActivityType).toLowerCase()}',
        );

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Report submitted successfully! You earned 15 points.',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Reset form
          setState(() {
            _imageFile = null;
            _selectedActivityType = IllegalActivityType.illegalCutting;
          });
          _descriptionController.clear();
          _formKey.currentState!.reset();
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit report. Please try again.'),
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
                  'Report Illegal Activity',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Help protect mangrove forests by reporting illegal activities',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                // Activity type section
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
                            Icon(Icons.warning, color: AppTheme.errorColor),
                            const SizedBox(width: 8),
                            const Text(
                              'Activity Type',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<IllegalActivityType>(
                          value: _selectedActivityType,
                          decoration: const InputDecoration(
                            labelText: 'Select Activity Type',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              IllegalActivityType.values.map((type) {
                                return DropdownMenuItem<IllegalActivityType>(
                                  value: type,
                                  child: Text(
                                    _getActivityTypeDisplayName(type),
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedActivityType = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description section
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
                              Icons.description,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Describe what you observed',
                            hintText:
                                'Provide details about the illegal activity...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please provide a description';
                            }
                            if (value.trim().length < 10) {
                              return 'Description must be at least 10 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

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
                          Column(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _getCurrentLocation,
                                icon: const Icon(Icons.my_location),
                                label: const Text('Get Current Location'),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  // Navigate to map to select location
                                  final result = await Navigator.of(
                                    context,
                                  ).push(
                                    MaterialPageRoute(
                                      builder:
                                          (_) => const LocationPickerScreen(),
                                    ),
                                  );

                                  if (result != null) {
                                    setState(() {
                                      _currentPosition = Position(
                                        latitude: result.latitude,
                                        longitude: result.longitude,
                                        timestamp: DateTime.now(),
                                        accuracy: 0,
                                        altitude: 0,
                                        heading: 0,
                                        speed: 0,
                                        speedAccuracy: 0,
                                        altitudeAccuracy: 0,
                                        headingAccuracy: 0,
                                      );
                                    });
                                  }
                                },
                                icon: const Icon(Icons.map),
                                label: const Text('Pick on Map'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  foregroundColor: Colors.black87,
                                ),
                              ),
                            ],
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
                              'Photo Evidence',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Take a photo as evidence (optional but recommended)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
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
                    onPressed: _isLoading ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            )
                            : const Text(
                              'Submit Report',
                              style: TextStyle(fontSize: 16),
                            ),
                  ),
                ),
                const SizedBox(height: 16),

                // Info section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[800]),
                          const SizedBox(width: 8),
                          Text(
                            'Important Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Your report will be reviewed by community administrators\n'
                        '• Provide accurate and detailed information\n'
                        '• Photos help authorities take action\n'
                        '• You earn points for valid reports\n'
                        '• False reports may result in point deduction',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[800],
                        ),
                      ),
                    ],
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
