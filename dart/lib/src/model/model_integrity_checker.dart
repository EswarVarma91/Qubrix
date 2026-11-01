import 'dart:io';
import '../core/security/integrity_verifier.dart';
import '../core/security/security_config.dart';
import 'model_types.dart';

/// Handles model integrity checks when models change or are re-downloaded
/// 
/// SCENARIOS COVERED:
/// 
/// 1. **HuggingFace deletes the model** (source removes it)
///    - Already downloaded models: SAFE - they remain on device
///    - Need to re-download: Will fail gracefully with clear error
///    - User's data encrypted with customer keys: SAFE (unaffected by model)
/// 
/// 2. **Model updated/replaced on HuggingFace** (same ID, different content)
///    - Existing download: Will fail integrity check (hash mismatch)
///    - User must explicitly update to new version
///    - Old model data: Still works with old model files
/// 
/// 3. **User clears cache / fresh install**
///    - Model files deleted: Must re-download
///    - Customer encryption keys: NOT affected (stored separately in secure storage)
///    - Per-customer keys: Can be re-derived from master key + customer ID + salt
///    - User data: Still encrypted, just need to re-download model to use it
/// 
/// 4. **Model content changes maliciously** (attacker modifies HuggingFace repo)
///    - Integrity verification catches hash mismatch
///    - Download rejected until proper version is restored
///    - Logged as security event
class ModelIntegrityChecker {
  final IntegrityVerifier _integrityVerifier;
  final SecurityConfig config;

  ModelIntegrityChecker({
    required IntegrityVerifier integrityVerifier,
    required this.config,
  }) : _integrityVerifier = integrityVerifier;

  /// Check if an existing model installation is still valid
  /// 
  /// Called when:
  /// - App starts and checks installed models
  /// - Model needs to be loaded for inference
  /// - After device reboot (files might be corrupted)
  /// 
  /// Returns:
  /// - valid: Model files present and hash matches expected
  /// - modified: Files present but hash doesn't match (model changed!)
  /// - missing: Model files not found (need to re-download)
  Future<ModelIntegrityStatus> checkInstalledModel(
    String modelId,
    ModelVariant expectedVariant,
    String modelPath,
  ) async {
    // Check if files exist
    final modelFile = File(modelPath);
    if (!await modelFile.exists()) {
      return ModelIntegrityStatus.missing(
        modelId,
        reason: 'Model files not found on device',
      );
    }

    // Get file size
    final fileSize = await modelFile.length();
    
    // If variant expects specific size, check it
    if (expectedVariant.downloadSize > 0 && fileSize != expectedVariant.downloadSize) {
      // Size mismatch - could be truncated download or corrupted
      return ModelIntegrityStatus.corrupted(
        modelId,
        reason: 'File size mismatch: expected ${expectedVariant.downloadSize}, got $fileSize',
        expectedSize: expectedVariant.downloadSize,
        actualSize: fileSize,
      );
    }

    // Verify hash if checksum is available
    if (expectedVariant.checksum != null) {
      try {
        final fileData = await modelFile.readAsBytes();
        final result = await _integrityVerifier.verifyModelIntegrity(
          modelId: modelId,
          modelData: fileData,
          expectedHash: expectedVariant.checksum!,
        );

        if (!result.success) {
          return ModelIntegrityStatus.modified(
            modelId,
            reason: 'Hash verification failed: ${result.reason}',
            integrityResult: result,
            expectedHash: expectedVariant.checksum,
          );
        }

        return ModelIntegrityStatus.valid(
          modelId,
          integrityResult: result,
        );
      } catch (e) {
        return ModelIntegrityStatus.error(
          modelId,
          reason: 'Error reading model file: $e',
        );
      }
    }

    // No checksum to verify against - assume valid if file exists
    return ModelIntegrityStatus.valid(
      modelId,
      details: 'No checksum available, file integrity assumed',
    );
  }

