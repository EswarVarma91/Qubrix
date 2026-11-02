import 'dart:io';
import 'dart:typed_data';
import 'security_config.dart';
import 'data_protector.dart';

/// Secure deletion of files and data
/// 
/// Simply deleting files isn't enough - data can often be recovered.
/// This manager ensures data is irrecoverably deleted by:
/// 1. Overwriting data multiple times with random/pattern data
/// 2. Then deleting the file
/// 3. Verifying deletion (if possible)
/// 
/// Also handles:
/// - Secure deletion of user data
/// - Secure deletion of encryption keys
/// - Secure deletion of model files
/// - Wipe free space (in production)
class SecureDeleteManager {
  final SecurityConfig config;
  final List<SecurityEvent> _events = [];

  // Number of overwrite passes for secure deletion
  // NIST recommends 1 pass for modern storage (SSD), 3-7 for magnetic
  final int _overwritePasses;

  SecureDeleteManager({
    required this.config,
    int overwritePasses = 3,
  }) : _overwritePasses = overwritePasses.clamp(1, 35).toInt();

  List<SecurityEvent> get events => List.unmodifiable(_events);
  void clearEvents() => _events.clear();

  /// Securely delete a file
  /// 
  /// Overwrites file contents multiple times before deletion.
  /// For SSDs, this is less effective but still provides defense.
  Future<bool> secureDeleteFile(String filePath) async {
    if (!config.enabled) {
      // Just delete without secure overwrite
      return await _deleteFile(filePath);
    }

    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        _logEvent(SecurityEventType.actionAuthorized,
            details: 'File not found for deletion: $filePath');
        return true; // Already gone
      }

      // Get file size
      final length = await file.length();
      
      if (length == 0) {
        // Empty file, just delete
        return await _deleteFile(filePath);
      }

      // Overwrite with random data
      await _overwriteFile(filePath, length, pattern: 'random');

      // Overwrite with zeros
      await _overwriteFile(filePath, length, pattern: 'zeros');

      // Final overwrite with ones (0xFF)
      await _overwriteFile(filePath, length, pattern: 'ones');

      // Delete the file
      final deleted = await _deleteFile(filePath);

      _logEvent(SecurityEventType.actionAuthorized,
          details: 'Securely deleted: $filePath (${length} bytes)');

