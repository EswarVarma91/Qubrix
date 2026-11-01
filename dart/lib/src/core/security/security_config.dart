/// Security configuration for the Qubrix
/// 
/// This class defines security policies that protect the SDK from:
/// - Unauthorized model downloads
/// - Tampering with model files
/// - Unauthorized actions
/// - Data exfiltration
class SecurityConfig {
  SecurityConfig({
    this.enabled = true,
    this.requireModelVerification = true,
    this.requireActionAuthorization = true,
    this.enableTamperDetection = true,
    this.encryptionEnabled = true,
    this.logSecurityEvents = true,
    this.allowedModelSources = const ['official'],
    this.blockedActionCategories = const [],
    this.requireConfirmationForSensitiveActions = true,
    this.minModelIntegrityScore = 0.8,
  });

  /// Enable/disable all security features
  final bool enabled;

  /// Require cryptographic verification of downloaded models
  final bool requireModelVerification;

  /// Require authorization check for all actions
  final bool requireActionAuthorization;

  /// Enable tamper detection for model files and SDK components
  final bool enableTamperDetection;

  /// Enable encryption for stored sensitive data
  final bool encryptionEnabled;

  /// Log security events for audit trail
  final bool logSecurityEvents;

  /// Allowed sources for model downloads (e.g., 'official', 'verified')
  final List<String> allowedModelSources;

  /// Action categories that are blocked (e.g., 'payment', 'delete')
  final List<String> blockedActionCategories;

  /// Require user confirmation for sensitive operations
  final bool requireConfirmationForSensitiveActions;

  /// Minimum integrity score for model acceptance (0.0 - 1.0)
  final double minModelIntegrityScore;
}

/// Security event types for logging
enum SecurityEventType {
  modelDownloadAttempt,
  modelVerificationFailed,
  modelVerificationSuccess,
  unauthorizedActionAttempt,
  actionAuthorized,
  tamperDetected,
  tamperingAttemptBlocked,
  permissionDenied,
  permissionGranted,
  encryptionError,
  integrityCheckFailed,
}

/// Security event for audit logging
class SecurityEvent {
  final SecurityEventType type;
  final String modelId;
  final String actionId;
  final String details;
  final DateTime timestamp;

  SecurityEvent({
    required this.type,
    this.modelId = '',
    this.actionId = '',
    this.details = '',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return '[${timestamp.toIso8601String()}] ${type.name}: '
        'model=${modelId.isEmpty ? "-" : modelId} '
        'action=${actionId.isEmpty ? "-" : actionId} '
        '${details.isNotEmpty ? " - $details" : ""}';
  }
}