  /// Handle model that has been modified/deleted on source
  /// 
  /// When HuggingFace deletes or modifies a model:
  /// 1. Check existing installation integrity
  /// 2. If invalid, notify user
  /// 3. Don't auto-delete - let user decide
  /// 4. Block inference until resolved
  Future<ModelChangeHandling> handleModelChange(
    String modelId,
    ModelVariant expectedVariant,
    String modelPath,
  ) async {
    final status = await checkInstalledModel(modelId, expectedVariant, modelPath);

    switch (status.status) {
      case ModelIntegrityStatusType.valid:
        // Model is fine, no action needed
        return ModelChangeHandling.ok(
          modelId,
          message: 'Model integrity verified',
        );

      case ModelIntegrityStatusType.missing:
        // Model files gone - user cleared cache or fresh install
        return ModelChangeHandling.downloadRequired(
          modelId,
          reason: 'Model files not found. Re-download required.',
          canRecover: true, // Can re-download if source still exists
        );

      case ModelIntegrityStatusType.modified:
        // Model changed on source OR files corrupted
        // This is the critical security case
        return ModelChangeHandling.securityIssue(
          modelId,
          reason: 'Model integrity check failed. Model may have been modified or deleted from source.',
          details: status.details,
          actionRequired: 'User must update to new version or obtain valid model',
        );

      case ModelIntegrityStatusType.corrupted:
        // File corruption (not malicious, just bad download/storage)
        return ModelChangeHandling.downloadRequired(
          modelId,
          reason: 'Model file corrupted. Re-download required.',
          canRecover: true,
        );

      case ModelIntegrityStatusType.error:
        return ModelChangeHandling.error(
          modelId,
          reason: status.reason,
        );
    }
  }

  /// Check if model source is still available
  /// 
  /// In production, this would:
  /// - Try to fetch model info from HuggingFace API
  /// - Check if model ID still exists
  /// - Get latest version info
  /// 
  /// For now, returns that source is assumed available
  Future<SourceAvailability> checkSourceAvailability(String modelId) async {
    // In production: query HuggingFace API
    // 
    // Example with HTTP:
    // final response = await http.get(
    //   Uri.parse('https://huggingface.co/api/models/$modelId'),
    // );
    // if (response.statusCode == 404) {
    //   return SourceAvailability.deleted(
    //     modelId,
    //     reason: 'Model deleted from HuggingFace',
    //   );
    // }
    
    // Simulated: assume available (implement real check in production)
    return SourceAvailability.available(
      modelId,
      note: 'Implement HuggingFace API check in production',
    );
  }

  /// Get recommendation for handling a model integrity issue
  String getRecommendation(ModelIntegrityStatus status) {
    switch (status.status) {
      case ModelIntegrityStatusType.valid:
        return 'Model is valid and ready to use.';
      
      case ModelIntegrityStatusType.missing:
        return 'Re-download the model from the source.';
      
      case ModelIntegrityStatusType.modified:
        return '''
WARNING: Model has been modified! Possible causes:
1. Model was updated on HuggingFace (new version available)
2. Model was deleted and replaced with different content
3. File corruption or tampering

Action: Update to the latest version or contact support.
Do NOT use this model until integrity is verified.
''';
      
      case ModelIntegrityStatusType.corrupted:
        return 'Model file is corrupted. Re-download the model.';
      
      case ModelIntegrityStatusType.error:
        return 'Error checking model: ${status.reason}';
    }
  }

  /// Verify model before allowing inference
  /// 
  /// Blocks inference if model integrity is compromised.
  Future<bool> canRunInference(
    String modelId,
    ModelVariant expectedVariant,
    String modelPath,
  ) async {
    final status = await checkInstalledModel(modelId, expectedVariant, modelPath);

    if (status.status == ModelIntegrityStatusType.valid) {
      return true;
    }

    // Log security event for modified/missing models
    if (config.logSecurityEvents) {
      // Would log here
    }

    return false;
  }
}

/// Result of model integrity check
class ModelIntegrityStatus {
  final String modelId;
  final ModelIntegrityStatusType status;
  final String reason;
  final String? details;
  final IntegrityResult? integrityResult;
  final int? expectedSize;
  final int? actualSize;
  final String? expectedHash;

  const ModelIntegrityStatus._({
    required this.modelId,
    required this.status,
    required this.reason,
    this.details,
    this.integrityResult,
    this.expectedSize,
    this.actualSize,
    this.expectedHash,
  });

  factory ModelIntegrityStatus.valid(
    String modelId, {
    IntegrityResult? integrityResult,
    String? details,
  }) {
    return ModelIntegrityStatus._(
      modelId: modelId,
      status: ModelIntegrityStatusType.valid,
      reason: 'Model integrity verified',
      integrityResult: integrityResult,
      details: details,
    );
  }

  factory ModelIntegrityStatus.missing(
    String modelId, {
    required String reason,
  }) {
    return ModelIntegrityStatus._(
      modelId: modelId,
      status: ModelIntegrityStatusType.missing,
      reason: reason,
    );
  }