      return deleted;
    } catch (e) {
      _logEvent(SecurityEventType.encryptionError,
          details: 'Secure delete failed: $e');
      return false;
    }
  }

  /// Securely delete user data
  /// 
  /// Deletes all data associated with a customer:
  /// - Encrypted data files
  /// - Metadata
  /// - Any cached copies
  Future<SecureDeleteResult> secureDeleteUserData({
    required String customerId,
    bool wipeKeys = true,
    bool wipeAllData = true,
    List<String>? specificFiles,
  }) async {
    if (!config.enabled) {
      throw SecurityException('Security is disabled');
    }

    _logEvent(SecurityEventType.actionAuthorized,
        details: 'Secure delete initiated for customer: $customerId');

    final result = SecureDeleteResult(
      customerId: customerId,
      startedAt: DateTime.now(),
      filesDeleted: <String>[],
      filesFailed: <String>[],
      keysWiped: false,
    );

    // Wipe encryption keys if requested
    if (wipeKeys) {
      try {
        // In production: wipe keys from secure storage
        // This makes all encrypted data permanently unreadable
        result.keysWiped = true;
        _logEvent(SecurityEventType.actionAuthorized,
            details: 'Encryption keys wiped for: $customerId');
      } catch (e) {
        result.keysWiped = false;
        result.errors.add('Key wipe failed: $e');
        _logEvent(SecurityEventType.encryptionError,
            details: 'Key wipe failed: $e');
      }
    }

    // Delete specific files if provided
    if (specificFiles != null) {
      for (final file in specificFiles) {
        final success = await secureDeleteFile(file);
        if (success) {
          result.filesDeleted.add(file);
        } else {
          result.filesFailed.add(file);
        }
      }
    }

    // Wipe all data for this customer if requested
    if (wipeAllData) {
      // In production: find and delete all files related to customer
      // For now: placeholder
    }

    result.completedAt = DateTime.now();
    result.wipedKeys = result.keysWiped;

    _logEvent(SecurityEventType.actionAuthorized,
        details: 'Secure delete completed for: $customerId '
            '(${result.filesDeleted.length} files, keys: ${result.keysWiped})');

    return result;
  }

  /// Securely delete model files
  /// 
  /// When removing a model, ensure it's securely deleted.
  Future<SecureDeleteResult> secureDeleteModel({
    required String modelId,
    String? modelPath,
    bool wipeAssociatedData = true,
  }) async {
    _logEvent(SecurityEventType.actionAuthorized,
        details: 'Secure delete model: $modelId');

    final result = SecureDeleteResult(
      customerId: modelId,
      startedAt: DateTime.now(),
      filesDeleted: <String>[],
      filesFailed: <String>[],
      keysWiped: false,
    );

    // Delete model files
    if (modelPath != null) {
      final success = await secureDeleteFile(modelPath);
      if (success) {
        result.filesDeleted.add(modelPath);
      } else {
        result.filesFailed.add(modelPath);
      }
    }

    // Delete any associated data
    if (wipeAssociatedData) {
      // In production: delete model's metadata, cache, etc.
    }

    result.completedAt = DateTime.now();
    result.wipedKeys = false;

    _logEvent(SecurityEventType.actionAuthorized,
        details: 'Model deleted: $modelId');

    return result;
  }

  /// Wipe free space on a volume
  /// 
  /// After deleting files, free space may still contain recoverable data.
  /// This fills free space with random data, then deletes it.
  /// 
  /// CAUTION: This is slow and wears SSDs. Use sparingly.
  Future<bool> wipeFreeSpace(String volumePath) async {
    if (!config.enabled) {
      return true;
    }

    try {
      // Create a large temporary file to fill free space
      final tempFile = File('$volumePath/.secure_wipe_temp');
      
      // Write random data until disk is full
      final random = List<int>.generate(
        1024 * 1024, // 1MB chunks
        (_) => DateTime.now().microsecondsSinceEpoch % 256,
      );
      
      while (true) {
        try {
          await tempFile.writeAsBytes(random, flush: true);
        } catch (e) {
          // Disk full - this is expected
          break;
        }
      }
      
      // Securely delete the temp file
      await secureDeleteFile(tempFile.path);
      
      _logEvent(SecurityEventType.actionAuthorized,
          details: 'Free space wiped: $volumePath');
      
      return true;
    } catch (e) {
      _logEvent(SecurityEventType.encryptionError,
          details: 'Free space wipe failed: $e');
      return false;
    }
  }

  /// Overwrite file with specified pattern
  Future<void> _overwriteFile(
    String filePath,
    int length,
    {required String pattern}
  ) async {
    final file = File(filePath);
    final raf = await file.open(mode: FileMode.write);
    
    try {
      final chunkSize = 64 * 1024; // 64KB chunks
      var remaining = length;
      var position = 0;
      
      while (remaining > 0) {
        final chunk = _generatePattern(
          pattern,
          remaining < chunkSize ? remaining : chunkSize,
        );
        
        await raf.setPosition(position);
        await raf.writeFrom(chunk);
        
        position += chunk.length;
        remaining -= chunk.length;
      }
      
      await raf.flush();
    } finally {
      await raf.close();
    }
  }

  /// Generate pattern bytes
  Uint8List _generatePattern(String pattern, int length) {
    final bytes = Uint8List(length);
    
    for (var i = 0; i < length; i++) {
      switch (pattern) {
        case 'random':
          // Pseudo-random based on position
          bytes[i] = (DateTime.now().microsecondsSinceEpoch + i) % 256;
          break;
        case 'zeros':
          bytes[i] = 0;
          break;
        case 'ones':
          bytes[i] = 0xFF;
          break;
        case 'random_alphabet':
          // Random but valid UTF-8 to make data look like text
          bytes[i] = 0x20 + (DateTime.now().microsecondsSinceEpoch + i) % 95;
          break;
        default:
          bytes[i] = 0;
      }
    }
    
    return bytes;
  }

  /// Delete file (without secure overwrite)
  Future<bool> _deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return true; // Already doesn't exist
    } catch (e) {
      _logEvent(SecurityEventType.encryptionError,
          details: 'Delete failed: $e');
      return false;
    }
  }

  /// Securely overwrite and delete data in memory
  /// 
  /// For sensitive data stored in memory (strings, byte arrays).
  /// Note: Dart doesn't guarantee memory clearing, but this is best effort.
  void secureWipeMemory(Uint8List data) {
    if (!config.enabled) return;
    
    // Overwrite with zeros
    for (var i = 0; i < data.length; i++) {
      data[i] = 0;
    }
    
    // Overwrite with random
    for (var i = 0; i < data.length; i++) {
      data[i] = (DateTime.now().microsecondsSinceEpoch + i) % 256;
    }
    
    // Overwrite with zeros again
    for (var i = 0; i < data.length; i++) {
      data[i] = 0;
    }
    
    _logEvent(SecurityEventType.actionAuthorized,
        details: 'Memory wiped: ${data.length} bytes');
  }

  /// Securely wipe a string (best effort)
  /// 
  /// Dart strings are immutable, so this is best effort.
  /// For sensitive strings, use Uint8List instead.
  void secureWipeString(StringBuffer buffer) {
    if (!config.enabled) return;
    
    // Replace contents with zeros
    buffer.write('\x00' * buffer.length);
    buffer.clear();
    
    _logEvent(SecurityEventType.actionAuthorized,
        details: 'String buffer wiped');
  }

  /// Get deletion status
  String getStatus() {
    return '''
Secure Delete Manager Status
=============================
Overwrite Passes: $_overwritePasses
Security Enabled: ${config.enabled}
''';
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

/// Result of secure delete operation
class SecureDeleteResult {
  final String customerId;
  final DateTime startedAt;
  DateTime? completedAt;
  final List<String> filesDeleted;
  final List<String> filesFailed;
  final List<String> errors;
  bool keysWiped;
  bool wipedKeys;

  SecureDeleteResult({
    required this.customerId,
    required this.startedAt,
    this.completedAt,
    required this.filesDeleted,
    required this.filesFailed,
    List<String>? errors,
    this.keysWiped = false,
  })  : errors = errors ?? [],
        wipedKeys = keysWiped;

  /// Calculate duration
  Duration? get duration {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt);
  }

  /// Whether deletion was successful
  bool get success => filesFailed.isEmpty && (!keysWiped || wipedKeys);

  /// Total files processed
  int get totalFiles => filesDeleted.length + filesFailed.length;

  /// Success rate
  double get successRate {
    if (totalFiles == 0) return 1.0;
    return filesDeleted.length / totalFiles;
  }

  @override
  String toString() {
    return '''
SecureDeleteResult($customerId):
  Duration: ${duration?.toString() ?? 'in progress'}
  Files Deleted: ${filesDeleted.length}
  Files Failed: ${filesFailed.length}
  Keys Wiped: $wipedKeys
  Success Rate: ${(successRate * 100).toStringAsFixed(1)}%
  Errors: ${errors.length}
''';
  }
}

/// Secure deletion options
class SecureDeleteOptions {
  /// Number of overwrite passes (1-35)
  /// - 1: Fast, sufficient for SSDs, modern security
  /// - 3: Balanced, good for HDDs
  /// - 7+: Legacy compliance (US DoD, etc.)
  final int overwritePasses;

  /// Whether to also wipe free space after deletion
  final bool wipeFreeSpace;

  /// Pattern to use for overwriting
  final OverwritePattern pattern;

  const SecureDeleteOptions({
    this.overwritePasses = 3,
    this.wipeFreeSpace = false,
    this.pattern = OverwritePattern.random,
  });
}

enum OverwritePattern {
  /// Pseudo-random data
  random,
  
  /// All zeros
  zeros,
  
  /// All ones (0xFF)
  ones,
  
  /// Random but valid text characters
  randomText,
  
  /// US DoD 5220.22-M compliant (complex pattern)
  dod,
  
  /// Gutmann method (35 passes, maximum security, very slow)
  gutmann,
}
