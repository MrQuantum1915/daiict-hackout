import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:mangrove_protector/models/user_model.dart';
import 'package:mangrove_protector/models/community_model.dart';
import 'package:mangrove_protector/services/database_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  Community? _currentCommunity;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  final DatabaseService _databaseService = DatabaseService();
  final Uuid _uuid = const Uuid();

  User? get currentUser => _currentUser;
  Community? get currentCommunity => _currentCommunity;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _initAuthState();
  }

  Future<void> _initAuthState() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userData = prefs.getString('user_data');
      
      if (userData != null) {
        final Map<String, dynamic> userMap = json.decode(userData);
        _currentUser = User.fromJson(userMap);
        
        // Load community data
        if (_currentUser != null) {
          _currentCommunity = await _databaseService.getCommunity(_currentUser!.communityId);
          _isAuthenticated = true;
        }
      }
    } catch (e) {
      debugPrint('Error initializing auth state: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String nickname,
    required String communityId,
    String? profileImage,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if community exists
      final community = await _databaseService.getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      final now = DateTime.now();
      final user = User(
        id: _uuid.v4(),
        nickname: nickname,
        communityId: communityId,
        profileImage: profileImage,
        isAdmin: false,
        points: 0,
        createdAt: now,
        updatedAt: now,
      );

      // Save user to local database
      await _databaseService.insertUser(user);

      // Save user data to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(user.toJson()));

      _currentUser = user;
      _currentCommunity = community;
      _isAuthenticated = true;

      return true;
    } catch (e) {
      debugPrint('Error during registration: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String nickname,
    required String communityId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get community users
      final users = await _databaseService.getUsersByCommunity(communityId);
      
      // Find user with matching nickname
      final user = users.firstWhere(
        (u) => u.nickname.toLowerCase() == nickname.toLowerCase(),
        orElse: () => throw Exception('User not found'),
      );

      // Get community
      final community = await _databaseService.getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      // Save user data to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(user.toJson()));

      _currentUser = user;
      _currentCommunity = community;
      _isAuthenticated = true;

      return true;
    } catch (e) {
      debugPrint('Error during login: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');

      _currentUser = null;
      _currentCommunity = null;
      _isAuthenticated = false;
    } catch (e) {
      debugPrint('Error during logout: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? nickname,
    String? profileImage,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = _currentUser!.copyWith(
        nickname: nickname,
        profileImage: profileImage,
        updatedAt: DateTime.now(),
      );

      // Update user in local database
      await _databaseService.updateUser(updatedUser);

      // Update shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(updatedUser.toJson()));

      _currentUser = updatedUser;
      
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCommunity({
    required String name,
    String? description,
    String? location,
    String? imageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final String communityId = _uuid.v4();
      
      // Create community first
      final community = Community(
        id: communityId,
        name: name,
        description: description,
        location: location,
        imageUrl: imageUrl,
        adminIds: [], // Will be updated after user creation
        createdAt: now,
        updatedAt: now,
      );

      // Save community to local database
      await _databaseService.insertCommunity(community);
      
      // If there's no current user, create one
      if (_currentUser == null) {
        // Create a temporary user for community creation
        final tempUser = User(
          id: _uuid.v4(),
          nickname: 'Admin',
          communityId: communityId,
          isAdmin: true,
          points: 0,
          createdAt: now,
          updatedAt: now,
        );
        
        // Save user to local database
        await _databaseService.insertUser(tempUser);
        
        // Update community with admin ID
        final updatedCommunity = community.copyWith(
          adminIds: [tempUser.id],
          updatedAt: now,
        );
        await _databaseService.updateCommunity(updatedCommunity);
        
        // Save user data to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', json.encode(tempUser.toJson()));

        _currentUser = tempUser;
        _currentCommunity = updatedCommunity;
      } else {
        // Update existing user to be admin of this community
        final updatedUser = _currentUser!.copyWith(
          communityId: communityId,
          isAdmin: true,
          updatedAt: now,
        );
        
        // Update user in local database
        await _databaseService.updateUser(updatedUser);
        
        // Update community with admin ID
        final updatedCommunity = community.copyWith(
          adminIds: [updatedUser.id],
          updatedAt: now,
        );
        await _databaseService.updateCommunity(updatedCommunity);
        
        // Update shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', json.encode(updatedUser.toJson()));

        _currentUser = updatedUser;
        _currentCommunity = updatedCommunity;
      }
      
      return true;
    } catch (e) {
      debugPrint('Error creating community: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Community>> getAllCommunities() async {
    try {
      return await _databaseService.getAllCommunities();
    } catch (e) {
      debugPrint('Error getting communities: $e');
      return [];
    }
  }

  Future<bool> addPointsToUser(int points) async {
    if (_currentUser == null) return false;

    try {
      final updatedUser = _currentUser!.copyWith(
        points: _currentUser!.points + points,
        updatedAt: DateTime.now(),
      );

      // Update user in local database
      await _databaseService.updateUser(updatedUser);

      // Update shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(updatedUser.toJson()));

      _currentUser = updatedUser;
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Error adding points to user: $e');
      return false;
    }
  }

  bool isAdmin() {
    return _currentUser?.isAdmin ?? false;
  }
  
  // Get users by community ID
  Future<List<User>> getUsersByCommunity(String communityId) async {
    try {
      return await _databaseService.getUsersByCommunity(communityId);
    } catch (e) {
      debugPrint('Error getting users by community: $e');
      return [];
    }
  }
}
