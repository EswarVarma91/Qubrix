import 'security_config.dart';

/// Detects tampering with SDK components, model files, or app data
/// 
/// Protects against:
/// - Modified model files
/// - Tampered SDK code
/// - Unauthorized data access
/// - Debugging/reverse engineering attempts
class TamperDetector {
  final SecurityConfig config;
  final List<SecurityEvent> _events = [];
  
  // Known-good checksums (would be computed at build time in production)
  final Map<String, String> _knownGoodHashes = {};
  
  // Integrity state
  bool _sdkIntegrityVerified = false;
  DateTime? _lastIntegrityCheck;

  TamperDetector(this.config);

  List<SecurityEvent> get events => List.unmodifiable(_events);
  bool get isSdkIntegrityVerified => _sdkIntegrityVerified;
  DateTime? get lastIntegrityCheck => _lastIntegrityCheck;

  /// Verify SDK component integrity at startup
  Future<IntegrityStatus> verifySdkIntegrity() async {
    if (!config.enabled || !config.enableTamperDetection) {
      return IntegrityStatus.ok('Integrity check skipped');
    }

    // In production, this would:
    // - Verify compiled code checksums
    // - Check for debug mode
    // - Verify app signature
    // - Check root/jailbreak status
    // - Detect hooking frameworks (Frida, Xposed, etc.)
    
    await Future.delayed(const Duration(milliseconds: 50));

    // Simulated checks
    final checks = await _runIntegrityChecks();

    var allPassed = true;
    var failedChecks = <String>[];

    for (final check in checks) {
      if (!check.passed) {
        allPassed = false;
        failedChecks.add(check.name);
        _logEvent(SecurityEventType.tamperDetected,
            details: 'Check failed: ${check.name} - ${check.details}');
      }
    }

    _sdkIntegrityVerified = allPassed;
    _lastIntegrityCheck = DateTime.now();

    if (!allPassed) {
      _logEvent(SecurityEventType.tamperingAttemptBlocked,
          details: 'Failed checks: ${failedChecks.join(", ")}');
    }

    return allPassed
        ? IntegrityStatus.ok('SDK integrity verified')
        : IntegrityStatus.compromised(failedChecks);
  }

  /// Run individual integrity checks
  Future<List<IntegrityCheck>> _runIntegrityChecks() async {
    return [
      // Check for debug mode
      IntegrityCheck(
        name: 'debug_mode',
        passed: !_isDebugMode(),
        details: 'Debug mode detected',
      ),
      
      // Check for emulator
      IntegrityCheck(
        name: 'emulator_detected',
        passed: !_isEmulator(),
        details: 'Emulator detected',
      ),
      
      // Check app signature (production would verify against known signature)
      IntegrityCheck(
        name: 'app_signature',
        passed: true, // Would be verified in production
        details: 'App signature verified',
      ),
      
      // Check for hooking frameworks
      IntegrityCheck(
        name: 'hooking_frameworks',
        passed: true, // Would be detected in production
        details: 'No hooking frameworks detected',
      ),
      
      // Check for runtime manipulation
      IntegrityCheck(
        name: 'runtime_integrity',
        passed: true, // Would verify in production
        details: 'Runtime integrity OK',
      ),
    ];
  }

  bool _isDebugMode() {
    // In Flutter, check debug mode
    // bool.fromEnvironment('DEBUG') would be used in Dart
    return false; // Simulated
  }

  bool _isEmulator() {
    // Check for emulator indicators
    // In production, check for emulator-specific files/properties
    return false; // Simulated
  }

  /// Register known-good hash for a file/model
  void registerKnownHash(String identifier, String hash) {
    _knownGoodHashes[identifier] = hash;
  }

  /// Check if file/model has been tampered with
  bool isTampered(String identifier, List<int> data) {
    final knownHash = _knownGoodHashes[identifier];
    if (knownHash == null) {
      // No known hash to compare against
      return false;
    }

    final computedHash = _computeHash(data);
    return !_secureCompare(computedHash, knownHash);
  }

  /// Detect suspicious access patterns
  bool detectSuspiciousAccess({
    required String resource,
    required int accessCount,
    required Duration timeWindow,
  }) {
    // Detect rapid repeated access (potential data scraping)
    if (accessCount > 100 && timeWindow.inSeconds < 60) {
      _logEvent(SecurityEventType.tamperDetected,
          details: 'Suspicious access pattern: $accessCount accesses in ${timeWindow.inSeconds}s');
      return true;
    }

    // Detect access at unusual hours
    final hour = DateTime.now().hour;
    if (hour < 5 || hour > 23) {
      if (accessCount > 10) {
        _logEvent(SecurityEventType.tamperDetected,
            details: 'Unusual access time: ${DateTime.now()}');
        return true;
      }
    }

    return false;
  }

  String _computeHash(List<int> data) {
    // Simplified hash for demo
    var hash = 0xcbf29ce484222325;
    for (final byte in data) {
      hash ^= byte;
      hash = (hash * 0x100000001b3) & 0xffffffffffffffff;
    }
    return hash.toRadixString(16);
  }

  bool _secureCompare(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
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

  /// Get integrity report
  String getIntegrityReport() {
    return '''
Tamper Detection Report
=======================
SDK Integrity Verified: $_sdkIntegrityVerified
Last Check: ${_lastIntegrityCheck?.toIso8601String() ?? 'Never'}
Known Good Hashes: ${_knownGoodHashes.length}
Security Events: ${_events.length}
''';
  }
}

/// Status of integrity verification
class IntegrityStatus {
  final bool ok;
  final String message;
  final List<String> failedChecks;

  IntegrityStatus._({
    required this.ok,
    required this.message,
    this.failedChecks = const [],
  });

  factory IntegrityStatus.ok(String message) {
    return IntegrityStatus._(ok: true, message: message);
  }

  factory IntegrityStatus.compromised(List<String> failedChecks) {
    return IntegrityStatus._(
      ok: false,
      message: 'Integrity compromised',
      failedChecks: failedChecks,
    );
  }
}

/// Individual integrity check result
class IntegrityCheck {
  final String name;
  final bool passed;
  final String details;

  IntegrityCheck({
    required this.name,
    required this.passed,
    required this.details,
  });
}
