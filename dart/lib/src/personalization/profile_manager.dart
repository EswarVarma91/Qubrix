/// Profile Manager
///
/// Stores and manages user profile data including preferences and routines.
/// Layer 1 & 2 of the personalization system.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'activity_event.dart';

/// User profile containing learned preferences and patterns
@immutable
class UserProfile {
  /// Unique user identifier (app-specific, not personally identifiable)
  final String profileId;

  /// When the profile was created
  final DateTime createdAt;

  /// When the profile was last updated
  final DateTime lastUpdated;

  /// User preferences discovered through interaction
  final Map<String, Preference> preferences;

  /// Detected routines/patterns
  final List<DetectedRoutine> routines;

  /// Feature usage statistics
  final FeatureUsageStats usageStats;

  /// Recent activity summary (aggregated, not raw events)
  final List<ActivitySummary> recentActivity;

  /// Configuration for this profile
  final ProfileConfig config;

  const UserProfile({
    required this.profileId,
    required this.createdAt,
    required this.lastUpdated,
    this.preferences = const {},
    this.routines = const [],
    this.usageStats = const FeatureUsageStats(),
    this.recentActivity = const [],
    this.config = const ProfileConfig(),
  });

  /// Check if the profile is empty (no learned data)
  bool get isEmpty =>
      preferences.isEmpty &&
      routines.isEmpty &&
      usageStats.totalEvents == 0;

  /// Get total feature usage count
  int get totalUsageCount => usageStats.totalEvents;

  /// Get most used features
  List<FeatureUsage> getMostUsedFeatures({int limit = 10}) {
    final sorted = List<FeatureUsage>.from(usageStats.featureUsage)
      ..sort((a, b) => b.count.compareTo(a.count));
    return sorted.take(limit).toList();
  }

  /// Get routines by frequency
  List<DetectedRoutine> getMostFrequentRoutines({int limit = 5}) {
    final sorted = List<DetectedRoutine>.from(routines)
      ..sort((a, b) => b.frequency.compareTo(a.frequency));
    return sorted.take(limit).toList();
  }

  /// Copy with modified fields
  UserProfile copyWith({
    String? profileId,
    DateTime? createdAt,
    DateTime? lastUpdated,
    Map<String, Preference>? preferences,
    List<DetectedRoutine>? routines,
    FeatureUsageStats? usageStats,
    List<ActivitySummary>? recentActivity,
    ProfileConfig? config,
  }) {
    return UserProfile(
      profileId: profileId ?? this.profileId,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? DateTime.now(),
      preferences: preferences ?? this.preferences,
      routines: routines ?? this.routines,
      usageStats: usageStats ?? this.usageStats,
      recentActivity: recentActivity ?? this.recentActivity,
      config: config ?? this.config,
    );
  }

