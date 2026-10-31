/// Permission Manager
///
/// Manages permissions for automation actions.
/// Controls what the automation engine can do.

import 'package:flutter/foundation.dart';
import 'action_registry.dart';

/// Permission grant status
enum PermissionGrant {
  /// Permission granted
  granted,

  /// Permission denied
  denied,

  /// Permission not requested yet
  notRequested,

  /// Permission requires additional confirmation
  requiresConfirmation,

  /// Permission temporarily unavailable
  unavailable,
}

/// Permission request
@immutable
class PermissionRequest {
  final String id;
  final String actionId;
  final PermissionLevel level;
  final String? reason;
  final DateTime requestedAt;
  final bool isPersisted;

  const PermissionRequest({
    required this.id,
    required this.actionId,
    required this.level,
    this.reason,
    required this.requestedAt,
    this.isPersisted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'actionId': actionId,
        'level': level.name,
        'reason': reason,
        'requestedAt': requestedAt.toIso8601String(),
        'isPersisted': isPersisted,
      };

  factory PermissionRequest.fromJson(Map<String, dynamic> json) {
    return PermissionRequest(
      id: json['id'] as String,
      actionId: json['actionId'] as String,
      level: PermissionLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => PermissionLevel.execute,
      ),
      reason: json['reason'] as String?,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      isPersisted: json['isPersisted'] as bool? ?? false,
    );
  }

  @override
  String toString() => 'PermissionRequest($actionId, $level)';
}

/// Permission record
@immutable
class PermissionRecord {
  final String actionId;
  final PermissionLevel level;
  final bool granted;
  final DateTime? grantedAt;
  final DateTime? lastUsed;
  final int usageCount;
  final String? grantedBy;
  final String? lastDeniedReason;

  const PermissionRecord({
    required this.actionId,
    required this.level,
    required this.granted,
    this.grantedAt,
    this.lastUsed,
    this.usageCount = 0,
    this.grantedBy,
    this.lastDeniedReason,
  });

  /// Check if permission is effectively granted
  bool get isEffectivelyGranted => granted;

  /// Check if permission has expired (not used in a while)
  bool get isExpired {
    if (!granted || lastUsed == null) return false;
    return DateTime.now().difference(lastUsed!) > const Duration(days: 30);
  }

  PermissionRecord copyWith({
    String? actionId,
    PermissionLevel? level,
    bool? granted,
    DateTime? grantedAt,
    DateTime? lastUsed,
    int? usageCount,
    String? grantedBy,
    String? lastDeniedReason,
  }) {
    return PermissionRecord(
      actionId: actionId ?? this.actionId,
      level: level ?? this.level,
      granted: granted ?? this.granted,
      grantedAt: grantedAt ?? this.grantedAt,
      lastUsed: lastUsed ?? this.lastUsed,
      usageCount: usageCount ?? this.usageCount,
      grantedBy: grantedBy ?? this.grantedBy,
      lastDeniedReason: lastDeniedReason ?? this.lastDeniedReason,
    );
  }

  Map<String, dynamic> toJson() => {
        'actionId': actionId,
        'level': level.name,
        'granted': granted,
        'grantedAt': grantedAt?.toIso8601String(),
        'lastUsed': lastUsed?.toIso8601String(),
        'usageCount': usageCount,
        'grantedBy': grantedBy,
        'lastDeniedReason': lastDeniedReason,
      };

  factory PermissionRecord.fromJson(Map<String, dynamic> json) {
    return PermissionRecord(
      actionId: json['actionId'] as String,
      level: PermissionLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => PermissionLevel.execute,
      ),
      granted: json['granted'] as bool,
      grantedAt: json['grantedAt'] != null
          ? DateTime.parse(json['grantedAt'] as String)
          : null,
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : null,
      usageCount: json['usageCount'] as int? ?? 0,
      grantedBy: json['grantedBy'] as String?,
      lastDeniedReason: json['lastDeniedReason'] as String?,
    );
  }

  @override
  String toString() =>
      'PermissionRecord($actionId: ${granted ? "granted" : "denied"})';
}

