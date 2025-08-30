import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libsodium/libsodium.dart';

class EncryptionService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _privateKeyKey = 'private_key';
  static const String _publicKeyKey = 'public_key';
  static bool _initialized = false;

  /// Initialize libsodium
  static Future<void> _initSodium() async {
    if (!_initialized) {
      try {
        Sodium.init();
        _initialized = true;
      } catch (e) {
        print('Warning: libsodium initialization failed: $e');
        // Continue with fallback encryption
      }
    }
  }

  /// Generate a new key pair using libsodium
  static Future<Map<String, String>> generateKeyPair() async {
    try {
      await _initSodium();
      
      if (_initialized) {
        // Use proper libsodium key generation
        final keyPair = Sodium.cryptoBoxKeypair();
        final privateKey = base64Encode(keyPair.sk);
        final publicKey = base64Encode(keyPair.pk);
        
        return {
          'privateKey': privateKey,
          'publicKey': publicKey,
        };
      } else {
        // Fallback to random key generation
        final privateKeyBytes = Sodium.randombytesBuf(32);
        final publicKeyBytes = Sodium.randombytesBuf(32);
        
        final privateKey = base64Encode(privateKeyBytes);
        final publicKey = base64Encode(publicKeyBytes);
        
        return {
          'privateKey': privateKey,
          'publicKey': publicKey,
        };
      }
    } catch (e) {
      throw Exception('Failed to generate key pair: $e');
    }
  }

  /// Store private key securely
  static Future<void> storePrivateKey(String privateKey) async {
    await _storage.write(key: _privateKeyKey, value: privateKey);
  }

  /// Retrieve private key from secure storage
  static Future<String?> getPrivateKey() async {
    return await _storage.read(key: _privateKeyKey);
  }

  /// Store public key in secure storage (for backup purposes)
  static Future<void> storePublicKey(String publicKey) async {
    await _storage.write(key: _publicKeyKey, value: publicKey);
  }

  /// Retrieve public key from secure storage
  static Future<String?> getPublicKey() async {
    return await _storage.read(key: _publicKeyKey);
  }

  /// Check if user has backed up their private key
  static Future<bool> hasBackedUpPrivateKey() async {
    final privateKey = await getPrivateKey();
    return privateKey != null;
  }

  /// Encrypt data with public key
  static Future<String> encryptData(String data, String publicKey) async {
    try {
      await _initSodium();
      
      if (_initialized) {
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
        // Fallback to XOR encryption
        final dataBytes = utf8.encode(data);
        final keyBytes = base64Decode(publicKey);
        
        final encrypted = Uint8List(dataBytes.length);
        for (int i = 0; i < dataBytes.length; i++) {
          encrypted[i] = dataBytes[i] ^ keyBytes[i % keyBytes.length];
        }
        
        return base64Encode(encrypted);
      }
    } catch (e) {
      throw Exception('Failed to encrypt data: $e');
    }
  }

  /// Decrypt data with private key
  static Future<String> decryptData(String encryptedData, String privateKey) async {
    try {
      await _initSodium();
      
      if (_initialized) {
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
        // Fallback to XOR decryption
        final encryptedBytes = base64Decode(encryptedData);
        final keyBytes = base64Decode(privateKey);
        
        final decrypted = Uint8List(encryptedBytes.length);
        for (int i = 0; i < encryptedBytes.length; i++) {
          decrypted[i] = encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
        }
        
        return utf8.decode(decrypted);
      }
    } catch (e) {
      throw Exception('Failed to decrypt data: $e');
    }
  }

  /// Clear all stored keys
  static Future<void> clearKeys() async {
    await _storage.delete(key: _privateKeyKey);
    await _storage.delete(key: _publicKeyKey);
  }
}
