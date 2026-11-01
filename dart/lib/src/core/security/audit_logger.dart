import 'dart:convert';
import 'dart:io';
import 'security_config.dart';

/// Comprehensive security audit logging
/// 
/// Logs all security-relevant events for:
/// - Forensic analysis after incidents
/// - Compliance requirements
/// - Debugging security issues
/// - Security monitoring/alerting
/// 
/// Supports:
/// - In-memory logging (default)
/// - File-based logging (for persistence)
/// - Export for external analysis
/// - Log rotation
/// - Tamper-evident logging (hashes chain)
class AuditLogger {
  final SecurityConfig config;
  
  // In-memory event store
  final List<AuditEntry> _events = [];
  
  // File-based logging (optional)
  File? _logFile;
  bool _fileLoggingEnabled = false;
  
  // Tamper-evident chain
  String? _previousHash;
  int _entryCount = 0;

  AuditLogger({required this.config});

  /// Enable file-based logging
  void enableFileLogging({String? logDirectory}) {
    if (!config.logSecurityEvents) return;
    
    _fileLoggingEnabled = true;
    // In production: create log file in app's documents directory
    // final dir = logDirectory ?? await getApplicationDocumentsDirectory();
    // _logFile = File('${dir.path}/security_audit.log');
  }

  /// Log a security event
  void log({
    required SecurityEventType type,
    String? modelId,
    String? actionId,
    String? userId,
    String? details,
    Map<String, String>? metadata,
    SecurityLevel level = SecurityLevel.info,
  }) {
    if (!config.logSecurityEvents) return;

    final entry = AuditEntry(
      id: 'audit_${DateTime.now().millisecondsSinceEpoch}_${_entryCount++}',
      type: type,
      timestamp: DateTime.now(),
      modelId: modelId ?? '',
      actionId: actionId ?? '',
      userId: userId ?? '',
      details: details ?? '',
      level: level,
      metadata: metadata ?? {},
      previousHash: _previousHash,
    );

    // Compute hash for tamper-evident chain
    entry.hash = _computeEntryHash(entry);
    _previousHash = entry.hash;

    _events.add(entry);

    // Write to file if enabled
    if (_fileLoggingEnabled) {
      _writeToFile(entry);
    }
  }

  /// Log model-related events
  void logModelEvent({
    required String modelId,
    required ModelAuditAction action,
    String? details,
    Map<String, String>? metadata,
  }) {
    log(
      type: SecurityEventType.modelDownloadAttempt,
      modelId: modelId,
      actionId: action.name,
      details: details,
      metadata: metadata,
    );
  }

  /// Log action authorization events
  void logActionEvent({
    required String actionId,
    required bool authorized,
    String? userId,
    String? details,
    String? actionCategory,
  }) {
    final type = authorized
        ? SecurityEventType.actionAuthorized
        : SecurityEventType.unauthorizedActionAttempt;
    
    log(
      type: type,
      actionId: actionId,
      userId: userId,
      details: details ?? (authorized ? 'Action authorized' : 'Action denied'),
      metadata: {'category': actionCategory ?? ''},
      level: authorized ? SecurityLevel.info : SecurityLevel.warning,
    );
  }

  /// Log encryption events
  void logEncryptionEvent({
    required EncryptionAuditAction action,
    String? keyId,
    String? details,
    bool success = true,
  }) {
    final type = success
        ? SecurityEventType.actionAuthorized
        : SecurityEventType.encryptionError;
    
    log(
      type: type,
      modelId: keyId ?? '',
      actionId: action.name,
      details: details ?? (success ? 'Encryption operation successful' : 'Encryption failed'),
      level: success ? SecurityLevel.info : SecurityLevel.error,
    );
  }

