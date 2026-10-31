/// Activity Event System
///
/// Stores permitted, structured facts about recent interactions.
/// Layer 1 of the personalization system.

import 'package:flutter/foundation.dart';

/// Types of activity events that can be recorded
enum ActivityEventType {
  /// User performed a task
  taskExecution,

  /// User interacted with a feature
  featureUsage,

  /// User completed a workflow
  workflowCompletion,

  /// User started a workflow
  workflowStart,

  /// User cancelled an action
  actionCancelled,

  /// User searched for something
  search,

  /// User applied a filter
  filterApplied,

  /// User selected an option
  selection,

  /// User opened a screen
  screenOpened,

  /// User dismissed a suggestion
  suggestionDismissed,

  /// User accepted a suggestion
  suggestionAccepted,

  /// User modified a preference
  preferenceChanged,

  /// User granted a permission
  permissionGranted,

  /// User revoked a permission
  permissionRevoked,

  /// Custom event type
  custom,
}

/// Priority of activity event
enum ActivityPriority {
  /// High priority - immediately relevant
  high,

  /// Normal priority - for pattern detection
  normal,

  /// Low priority - may be aggregated
  low,

  /// Very low - historical reference
  archival,
}

/// An activity event capturing user interaction
@immutable
class ActivityEvent {
  /// Unique event ID
  final String eventId;

  /// Type of event
  final ActivityEventType eventType;

  /// Associated task type (if applicable)
  final TaskType? taskType;

  /// Associated task ID (if applicable)
  final String? taskId;

  /// Associated action ID (if applicable)
  final String? actionId;

  /// Whether the action was successful
  final bool success;

  /// Duration of the activity in milliseconds
  final int durationMs;

  /// When the event occurred
  final DateTime timestamp;

  /// Contextual data about the event
  final Map<String, dynamic> context;

  /// Additional metadata
  final Map<String, dynamic> metadata;

  /// Priority of the event
  final ActivityPriority priority;

  /// Privacy classification
  final PrivacyLevel privacyLevel;

  const ActivityEvent({
    required this.eventType,
    this.taskType,
    this.taskId,
    this.actionId,
    this.success = true,
    this.durationMs = 0,
    DateTime? timestamp,
    this.context = const {},
    this.metadata = const {},
    this.priority = ActivityPriority.normal,
    this.privacyLevel = PrivacyLevel.local,
  }) : eventId = _generateId(),
       timestamp = timestamp ?? DateTime.now();

  /// Generate unique event ID
  static String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_randomString(8)}';
  }

  static String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().microsecondsSinceEpoch;
    return String.fromCharCodes(
      List.generate(length, (i) => chars.codeUnitAt(random % chars.length + i)),
    );
  }

  /// Create a copy with modified fields
  ActivityEvent copyWith({
    String? eventId,
    ActivityEventType? eventType,
    TaskType? taskType,
    String? taskId,
    String? actionId,
    bool? success,
    int? durationMs,
    DateTime? timestamp,
    Map<String, dynamic>? context,
    Map<String, dynamic>? metadata,
    ActivityPriority? priority,
    PrivacyLevel? privacyLevel,
  }) {
    return ActivityEvent(
      eventId: eventId ?? this.eventId,
      eventType: eventType ?? this.eventType,
      taskType: taskType ?? this.taskType,
      taskId: taskId ?? this.taskId,
      actionId: actionId ?? this.actionId,
      success: success ?? this.success,
      durationMs: durationMs ?? this.durationMs,
      timestamp: timestamp ?? this.timestamp,
      context: context ?? this.context,
      metadata: metadata ?? this.metadata,
      priority: priority ?? this.priority,
      privacyLevel: privacyLevel ?? this.privacyLevel,
    );
  }

  /// Check if this event is high priority
  bool get isHighPriority => priority == ActivityPriority.high;

  /// Check if this event is temporary (will expire)
  bool get isTemporary => priority == ActivityPriority.low;

  /// Get the age of the event
  Duration get age => DateTime.now().difference(timestamp);

  /// Check if the event is expired based on retention policy
  bool isExpired({Duration? maxAge}) {
    final max = maxAge ?? const Duration(days: 90);
    return age > max;
  }

  /// Create a simplified version for sharing/debugging (removes sensitive data)
  ActivityEvent toSimplified() {
    return copyWith(
      context: _simplifyContext(context),
      metadata: _simplifyMetadata(metadata),
    );
  }

  Map<String, dynamic> _simplifyContext(Map<String, dynamic> ctx) {
    // Remove potentially sensitive fields
    final simplified = Map<String, dynamic>.from(ctx);
    simplified.remove('userInput');
    simplified.remove('sensitiveData');
    simplified.remove('personalInfo');
    return simplified;
  }

  Map<String, dynamic> _simplifyMetadata(Map<String, dynamic> meta) {
    final simplified = Map<String, dynamic>.from(meta);
    simplified.remove('internalId');
    simplified.remove('debugInfo');
    return simplified;
  }

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'eventType': eventType.name,
        'taskType': taskType?.name,
        'taskId': taskId,
        'actionId': actionId,
        'success': success,
        'durationMs': durationMs,
        'timestamp': timestamp.toIso8601String(),
        'context': context,
        'metadata': metadata,
        'priority': priority.name,
        'privacyLevel': privacyLevel.name,
      };

  factory ActivityEvent.fromJson(Map<String, dynamic> json) {
    return ActivityEvent(
      eventId: json['eventId'] as String,
      eventType: ActivityEventType.values.firstWhere(
        (e) => e.name == json['eventType'],
        orElse: () => ActivityEventType.custom,
      ),
      taskType: json['taskType'] != null
          ? TaskType.values.firstWhere(
              (e) => e.name == json['taskType'],
              orElse: () => TaskType.processing,
            )
          : null,
      taskId: json['taskId'] as String?,
      actionId: json['actionId'] as String?,
      success: json['success'] as bool? ?? true,
      durationMs: json['durationMs'] as int? ?? 0,
      timestamp: DateTime.parse(json['timestamp'] as String),
      context: (json['context'] as Map<String, dynamic>?) ?? {},
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      priority: ActivityPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => ActivityPriority.normal,
      ),
      privacyLevel: PrivacyLevel.values.firstWhere(
        (e) => e.name == json['privacyLevel'],
        orElse: () => PrivacyLevel.local,
      ),
    );
  }

  @override
  String toString() =>
      'ActivityEvent(${eventType.name}, ${taskType?.name ?? "no-task"}, ${durationMs}ms)';
}