  Map<String, dynamic> toJson() => {
        'profileId': profileId,
        'createdAt': createdAt.toIso8601String(),
        'lastUpdated': lastUpdated.toIso8601String(),
        'preferences': preferences.map((k, v) => MapEntry(k, v.toJson())),
        'routines': routines.map((r) => r.toJson()).toList(),
        'usageStats': usageStats.toJson(),
        'recentActivity': recentActivity.map((a) => a.toJson()).toList(),
        'config': config.toJson(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      profileId: json['profileId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdated:
          DateTime.parse(json['lastUpdated'] as String),
      preferences: (json['preferences'] as Map<String, dynamic>?)
              ?.map((k, v) =>
                  MapEntry(k, Preference.fromJson(v as Map<String, dynamic>))) ??
          {},
      routines: (json['routines'] as List<dynamic>?)
              ?.map((r) =>
                  DetectedRoutine.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      usageStats: json['usageStats'] != null
          ? FeatureUsageStats.fromJson(
              json['usageStats'] as Map<String, dynamic>)
          : const FeatureUsageStats(),
      recentActivity: (json['recentActivity'] as List<dynamic>?)
              ?.map((a) =>
                  ActivitySummary.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      config:
          json['config'] != null ? ProfileConfig.fromJson(json['config'] as Map<String, dynamic>) : const ProfileConfig(),
    );
  }

  @override
  String toString() =>
      'UserProfile($profileId, ${preferences.length} prefs, ${routines.length} routines)';
}

/// User preference discovered through interaction
@immutable
class Preference {
  /// Preference key/category
  final String key;

  /// Human-readable name
  final String name;

  /// Description of what this preference represents
  final String? description;

  /// Preference value
  final PreferenceValue value;

  /// How confident we are in this preference
  final double confidence;

  /// Number of times this preference was confirmed
  final int confirmationCount;

  /// Last time this preference was used/influenced behavior
  final DateTime? lastUsed;

  /// When this preference was first detected
  final DateTime detectedAt;

  /// Source of this preference (how it was learned)
  final PreferenceSource source;

  const Preference({
    required this.key,
    required this.name,
    this.description,
    required this.value,
    required this.confidence,
    this.confirmationCount = 0,
    this.lastUsed,
    required this.detectedAt,
    this.source = PreferenceSource.implicit,
  });

  /// Create a copy with modified fields
  Preference copyWith({
    String? key,
    String? name,
    String? description,
    PreferenceValue? value,
    double? confidence,
    int? confirmationCount,
    DateTime? lastUsed,
    DateTime? detectedAt,
    PreferenceSource? source,
  }) {
    return Preference(
      key: key ?? this.key,
      name: name ?? this.name,
      description: description ?? this.description,
      value: value ?? this.value,
      confidence: confidence ?? this.confidence,
      confirmationCount: confirmationCount ?? this.confirmationCount,
      lastUsed: lastUsed ?? this.lastUsed,
      detectedAt: detectedAt ?? this.detectedAt,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
        'description': description,
        'value': value.toJson(),
        'confidence': confidence,
        'confirmationCount': confirmationCount,
        'lastUsed': lastUsed?.toIso8601String(),
        'detectedAt': detectedAt.toIso8601String(),
        'source': source.name,
      };

  factory Preference.fromJson(Map<String, dynamic> json) {
    return Preference(
      key: json['key'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      value:
          PreferenceValue.fromJson(json['value'] as Map<String, dynamic>),
      confidence: (json['confidence'] as num).toDouble(),
      confirmationCount: json['confirmationCount'] as int? ?? 0,
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : null,
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      source: PreferenceSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => PreferenceSource.implicit,
      ),
    );
  }

  @override
  String toString() => 'Preference($key: $value, confidence: $confidence)';
}

/// Preference value types
@immutable
class PreferenceValue {
  final PreferenceValueType type;
  final String? stringValue;
  final int? intValue;
  final double? doubleValue;
  final bool? boolValue;
  final List<String>? listValue;

  const PreferenceValue({
    required this.type,
    this.stringValue,
    this.intValue,
    this.doubleValue,
    this.boolValue,
    this.listValue,
  });

  static PreferenceValue string(String value) {
    return PreferenceValue(type: PreferenceValueType.string, stringValue: value);
  }

  static PreferenceValue integer(int value) {
    return PreferenceValue(type: PreferenceValueType.integer, intValue: value);
  }

  static PreferenceValue number(double value) {
    return PreferenceValue(type: PreferenceValueType.number, doubleValue: value);
  }

  static PreferenceValue boolean(bool value) {
    return PreferenceValue(type: PreferenceValueType.boolean, boolValue: value);
  }

  static PreferenceValue list(List<String> value) {
    return PreferenceValue(type: PreferenceValueType.list, listValue: value);
  }

  operator [](String key) {
    switch (key) {
      case 'string':
        return stringValue;
      case 'int':
      case 'integer':
        return intValue;
      case 'double':
      case 'number':
        return doubleValue;
      case 'bool':
      case 'boolean':
        return boolValue;
      case 'list':
        return listValue;
      default:
        return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'stringValue': stringValue,
        'intValue': intValue,
        'doubleValue': doubleValue,
        'boolValue': boolValue,
        'listValue': listValue,
      };

  factory PreferenceValue.fromJson(Map<String, dynamic> json) {
    return PreferenceValue(
      type: PreferenceValueType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PreferenceValueType.string,
      ),
      stringValue: json['stringValue'] as String?,
      intValue: json['intValue'] as int?,
      doubleValue: (json['doubleValue'] as num?)?.toDouble(),
      boolValue: json['boolValue'] as bool?,
      listValue: (json['listValue'] as List<dynamic>?)
          ?.map((v) => v as String)
          .toList(),
    );
  }

  @override
  String toString() {
    switch (type) {
      case PreferenceValueType.string:
        return stringValue ?? '';
      case PreferenceValueType.integer:
        return intValue?.toString() ?? '';
      case PreferenceValueType.number:
        return doubleValue?.toString() ?? '';
      case PreferenceValueType.boolean:
        return boolValue?.toString() ?? '';
      case PreferenceValueType.list:
        return (listValue ?? []).join(', ');
    }
  }
}

enum PreferenceValueType {
  string,
  integer,
  number,
  boolean,
  list,
}

enum PreferenceSource {
  /// Learned from repeated behavior
  implicit,

  /// Explicitly set by user
  explicit,

  /// Imported from another source
  imported,

  /// Default/hint value
  default_,
}

/// Detected routine/pattern
@immutable
class DetectedRoutine {
  /// Unique routine identifier
  final String routineId;

  /// Human-readable name/description
  final String name;

  /// Description of what the routine does
  final String? description;

  /// Pattern of actions in the routine
  final List<RoutineStep> steps;

  /// How frequently this routine is performed
  final int frequency;

  /// Confidence in the detection
  final double confidence;

  /// Days of week this routine typically occurs
  final List<int>? typicalDays;

  /// Typical time of day
  final TimeRange? typicalTime;

  /// Context in which this routine occurs
  final Map<String, dynamic>? context;

  /// Last time this routine was observed
  final DateTime? lastObserved;

  /// First time this routine was detected
  final DateTime detectedAt;

  /// Status of the routine
  final RoutineStatus status;

  const DetectedRoutine({
    required this.routineId,
    required this.name,
    this.description,
    required this.steps,
    required this.frequency,
    required this.confidence,
    this.typicalDays,
    this.typicalTime,
    this.context,
    this.lastObserved,
    required this.detectedAt,
    this.status = RoutineStatus.observed,
  });

  /// Check if this routine is significant (high confidence and frequency)
  bool get isSignificant => confidence >= 0.7 && frequency >= 3;

  /// Check if the routine is ready for automation suggestion
  bool get isReadyForSuggestion =>
      confidence >= 0.8 &&
      frequency >= 5 &&
      status == RoutineStatus.observed;

  /// Create a copy with modified fields
  DetectedRoutine copyWith({
    String? routineId,
    String? name,
    String? description,
    List<RoutineStep>? steps,
    int? frequency,
    double? confidence,
    List<int>? typicalDays,
    TimeRange? typicalTime,
    Map<String, dynamic>? context,
    DateTime? lastObserved,
    DateTime? detectedAt,
    RoutineStatus? status,
  }) {
    return DetectedRoutine(
      routineId: routineId ?? this.routineId,
      name: name ?? this.name,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      frequency: frequency ?? this.frequency,
      confidence: confidence ?? this.confidence,
      typicalDays: typicalDays ?? this.typicalDays,
      typicalTime: typicalTime ?? this.typicalTime,
      context: context ?? this.context,
      lastObserved: lastObserved ?? this.lastObserved,
      detectedAt: detectedAt ?? this.detectedAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'routineId': routineId,
        'name': name,
        'description': description,
        'steps': steps.map((s) => s.toJson()).toList(),
        'frequency': frequency,
        'confidence': confidence,
        'typicalDays': typicalDays,
        'typicalTime': typicalTime?.toJson(),
        'context': context,
        'lastObserved': lastObserved?.toIso8601String(),
        'detectedAt': detectedAt.toIso8601String(),
        'status': status.name,
      };

  factory DetectedRoutine.fromJson(Map<String, dynamic> json) {
    return DetectedRoutine(
      routineId: json['routineId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      steps: (json['steps'] as List<dynamic>)
          .map((s) => RoutineStep.fromJson(s as Map<String, dynamic>))
          .toList(),
      frequency: json['frequency'] as int,
      confidence: (json['confidence'] as num).toDouble(),
      typicalDays: (json['typicalDays'] as List<dynamic>?)
          ?.map((d) => d as int)
          .toList(),
      typicalTime: json['typicalTime'] != null
          ? TimeRange.fromJson(json['typicalTime'] as Map<String, dynamic>)
          : null,
      context: json['context'] as Map<String, dynamic>?,
      lastObserved: json['lastObserved'] != null
          ? DateTime.parse(json['lastObserved'] as String)
          : null,
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      status: RoutineStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RoutineStatus.observed,
      ),
    );
  }

  @override
  String toString() =>
      'DetectedRoutine($name, freq: $frequency, conf: $confidence)';
}

/// A step in a detected routine
@immutable
class RoutineStep {
  /// Action identifier for this step
  final String actionId;

  /// Human-readable name
  final String name;

  /// Step order in the routine
  final int order;

  /// Typical parameters for this step
  final Map<String, dynamic>? typicalParameters;

  /// Whether this step requires confirmation
  final bool requiresConfirmation;

  const RoutineStep({
    required this.actionId,
    required this.name,
    required this.order,
    this.typicalParameters,
    this.requiresConfirmation = false,
  });

  Map<String, dynamic> toJson() => {
        'actionId': actionId,
        'name': name,
        'order': order,
        'typicalParameters': typicalParameters,
        'requiresConfirmation': requiresConfirmation,
      };

  factory RoutineStep.fromJson(Map<String, dynamic> json) {
    return RoutineStep(
      actionId: json['actionId'] as String,
      name: json['name'] as String,
      order: json['order'] as int,
      typicalParameters: json['typicalParameters'] as Map<String, dynamic>?,
      requiresConfirmation: json['requiresConfirmation'] as bool? ?? false,
    );
  }

  @override
  String toString() => 'RoutineStep($actionId, order: $order)';
}

/// Time range for routine occurrence
@immutable
class TimeRange {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const TimeRange({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  Map<String, dynamic> toJson() => {
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
      };

  factory TimeRange.fromJson(Map<String, dynamic> json) {
    return TimeRange(
      startHour: json['startHour'] as int,
      startMinute: json['startMinute'] as int,
      endHour: json['endHour'] as int,
      endMinute: json['endMinute'] as int,
    );
  }

  @override
  String toString() =>
      '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')} - ${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
}

enum RoutineStatus {
  /// Routine has been observed
  observed,

  /// Routine has been suggested to user
  suggested,

  /// User has created automation for this routine
  automated,

  /// Routine detected but requires more observation
  needsMoreData,

  /// Routine was dismissed by user
  dismissed,

  /// Routine is no longer observed (may have changed)
  deprecated,
}

/// Feature usage statistics
@immutable
class FeatureUsageStats {
  final int totalEvents;
  final int totalSessions;
  final int totalFeaturesUsed;
  final List<FeatureUsage> featureUsage;
  final int totalSearches;
  final int totalFiltersApplied;
  final Map<String, int> usageByDayOfWeek;
  final Map<String, int> usageByHour;

  const FeatureUsageStats({
    this.totalEvents = 0,
    this.totalSessions = 0,
    this.totalFeaturesUsed = 0,
    this.featureUsage = const [],
    this.totalSearches = 0,
    this.totalFiltersApplied = 0,
    this.usageByDayOfWeek = const {},
    this.usageByHour = const {},
  });

  /// Get most active day of week
  String? get mostActiveDay {
    if (usageByDayOfWeek.isEmpty) return null;
    return usageByDayOfWeek.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get most active hour
  int? get mostActiveHour {
    if (usageByHour.isEmpty) return null;
    return usageByHour.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key
        .toInt();
  }

  /// Create a copy with modified fields
  FeatureUsageStats copyWith({
    int? totalEvents,
    int? totalSessions,
    int? totalFeaturesUsed,
    List<FeatureUsage>? featureUsage,
    int? totalSearches,
    int? totalFiltersApplied,
    Map<String, int>? usageByDayOfWeek,
    Map<String, int>? usageByHour,
  }) {
    return FeatureUsageStats(
      totalEvents: totalEvents ?? this.totalEvents,
      totalSessions: totalSessions ?? this.totalSessions,
      totalFeaturesUsed: totalFeaturesUsed ?? this.totalFeaturesUsed,
      featureUsage: featureUsage ?? this.featureUsage,
      totalSearches: totalSearches ?? this.totalSearches,
      totalFiltersApplied: totalFiltersApplied ?? this.totalFiltersApplied,
      usageByDayOfWeek: usageByDayOfWeek ?? this.usageByDayOfWeek,
      usageByHour: usageByHour ?? this.usageByHour,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalEvents': totalEvents,
        'totalSessions': totalSessions,
        'totalFeaturesUsed': totalFeaturesUsed,
        'featureUsage': featureUsage.map((f) => f.toJson()).toList(),
        'totalSearches': totalSearches,
        'totalFiltersApplied': totalFiltersApplied,
        'usageByDayOfWeek': usageByDayOfWeek,
        'usageByHour': usageByHour,
      };

  factory FeatureUsageStats.fromJson(Map<String, dynamic> json) {
    return FeatureUsageStats(
      totalEvents: json['totalEvents'] as int? ?? 0,
      totalSessions: json['totalSessions'] as int? ?? 0,
      totalFeaturesUsed: json['totalFeaturesUsed'] as int? ?? 0,
      featureUsage: (json['featureUsage'] as List<dynamic>?)
          ?.map((f) => FeatureUsage.fromJson(f as Map<String, dynamic>))
          .toList() ??
          [],
      totalSearches: json['totalSearches'] as int? ?? 0,
      totalFiltersApplied: json['totalFiltersApplied'] as int? ?? 0,
      usageByDayOfWeek: (json['usageByDayOfWeek'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      usageByHour: (json['usageByHour'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
    );
  }
}

/// Usage statistics for a single feature
@immutable
class FeatureUsage {
  final String featureId;
  final String featureName;
  final int count;
  final int totalDurationMs;
  final DateTime? lastUsed;

  const FeatureUsage({
    required this.featureId,
    required this.featureName,
    required this.count,
    this.totalDurationMs = 0,
    this.lastUsed,
  });

  /// Average duration per use
  double get averageDurationMs =>
      count > 0 ? totalDurationMs / count : 0;

  FeatureUsage copyWith({
    String? featureId,
    String? featureName,
    int? count,
    int? totalDurationMs,
    DateTime? lastUsed,
  }) {
    return FeatureUsage(
      featureId: featureId ?? this.featureId,
      featureName: featureName ?? this.featureName,
      count: count ?? this.count,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  Map<String, dynamic> toJson() => {
        'featureId': featureId,
        'featureName': featureName,
        'count': count,
        'totalDurationMs': totalDurationMs,
        'lastUsed': lastUsed?.toIso8601String(),
      };

  factory FeatureUsage.fromJson(Map<String, dynamic> json) {
    return FeatureUsage(
      featureId: json['featureId'] as String,
      featureName: json['featureName'] as String,
      count: json['count'] as int,
      totalDurationMs: json['totalDurationMs'] as int? ?? 0,
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : null,
    );
  }

  @override
  String toString() =>
      'FeatureUsage($featureName: $count times, ${averageDurationMs.toStringAsFixed(0)}ms avg)';
}

/// Aggregated summary of recent activity
@immutable
class ActivitySummary {
  final DateTime date;
  final int totalEvents;
  final int distinctFeaturesUsed;
  final List<String> topFeatures;
  final bool hadSignificantActions;

  const ActivitySummary({
    required this.date,
    required this.totalEvents,
    required this.distinctFeaturesUsed,
    this.topFeatures = const [],
    this.hadSignificantActions = false,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'totalEvents': totalEvents,
        'distinctFeaturesUsed': distinctFeaturesUsed,
        'topFeatures': topFeatures,
        'hadSignificantActions': hadSignificantActions,
      };

  factory ActivitySummary.fromJson(Map<String, dynamic> json) {
    return ActivitySummary(
      date: DateTime.parse(json['date'] as String),
      totalEvents: json['totalEvents'] as int,
      distinctFeaturesUsed: json['distinctFeaturesUsed'] as int,
      topFeatures: (json['topFeatures'] as List<dynamic>?)
          ?.map((f) => f as String)
          .toList() ??
          [],
      hadSignificantActions: json['hadSignificantActions'] as bool? ?? false,
    );
  }
}

/// Profile configuration
@immutable
class ProfileConfig {
  /// Whether personalization is enabled
  final bool personalizationEnabled;

  /// How long to retain activity data (default 90 days)
  final Duration dataRetention;

  /// Minimum confidence for accepting a detected pattern
  final double minPatternConfidence;

  /// Minimum frequency for detecting a routine
  final int minRoutineFrequency;

  /// Whether to use anonymized data for improvement
  final bool allowAnonymizedUsage;

  /// Maximum number of stored routines
  final int maxRoutines;

  /// Maximum number of stored preferences
  final int maxPreferences;

  const ProfileConfig({
    this.personalizationEnabled = true,
    this.dataRetention = const Duration(days: 90),
    this.minPatternConfidence = 0.7,
    this.minRoutineFrequency = 3,
    this.allowAnonymizedUsage = false,
    this.maxRoutines = 50,
    this.maxPreferences = 100,
  });

  ProfileConfig copyWith({
    bool? personalizationEnabled,
    Duration? dataRetention,
    double? minPatternConfidence,
    int? minRoutineFrequency,
    bool? allowAnonymizedUsage,
    int? maxRoutines,
    int? maxPreferences,
  }) {
    return ProfileConfig(
      personalizationEnabled:
          personalizationEnabled ?? this.personalizationEnabled,
      dataRetention: dataRetention ?? this.dataRetention,
      minPatternConfidence:
          minPatternConfidence ?? this.minPatternConfidence,
      minRoutineFrequency:
          minRoutineFrequency ?? this.minRoutineFrequency,
      allowAnonymizedUsage:
          allowAnonymizedUsage ?? this.allowAnonymizedUsage,
      maxRoutines: maxRoutines ?? this.maxRoutines,
      maxPreferences: maxPreferences ?? this.maxPreferences,
    );
  }

  Map<String, dynamic> toJson() => {
        'personalizationEnabled': personalizationEnabled,
        'dataRetention': dataRetention.inDays,
        'minPatternConfidence': minPatternConfidence,
        'minRoutineFrequency': minRoutineFrequency,
        'allowAnonymizedUsage': allowAnonymizedUsage,
        'maxRoutines': maxRoutines,
        'maxPreferences': maxPreferences,
      };

  factory ProfileConfig.fromJson(Map<String, dynamic> json) {
    return ProfileConfig(
      personalizationEnabled:
          json['personalizationEnabled'] as bool? ?? true,
      dataRetention: Duration(days: json['dataRetention'] as int? ?? 90),
      minPatternConfidence:
          (json['minPatternConfidence'] as num?)?.toDouble() ?? 0.7,
      minRoutineFrequency: json['minRoutineFrequency'] as int? ?? 3,
      allowAnonymizedUsage:
          json['allowAnonymizedUsage'] as bool? ?? false,
      maxRoutines: json['maxRoutines'] as int? ?? 50,
      maxPreferences: json['maxPreferences'] as int? ?? 100,
    );
  }

  @override
  String toString() =>
      'ProfileConfig(enabled: $personalizationEnabled, retention: ${dataRetention.inDays}d)';
}

/// Profile Manager - manages user profile storage and retrieval
class ProfileManager {
  ProfileConfig _config;

  UserProfile? _cachedProfile;
  DateTime? _lastLoadTime;

  ProfileManager({ProfileConfig? config})
      : _config = config ?? const ProfileConfig();

  /// Get the current user profile
  Future<UserProfile> getUserProfile() async {
    // In a real implementation, this would load from local storage
    // For now, return a default profile

    if (_cachedProfile != null &&
        _lastLoadTime != null &&
        DateTime.now().difference(_lastLoadTime!) < const Duration(minutes: 5)) {
      return _cachedProfile!;
    }

    // Load or create profile
    _cachedProfile = await _loadOrCreateProfile();
    _lastLoadTime = DateTime.now();

    return _cachedProfile!;
  }

  /// Load or create the user profile
  Future<UserProfile> _loadOrCreateProfile() async {
    // In a real implementation, this would use local storage
    // Return a new profile for demonstration

    return UserProfile(
      profileId: 'user_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      config: _config,
    );
  }

  /// Update user preferences
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    final profile = await getUserProfile();

    final newPreferences = <String, Preference>{};
    for (final entry in profile.preferences.entries) {
      newPreferences[entry.key] = entry.value;
    }

    for (final entry in preferences.entries) {
      final key = entry.key;
      final value = entry.value;

      PreferenceValue prefValue;
      if (value is String) {
        prefValue = PreferenceValue.string(value);
      } else if (value is int) {
        prefValue = PreferenceValue.integer(value);
      } else if (value is double) {
        prefValue = PreferenceValue.number(value);
      } else if (value is bool) {
        prefValue = PreferenceValue.boolean(value);
      } else if (value is List) {
        prefValue = PreferenceValue.list(value.cast());
      } else {
        prefValue = PreferenceValue.string(value.toString());
      }

      final existing = profile.preferences[key];
      if (existing != null) {
        newPreferences[key] = existing.copyWith(
          value: prefValue,
          confidence: (existing.confidence + 0.1).clamp(0, 1),
          confirmationCount: existing.confirmationCount + 1,
          lastUsed: DateTime.now(),
        );
      } else if (newPreferences.length < _config.maxPreferences) {
        newPreferences[key] = Preference(
          key: key,
          name: key,
          value: prefValue,
          confidence: 0.5,
          detectedAt: DateTime.now(),
          source: PreferenceSource.explicit,
        );
      }
    }

    // Save updated profile
    // await _saveProfile(profile.copyWith(preferences: newPreferences));
    _cachedProfile = profile.copyWith(preferences: newPreferences);
  }

  /// Clear all personalization data
  Future<void> clearAllData() async {
    // In a real implementation, this would delete stored data
    _cachedProfile = UserProfile(
      profileId: 'user_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      config: _config,
    );
    _lastLoadTime = DateTime.now();
  }

  /// Check if personalization is enabled
  bool get isPersonalizationEnabled => _config.personalizationEnabled;

  /// Enable or disable personalization
  void setPersonalizationEnabled(bool enabled) {
    _config = _config.copyWith(personalizationEnabled: enabled);
  }

  /// Update profile configuration
  void updateConfig(ProfileConfig config) {
    _config = config;
  }

  /// Get profile configuration
  ProfileConfig get config => _config;

  /// Get cached profile (without loading)
  UserProfile? get cachedProfile => _cachedProfile;
}
