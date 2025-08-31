import 'package:flutter/material.dart';

import 'package:mangrove_protector/models/user_model.dart';
import 'package:mangrove_protector/services/supabase_service.dart';
import 'package:mangrove_protector/services/encryption_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _hasGeneratedKeys = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get hasGeneratedKeys => _hasGeneratedKeys;

  AuthProvider() {
    _initAuthState();
  }

  Future<void> _initAuthState() async {
    try {
      // Check if user has backed up private key
      _hasGeneratedKeys = await EncryptionService.hasBackedUpPrivateKey();
      
      // Check if user is authenticated
      final user = SupabaseService.getCurrentUser();
      if (user != null) {
        // Fetch user data from database
        final userData = await SupabaseService.getUser(user.id);
        if (userData != null) {
          _currentUser = userData;
          _isAuthenticated = true;
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing auth state: $e');
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseService.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Generate encryption keys
        await generateAndBackupKeys();
        
        // Create a basic user object if database fetch fails
        _currentUser = User(
          id: response.user!.id,
          points: 50, // Default credits
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        // Try to fetch user data from database, but don't fail if it doesn't work
        try {
          final userData = await SupabaseService.getUser(response.user!.id);
          if (userData != null) {
            _currentUser = userData;
          }
        } catch (e) {
          debugPrint('Warning: Could not fetch user data from database: $e');
          debugPrint('Using default user object. This is normal for new users.');
        }
        
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error during sign up: $e');
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Check if user has encryption keys
        _hasGeneratedKeys = await EncryptionService.hasBackedUpPrivateKey();
        
        // If keys don't exist, generate them automatically
        if (!_hasGeneratedKeys) {
          print('No encryption keys found, generating new keys...');
          try {
            await generateAndBackupKeys();
            print('Encryption keys generated successfully');
          } catch (e) {
            print('Failed to generate encryption keys: $e');
            // Continue without keys for now, but this might cause issues later
          }
        }
        
        // Create a basic user object if database fetch fails
        _currentUser = User(
          id: response.user!.id,
          points: 0, // Will be fetched from database
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        // Try to fetch user data from database, but don't fail if it doesn't work
        try {
          final userData = await SupabaseService.getUser(response.user!.id);
          if (userData != null) {
            _currentUser = userData;
          }
        } catch (e) {
          debugPrint('Warning: Could not fetch user data from database: $e');
          debugPrint('Using default user object. This is normal for new users.');
        }
        
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error during sign in: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await SupabaseService.signOut();
      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error during sign out: $e');
    }
  }

  Future<void> generateAndBackupKeys() async {
    try {
      print('Generating encryption keys...');
      
      // Test encryption service first
      final testResult = await EncryptionService.testEncryption();
      if (!testResult) {
        throw Exception('Encryption service test failed');
      }
      
      final keyPair = await EncryptionService.generateKeyPair();
      
      if (keyPair['privateKey'] == null || keyPair['publicKey'] == null) {
        throw Exception('Failed to generate valid key pair');
      }
      
      // Store private key locally
      await EncryptionService.storePrivateKey(keyPair['privateKey']!);
      
      // Store public key locally (for backup)
      await EncryptionService.storePublicKey(keyPair['publicKey']!);
      
      // Verify keys were stored correctly
      final storedPrivateKey = await EncryptionService.getPrivateKey();
      final storedPublicKey = await EncryptionService.getPublicKey();
      
      if (storedPrivateKey == null || storedPublicKey == null) {
        throw Exception('Failed to store keys securely');
      }
      
      _hasGeneratedKeys = true;
      notifyListeners();
      
      print('Encryption keys generated and stored successfully');
    } catch (e) {
      print('Error generating keys: $e');
      _hasGeneratedKeys = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<String?> getPrivateKey() async {
    return await EncryptionService.getPrivateKey();
  }

  Future<String?> getPublicKey() async {
    return await EncryptionService.getPublicKey();
  }

  /// Validate stored encryption keys
  Future<bool> validateStoredKeys() async {
    try {
      final privateKey = await getPrivateKey();
      final publicKey = await getPublicKey();
      
      if (privateKey == null || publicKey == null) {
        print('Stored keys validation: Keys not found');
        return false;
      }
      
      // Test with stored keys
      final isValid = await EncryptionService.validateStoredKeys();
      print('Stored keys validation result: $isValid');
      
      if (isValid) {
        _hasGeneratedKeys = true;
        notifyListeners();
      }
      
      return isValid;
    } catch (e) {
      print('Stored keys validation failed: $e');
      return false;
    }
  }

  /// Manually regenerate encryption keys
  Future<bool> regenerateKeys() async {
    try {
      print('Regenerating encryption keys...');
      
      // Clear existing keys
      await EncryptionService.clearKeys();
      
      // Generate new keys
      await generateAndBackupKeys();
      
      print('Encryption keys regenerated successfully');
      return true;
    } catch (e) {
      print('Error regenerating keys: $e');
      return false;
    }
  }

  /// Check and fix encryption keys if needed
  Future<bool> ensureEncryptionKeys() async {
    try {
      // First check if keys exist
      _hasGeneratedKeys = await EncryptionService.hasBackedUpPrivateKey();
      
      if (!_hasGeneratedKeys) {
        print('No encryption keys found, generating new keys...');
        await generateAndBackupKeys();
        return true;
      }
      
      // Validate existing keys
      final isValid = await validateStoredKeys();
      if (!isValid) {
        print('Stored keys are invalid, regenerating...');
        await regenerateKeys();
        return true;
      }
      
      return true;
    } catch (e) {
      print('Error ensuring encryption keys: $e');
      return false;
    }
  }

  Future<void> refreshUser() async {
    if (_currentUser != null) {
      try {
        final userData = await SupabaseService.getUser(_currentUser!.id);
        if (userData != null) {
          _currentUser = userData;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error refreshing user: $e');
      }
    }
  }

  Future<void> updateUserPoints(int points) async {
    if (_currentUser != null) {
      try {
        final updatedUser = _currentUser!.copyWith(points: points);
        final savedUser = await SupabaseService.updateUser(updatedUser);
        _currentUser = savedUser;
        notifyListeners();
      } catch (e) {
        debugPrint('Error updating user points: $e');
      }
    }
  }
}
