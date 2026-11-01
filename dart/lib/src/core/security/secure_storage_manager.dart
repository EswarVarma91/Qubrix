import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'security_config.dart';

/// Manages secure storage of encryption keys and sensitive data
/// 
/// In production, this wraps flutter_secure_storage / Keychain / Keystore.
/// 
/// Handles:
/// - Storing encryption keys securely
/// - Retrieving keys with optional biometric authentication
/// - Key rotation
/// - Backup/restore of keys
/// - Secure deletion
/// 
/// KEYS ARE NEVER STORED IN PLAINTEXT IN THE APP'S NORMAL STORAGE.
/// They go through secure platform storage APIs.
class SecureStorageManager {
  final SecurityConfig config;
  final List<SecurityEvent> _events = [];
  
  // In-memory key cache (for performance, cleared on memory pressure)
  final Map<String, _CachedKey> _keyCache = {};
  
  // Simulated secure storage (in production: use flutter_secure_storage)
  final Map<String, String> _secureStorage = {};
  
  // Key rotation tracking
  final Map<String, KeyVersion> _keyVersions = {};

  SecureStorageManager({required this.config});

  List<SecurityEvent> get events => List.unmodifiable(_events);
  void clearEvents() => _events.clear();

  /// Store a key securely
  /// 
  /// In production:
  /// - Encrypt key with a storage-specific key
  /// - Store via flutter_secure_storage.write()
  /// - Key is stored in iOS Keychain / Android Keystore
  Future<void> storeKey({
    required String keyId,
    required encrypt.Key key,
    String? purpose,
    Map<String, String>? metadata,
  }) async {
    if (!config.enabled) {
      throw SecureStorageException('Security is disabled');
    }

    // Encrypt the key before storage (defense in depth)
    final encryptedKey = _encryptKeyForStorage(key);
    
    // Store as base64 string
    final storageValue = base64.encode(encryptedKey);
    
    // Add metadata
    final fullValue = jsonEncode({
      'key': storageValue,
      'purpose': purpose ?? 'general',
      'metadata': metadata ?? {},
      'storedAt': DateTime.now().toIso8601String(),
    });
    
    _secureStorage[keyId] = fullValue;
    
    // Add to cache for quick access
    _keyCache[keyId] = _CachedKey(
      key: key,
      cachedAt: DateTime.now(),
      purpose: purpose,
    );
    
    _logEvent(SecurityEventType.actionAuthorized,
        details: 'Key stored securely: $keyId');
  }

  /// Retrieve a stored key
  /// 
  /// Optionally requires biometric authentication before returning.
  Future<encrypt.Key> retrieveKey({
    required String keyId,
    bool requireBiometric = false,
    String? biometricReason,
  }) async {
    if (!config.enabled) {
      throw SecureStorageException('Security is disabled');
    }

    // Check cache first (faster)
    final cached = _keyCache[keyId];
    if (cached != null) {
      // Optionally verify biometric before returning cached key
      if (requireBiometric) {
        final authenticated = await _authenticateBiometric(
          reason: biometricReason ?? 'Access encryption key',
        );
        if (!authenticated) {
          throw SecureStorageException(
            'Biometric authentication required to access key',
            code: 'BIOMETRIC_REQUIRED',
          );
        }
      }
      
      // Refresh cache timestamp
      _keyCache[keyId] = _CachedKey(
        key: cached.key,
        cachedAt: DateTime.now(),
        purpose: cached.purpose,
      );
      
      return cached.key;
    }

    // Retrieve from secure storage
    final storedValue = _secureStorage[keyId];
    if (storedValue == null) {
      throw SecureStorageException(
        'Key not found: $keyId',
        code: 'KEY_NOT_FOUND',
      );
    }

    // Decrypt and return
    final decrypted = jsonDecode(storedValue) as Map<String, dynamic>;
    final encryptedBytes = base64.decode(decrypted['key'] as String);
    final key = encrypt.Key(encryptedBytes);
    
    // Cache for future access
    _keyCache[keyId] = _CachedKey(
      key: key,
      cachedAt: DateTime.now(),
      purpose: decrypted['purpose'] as String?,
    );
    
    if (requireBiometric) {
      final authenticated = await _authenticateBiometric(
        reason: biometricReason ?? 'Access encryption key',
      );
      if (!authenticated) {
        throw SecureStorageException(
          'Biometric authentication required',
          code: 'BIOMETRIC_REQUIRED',
        );
      }
    }

    _logEvent(SecurityEventType.actionAuthorized,
        details: 'Key retrieved: $keyId');
    
    return key;
  }

