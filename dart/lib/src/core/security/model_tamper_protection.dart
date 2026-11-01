import 'dart:convert';
import '../security/security_config.dart';
import 'integrity_verifier.dart';
import 'data_protector.dart';

/// Protection against model tampering, replacement, and poisoning
/// 
/// Covers:
/// 1. Model file integrity (hash verification)
/// 2. Model signature verification (in production)
/// 3. Model update authorization (who can update)
/// 4. Rollback protection (prevent downgrade attacks)
/// 5. Model poisoning detection (suspicious patterns)
/// 6. Model substitution prevention (same ID, different content)
class ModelTamperProtection {
  final SecurityConfig config;
  final IntegrityVerifier integrityVerifier;
  final List<SecurityEvent> _events = [];
  
  // Track model versions to prevent rollback
  final Map<String, ModelVersionInfo> _knownVersions = {};
  
  // Track model hashes for substitution detection
  final Map<String, String> _knownHashes = {};

  ModelTamperProtection({
    required this.config,
    required this.integrityVerifier,
  });

  List<SecurityEvent> get events => List.unmodifiable(_events);
  void clearEvents() => _events.clear();

  /// Verify model hasn't been tampered with
  /// 
  /// Checks:
  /// - Hash matches expected
  /// - Version not downgraded
  /// - Not a known-substituted model
  Future<ModelTamperResult> verifyModelIntegrity({
    required String modelId,
    required ModelVariant variant,
    required List<int> modelData,
    String? expectedHash,
    String? signature,
    String? publicKey,
    String? expectedVersion,
  }) async {
    if (!config.enabled) {
      return ModelTamperResult.passed(
        modelId,
        reason: 'Security disabled, skipping verification',
      );
    }

    // Check 1: Hash verification
    final hashResult = await integrityVerifier.verifyModelIntegrity(
      modelId: modelId,
      modelData: modelData,
      expectedHash: expectedHash ?? variant.checksum ?? '',
    );

    if (!hashResult.success) {
      _logEvent(SecurityEventType.modelVerificationFailed,
          modelId: modelId,
          details: 'Hash verification failed: ${hashResult.reason}');
      
      return ModelTamperResult.failed(
        modelId,
        failureType: ModelTamperFailureType.hashMismatch,
        reason: 'Model hash does not match expected',
        details: hashResult.details,
      );
    }

    // Check 2: Version rollback protection
    if (expectedVersion != null) {
      final versionCheck = _checkVersionRollback(
        modelId,
        expectedVersion,
      );
      
      if (!versionCheck.allowed) {
        _logEvent(SecurityEventType.integrityCheckFailed,
            modelId: modelId,
            details: 'Version rollback detected: ${versionCheck.reason}');
        
        return ModelTamperResult.failed(
          modelId,
          failureType: ModelTamperFailureType.versionRollback,
          reason: versionCheck.reason,
        );
      }
    }

    // Check 3: Check for known substitution
    final expectedHash = variant.checksum ?? '';
    if (_knownHashes.containsKey(modelId)) {
      final knownHash = _knownHashes[modelId]!;
      if (knownHash != expectedHash) {
        // Hash changed - model might have been substituted
        // Check if it's a legitimate update
        final isLegitimateUpdate = await _isLegitimateUpdate(
          modelId,
          expectedHash,
          variant.version,
        );
        
        if (!isLegitimateUpdate) {
          _logEvent(SecurityEventType.tamperDetected,
              modelId: modelId,
              details: 'Potential model substitution detected');
          
          return ModelTamperResult.failed(
            modelId,
            failureType: ModelTamperFailureType.substitution,
            reason: 'Model hash changed unexpectedly',
            details: 'Known hash: $knownHash, New hash: $expectedHash',
          );
        }
      }
    }

    // All checks passed
    // Update tracking
    _knownVersions[modelId] = ModelVersionInfo(
      modelId: modelId,
      version: variant.version,
      hash: expectedHash,
      verifiedAt: DateTime.now(),
    );
    _knownHashes[modelId] = expectedHash;

    _logEvent(SecurityEventType.modelVerificationSuccess,
        modelId: modelId,
        details: 'All tamper checks passed');

    return ModelTamperResult.passed(
      modelId,
      score: hashResult.score,
      hash: expectedHash,
      version: variant.version,
    );
  }

  /// Check for version rollback attack
  /// 
  /// Prevents attackers from downgrading to older, vulnerable versions.
  VersionCheckResult _checkVersionRollback(
    String modelId,
    String newVersion,
  ) {
    final known = _knownVersions[modelId];
    
    if (known == null) {
      // First time seeing this model - allow
      return VersionCheckResult.allowed(
        modelId,
        reason: 'First version seen, no rollback possible',
      );
    }

    // Parse versions (simple major.minor.patch)
    final newParts = _parseVersion(newVersion);
    final oldParts = _parseVersion(known.version);
    
    // Check if new version is actually older
    if (_compareVersions(newParts, oldParts) < 0) {
      return VersionCheckResult.denied(
        modelId,
        reason: 'Version rollback detected: $newVersion < ${known.version}',
      );
    }

    return VersionCheckResult.allowed(
      modelId,
      reason: 'Version $newVersion >= ${known.version}, upgrade allowed',
    );
  }