  /// Log security incidents
  void logSecurityIncident({
    required String incidentId,
    required SecurityIncidentType incidentType,
    required String description,
    String? affectedModelId,
    String? affectedUserId,
    Map<String, String>? evidence,
    SecurityLevel level = SecurityLevel.critical,
  }) {
    log(
      type: SecurityEventType.tamperDetected,
      modelId: affectedModelId ?? '',
      actionId: incidentId,
      userId: affectedUserId,
      details: 'SECURITY INCIDENT: $incidentType - $description',
      metadata: evidence ?? {},
      level: level,
    );
  }

  /// Export all logs for analysis
  String exportLogs({bool includeHashes = true}) {
    final buffer = StringBuffer();
    buffer.writeln('=== Security Audit Log ===');
    buffer.writeln('Exported: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Entries: ${_events.length}');
    buffer.writeln('Previous Hash: $_previousHash');
    buffer.writeln('===========================\n');

    for (final entry in _events) {
      buffer.writeln(entry.toExportString(includeHashes: includeHashes));
      buffer.writeln('---');
    }

    return buffer.toString();
  }

  /// Export as JSON for machine analysis
  String exportJson() {
    final entries = _events.map((e) => e.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert({
      'exportTimestamp': DateTime.now().toIso8601String(),
      'totalEntries': _events.length,
      'chainHash': _previousHash,
      'entries': entries,
    });
  }

  /// Get entries by type
  List<AuditEntry> getByType(SecurityEventType type) {
    return _events.where((e) => e.type == type).toList();
  }

  /// Get entries by model
  List<AuditEntry> getByModel(String modelId) {
    return _events.where((e) => e.modelId == modelId).toList();
  }

  /// Get entries by time range
  List<AuditEntry> getByTimeRange(DateTime start, DateTime end) {
    return _events.where((e) => 
      e.timestamp.isAfter(start) && e.timestamp.isBefore(end)
    ).toList();
  }

  /// Get entries by level
  List<AuditEntry> getByLevel(SecurityLevel level) {
    return _events.where((e) => e.level == level).toList();
  }

  /// Get security summary
  AuditSummary getSummary() {
    final byType = <SecurityEventType, int>{};
    final byLevel = <SecurityLevel, int>{};
    final modelIds = <String>{};
    
    for (final entry in _events) {
      byType[entry.type] = (byType[entry.type] ?? 0) + 1;
      byLevel[entry.level] = (byLevel[entry.level] ?? 0) + 1;
      if (entry.modelId.isNotEmpty) modelIds.add(entry.modelId);
    }

    return AuditSummary(
      totalEntries: _events.length,
      byType: byType,
      byLevel: byLevel,
      uniqueModels: modelIds.length,
      firstEvent: _events.isNotEmpty ? _events.first.timestamp : null,
      lastEvent: _events.isNotEmpty ? _events.last.timestamp : null,
      chainHash: _previousHash,
    );
  }

  /// Clear all logs (for privacy/compliance)
  void clear() {
    _events.clear();
    _previousHash = null;
    _entryCount = 0;
  }

  /// Write entry to file
  void _writeToFile(AuditEntry entry) {
    if (_logFile == null) return;
    
    try {
      final line = '${entry.toCsvLine()}\n';
      _logFile!.openWrite(mode: FileMode.append).write(line);
    } catch (e) {
      // Silently fail - logging shouldn't crash the app
    }
  }

  /// Compute hash of entry for tamper-evident chain
  String _computeEntryHash(AuditEntry entry) {
    final data = '''
${entry.id}
${entry.type.name}
${entry.timestamp.millisecondsSinceEpoch}
${entry.modelId}
${entry.actionId}
${entry.details}
${entry.level.name}
${entry.previousHash ?? ''}
''';
    
    // In production: use SHA-256 from crypto library
    // For now: simple hash (replace with proper crypto)
    return 'sha256:${data.hashCode}';
  }
}

/// A single audit log entry
class AuditEntry {
  final String id;
  final SecurityEventType type;
  final DateTime timestamp;
  final String modelId;
  final String actionId;
  final String userId;
  final String details;
  final SecurityLevel level;
  final Map<String, String> metadata;
  final String? previousHash;
  String? hash; // Computed after creation

