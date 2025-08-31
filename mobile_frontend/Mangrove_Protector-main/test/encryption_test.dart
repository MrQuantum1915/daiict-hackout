import 'package:flutter_test/flutter_test.dart';
import 'package:mangrove_protector/services/encryption_service.dart';

void main() {
  group('EncryptionService Tests', () {
    test('should generate key pair', () async {
      final keyPair = await EncryptionService.generateKeyPair();
      expect(keyPair['privateKey'], isNotNull);
      expect(keyPair['publicKey'], isNotNull);
      expect(keyPair['privateKey']!.length, greaterThan(0));
      expect(keyPair['publicKey']!.length, greaterThan(0));
    });

    test('should encrypt and decrypt data', () async {
      final keyPair = await EncryptionService.generateKeyPair();
      final testData = 'Hello, World!';
      
      final encrypted = await EncryptionService.encryptData(testData, keyPair['publicKey']!);
      final decrypted = await EncryptionService.decryptData(encrypted, keyPair['privateKey']!);
      
      expect(decrypted, equals(testData));
    });

    test('should test encryption service', () async {
      final result = await EncryptionService.testEncryption();
      expect(result, isTrue);
    });
  });
}