/// Permission manager for handling action permissions
class PermissionManager {
  final Map<String, PermissionRecord> _permissions = {};
  final List<PermissionRequest> _pendingRequests = [];

  /// Request permission for an action
  Future<PermissionGrant> requestPermission({
    required String actionId,
    required PermissionLevel level,
    String? reason,
  }) async {
    // Check if permission already exists
    final existing = _permissions[actionId];
    if (existing != null) {
      if (existing.granted && existing.level.index >= level.index) {
        return PermissionGrant.granted;
      }
      if (!existing.granted) {
        return PermissionGrant.denied;
      }
    }

    // For demonstration, auto-grant permissions
    // In a real implementation, this would show a UI prompt

    final grant = PermissionGrant.granted;

    // Record the permission
    if (grant == PermissionGrant.granted) {
      _permissions[actionId] = PermissionRecord(
        actionId: actionId,
        level: level,
        granted: true,
        grantedAt: DateTime.now(),
        grantedBy: 'user', // In real impl, would be user ID
      );
    }

    return grant;
  }

  /// Check if permission is granted for an action
  bool hasPermission(String actionId, PermissionLevel level) {
    final record = _permissions[actionId];
    if (record == null) return false;
    return record.granted && record.level.index >= level.index;
  }

  /// Check if permission exists (any level)
  bool hasAnyPermission(String actionId) {
    return _permissions.containsKey(actionId);
  }

  /// Get permission level for an action
  PermissionLevel? getPermissionLevel(String actionId) {
    final record = _permissions[actionId];
    return record?.granted == true ? record!.level : null;
  }

  /// Revoke permission
  void revokePermission(String actionId) {
    _permissions.remove(actionId);
  }

  /// Update permission usage
  void recordUsage(String actionId) {
    final record = _permissions[actionId];
    if (record != null) {
      _permissions[actionId] = record.copyWith(
        lastUsed: DateTime.now(),
        usageCount: record.usageCount + 1,
      );
    }
  }

  /// Get all permissions
  List<PermissionRecord> get permissions {
    return _permissions.values.toList();
  }

  /// Get permissions for an action
  PermissionRecord? getPermission(String actionId) {
    return _permissions[actionId];
  }

  /// Get pending requests
  List<PermissionRequest> get pendingRequests {
    return List.unmodifiable(_pendingRequests);
  }

  /// Get permission statistics
  Map<String, int> getPermissionStats() {
    return {
      'total_granted': _permissions.values.where((p) => p.granted).length,
      'total_denied': _permissions.values.where((p) => !p.granted).length,
      'total_actions': _permissions.length,
    };
  }

  /// Check if permission needs renewal
  bool needsRenewal(String actionId) {
    final record = _permissions[actionId];
    return record?.isExpired ?? false;
  }

  /// Clear all permissions
  void clearAll() {
    _permissions.clear();
    _pendingRequests.clear();
  }

  /// Export permissions (for backup/migration)
  Map<String, dynamic> exportPermissions() {
    return {
      'permissions': _permissions.values.map((p) => p.toJson()).toList(),
    };
  }

  /// Import permissions (from backup/migration)
  void importPermissions(Map<String, dynamic> data) {
    if (data['permissions'] is List) {
      for (final p in data['permissions']) {
        if (p is Map) {
          final record = PermissionRecord.fromJson(p.cast());
          _permissions[record.actionId] = record;
        }
      }
    }
  }

  /// Check if an action is safe to automate
  bool isSafeForAutomation(String actionId, ActionDefinition? action) {
    // Check permission level
    if (!hasPermission(actionId, PermissionLevel.execute)) {
      return false;
    }

    // Check if action has dangerous side effects
    if (action != null) {
      if (action.sideEffectType == SideEffectType.payment) {
        return false; // Payment always requires confirmation
      }
      if (action.sideEffectType == SideEffectType.dataDeletion) {
        return false; // Deletion always requires confirmation
      }
      if (action.requiresConfirmation) {
        return false;
      }
    }

    return true;
  }
}