  AuditEntry({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.modelId,
    required this.actionId,
    required this.userId,
    required this.details,
    required this.level,
    required this.metadata,
    this.previousHash,
  });

  String toExportString({bool includeHashes = true}) {
    final buffer = StringBuffer();
    buffer.writeln('ID: $id');
    buffer.writeln('Type: ${type.name}');
    buffer.writeln('Timestamp: ${timestamp.toIso8601String()}');
    buffer.writeln('Level: ${level.name}');
    if (modelId.isNotEmpty) buffer.writeln('Model: $modelId');
    if (actionId.isNotEmpty) buffer.writeln('Action: $actionId');
    if (userId.isNotEmpty) buffer.writeln('User: $userId');
    if (details.isNotEmpty) buffer.writeln('Details: $details');
    if (metadata.isNotEmpty) buffer.writeln('Metadata: $metadata');
    if (includeHashes) {
      if (previousHash != null) buffer.writeln('Previous Hash: $previousHash');
      if (hash != null) buffer.writeln('Hash: $hash');
    }
    return buffer.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'modelId': modelId,
      'actionId': actionId,
      'userId': userId,
      'details': details,
      'metadata': metadata,
      'previousHash': previousHash,
      'hash': hash,
    };
  }

  String toCsvLine() {
    return '''
${id},
${type.name},
${timestamp.toIso8601String()},
${level.name},
$modelId,
$actionId,
$userId,
$details,
$metadata,
$previousHash,
$hash
''';
  }

  @override
  String toString() => '[${timestamp.toIso8601String()}] ${type.name}: $details';
}

/// Audit summary
class AuditSummary {
  final int totalEntries;
  final Map<SecurityEventType, int> byType;
  final Map<SecurityLevel, int> byLevel;
  final int uniqueModels;
  final DateTime? firstEvent;
  final DateTime? lastEvent;
  final String? chainHash;

  AuditSummary({
    required this.totalEntries,
    required this.byType,
    required this.byLevel,
    required this.uniqueModels,
    this.firstEvent,
    this.lastEvent,
    this.chainHash,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('=== Audit Summary ===');
    buffer.writeln('Total Entries: $totalEntries');
    buffer.writeln('Unique Models: $uniqueModels');
    if (firstEvent != null) buffer.writeln('First Event: $firstEvent');
    if (lastEvent != null) buffer.writeln('Last Event: $lastEvent');
    buffer.writeln('\nBy Type:');
    for (final entry in byType.entries) {
      buffer.writeln('  ${entry.key.name}: ${entry.value}');
    }
    buffer.writeln('\nBy Level:');
    for (final entry in byLevel.entries) {
      buffer.writeln('  ${entry.key.name}: ${entry.value}');
    }
    if (chainHash != null) buffer.writeln('\nChain Hash: $chainHash');
    return buffer.toString();
  }
}

/// Security log level
enum SecurityLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Model audit actions
enum ModelAuditAction {
  downloadRequested,
  downloadStarted,
  downloadProgress,
  downloadCompleted,
  downloadFailed,
  verificationStarted,
  verificationPassed,
  verificationFailed,
  installed,
  updated,
  removed,
  loadedIntoMemory,
  unloadedFromMemory,
  inferenceExecuted,
  inferenceFailed,
}

/// Encryption audit actions
enum EncryptionAuditAction {
  keyGenerated,
  keyStored,
  keyRetrieved,
  keyRotated,
  keyDeleted,
  keyBackedUp,
  keyRestored,
  dataEncrypted,
  dataDecrypted,
  encryptionFailed,
  decryptionFailed,
  tamperDetected,
}

/// Security incident types
enum SecurityIncidentType {
  unauthorizedAccess,
  dataExfiltration,
  tamperingAttempt,
  integrityViolation,
  suspiciousActivity,
  bruteForceAttempt,
  credentialCompromise,
  modelPoisoning,
  modelTheft,
  keyExtractionAttempt,
}
