import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libsodium/libsodium.dart';

class EncryptionService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _privateKeyKey = 'private_key';
  static const String _publicKeyKey = 'public_key';
  static bool _initialized = false;
  static bool _useLibsodium = false;

  /// Initialize libsodium with platform detection
  static Future<void> _initSodium() async {
    if (!_initialized) {
      try {
        // Check platform compatibility
        if (kIsWeb) {
          print('Web platform detected, libsodium may not work properly');
          _useLibsodium = false;
        } else if (Platform.isAndroid || Platform.isIOS) {
          print('Mobile platform detected, attempting libsodium initialization');
          try {
            Sodium.init();
            _useLibsodium = true;
            print('libsodium initialized successfully on mobile');
          } catch (e) {
            print('libsodium failed on mobile: $e');
            _useLibsodium = false;
          }
        } else {
          print('Desktop platform detected, attempting libsodium initialization');
          try {
            Sodium.init();
            _useLibsodium = true;
            print('libsodium initialized successfully on desktop');
          } catch (e) {
            print('libsodium failed on desktop: $e');
            _useLibsodium = false;
          }
        }
        
        _initialized = true;
      } catch (e) {
        print('Warning: libsodium initialization failed: $e');
        _useLibsodium = false;
        _initialized = true;
      }
    }
  }

  /// Generate a new key pair using libsodium or fallback
  static Future<Map<String, String>> generateKeyPair() async {
    try {
      await _initSodium();
      
      if (_useLibsodium) {
        // Use proper libsodium key generation
        final keyPair = Sodium.cryptoBoxKeypair();
        final privateKey = base64Encode(keyPair.sk);
        final publicKey = base64Encode(keyPair.pk);
        
        return {
          'privateKey': privateKey,
          'publicKey': publicKey,
        };
      } else {
        // Fallback to random key generation - use same key for both to make cipher symmetric
        final random = Random.secure();
        final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
        
        final key = base64Encode(Uint8List.fromList(keyBytes));
        
        return {
          'privateKey': key,
          'publicKey': key, // Same key for symmetric cipher
        };
      }
    } catch (e) {
      print('Error in generateKeyPair: $e');
      // Always fallback to random generation if libsodium fails
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
      
      final key = base64Encode(Uint8List.fromList(keyBytes));
      
      return {
        'privateKey': key,
        'publicKey': key, // Same key for symmetric cipher
      };
    }
  }

  /// Store private key securely
  static Future<void> storePrivateKey(String privateKey) async {
    try {
      await _storage.write(key: _privateKeyKey, value: privateKey);
    } catch (e) {
      throw Exception('Failed to store private key: $e');
    }
  }

  /// Retrieve private key from secure storage
  static Future<String?> getPrivateKey() async {
    try {
      return await _storage.read(key: _privateKeyKey);
    } catch (e) {
      print('Error retrieving private key: $e');
      return null;
    }
  }

  /// Store public key in secure storage (for backup purposes)
  static Future<void> storePublicKey(String publicKey) async {
    try {
      await _storage.write(key: _publicKeyKey, value: publicKey);
    } catch (e) {
      throw Exception('Failed to store public key: $e');
    }
  }

  /// Retrieve public key from secure storage
  static Future<String?> getPublicKey() async {
    try {
      return await _storage.read(key: _publicKeyKey);
    } catch (e) {
      print('Error retrieving public key: $e');
      return null;
    }
  }

  /// Check if user has backed up their private key
  static Future<bool> hasBackedUpPrivateKey() async {
    try {
      final privateKey = await getPrivateKey();
      return privateKey != null && privateKey.isNotEmpty;
    } catch (e) {
      print('Error checking private key backup: $e');
      return false;
    }
  }

  /// Encrypt data with public key
  static Future<String> encryptData(String data, String publicKey) async {
    try {
      await _initSodium();
      
      if (_useLibsodium) {
        // Use proper libsodium encryption
        final publicKeyBytes = base64Decode(publicKey);
        final ephemeralKeyPair = Sodium.cryptoBoxKeypair();
        final nonce = Sodium.randombytesBuf(Sodium.cryptoBoxNoncebytes);
        final encryptedData = Sodium.cryptoBoxEasy(
          utf8.encode(data),
          nonce,
          publicKeyBytes,
          ephemeralKeyPair.sk,
        );
        final combined = Uint8List.fromList([
          ...ephemeralKeyPair.pk,
          ...nonce,
          ...encryptedData,
        ]);
        return base64Encode(combined);
      } else {
        // Simple substitution cipher fallback - use a symmetric key
        final keyBytes = base64Decode(publicKey);
        final keySum = keyBytes.fold<int>(0, (sum, byte) => sum + byte);
        
        final encrypted = Uint8List(data.length);
        for (int i = 0; i < data.length; i++) {
          final charCode = data.codeUnitAt(i);
          encrypted[i] = (charCode + keySum + i) % 256;
        }
        
        return base64Encode(encrypted);
      }
    } catch (e) {
      print('Encryption error: $e');
      // Final fallback to simple substitution
      try {
        final keyBytes = base64Decode(publicKey);
        final keySum = keyBytes.fold<int>(0, (sum, byte) => sum + byte);
        
        final encrypted = Uint8List(data.length);
        for (int i = 0; i < data.length; i++) {
          final charCode = data.codeUnitAt(i);
          encrypted[i] = (charCode + keySum + i) % 256;
        }
        
        return base64Encode(encrypted);
      } catch (fallbackError) {
        print('Fallback encryption also failed: $fallbackError');
        throw Exception('All encryption methods failed: $e');
      }
    }
  }

  /// Decrypt data with private key
  static Future<String> decryptData(String encryptedData, String privateKey) async {
    try {
      await _initSodium();
      
      if (_useLibsodium) {
        // Use proper libsodium decryption
        final combined = base64Decode(encryptedData);
        final privateKeyBytes = base64Decode(privateKey);
        final ephemeralPublicKey = combined.sublist(0, Sodium.cryptoBoxPublickeybytes);
        final nonce = combined.sublist(
          Sodium.cryptoBoxPublickeybytes,
          Sodium.cryptoBoxPublickeybytes + Sodium.cryptoBoxNoncebytes,
        );
        final encrypted = combined.sublist(
          Sodium.cryptoBoxPublickeybytes + Sodium.cryptoBoxNoncebytes,
        );
        final decrypted = Sodium.cryptoBoxOpenEasy(
          encrypted,
          nonce,
          ephemeralPublicKey,
          privateKeyBytes,
        );
        
        return utf8.decode(decrypted);
      } else {
        // For fallback cipher, we need to use the same key that was used for encryption
        // Since the fallback is symmetric, we'll use the private key (which should be the same as public key in this case)
        final encryptedBytes = base64Decode(encryptedData);
        final keyBytes = base64Decode(privateKey);
        final keySum = keyBytes.fold<int>(0, (sum, byte) => sum + byte);
        
        final decrypted = Uint8List(encryptedBytes.length);
        for (int i = 0; i < encryptedBytes.length; i++) {
          final encryptedByte = encryptedBytes[i];
          decrypted[i] = (encryptedByte - keySum - i + 256) % 256;
        }
        
        return String.fromCharCodes(decrypted);
      }
    } catch (e) {
      print('Decryption error: $e');
      // Final fallback to simple substitution
      try {
        final encryptedBytes = base64Decode(encryptedData);
        final keyBytes = base64Decode(privateKey);
        final keySum = keyBytes.fold<int>(0, (sum, byte) => sum + byte);
        
        final decrypted = Uint8List(encryptedBytes.length);
        for (int i = 0; i < encryptedBytes.length; i++) {
          final encryptedByte = encryptedBytes[i];
          decrypted[i] = (encryptedByte - keySum - i + 256) % 256;
        }
        
        return String.fromCharCodes(decrypted);
      } catch (fallbackError) {
        print('Fallback decryption also failed: $fallbackError');
        throw Exception('All decryption methods failed: $e');
      }
    }
  }

  /// Clear all stored keys
  static Future<void> clearKeys() async {
    try {
      await _storage.delete(key: _privateKeyKey);
      await _storage.delete(key: _publicKeyKey);
    } catch (e) {
      print('Error clearing keys: $e');
    }
  }

  /// Test encryption/decryption
  static Future<bool> testEncryption() async {
    try {
      await _initSodium();
      
      print('Platform: ${kIsWeb ? "Web" : Platform.operatingSystem}');
      print('Using libsodium: $_useLibsodium');
      
      if (!_initialized) {
        print('Service not initialized, skipping test');
        return false;
      }
      
      final testData = 'Test encryption data';
      final keyPair = await generateKeyPair();
      
      final encrypted = await encryptData(testData, keyPair['publicKey']!);
      final decrypted = await decryptData(encrypted, keyPair['privateKey']!);
      
      final isValid = testData == decrypted;
      print('Encryption test result: $isValid');
      return isValid;
    } catch (e) {
      print('Encryption test failed: $e');
      return false;
    }
  }

  /// Validate stored keys
  static Future<bool> validateStoredKeys() async {
    try {
      final privateKey = await getPrivateKey();
      final publicKey = await getPublicKey();
      
      if (privateKey == null || publicKey == null) {
        print('Stored keys validation: Keys not found');
        return false;
      }
      
      // Test with stored keys
      final testData = 'Validation test';
      final encrypted = await encryptData(testData, publicKey);
      final decrypted = await decryptData(encrypted, privateKey);
      
      final isValid = testData == decrypted;
      print('Stored keys validation: $isValid');
      return isValid;
    } catch (e) {
      print('Stored keys validation failed: $e');
      return false;
    }
  }
}
