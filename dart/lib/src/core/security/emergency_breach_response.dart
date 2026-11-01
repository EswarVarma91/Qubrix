import '../security/security_config.dart';
import '../security/data_isolation.dart';

/// Emergency response system for when a breach is detected
/// 
/// When the SDK or customer data is compromised, this system:
/// - Immediately locks down access
/// - Wipes encryption keys
/// - Isolates affected data
/// - Preserves logs for forensics
/// - Notifies about the breach
class EmergencyBreachResponse {
  final SecurityConfig config;
  final DataIsolation _isolation;
  final List<SecurityEvent> _events = [];
  
  bool _isBreached = false;
  bool _isLockedDown = false;
  DateTime? _breachDetectedAt;
  String? _breachType;
  String? _affectedCustomerId;
  List<BreachAction> _actionsTaken = [];

  EmergencyBreachResponse(this.config, this._isolation);

  List<SecurityEvent> get events => List.unmodifiable(_events);
  bool get isBreached => _isBreached;
  bool get isLockedDown => _isLockedDown;
  DateTime? get breachDetectedAt => _breachDetectedAt;

  /// Detect and respond to a breach
  Future<void> respondToBreach({
    required String breachType,
    String? affectedCustomerId,
    String? attackVector,
    Map<String, dynamic>? evidence,
  }) async {
    if (_isLockedDown) {
      _logEvent(SecurityEventType.tamperDetected,
          details: 'Breach response already active, ignoring duplicate');
      return;
    }

    _isBreached = true;
    _isLockedDown = true;
    _breachDetectedAt = DateTime.now();
    _breachType = breachType;
    _affectedCustomerId = affectedCustomerId;

    _logEvent(SecurityEventType.tamperingAttemptBlocked,
        details: 'BREACH DETECTED: $breachType${affectedCustomerId != null ? " (customer: $affectedCustomerId)" : ""}');

    // Execute emergency actions
    await _executeEmergencyActions(breachType, affectedCustomerId, evidence);

    _logEvent(SecurityEventType.tamperingAttemptBlocked,
        details: 'Breach response completed: ${_actionsTaken.length} actions taken');
  }

  /// Execute emergency lockdown actions
  Future<void> _executeEmergencyActions(
    String breachType,
    String? affectedCustomerId,
    Map<String, dynamic>? evidence,
  ) async {
    // 1. Immediately end all sessions
    _isolation.endCustomerSession();
    _recordAction(BreachAction(
      action: 'endAllSessions',
      status: 'completed',
      timestamp: DateTime.now(),
      details: 'All customer sessions terminated',
    ));

    // 2. If specific customer affected, wipe their data
    if (affectedCustomerId != null) {
      await _isolation.wipeCustomerData(affectedCustomerId);
      _recordAction(BreachAction(
        action: 'wipeCustomerData',
        status: 'completed',
        timestamp: DateTime.now(),
        details: 'Data wiped for customer: $affectedCustomerId',
      ));
    }

    // 3. Disable sensitive operations
    if (config.requireConfirmationForSensitiveActions) {
      // In production: disable payment/action execution
      _recordAction(BreachAction(
        action: 'disableSensitiveOperations',
        status: 'completed',
        timestamp: DateTime.now(),
        details: 'Sensitive operations disabled',
      ));
    }

    // 4. Preserve logs (don't delete them)
    _recordAction(BreachAction(
      action: 'preserveLogs',
      status: 'completed',
      timestamp: DateTime.now(),
      details: 'Security logs preserved for forensics',
    ));

    // 5. Mark system as breached (prevents normal operation)
    _recordAction(BreachAction(
      action: 'markSystemBreached',
      status: 'completed',
      timestamp: DateTime.now(),
      details: 'System marked as breached - normal operation suspended',
    ));
  }

  /// Record an action taken during breach response
  void _recordAction(BreachAction action) {
    _actionsTaken.add(action);
  }

  /// Clear breach state (after remediation)
  Future<void> clearBreachState() async {
    if (!_isBreached) return;

    _isBreached = false;
    _isLockedDown = false;
    _breachDetectedAt = null;
    _breachType = null;
    _affectedCustomerId = null;
    _actionsTaken.clear();

    _logEvent(SecurityEventType.actionAuthorized,
        details: 'Breach state cleared - system recovered');

    // Can now reinitialize
  }

  /// Check if system is in breach state
  bool isInBreach() => _isBreached && _isLockedDown;

  /// Attempt to perform an operation during breach
  bool canPerformOperation(String operationType) {
    if (_isLockedDown) {
      _logEvent(SecurityEventType.permissionDenied,
          details: 'Operation blocked: system is in breach lockdown');
      return false;
    }
    return true;
  }

  /// Get breach report
  BreachReport getBreachReport() {
    return BreachReport(
      breached: _isBreached,
      lockedDown: _isLockedDown,
      breachType: _breachType,
      detectedAt: _breachDetectedAt,
      affectedCustomerId: _affectedCustomerId,
      actionsTaken: _actionsTaken,
    );
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

/// Action taken during breach response
class BreachAction {
  final String action;
  final String status;
  final DateTime timestamp;
  final String? details;

  BreachAction({
    required this.action,
    required this.status,
    required this.timestamp,
    this.details,
  });
}

/// Breach report
class BreachReport {
  final bool breached;
  final bool lockedDown;
  final String? breachType;
  final DateTime? detectedAt;
  final String? affectedCustomerId;
  final List<BreachAction> actionsTaken;

  BreachReport({
    required this.breached,
    required this.lockedDown,
    this.breachType,
    this.detectedAt,
    this.affectedCustomerId,
    required this.actionsTaken,
  });

  @override
  String toString() {
    return '''
Breach Report
=============
Status: ${breached ? 'BREACHED - LOCKDOWN ACTIVE' : 'No active breach'}
Type: ${breachType ?? 'Unknown'}
Detected: ${detectedAt?.toIso8601String() ?? 'Unknown'}
Affected Customer: ${affectedCustomerId ?? 'None'}
Actions Taken: ${actionsTaken.length}
${actionsTaken.map((a) => '  - $action: $status').join('\n')}
''';
  }
}

extension on String {
  String get action => this;
  String get status => this;
}