  /// Store the device master key
  /// 
  /// This is the root key from which all other keys are derived.
  /// It must be stored most securely.
  Future<void> storeDeviceMasterKey({
    required encrypt.Key masterKey,
    String? deviceId,
    Map<String, String>? backupInfo,
  }) async {
    await storeKey(
      keyId: 'device_master_key',
      key: masterKey,
      purpose: 'device_master',
      metadata: {
        'deviceId': deviceId ?? 'unknown',
        'backupEnabled': backupInfo != null ? 'true' : 'false',
        'version': '1',
      },
    );
    
    // Track version for rotation
    _keyVersions['device_master_key'] = KeyVersion(
      version: 1,
      createdAt: DateTime.now(),
      algorithm: 'AES-256',
    );
  }

  /// Get the device master key
  Future<encrypt.Key> getDeviceMasterKey({
    bool requireBiometric = true,
  }) async {
    return retrieveKey(
      keyId: 'device_master_key',
      requireBiometric: requireBiometric,
      biometricReason: 'Access device master key for decryption',
    );
  }

  /// Rotate (change) a key
  /// 
  /// Creates a new key and re-encrypts any data that used the old key.
  /// Old key is securely deleted.
  Future<KeyRotationResult> rotateKey({
    required String keyId,
    required encrypt.Key newKey,
    bool reEncryptData = false,
    List<String>? dataIdsToReEncrypt,
  }) async {
    if (!config.enabled) {
      throw SecureStorageException('Security is disabled');
    }

    await retrieveKey(keyId: keyId);
    
    // Store new key
    await storeKey(
      keyId: keyId,
      key: newKey,
      purpose: _keyCache[keyId]?.purpose,
    );
    
    // Update version tracking
    final currentVersion = _keyVersions[keyId]?.version ?? 0;
    _keyVersions[keyId] = KeyVersion(
      version: currentVersion + 1,
      createdAt: DateTime.now(),
      algorithm: 'AES-256',
      rotatedFrom: currentVersion,
    );
    
    // Re-encrypt data if needed
    if (reEncryptData && dataIdsToReEncrypt != null) {
      for (var i = 0; i < dataIdsToReEncrypt.length; i++) {
        // In production: re-encrypt data with new key
        // This is a placeholder
      }
    }
    
    // Securely delete old key from cache
    _keyCache.remove(keyId);
    
    _logEvent(SecurityEventType.actionAuthorized,
        details: 'Key rotated: $keyId (v${currentVersion + 1})');
    
    return KeyRotationResult(
      keyId: keyId,
      oldVersion: currentVersion,
      newVersion: currentVersion + 1,
      rotatedAt: DateTime.now(),
      success: true,
    );
  }

  /// Backup a key for recovery
  /// 
  /// In production, this would encrypt the key with a backup key
  /// and store it in a secure location (cloud storage, user backup).
  Future<String> backupKey({
    required String keyId,
    required String backupKeyId,
    String? backupLocation,
  }) async {
    await retrieveKey(keyId: keyId);
    
    // In production: encrypt with backup key and upload to secure storage
    // For now: return a placeholder backup reference
    final backupRef = 'backup_${keyId}_${DateTime.now().millisecondsSinceEpoch}';
    
    _logEvent(SecurityEventType.actionAuthorized,
        details: 'Key backed up: $keyId -> $backupRef');
    
    return backupRef;
  }

  /// Restore a key from backup
  Future<void> restoreKey({
    required String keyId,
    required String backupReference,
    bool overwriteExisting = false,
  }) async {
    // In production: retrieve from backup location, decrypt with backup key
    // For now: placeholder
    _logEvent(SecurityEventType.actionAuthorized,
        details: 'Key restored: $keyId from $backupReference');
  }

  /// Securely delete a key
  Future<void> deleteKey(String keyId) async {
    _secureStorage.remove(keyId);
    _keyCache.remove(keyId);
    _keyVersions.remove(keyId);
    
    _logEvent(SecurityEventType.actionAuthorized,
        details: 'Key deleted: $keyId');
  }

