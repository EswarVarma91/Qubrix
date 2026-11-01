import '../model/permissions.dart';
import '../security/security_config.dart';

/// Guard that enforces security policies for actions
/// Prevents unauthorized actions and protects against misuse
class PermissionGuard {
  final SecurityConfig config;
  final List<SecurityEvent> _events = [];

  PermissionGuard(this.config);

  List<SecurityEvent> get events => List.unmodifiable(_events);

  void clearEvents() => _events.clear();

  /// Check if an action is allowed
  /// 
  /// Verifies:
  /// - Action is not blocked by category
  /// - User has required permission level
  /// - Sensitive actions require confirmation
  PermissionCheckResult checkAction({
    required String actionId,
    required String category,
    required PermissionLevel requiredLevel,
    bool isSensitive = false,
    Map<String, dynamic>? userPermissions,
  }) {
    if (!config.enabled) {
      return PermissionCheckResult.allowed(
        actionId,
        details: 'Security disabled, action allowed',
      );
    }

    // Check if action category is blocked
    if (config.blockedActionCategories.contains(category)) {
      _logEvent(SecurityEventType.permissionDenied,
          actionId: actionId,
          details: 'Action category "$category" is blocked');
      
      return PermissionCheckResult.denied(
        actionId,
        reason: 'Action category is blocked',
        deniedBy: 'security_policy',
      );
    }

    // Check if user has required permission
    if (config.requireActionAuthorization) {
      final hasPermission = _userHasPermission(
        userPermissions,
        actionId,
        requiredLevel,
      );

      if (!hasPermission) {
        _logEvent(SecurityEventType.permissionDenied,
            actionId: actionId,
            details: 'User lacks permission level $requiredLevel');
        
        return PermissionCheckResult.denied(
          actionId,
          reason: 'Insufficient permissions',
          requiredLevel: requiredLevel,
          deniedBy: 'permission_check',
        );
      }
    }

    // Check if sensitive action requires confirmation
    if (isSensitive && config.requireConfirmationForSensitiveActions) {
      // This should return pending, requiring caller to get confirmation
      return PermissionCheckResult.pendingConfirmation(
        actionId,
        reason: 'Sensitive action requires user confirmation',
        confirmationRequiredFor: 'sensitive_operation',
      );
    }

    _logEvent(SecurityEventType.actionAuthorized,
        actionId: actionId, details: 'Action authorized');

    return PermissionCheckResult.allowed(
      actionId,
      details: 'Action authorized',
    );
  }

  /// Verify user permissions
  bool _userHasPermission(
    Map<String, dynamic>? userPermissions,
    String actionId,
    PermissionLevel requiredLevel,
  ) {
    if (userPermissions == null) {
      // No permissions specified - allow for demo
      return true;
    }

    // Check explicit action permission
    final explicitPermission = userPermissions[actionId];
    if (explicitPermission != null) {
      final level = PermissionLevel.values.firstWhere(
        (l) => l.name == explicitPermission,
        orElse: () => PermissionLevel.none,
      );
      return level.index >= requiredLevel.index;
    }

    // Check role-based permissions
    final role = userPermissions['role'] as String? ?? 'user';
    return _roleHasPermission(role, actionId, requiredLevel);
  }

  /// Check if role has permission for action
  bool _roleHasPermission(
    String role,
    String actionId,
    PermissionLevel requiredLevel,
  ) {
    // Role-based permission matrix
    final rolePermissions = {
      'admin': {
        'all': true,
      },
      'developer': {
        'search_products': true,
        'create_report': true,
        'open_report': true,
        'add_to_cart': true,
      },
      'user': {
        'search_products': true,
        'create_report': true,
        'open_report': true,
      },
    };

    final userPerms = rolePermissions[role] ?? {};
    if (userPerms['all'] == true) return true;
    
    // Check specific action
    if (userPerms[actionId] == true) {
      return true;
    }

    return false;
  }

  /// Check action with user confirmation
  /// 
  /// Returns whether user confirmed the action
  bool requiresConfirmation(String actionId, String confirmationMessage) {
    // In UI, this would trigger a confirmation dialog
    // For now, we just indicate that confirmation is needed
    return true; // Confirmation needed
  }

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
}

/// Result of permission check
class PermissionCheckResult {
  final String actionId;
  final bool allowed;
  final bool requiresConfirmation;
  final String? reason;
  final String? deniedBy;
  final PermissionLevel? requiredLevel;
  final String? confirmationRequiredFor;
  final String? details;

  PermissionCheckResult._({
    required this.actionId,
    this.allowed = false,
    this.requiresConfirmation = false,
    this.reason,
    this.deniedBy,
    this.requiredLevel,
    this.confirmationRequiredFor,
    this.details,
  });

  factory PermissionCheckResult.allowed(
    String actionId, {
    String? details,
  }) {
    return PermissionCheckResult._(
      actionId: actionId,
      allowed: true,
      details: details,
    );
  }

  factory PermissionCheckResult.denied(
    String actionId, {
    required String reason,
    String? deniedBy,
    PermissionLevel? requiredLevel,
  }) {
    return PermissionCheckResult._(
      actionId: actionId,
      allowed: false,
      reason: reason,
      deniedBy: deniedBy,
      requiredLevel: requiredLevel,
    );
  }

  factory PermissionCheckResult.pendingConfirmation(
    String actionId, {
    required String reason,
    String? confirmationRequiredFor,
  }) {
    return PermissionCheckResult._(
      actionId: actionId,
      allowed: false,
      requiresConfirmation: true,
      reason: reason,
      confirmationRequiredFor: confirmationRequiredFor,
    );
  }
}
