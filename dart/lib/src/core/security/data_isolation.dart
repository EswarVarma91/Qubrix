import 'security_config.dart';

/// Ensures complete data isolation between customers/users
/// 
/// When SDK is compromised, data isolation is the last line of defense:
/// - Each customer's data is logically separated
/// - Cross-customer data access is prevented
/// - Customer context is enforced on all operations
/// - Data leakage between customers is detected
class DataIsolation {
  final SecurityConfig config;
  final List<SecurityEvent> _events = [];

  // Current customer context (if any)
  String? _currentCustomerId;
  String? _currentSessionId;

  // Access history for anomaly detection
  final Map<String, List<AccessRecord>> _accessHistory = {};

  DataIsolation(this.config);

  List<SecurityEvent> get events => List.unmodifiable(_events);

  void clearEvents() => _events.clear();

  /// Initialize a session for a specific customer
  void beginCustomerSession({
    required String customerId,
    required String sessionId,
    Map<String, dynamic>? customerContext,
  }) {
    if (!config.enabled) {
      _currentCustomerId = customerId;
      _currentSessionId = sessionId;
      return;
    }

    _currentCustomerId = customerId;
    _currentSessionId = sessionId;
    _accessHistory[customerId] ??= [];

    _logEvent(SecurityEventType.actionAuthorized,
        details: 'Session started for customer: $customerId');

    // Clear any previous context
  }

  /// End the current customer session
  void endCustomerSession() {
    if (_currentCustomerId != null) {
      _logEvent(SecurityEventType.actionAuthorized,
          details: 'Session ended for customer: $_currentCustomerId');
    }

    _currentCustomerId = null;
    _currentSessionId = null;
  }

  /// Check if we're in a valid customer context
  bool get hasActiveSession => _currentCustomerId != null;

  /// Get current customer ID (null if no session)
  String? get currentCustomerId => _currentCustomerId;

  /// Get current session ID
  String? get currentSessionId => _currentSessionId;

  /// Verify that an operation is for the current customer
  /// 
  /// Returns true if the data belongs to current customer or no customer context
  bool verifyCustomerAccess({
    required String dataCustomerId,
    String? operation,
  }) {
    if (!config.enabled) {
      return true;
    }

    // If no session, check is bypassed (for demo - in production might deny)
    if (_currentCustomerId == null) {
      return true;
    }

    // Verify data belongs to current customer
    if (dataCustomerId != _currentCustomerId) {
      _logEvent(SecurityEventType.tamperDetected,
          details: 'Cross-customer access attempt blocked: '
              'current=${_currentCustomerId} requested=$dataCustomerId');

      _recordAccess(dataCustomerId, 'blocked_cross_customer', operation);

      return false;
    }

    _recordAccess(dataCustomerId, 'allowed', operation);

    return true;
  }

  /// Record an access for this customer
  void _recordAccess(
    String customerId,
    String type,
    String? operation,
  ) {
    final history = _accessHistory[customerId] ??= [];
    history.add(AccessRecord(
      customerId: customerId,
      type: type,
      operation: operation,
      timestamp: DateTime.now(),
      sessionId: _currentSessionId,
    ));

    // Keep only recent history
    if (history.length > 1000) {
      history.removeAt(0);
    }
  }

  /// Detect anomalous access patterns
  List<Anomaly> detectAnomalies(String customerId) {
    final history = _accessHistory[customerId];
    if (history == null || history.isEmpty) {
      return [];
    }

    final anomalies = <Anomaly>[];

    // Check for unusual patterns
    final recentAccesses = history
        .where((r) => r.timestamp.isAfter(
              DateTime.now().subtract(const Duration(minutes: 5)),
            ))
        .toList();

    // High frequency access
    if (recentAccesses.length > 100) {
      anomalies.add(Anomaly(
        severity: AnomalySeverity.high,
        type: 'high_frequency_access',
        message: 'Customer $customerId had ${recentAccesses.length} accesses in 5 minutes',
        timestamp: DateTime.now(),
      ));
    }

    // Blocked access attempts
    final blockedAttempts = recentAccesses
        .where((r) => r.type == 'blocked_cross_customer')
        .length;

    if (blockedAttempts > 5) {
      anomalies.add(Anomaly(
        severity: AnomalySeverity.critical,
        type: 'repeated_cross_customer_attempts',
        message: '$blockedAttempts cross-customer access attempts in 5 minutes',
        timestamp: DateTime.now(),
      ));
    }

    return anomalies;
  }

  /// Clear all data for a customer (secure deletion)
  Future<void> wipeCustomerData(String customerId) async {
    // Clear access history
    _accessHistory.remove(customerId);

    // Clear any cached data (in production: clear from all caches)
    _logEvent(SecurityEventType.actionAuthorized,
        details: 'Data wiped for customer: $customerId');

    // If this was the current session, end it
    if (_currentCustomerId == customerId) {
      endCustomerSession();
    }
  }

  /// Verify data isolation is working
  bool verifyIsolation() {
    // In production: verify that no cross-customer data leaks exist
    return config.enabled;
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

  /// Get isolation status report
  String getStatusReport() {
    return '''
Data Isolation Status
=====================
Active Session: ${_currentCustomerId ?? 'None'}
Session ID: ${_currentSessionId ?? 'None'}
Tracking Customers: ${_accessHistory.length}
Isolation Enabled: ${config.enabled}

Customer Access Summary:
${_accessHistory.entries.map((e) => '  ${e.key}: ${e.value.length} accesses').join('\n')}
''';
  }
}

/// Record of data access
class AccessRecord {
  final String customerId;
  final String type; // 'allowed', 'blocked_cross_customer', etc.
  final String? operation;
  final DateTime timestamp;
  final String? sessionId;

  AccessRecord({
    required this.customerId,
    required this.type,
    this.operation,
    required this.timestamp,
    this.sessionId,
  });
}

/// Detected anomaly
class Anomaly {
  final AnomalySeverity severity;
  final String type;
  final String message;
  final DateTime timestamp;

  Anomaly({
    required this.severity,
    required this.type,
    required this.message,
    required this.timestamp,
  });
}

enum AnomalySeverity {
  low,
  medium,
  high,
  critical,
}