  /// Check if model hash change is legitimate update
  /// 
  /// In production, this would verify:
  /// - Digital signature on the new model
  /// - That the update came from authorized source
  /// - That version incremented properly
  Future<bool> _isLegitimateUpdate(
    String modelId,
    String newHash,
    String newVersion,
  ) async {
    // In production: verify signature, check update authorization
    // For now: assume legitimate if version changed
    final known = _knownVersions[modelId];
    if (known == null) return true;
    
    final oldParts = _parseVersion(known.version);
    final newParts = _parseVersion(newVersion);
    
    return _compareVersions(newParts, oldParts) >= 0;
  }

  /// Parse version string to components
  List<int> _parseVersion(String version) {
    final parts = version.split('.');
    return parts.map((p) => int.tryParse(p) ?? 0).toList();
  }

  /// Compare two version tuples
  int _compareVersions(List<int> a, List<int> b) {
    final maxLen = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < maxLen; i++) {
      final av = i < a.length ? a[i] : 0;
      final bv = i < b.length ? b[i] : 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }

  /// Check if model is authorized for use
  /// 
  /// In production, would check:
  /// - Model signature against authorized keys
  /// - Model source is in allowed list
  /// - Model hasn't been revoked
  Future<bool> isModelAuthorized({
    required String modelId,
    required String source,
    String? signature,
    String? publicKey,
  }) async {
    // Check source
    if (!config.allowedModelSources.contains(source)) {
      _logEvent(SecurityEventType.permissionDenied,
          modelId: modelId,
          details: 'Source not allowed: $source');
      return false;
    }

    // Check signature (in production)
    if (signature != null && publicKey != null) {
      // Verify signature
      // For now: placeholder
    }

    return true;
  }

  /// Detect potential model poisoning
  /// 
  /// Model poisoning is when an attacker modifies the model to:
  /// - Produce specific incorrect outputs
  /// - Leak training data
  /// - Create backdoors
  /// 
  /// Detection heuristics:
  /// - Model size changed significantly
  /// - Model behavior changed unexpectedly
  /// - Output distribution shifted
  ModelPoisoningRisk detectPoisoningRisk({
    required String modelId,
    required ModelVariant expectedVariant,
    required int actualFileSize,
    List<double>? outputDistribution,
    List<double>? expectedDistribution,
  }) {
    if (!config.enableTamperDetection) {
      return ModelPoisoningRisk.low(
        modelId,
        reason: 'Tamper detection disabled',
      );
    }

    final risks = <String>[];

    // Check 1: File size anomaly
    if (expectedVariant.downloadSize > 0) {
      final sizeRatio = actualFileSize / expectedVariant.downloadSize;
      if (sizeRatio < 0.9 || sizeRatio > 1.1) {
        risks.add('File size anomaly: expected ${expectedVariant.downloadSize}, got $actualFileSize (${sizeRatio.toStringAsFixed(2)}x)');
      }
    }

    // Check 2: Output distribution shift (if we have baseline)
    if (outputDistribution != null && expectedDistribution != null) {
      final shift = _calculateDistributionShift(
        outputDistribution,
        expectedDistribution,
      );
      if (shift > 0.2) { // 20% shift threshold
        risks.add('Output distribution shifted: $shift');
      }
    }

    // Determine risk level
    SecurityLevel level;
    String reason;
    
    if (risks.isEmpty) {
      level = SecurityLevel.info;
      reason = 'No poisoning indicators detected';
    } else if (risks.length == 1) {
      level = SecurityLevel.warning;
      reason = risks.first;
    } else {
      level = SecurityLevel.error;
      reason = 'Multiple poisoning indicators: ${risks.join(', ')}';
    }

    return ModelPoisoningRisk(
      level: level,
      modelId: modelId,
      risks: risks,
      reason: reason,
    );
  }

  /// Calculate distribution shift (simplified)
  double _calculateDistributionShift(
    List<double> actual,
    List<double> expected,
  ) {
    if (actual.length != expected.length) return 1.0;
    
    double totalShift = 0;
    for (var i = 0; i < actual.length; i++) {
      totalShift += (actual[i] - expected[i]).abs();
    }
    
    return totalShift / actual.length;
  }

  /// Register a model as authorized for use
  void registerAuthorizedModel({
    required String modelId,
    required String version,
    required String hash,
    String? source,
  }) {
    _knownVersions[modelId] = ModelVersionInfo(
      modelId: modelId,
      version: version,
      hash: hash,
      source: source,
      registeredAt: DateTime.now(),
    );
    _knownHashes[modelId] = hash;
    
    _logEvent(SecurityEventType.actionAuthorized,
        modelId: modelId,
        details: 'Model authorized: $modelId v$version');
  }