/// Privacy level for activity data
enum PrivacyLevel {
  /// Data stays on device only
  local,

  /// Data can be used for local learning but not transmitted
  localOnly,

  /// Anonymized data may be used for improvements
  anonymized,

  /// Data may be transmitted with user consent
  consented,

  /// Highly sensitive - minimal retention
  sensitive,
}

/// Extension to add convenience methods to ActivityEvent
extension ActivityEventExtensions on ActivityEvent {
  /// Create a task execution event
  static ActivityEvent taskExecuted({
    required String taskId,
    required TaskType taskType,
    required bool success,
    int durationMs = 0,
    Map<String, dynamic>? context,
  }) {
    return ActivityEvent(
      eventType: ActivityEventType.taskExecution,
      taskId: taskId,
      taskType: taskType,
      success: success,
      durationMs: durationMs,
      context: context ?? {},
    );
  }

  /// Create a feature usage event
  static ActivityEvent featureUsed({
    required String featureName,
    required String featureId,
    Map<String, dynamic>? context,
  }) {
    return ActivityEvent(
      eventType: ActivityEventType.featureUsage,
      actionId: featureId,
      context: {
        'featureName': featureName,
        ...?context,
      },
    );
  }

  /// Create a suggestion accepted event
  static ActivityEvent suggestionAccepted({
    required String suggestionId,
    required String suggestionType,
    Map<String, dynamic>? context,
  }) {
    return ActivityEvent(
      eventType: ActivityEventType.suggestionAccepted,
      actionId: suggestionId,
      context: {
        'suggestionType': suggestionType,
        ...?context,
      },
      priority: ActivityPriority.high,
    );
  }

  /// Create a suggestion dismissed event
  static ActivityEvent suggestionDismissed({
    required String suggestionId,
    String? dismissalReason,
    Map<String, dynamic>? context,
  }) {
    return ActivityEvent(
      eventType: ActivityEventType.suggestionDismissed,
      actionId: suggestionId,
      context: {
        'dismissalReason': dismissalReason,
        ...?context,
      },
    );
  }

  /// Create a workflow completion event
  static ActivityEvent workflowCompleted({
    required String workflowId,
    required bool success,
    int durationMs = 0,
    Map<String, dynamic>? context,
  }) {
    return ActivityEvent(
      eventType: ActivityEventType.workflowCompletion,
      taskId: workflowId,
      success: success,
      durationMs: durationMs,
      context: context ?? {},
      priority: ActivityPriority.high,
    );
  }
}