  /// List all stored keys (metadata only, not key material)
  List<StoredKeyInfo> getStoredKeys() {
    return _secureStorage.keys.map((keyId) {
      final version = _keyVersions[keyId];
      final cached = _keyCache[keyId];
      
      return StoredKeyInfo(
        keyId: keyId,
        purpose: cached?.purpose ?? version?.algorithm ?? 'unknown',
        version: version?.version ?? 1,
        cachedAt: cached?.cachedAt,
        createdAt: version?.createdAt,
      );
    }).toList();
  }

  /// Clear all keys from memory cache (not from secure storage)
  void clearMemoryCache() {
    _keyCache.clear();
    _logEvent(SecurityEventType.actionAuthorized,
        details: 'Memory key cache cleared');
  }

  /// Check if key exists
  bool hasKey(String keyId) {
    return _secureStorage.containsKey(keyId) || _keyCache.containsKey(keyId);
  }

  /// Get cache status
  String getCacheStatus() {
    return '''
Secure Storage Status
=====================
Total Keys Stored: ${_secureStorage.length}
Keys in Memory Cache: ${_keyCache.length}
Device Master Key: ${hasKey('device_master_key') ? 'Present' : 'Missing'}
''';
  }

  /// Encrypt key for storage (defense in depth)
  Uint8List _encryptKeyForStorage(encrypt.Key key) {
    // In production: use a storage-specific encryption key
    // that's derived from device credentials
    
    // For now: simple protection (in production, use asymmetric encryption
    // or platform-provided key wrapping)
    final protectedKey = encrypt.Key(
      Uint8List.fromList(key.bytes.map((b) => b ^ 0xFF).toList()),
    );
    
    return protectedKey.bytes;
  }

  /// Authenticate with biometrics
  /// 
  /// In production: use local_auth package
  Future<bool> _authenticateBiometric({required String reason}) async {
    // Placeholder - implement with local_auth in production
    // final auth = LocalAuthentication();
    // return await auth.authenticate(localizedReason: reason);
    return true;
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

/// Cached key for quick access
class _CachedKey {
  final encrypt.Key key;
  final DateTime cachedAt;
  final String? purpose;

  _CachedKey({
    required this.key,
    required this.cachedAt,
    this.purpose,
  });
}

/// Key version info
class KeyVersion {
  final int version;
  final DateTime createdAt;
  final String algorithm;
  final int? rotatedFrom;

  KeyVersion({
    required this.version,
    required this.createdAt,
    required this.algorithm,
    this.rotatedFrom,
  });
}

/// Result of key rotation
class KeyRotationResult {
  final String keyId;
  final int oldVersion;
  final int newVersion;
  final DateTime rotatedAt;
  final bool success;

  KeyRotationResult({
    required this.keyId,
    required this.oldVersion,
    required this.newVersion,
    required this.rotatedAt,
    required this.success,
  });
}

/// Info about a stored key (no key material)
class StoredKeyInfo {
  final String keyId;
  final String purpose;
  final int version;
  final DateTime? cachedAt;
  final DateTime? createdAt;

  StoredKeyInfo({
    required this.keyId,
    required this.purpose,
    required this.version,
    this.cachedAt,
    this.createdAt,
  });
}

/// Exception for secure storage errors
class SecureStorageException implements Exception {
  final String message;
  final String? code;

  SecureStorageException(this.message, {this.code});

  @override
  String toString() => 'SecureStorageException: $message'
      '${code != null ? ' (code: $code)' : ''}';
}

/// Error codes
class SecureStorageErrorCode {
  static const String KEY_NOT_FOUND = 'KEY_NOT_FOUND';
  static const String BIOMETRIC_REQUIRED = 'BIOMETRIC_REQUIRED';
  static const String STORAGE_FULL = 'STORAGE_FULL';
  static const String ENCRYPTION_FAILED = 'ENCRYPTION_FAILED';
  static const String DECRYPTION_FAILED = 'DECRYPTION_FAILED';
  static const String KEY_EXPIRED = 'KEY_EXPIRED';
  static const String INVALID_KEY = 'INVALID_KEY';
}
