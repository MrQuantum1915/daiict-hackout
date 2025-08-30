import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

class QRService {
  static final QRService _instance = QRService._internal();
  final Uuid _uuid = const Uuid();
  
  factory QRService() {
    return _instance;
  }
  
  QRService._internal();
  
  // Generate a QR code data for a tree
  String generateTreeQRData(String treeId, String userId, String communityId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomSalt = _uuid.v4().substring(0, 8);
    
    // Create a signature to prevent tampering
    final signature = _generateSignature(treeId, userId, communityId, timestamp, randomSalt);
    
    // Create the data to be encoded in the QR code
    final Map<String, dynamic> qrData = {
      'type': 'tree',
      'treeId': treeId,
      'userId': userId,
      'communityId': communityId,
      'timestamp': timestamp,
      'salt': randomSalt,
      'signature': signature,
    };
    
    return json.encode(qrData);
  }
  
  // Generate a QR code data for maintenance verification
  String generateMaintenanceQRData(String maintenanceId, String treeId, String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomSalt = _uuid.v4().substring(0, 8);
    
    // Create a signature to prevent tampering
    final signature = _generateSignature(maintenanceId, treeId, userId, timestamp, randomSalt);
    
    // Create the data to be encoded in the QR code
    final Map<String, dynamic> qrData = {
      'type': 'maintenance',
      'maintenanceId': maintenanceId,
      'treeId': treeId,
      'userId': userId,
      'timestamp': timestamp,
      'salt': randomSalt,
      'signature': signature,
    };
    
    return json.encode(qrData);
  }
  
  // Generate a verification code for offline use
  String generateOfflineVerificationCode(String entityId, String type) {
    // Create a short, human-readable code for offline verification
    // Format: First 4 chars of entity ID + 4 random chars + type indicator (T/M)
    final entityPrefix = entityId.substring(0, 4);
    final randomChars = _uuid.v4().substring(0, 4).toUpperCase();
    final typeIndicator = type == 'tree' ? 'T' : 'M';
    
    return '$entityPrefix-$randomChars-$typeIndicator';
  }
  
  // Parse QR data into a Map
  Map<String, dynamic> parseQRData(String qrDataString) {
    try {
      return json.decode(qrDataString) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  // Verify a QR code data
  bool verifyQRData(String qrDataString) {
    try {
      final qrData = json.decode(qrDataString) as Map<String, dynamic>;
      
      final type = qrData['type'] as String;
      final signature = qrData['signature'] as String;
      final timestamp = qrData['timestamp'] as String;
      final salt = qrData['salt'] as String;
      
      // Check if QR code is expired (24 hours)
      final qrTimestamp = int.parse(timestamp);
      final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      final isExpired = currentTimestamp - qrTimestamp > 24 * 60 * 60 * 1000;
      
      if (isExpired) {
        return false;
      }
      
      // Verify signature based on type
      if (type == 'tree') {
        final treeId = qrData['treeId'] as String;
        final userId = qrData['userId'] as String;
        final communityId = qrData['communityId'] as String;
        
        final expectedSignature = _generateSignature(treeId, userId, communityId, timestamp, salt);
        return signature == expectedSignature;
      } else if (type == 'maintenance') {
        final maintenanceId = qrData['maintenanceId'] as String;
        final treeId = qrData['treeId'] as String;
        final userId = qrData['userId'] as String;
        
        final expectedSignature = _generateSignature(maintenanceId, treeId, userId, timestamp, salt);
        return signature == expectedSignature;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Generate a signature for data verification
  String _generateSignature(String id1, String id2, String id3, String timestamp, String salt) {
    final data = '$id1:$id2:$id3:$timestamp:$salt';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Verify an offline verification code
  Map<String, dynamic>? verifyOfflineCode(String code, String expectedEntityId, String expectedType) {
    try {
      final parts = code.split('-');
      if (parts.length != 3) return null;
      
      final entityPrefix = parts[0];
      final typeIndicator = parts[2];
      
      // Check if entity ID prefix matches
      if (!expectedEntityId.startsWith(entityPrefix)) {
        return null;
      }
      
      // Check if type matches
      final expectedTypeIndicator = expectedType == 'tree' ? 'T' : 'M';
      if (typeIndicator != expectedTypeIndicator) {
        return null;
      }
      
      return {
        'isValid': true,
        'entityId': expectedEntityId,
        'type': expectedType,
      };
    } catch (e) {
      return null;
    }
  }
}
