import 'dart:convert';
import 'dart:math';
import 'security_config.dart';

/// Verifies integrity of downloaded models to prevent tampering
/// Uses SHA-256 hashing and signature verification concepts
class IntegrityVerifier {
  final SecurityConfig config;
  final List<SecurityEvent> _events = [];

  IntegrityVerifier(this.config);

  /// Get security events log
  List<SecurityEvent> get events => List.unmodifiable(_events);

  /// Clear event log
  void clearEvents() {
    _events.clear();
  }

  /// Verify model integrity using hash comparison
  /// 
  /// In production, this would:
  /// - Download model signature from trusted source
  /// - Verify SHA-256 hash of model file
  /// - Check digital signature if available
  /// - Validate against known-good values
  Future<IntegrityResult> verifyModelIntegrity({
    required String modelId,
    required List<int> modelData,
    required String expectedHash,
    String? signature,
    String? publicKey,
  }) async {
    if (!config.enabled || !config.requireModelVerification) {
      return IntegrityResult.success(
        modelId,
        score: 1.0,
        details: 'Verification skipped (security disabled)',
      );
    }

    // Compute hash of downloaded data
    final computedHash = _computeHash(modelData);
    
    // Compare hashes
    final hashMatch = _secureCompare(computedHash, expectedHash);
    
    if (!hashMatch) {
      _logEvent(SecurityEventType.modelVerificationFailed,
          modelId: modelId, details: 'Hash mismatch detected');
      
      return IntegrityResult.failure(
        modelId,
        reason: 'Hash verification failed',
        score: 0.0,
        details: 'Expected: $expectedHash, Got: $computedHash',
      );
    }

    // In production, verify signature with public key
    // For now, simulate signature verification
    bool signatureValid = true;
    if (signature != null && publicKey != null) {
      signatureValid = await _verifySignature(
        modelData,
        signature,
        publicKey,
      );
      
      if (!signatureValid) {
        _logEvent(SecurityEventType.modelVerificationFailed,
            modelId: modelId, details: 'Signature verification failed');
        
        return IntegrityResult.failure(
          modelId,
          reason: 'Signature verification failed',
          score: 0.0,
        );
      }
    }

    // Calculate integrity score
    final score = _calculateIntegrityScore(
      hashMatch: hashMatch,
      signatureValid: signatureValid,
      modelSize: modelData.length,
    );

    if (score < config.minModelIntegrityScore) {
      _logEvent(SecurityEventType.integrityCheckFailed,
          modelId: modelId, details: 'Score $score below threshold');
      
      return IntegrityResult.failure(
        modelId,
        reason: 'Integrity score too low',
        score: score,
      );
    }

    _logEvent(SecurityEventType.modelVerificationSuccess,
        modelId: modelId, details: 'Score: ${score.toStringAsFixed(2)}');

    return IntegrityResult.success(
      modelId,
      score: score,
      hash: computedHash,
      details: 'Integrity verified successfully',
    );
  }

  /// Compute SHA-256 hash of data
  /// 
  /// In production, use PointyCastle or similar crypto library
  String _computeHash(List<int> data) {
    // Simplified hash for demonstration
    // In production: use proper SHA-256 from crypto package
    final bytes = data.isEmpty ? utf8.encode('empty') : data;
    final hash = _simpleHash(bytes);
    return 'sha256:$hash';
  }

  String _simpleHash(List<int> data) {
    // Simple hash for demonstration - NOT cryptographically secure
    // Replace with proper SHA-256 in production
    var hash = 0x811c9dc5;
    for (final byte in data) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  /// Constant-time comparison to prevent timing attacks
  bool _secureCompare(String a, String b) {
    if (a.length != b.length) {
      // Still do full comparison to prevent timing attacks
      for (var i = 0; i < max(a.length, b.length); i++) {
        // noop
      }
      return false;
    }

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Verify digital signature (simplified for demo)
  Future<bool> _verifySignature(
    List<int> data,
    String signature,
    String publicKey,
  ) async {
    // In production, use proper signature verification
    // This is a placeholder
    await Future.delayed(const Duration(milliseconds: 10));
    return signature.isNotEmpty && publicKey.isNotEmpty;
  }

  /// Calculate integrity score based on various factors
  double _calculateIntegrityScore({
    required bool hashMatch,
    required bool signatureValid,
    required int modelSize,
  }) {
    double score = 0.5; // Base score

    if (hashMatch) score += 0.3;
    if (signatureValid) score += 0.2;

    // Penalize suspiciously small/large models
    if (modelSize < 1024) score -= 0.1; // Too small
    if (modelSize > 100 * 1024 * 1024) score -= 0.1; // Too large

    return score.clamp(0.0, 1.0).toDouble();
  }

  /// Log security event
  void _logEvent(
    SecurityEventType type, {
    String modelId = '',
    String actionId = '',
    String details = '',
  }) {
    if (!config.logSecurityEvents) return;

    final event = SecurityEvent(
      type: type,
      modelId: modelId,
      actionId: actionId,
      details: details,
    );
    _events.add(event);
  }

  /// Check if model source is allowed
  bool isSourceAllowed(String source) {
    return config.allowedModelSources.contains(source);
  }

  /// Check if action category is blocked
  bool isActionBlocked(String category) {
    return config.blockedActionCategories.contains(category);
  }
}

/// Result of integrity verification
class IntegrityResult {
  final String modelId;
  final bool success;
  final double score;
  final String? hash;
  final String? reason;
  final String? details;

  IntegrityResult._({
    required this.modelId,
    required this.success,
    this.score = 0.0,
    this.hash,
    this.reason,
    this.details,
  });

  factory IntegrityResult.success(
    String modelId, {
    required double score,
    String? hash,
    String? details,
  }) {
    return IntegrityResult._(
      modelId: modelId,
      success: true,
      score: score,
      hash: hash,
      details: details,
    );
  }

  factory IntegrityResult.failure(
    String modelId, {
    required String reason,
    double score = 0.0,
    String? details,
  }) {
    return IntegrityResult._(
      modelId: modelId,
      success: false,
      score: score,
      reason: reason,
      details: details,
    );
  }
}