  /// Revoke a model (prevent its use)
  void revokeModel(String modelId, {String? reason}) {
    _knownVersions.remove(modelId);
    _knownHashes.remove(modelId);
    
    _logEvent(SecurityEventType.tamperingAttemptBlocked,
        modelId: modelId,
        details: 'Model revoked: $reason ?? \"No reason provided\"');
  }

  /// Get model authorization status
  ModelAuthorizationStatus getModelStatus(String modelId) {
    final version = _knownVersions[modelId];
    
    if (version == null) {
      return ModelAuthorizationStatus.unknown(
        modelId,
        reason: 'Model not registered',
      );
    }
    
    return ModelAuthorizationStatus.authorized(
      modelId,
      version: version.version,
      hash: version.hash,
      registeredAt: version.registeredAt,
    );
  }

  /// Check if model supports secure updates
  bool supportsSecureUpdates(String modelId) {
    // In production: check if model has signature verification capability
    return config.allowedModelSources.isNotEmpty;
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

/// Result of tamper verification
class ModelTamperResult {
  final String modelId;
  final bool passed;
  final ModelTamperFailureType? failureType;
  final String reason;
  final String? details;
  final double? score;
  final String? hash;
  final String? version;

  const ModelTamperResult._({
    required this.modelId,
    required this.passed,
    this.failureType,
    required this.reason,
    this.details,
    this.score,
    this.hash,
    this.version,
  });

  factory ModelTamperResult.passed(
    String modelId, {
    required String reason,
    double? score,
    String? hash,
    String? version,
    String? details,
  }) {
    return ModelTamperResult._(
      modelId: modelId,
      passed: true,
      reason: reason,
      score: score,
      hash: hash,
      version: version,
      details: details,
    );
  }

  factory ModelTamperResult.failed(
    String modelId, {
    required ModelTamperFailureType failureType,
    required String reason,
    String? details,
  }) {
    return ModelTamperResult._(
      modelId: modelId,
      passed: false,
      failureType: failureType,
      reason: reason,
      details: details,
    );
  }
}

enum ModelTamperFailureType {
  hashMismatch,
  versionRollback,
  substitution,
  signatureInvalid,
  sourceUnauthorized,
  revoked,
  unknown,
}

/// Version check result
class VersionCheckResult {
  final String modelId;
  final bool allowed;
  final String reason;

  VersionCheckResult._({
    required this.modelId,
    required this.allowed,
    required this.reason,
  });

  factory VersionCheckResult.allowed(String modelId, {required String reason}) {
    return VersionCheckResult._(modelId: modelId, allowed: true, reason: reason);
  }

  factory VersionCheckResult.denied(String modelId, {required String reason}) {
    return VersionCheckResult._(modelId: modelId, allowed: false, reason: reason);
  }
}

/// Model poisoning risk assessment
class ModelPoisoningRisk {
  final SecurityLevel level;
  final String modelId;
  final List<String> risks;
  final String reason;

  ModelPoisoningRisk({
    required this.level,
    required this.modelId,
    required this.risks,
    required this.reason,
  });

  factory ModelPoisoningRisk.low(String modelId, {required String reason}) {
    return ModelPoisoningRisk(
      level: SecurityLevel.info,
      modelId: modelId,
      risks: [],
      reason: reason,
    );
  }

  bool get isSafe => level == SecurityLevel.info;
  bool get isSuspicious => level == SecurityLevel.warning;
  bool get isHighRisk => level == SecurityLevel.error || level == SecurityLevel.critical;
}

/// Model authorization status
class ModelAuthorizationStatus {
  final String modelId;
  final ModelAuthorizationState state;
  final String? version;
  final String? hash;
  final DateTime? registeredAt;
  final String? reason;

  ModelAuthorizationStatus._({
    required this.modelId,
    required this.state,
    this.version,
    this.hash,
    this.registeredAt,
    this.reason,
  });

  factory ModelAuthorizationStatus.authorized(
    String modelId, {
    required String version,
    required String hash,
    required DateTime registeredAt,
  }) {
    return ModelAuthorizationStatus._(
      modelId: modelId,
      state: ModelAuthorizationState.authorized,
      version: version,
      hash: hash,
      registeredAt: registeredAt,
    );
  }

  factory ModelAuthorizationStatus.unknown(
    String modelId, {
    required String reason,
  }) {
    return ModelAuthorizationStatus._(
      modelId: modelId,
      state: ModelAuthorizationState.unknown,
      reason: reason,
    );
  }

  factory ModelAuthorizationStatus.revoked(
    String modelId, {
    required String reason,
  }) {
    return ModelAuthorizationStatus._(
      modelId: modelId,
      state: ModelAuthorizationState.revoked,
      reason: reason,
    );
  }
}

enum ModelAuthorizationState {
  authorized,
  unknown,
  revoked,
}

/// Model version tracking info
class ModelVersionInfo {
  final String modelId;
  final String version;
  final String hash;
  final DateTime verifiedAt;
  final DateTime? registeredAt;
  final String? source;

  ModelVersionInfo({
    required this.modelId,
    required this.version,
    required this.hash,
    required this.verifiedAt,
    this.registeredAt,
    this.source,
  });
}
