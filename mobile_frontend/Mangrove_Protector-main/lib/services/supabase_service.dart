import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:mangrove_protector/models/user_model.dart';
import 'package:mangrove_protector/models/illegal_activity_model.dart';
import 'package:mangrove_protector/models/reward_model.dart';
import 'package:mangrove_protector/services/encryption_service.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String _serverUrl = 'https://daiict-hackout.vercel.app/api/report';
  static const String _reportsUrl = 'https://daiict-hackout.vercel.app/api/reports';

  // User operations
  static Future<User?> getUser(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('user_uuid', userId)
          .maybeSingle();
      
      if (response == null) {
        return null; // User doesn't exist yet
      }
      
      return User(
        id: response['user_uuid'],
        points: response['credits'] ?? 0,
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['created_at']),
      );
    } catch (e) {
      // If there's an error, return null instead of throwing
      print('Warning: Failed to fetch user: $e');
      return null;
    }
  }

  static Future<User> createUser(User user) async {
    try {
      final response = await _client
          .from('users')
          .insert({
            'user_uuid': user.id,
            'credits': user.points,
          })
          .select()
          .single();
      
      return User(
        id: response['user_uuid'],
        points: response['credits'] ?? 0,
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['created_at']),
      );
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  static Future<User> updateUser(User user) async {
    try {
      final response = await _client
          .from('users')
          .update({
            'credits': user.points,
          })
          .eq('user_uuid', user.id)
          .select()
          .single();
      
      return User(
        id: response['user_uuid'],
        points: response['credits'] ?? 0,
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['created_at']),
      );
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Illegal Activity operations
  static Future<List<IllegalActivity>> getUserReports(String userId) async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) {
        throw Exception('No active session');
      }

      final response = await http.get(
        Uri.parse(_reportsUrl),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch reports: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final reports = data['reports'] as List;

      final List<IllegalActivity> activities = [];
      
      for (final json in reports) {
        String decryptedDescription = json['description'] ?? '';
        if (json['public_key'] != null) {
          try {
            final privateKey = await EncryptionService.getPrivateKey();
            if (privateKey != null) {
              decryptedDescription = await EncryptionService.decryptData(
                json['description'], 
                privateKey
              );
            }
          } catch (e) {
            print('Failed to decrypt description: $e');
          }
        }

        activities.add(IllegalActivity(
          id: json['report_id'].toString(),
          userId: json['reporter_uuid'],
          activityType: _parseActivityType(json['category']),
          description: decryptedDescription,
          latitude: _parseLocation(json['location']).first,
          longitude: _parseLocation(json['location']).last,
          imageUrl: json['image_url'],
          status: _parseStatus(json['status']),
          reportedDate: DateTime.parse(json['created_at']),
          createdAt: DateTime.parse(json['created_at']),
          updatedAt: DateTime.parse(json['created_at']),
          aiScore: json['ai_score']?['accuracy_score']?.toDouble(),
          aiExplanation: json['ai_score']?['analysis_summary'],
        ));
      }
      
      return activities;
    } catch (e) {
      throw Exception('Failed to fetch user reports: $e');
    }
  }

  static Future<IllegalActivity> createReport(IllegalActivity report) async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) {
        throw Exception('No active session');
      }

      final publicKey = await EncryptionService.getPublicKey();
      if (publicKey == null) {
        throw Exception('No public key found');
      }

      final encryptedDescription = await EncryptionService.encryptData(
        report.description, 
        publicKey
      );

      final formData = http.MultipartRequest('POST', Uri.parse(_serverUrl));
      
      formData.headers['Authorization'] = 'Bearer ${session.accessToken}';
      
      formData.fields['category'] = report.activityType.toString().split('.').last;
      formData.fields['location'] = '${report.latitude},${report.longitude}';
      formData.fields['description'] = encryptedDescription;
      formData.fields['public_key'] = publicKey;
      formData.fields['userId'] = report.userId;

      if (report.imageUrl != null && report.imageUrl!.isNotEmpty) {
        final file = File(report.imageUrl!);
        if (await file.exists()) {
          final stream = http.ByteStream(file.openRead());
          final length = await file.length();
          final multipartFile = http.MultipartFile(
            'file',
            stream,
            length,
            filename: 'report_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          formData.files.add(multipartFile);
        }
      }

      final response = await formData.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode} - $responseBody');
      }

      return report;
    } catch (e) {
      throw Exception('Failed to create report: $e');
    }
  }

  static Future<IllegalActivity> updateReport(IllegalActivity report) async {
    try {
      return report;
    } catch (e) {
      throw Exception('Failed to update report: $e');
    }
  }

  static Future<IllegalActivity?> getReport(String reportId) async {
    try {
      final response = await _client
          .from('reports')
          .select()
          .eq('report_id', reportId)
          .single();
      
      String decryptedDescription = response['description'] ?? '';
      if (response['public_key'] != null) {
        try {
          final privateKey = await EncryptionService.getPrivateKey();
          if (privateKey != null) {
            decryptedDescription = await EncryptionService.decryptData(
              response['description'], 
              privateKey
            );
          }
        } catch (e) {
          print('Failed to decrypt description: $e');
        }
      }

      return IllegalActivity(
        id: response['report_id'].toString(),
        userId: response['reporter_uuid'],
        activityType: _parseActivityType(response['category']),
        description: decryptedDescription,
        latitude: _parseLocation(response['location']).first,
        longitude: _parseLocation(response['location']).last,
        imageUrl: response['image_url'],
        status: _parseStatus(response['status']),
        reportedDate: DateTime.parse(response['created_at']),
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['created_at']),
        aiScore: response['ai_score']?['accuracy_score']?.toDouble(),
        aiExplanation: response['ai_score']?['analysis_summary'],
      );
    } catch (e) {
      throw Exception('Failed to fetch report: $e');
    }
  }

  // Reward operations
  static Future<List<Reward>> getUserRewards(String userId) async {
    try {
      return [];
    } catch (e) {
      throw Exception('Failed to fetch user rewards: $e');
    }
  }

  static Future<Reward> createReward(Reward reward) async {
    try {
      return reward;
    } catch (e) {
      throw Exception('Failed to create reward: $e');
    }
  }

  static Future<Reward> updateReward(Reward reward) async {
    try {
      return reward;
    } catch (e) {
      throw Exception('Failed to update reward: $e');
    }
  }

  // Authentication operations
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        try {
          // Try to create user record, but don't fail if it doesn't work
          await createUser(User(
            id: response.user!.id,
            points: 50,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        } catch (userError) {
          print('Warning: Failed to create user record: $userError');
          print('This might be due to RLS policies. User authentication succeeded.');
        }
      }
      
      return response;
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  static User? getCurrentUser() {
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        return User(
          id: user.id,
          points: 0, // Will be fetched from database later
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      print('Warning: Failed to get current user: $e');
      return null;
    }
  }

  // File upload operations
  static Future<String> uploadImage(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      await _client.storage
          .from('images')
          .upload(fileName, file);
      
      return _client.storage
          .from('images')
          .getPublicUrl(fileName);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Helper methods
  static IllegalActivityType _parseActivityType(String? category) {
    if (category == null) return IllegalActivityType.other;
    
    switch (category.toLowerCase()) {
      case 'illegaldumping':
        return IllegalActivityType.illegalDumping;
      case 'poaching':
        return IllegalActivityType.poaching;
      case 'deforestation':
        return IllegalActivityType.deforestation;
      case 'pollution':
        return IllegalActivityType.pollution;
      case 'construction':
        return IllegalActivityType.construction;
      default:
        return IllegalActivityType.other;
    }
  }

  static List<double> _parseLocation(String? location) {
    if (location == null) return [0.0, 0.0];
    
    final parts = location.split(',');
    if (parts.length >= 2) {
      return [
        double.tryParse(parts[0].trim()) ?? 0.0,
        double.tryParse(parts[1].trim()) ?? 0.0,
      ];
    }
    return [0.0, 0.0];
  }

  static String _parseStatus(String? status) {
    if (status == null) return 'Submitted';
    return status;
  }
}
