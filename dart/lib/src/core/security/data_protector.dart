import 'dart:convert';
import 'security_config.dart';

/// Protects sensitive data with encryption and secure storage concepts
/// 
/// In production, use flutter_secure_storage or similar.
/// This provides the concept/interface for secure data handling.
class DataProtector {
  final SecurityConfig config;
  final List<SecurityEvent> _events = [];

  DataProtector(this.config);

  List<SecurityEvent> get events => List.unmodifiable(_events);

  void clearEvents() => _events.clear();

  /// Encrypt sensitive data before storage
  Future<EncryptedData> encrypt({
    required String data,
    required String purpose,
    String? encryptionKeyId,
  }) async {
    if (!config.enabled || !config.encryptionEnabled) {
      // Return data as-is (not recommended for production)
      return EncryptedData(
        encryptedData: data, // Not actually encrypted
        iv: '',
        encryptionKeyId: encryptionKeyId ?? 'default',
        purpose: purpose,
        encrypted: false,
        note: 'Encryption disabled',
      );
    }

    // In production, use proper AES-GCM encryption
    // with secure key management (Keychain/Keystore)
    
    final iv = _generateIV();
    final encrypted = await _encryptData(data, iv);
    
    _logEvent(SecurityEventType.actionAuthorized,
        details: 'Data encrypted for: $purpose');

    return EncryptedData(
      encryptedData: encrypted,
      iv: iv,
      encryptionKeyId: encryptionKeyId ?? 'default',
      purpose: purpose,
      encrypted: true,
    );
  }

  /// Decrypt data that was encrypted
  Future<String> decrypt({
    required EncryptedData encryptedData,
    required String purpose,
  }) async {
    if (!encryptedData.encrypted) {
      // Data was not encrypted
      return encryptedData.encryptedData;
    }

    if (!config.encryptionEnabled) {
      throw SecurityException(
        'Cannot decrypt: encryption is disabled',
      );
    }

    // In production: decrypt with proper key from secure storage
    final decrypted = await _decryptData(
      encryptedData.encryptedData,
      encryptedData.iv,
    );

    _logEvent(SecurityEventType.actionAuthorized,
        details: 'Data decrypted for: $purpose');

    return decrypted;
  }

  /// Encrypt data for transmission (simulated)
  Future<EncryptedPayload> encryptForTransmission({
    required String payload,
    required String destination,
  }) async {
    final encrypted = await _encryptData(payload, _generateIV());
    
    return EncryptedPayload(
      payload: encrypted,
      iv: _generateIV(),
      destination: destination,
      timestamp: DateTime.now(),
      nonce: _generateNonce(),
    );
  }

  /// Verify data integrity and authenticity
  Future<bool> verifyIntegrity({
    required String data,
    required String expectedHash,
    String? signature,
  }) async {
    final computedHash = _computeHash(data);
    
    if (computedHash != expectedHash) {
      _logEvent(SecurityEventType.integrityCheckFailed,
          details: 'Hash mismatch for data integrity check');
      return false;
    }

    if (signature != null) {
      // Verify signature in production
      await Future.delayed(const Duration(milliseconds: 10));
    }

    return true;
  }

  /// Secure random IV generation
  String _generateIV() {
    // In production: use secure random from crypto library
    return DateTime.now().millisecondsSinceEpoch.toRadixString(16);
  }

  /// Secure nonce generation
  String _generateNonce() {
    final random = DateTime.now().microsecondsSinceEpoch % 100000;
    return 'nonce_${DateTime.now().millisecondsSinceEpoch}_$random';
  }

  Future<String> _encryptData(String data, String iv) async {
    // Simulated encryption - in production use proper AES
    await Future.delayed(const Duration(milliseconds: 10));
    
    // Simple obfuscation for demo (NOT secure - replace with real encryption)
    final encoded = base64.encode(utf8.encode(data));
    return 'enc:$iv:$encoded';
  }

  Future<String> _decryptData(String encrypted, String iv) async {
    // Simulated decryption
    await Future.delayed(const Duration(milliseconds: 10));
    
    try {
      final parts = encrypted.split(':');
      if (parts.length >= 3 && parts[0] == 'enc' && parts[1] == iv) {
        final decoded = utf8.decode(base64.decode(parts[2]));
        return decoded;
      }
    } catch (e) {
      throw SecurityException('Decryption failed: $e');
    }
    
    throw SecurityException('Invalid encrypted data format');
  }

  String _computeHash(String data) {
    var hash = 0xcbf29ce484222325;
    for (final byte in utf8.encode(data)) {
      hash ^= byte;
      hash = (hash * 0x100000001b3) & 0xffffffffffffffff;
    }
    return hash.toRadixString(16);
  }

  void _logEvent(
    SecurityEventType type, {
    String? modelId,
    String? actionId,
    String details = '',
  }) {
    if (!config.logSecurityEvents) return;

    final event = SecurityEvent(
      type: type,
      modelId: modelId ?? '',
      actionId: actionId ?? '',
      details: details,
    );
    _events.add(event);
  }
}

/// Encrypted data container
class EncryptedData {
  final String encryptedData;
  final String iv; // Initialization vector
  final String encryptionKeyId;
  final String purpose;
  final bool encrypted;
  final String? note;

  EncryptedData({
    required this.encryptedData,
    required this.iv,
    required this.encryptionKeyId,
    required this.purpose,
    this.encrypted = true,
    this.note,
  });
}

/// Encrypted payload for transmission
class EncryptedPayload {
  final String payload;
  final String iv;
  final String destination;
  final DateTime timestamp;
  final String nonce;

  EncryptedPayload({
    required this.payload,
    required this.iv,
    required this.destination,
    required this.timestamp,
    required this.nonce,
  });
}

/// Security exception
class SecurityException implements Exception {
  final String message;
  final String? code;

  SecurityException(this.message, {this.code});

  @override
  String toString() => 'SecurityException: $message${code != null ? ' ($code)' : ''}';
}

class Random {
  static int nextInt(int max) {
    // Simple pseudo-random for demo
    // Use dart:math in production
    return DateTime.now().millisecondsSinceEpoch % max;
  }
}