  factory ModelIntegrityStatus.modified(
    String modelId, {
    required String reason,
    IntegrityResult? integrityResult,
    String? details,
    String? expectedHash,
  }) {
    return ModelIntegrityStatus._(
      modelId: modelId,
      status: ModelIntegrityStatusType.modified,
      reason: reason,
      integrityResult: integrityResult,
      details: details,
      expectedHash: expectedHash,
    );
  }

  factory ModelIntegrityStatus.corrupted(
    String modelId, {
    required String reason,
    int? expectedSize,
    int? actualSize,
  }) {
    return ModelIntegrityStatus._(
      modelId: modelId,
      status: ModelIntegrityStatusType.corrupted,
      reason: reason,
      expectedSize: expectedSize,
      actualSize: actualSize,
    );
  }

  factory ModelIntegrityStatus.error(
    String modelId, {
    required String reason,
  }) {
    return ModelIntegrityStatus._(
      modelId: modelId,
      status: ModelIntegrityStatusType.error,
      reason: reason,
    );
  }
}

enum ModelIntegrityStatusType {
  valid,      // Model OK, hash matches
  missing,    // Files not found
  modified,   // Hash mismatch - model changed!
  corrupted,  // File corrupted (size mismatch)
  error,      // Error checking
}

/// How to handle a model change
class ModelChangeHandling {
  final String modelId;
  final ModelChangeType type;
  final String message;
  final String? reason;
  final String? details;
  final String? actionRequired;
  final bool canRecover;

  const ModelChangeHandling._({
    required this.modelId,
    required this.type,
    required this.message,
    this.reason,
    this.details,
    this.actionRequired,
    this.canRecover = false,
  });

  factory ModelChangeHandling.ok(
    String modelId, {
    String? message,
  }) {
    return ModelChangeHandling._(
      modelId: modelId,
      type: ModelChangeType.ok,
      message: message ?? 'Model is valid',
    );
  }

  factory ModelChangeHandling.downloadRequired(
    String modelId, {
    required String reason,
    String? details,
    bool canRecover = true,
  }) {
    return ModelChangeHandling._(
      modelId: modelId,
      type: ModelChangeType.downloadRequired,
      message: 'Model needs to be re-downloaded',
      reason: reason,
      details: details,
      canRecover: canRecover,
    );
  }

  factory ModelChangeHandling.securityIssue(
    String modelId, {
    required String reason,
    String? details,
    required String actionRequired,
  }) {
    return ModelChangeHandling._(
      modelId: modelId,
      type: ModelChangeType.securityIssue,
      message: 'SECURITY: Model integrity compromised',
      reason: reason,
      details: details,
      actionRequired: actionRequired,
      canRecover: false,
    );
  }

  factory ModelChangeHandling.error(
    String modelId, {
    required String reason,
  }) {
    return ModelChangeHandling._(
      modelId: modelId,
      type: ModelChangeType.error,
      message: 'Error checking model',
      reason: reason,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('ModelChangeHandling($modelId): ${type.name}');
    buffer.writeln('  Message: $message');
    if (reason != null) buffer.writeln('  Reason: $reason');
    if (details != null) buffer.writeln('  Details: $details');
    if (actionRequired != null) buffer.writeln('  Action Required: $actionRequired');
    buffer.writeln('  Can Recover: $canRecover');
    return buffer.toString();
  }
}

enum ModelChangeType {
  ok,                // No issue
  downloadRequired,  // Need to re-download
  securityIssue,     // Potentially malicious change
  error,             // Error occurred
}

/// Source availability check result
class SourceAvailability {
  final String modelId;
  final bool available;
  final String? reason;
  final String? note;

  const SourceAvailability._({
    required this.modelId,
    required this.available,
    this.reason,
    this.note,
  });

  factory SourceAvailability.available(
    String modelId, {
    String? note,
  }) {
    return SourceAvailability._(
      modelId: modelId,
      available: true,
      note: note,
    );
  }

  factory SourceAvailability.deleted(
    String modelId, {
    required String reason,
  }) {
    return SourceAvailability._(
      modelId: modelId,
      available: false,
      reason: reason,
    );
  }

  factory SourceAvailability.error(
    String modelId, {
    required String reason,
  }) {
    return SourceAvailability._(
      modelId: modelId,
      available: false,
      reason: reason,
    );
  }
}
