/// Personalization Engine
///
/// Learns permitted routines and preferences from user interactions.
/// Layer 2 of the personalization system - pattern detection and preference learning.

import 'activity_event.dart';
import 'profile_manager.dart';
import '../core/types.dart' show HealthStatus, PrivacyMode, TaskType;

/// Personalization engine that learns from user activity
class PersonalizationEngine {
  final ProfileManager profileManager;
  final PrivacyMode privacyMode;

  // Activity buffer for pattern detection
  final List<ActivityEvent> _recentActivity = [];
  final int _maxRecentActivity;

  // Debouncing for pattern updates
  DateTime? _lastPatternUpdate;
  static const Duration _patternUpdateInterval = Duration(minutes: 1);

  PersonalizationEngine({
    required this.profileManager,
    this.privacyMode = PrivacyMode.localFirst,
    int maxRecentActivity = 1000,
  }) : _maxRecentActivity = maxRecentActivity;

  /// Record an activity event
  Future<void> recordActivity(ActivityEvent event) async {
    // Apply privacy filter
    final filteredEvent = _applyPrivacyFilter(event);

    // Add to recent activity
    _recentActivity.add(filteredEvent);

    // Trim old activities
    if (_recentActivity.length > _maxRecentActivity) {
      _recentActivity.removeAt(0);
    }

    // Update usage statistics
    await _updateUsageStats(filteredEvent);

    // Check for patterns periodically
    await _maybeUpdatePatterns();
  }

  /// Apply privacy filter to event
  ActivityEvent _applyPrivacyFilter(ActivityEvent event) {
    if (privacyMode == PrivacyMode.localOnly) {
      // Strip any data that shouldn't be stored
      return event.toSimplified();
    }
    return event;
  }

  /// Update usage statistics from event
  Future<void> _updateUsageStats(ActivityEvent event) async {
    final profile = await profileManager.getUserProfile();

    var stats = profile.usageStats;

    // Update totals
    stats = stats.copyWith(
      totalEvents: stats.totalEvents + 1,
    );

    // Update by day of week
    final dayOfWeek = DateTime.now().weekday.toString();
    final dayStats = Map<String, int>.from(stats.usageByDayOfWeek);
    dayStats[dayOfWeek] = (dayStats[dayOfWeek] ?? 0) + 1;

    // Update by hour
    final hour = DateTime.now().hour.toString();
    final hourStats = Map<String, int>.from(stats.usageByHour);
    hourStats[hour] = (hourStats[hour] ?? 0) + 1;

    // Update feature usage
    List<FeatureUsage> featureUsage = List.from(stats.featureUsage);

    if (event.eventType == ActivityEventType.featureUsage ||
        event.eventType == ActivityEventType.taskExecution) {
      final featureId = event.actionId ?? event.taskType?.name ?? 'unknown';
      final featureName =
          event.context['featureName'] as String? ?? featureId;

      final existingIndex = featureUsage.indexWhere(
        (f) => f.featureId == featureId,
      );

      if (existingIndex >= 0) {
        final existing = featureUsage[existingIndex];
        featureUsage[existingIndex] = existing.copyWith(
          count: existing.count + 1,
          totalDurationMs: existing.totalDurationMs + event.durationMs,
          lastUsed: DateTime.now(),
        );
      } else if (featureUsage.length < 100) {
        featureUsage.add(FeatureUsage(
          featureId: featureId,
          featureName: featureName,
          count: 1,
          totalDurationMs: event.durationMs,
          lastUsed: DateTime.now(),
        ));
      }
    }

    // Update searches/filters
    if (event.eventType == ActivityEventType.search) {
      stats = stats.copyWith(totalSearches: stats.totalSearches + 1);
    }
    if (event.eventType == ActivityEventType.filterApplied) {
      stats = stats.copyWith(totalFiltersApplied: stats.totalFiltersApplied + 1);
    }

    stats = stats.copyWith(
      featureUsage: featureUsage,
      usageByDayOfWeek: dayStats,
      usageByHour: hourStats,
    );

    await profileManager.updatePreferences({
      'totalEvents': stats.totalEvents,
      'totalSessions': stats.totalSessions,
    });
  }

  /// Maybe update patterns (debounced)
  Future<void> _maybeUpdatePatterns() async {
    final now = DateTime.now();

    if (_lastPatternUpdate == null) {
      _lastPatternUpdate = now;
      await _updatePatterns();
      return;
    }

    if (now.difference(_lastPatternUpdate!) >= _patternUpdateInterval) {
      _lastPatternUpdate = now;
      await _updatePatterns();
    }
  }

  /// Update detected patterns from recent activity
  Future<void> _updatePatterns() async {
    final profile = await profileManager.getUserProfile();

    // Detect sequential patterns (routines)
    final sequences = _detectSequentialPatterns();

    // Detect temporal patterns (time-based routines)
    final temporalPatterns = _detectTemporalPatterns();

    // Detect feature usage patterns
    final usagePatterns = _detectUsagePatterns();

    // Merge new patterns with existing
    final existingRoutines = Map<String, DetectedRoutine>.from(
      profile.routines.fold<Map<String, DetectedRoutine>>(
        {},
        (map, r) => map..[r.routineId] = r,
      ),
    );

    // Update existing routines with new observations
    for (final seq in sequences) {
      final key = seq['key'] as String;
      if (existingRoutines.containsKey(key)) {
        final existing = existingRoutines[key]!;
        existingRoutines[key] = existing.copyWith(
          frequency: existing.frequency + 1,
          confidence: (existing.confidence * 0.9 +
                  (seq['confidence'] as double) * 0.1)
              .clamp(0, 1),
          lastObserved: DateTime.now(),
          status: RoutineStatus.observed,
        );
      } else {
        existingRoutines[key] = DetectedRoutine(
          routineId: key,
          name: seq['name'] as String,
          description: seq['description'] as String?,
          steps: seq['steps'] as List<RoutineStep>,
          frequency: 1,
          confidence: seq['confidence'] as double,
          detectedAt: DateTime.now(),
          lastObserved: DateTime.now(),
          status: RoutineStatus.needsMoreData,
        );
      }
    }

    // Add temporal patterns
    for (final pattern in temporalPatterns) {
      final key = pattern['key'] as String;
      if (!existingRoutines.containsKey(key)) {
        existingRoutines[key] = DetectedRoutine(
          routineId: key,
          name: pattern['name'] as String,
          description: pattern['description'] as String?,
          steps: pattern['steps'] as List<RoutineStep>? ?? [],
          frequency: pattern['frequency'] as int,
          confidence: pattern['confidence'] as double,
          typicalDays: pattern['typicalDays'] as List<int>?,
          typicalTime: pattern['typicalTime'] as TimeRange?,
          detectedAt: DateTime.now(),
          status: RoutineStatus.observed,
        );
      }
    }

    // Add feature usage patterns
    for (final pattern in usagePatterns) {
      final key = pattern['key'] as String;
      existingRoutines.putIfAbsent(
        key,
        () => DetectedRoutine(
          routineId: key,
          name: pattern['name'] as String,
          description: pattern['description'] as String?,
          steps: (pattern['steps'] as List<RoutineStep>?) ?? const [],
          frequency: pattern['frequency'] as int,
          confidence: pattern['confidence'] as double,
          detectedAt: DateTime.now(),
          status: RoutineStatus.observed,
        ),
      );
    }

    // Limit number of routines
    final maxRoutines = profile.config.maxRoutines;
    final sortedRoutines = existingRoutines.values.toList()
      ..sort((a, b) => b.frequency.compareTo(a.frequency));

    final updatedRoutines = sortedRoutines.length > maxRoutines
        ? sortedRoutines.take(maxRoutines).toList()
        : sortedRoutines;

    // Save updated profile
    await profileManager.updatePreferences({
      'routines_count': updatedRoutines.length,
    });
  }

  /// Detect sequential patterns in activity
  List<Map<String, dynamic>> _detectSequentialPatterns() {
    final patterns = <Map<String, dynamic>>[];

    if (_recentActivity.length < 2) return patterns;

    // Look for repeated sequences of actions
    final actionSequence = _recentActivity
        .where((e) =>
            e.eventType == ActivityEventType.featureUsage ||
            e.eventType == ActivityEventType.taskExecution)
        .map((e) => e.actionId ?? e.taskType?.name ?? 'unknown')
        .toList();

    // Check for 2-3 action sequences
    for (var seqLength = 2; seqLength <= 3 && seqLength <= actionSequence.length; seqLength++) {
      final sequenceCounts = <String, int>{};

      for (var i = 0; i <= actionSequence.length - seqLength; i++) {
        final sequence = actionSequence.sublist(i, i + seqLength);
        final key = sequence.join(' -> ');

        sequenceCounts[key] = (sequenceCounts[key] ?? 0) + 1;
      }

      // Find sequences that occur multiple times
      for (final entry in sequenceCounts.entries) {
        if (entry.value >= profileManager.config.minRoutineFrequency) {
          // Calculate confidence based on frequency
          final confidence = (entry.value /
                  (_recentActivity.length - seqLength + 1))
              .clamp(0, 1);

          if (confidence >= profileManager.config.minPatternConfidence) {
            final actions = entry.key.split(' -> ');
            patterns.add({
              'key': 'seq_${entry.key.hashCode}',
              'name': 'Repeated sequence: ${actions.join(' → ')}',
              'description': 'This sequence of actions is performed repeatedly',
              'steps': actions.asMap().entries.map((e) {
                return RoutineStep(
                  actionId: e.value,
                  name: e.value,
                  order: e.key,
                );
              }).toList(),
              'frequency': entry.value,
              'confidence': confidence,
            });
          }
        }
      }
    }

    return patterns;
  }

  /// Detect temporal patterns (time-based routines)
  List<Map<String, dynamic>> _detectTemporalPatterns() {
    final patterns = <Map<String, dynamic>>[];

    if (_recentActivity.length < 5) return patterns;

    // Group activities by time of day
    final timeBuckets = <String, List<ActivityEvent>>{};

    for (final event in _recentActivity) {
      final hour = event.timestamp.hour;
      final bucket =
          '${hour ~/ 3 * 3}-${(hour ~/ 3 * 3) + 2} (${hour < 12 ? 'AM' : 'PM'})';

      timeBuckets.putIfAbsent(bucket, () => []).add(event);
    }

    // Find time periods with high activity
    for (final entry in timeBuckets.entries) {
      if (entry.value.length >= 5) {
        final confidence = (entry.value.length / _recentActivity.length).clamp(0, 1);

        if (confidence >= 0.1) {
          // Check which features are used most in this time period
          final featureCounts = <String, int>{};
          for (final event in entry.value) {
            final feature = event.actionId ?? event.taskType?.name ?? 'unknown';
            featureCounts[feature] = (featureCounts[feature] ?? 0) + 1;
          }

          final topFeatures = featureCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          patterns.add({
            'key': 'time_${entry.key.hashCode}',
            'name': 'Active during ${entry.key}',
            'description': 'You are frequently active during this time period',
            'steps': topFeatures.take(3).map((f) {
              return RoutineStep(
                actionId: f.key,
                name: f.key,
                order: 0,
              );
            }).toList(),
            'frequency': entry.value.length,
            'confidence': confidence,
            'typicalDays': _getTypicalDays(entry.value),
            'typicalTime': _parseTimeRange(entry.key),
          });
        }
      }
    }

    return patterns;
  }

  /// Get typical days for a set of events
  List<int>? _getTypicalDays(List<ActivityEvent> events) {
    if (events.isEmpty) return null;

    final dayCounts = <int, int>{};
    for (final event in events) {
      final day = event.timestamp.weekday;
      dayCounts[day] = (dayCounts[day] ?? 0) + 1;
    }

    // Return days with significant activity
    final avg = events.length / 7;
    return dayCounts.entries
        .where((e) => e.value > avg)
        .map((e) => e.key)
        .toList()
      ..sort();
  }

  /// Parse time range string to TimeRange
  TimeRange? _parseTimeRange(String range) {
    // Parse "0-2 (AM)" or "15-17 (PM)" format
    final match = RegExp(r'(\d+)-(\d+)\s*(AM|PM)').firstMatch(range);
    if (match == null) return null;

    int startHour = int.parse(match.group(1)!);
    final endHour = int.parse(match.group(2)!);
    final period = match.group(3)!;

    if (period == 'PM' && startHour < 12) startHour += 12;

    return TimeRange(
      startHour: startHour,
      startMinute: 0,
      endHour: endHour < startHour ? endHour + 12 : endHour,
      endMinute: 59,
    );
  }

  /// Detect usage patterns
  List<Map<String, dynamic>> _detectUsagePatterns() {
    final patterns = <Map<String, dynamic>>[];

    final profile = profileManager.cachedProfile;
    if (profile == null) return patterns;

    // Detect frequently used features
    final sortedFeatures = profile.getMostUsedFeatures(limit: 5);

    for (final feature in sortedFeatures) {
      if (feature.count >= 5) {
        // Check if this feature is used at specific times
        final featureEvents = _recentActivity
            .where((e) =>
                (e.actionId == feature.featureId ||
                    e.taskType?.name == feature.featureId) &&
                e.timestamp.isAfter(
                  DateTime.now().subtract(const Duration(days: 30)),
                ))
            .toList();

        if (featureEvents.length >= 3) {
          patterns.add({
            'key': 'usage_${feature.featureId}_${DateTime.now().millisecondsSinceEpoch}',
            'name': 'Frequent use of ${feature.featureName}',
            'description':
                'You use ${feature.featureName} frequently (${(feature.count)} times)',
            'steps': [
              RoutineStep(
                actionId: feature.featureId,
                name: feature.featureName,
                order: 0,
              )
            ],
            'frequency': feature.count,
            'confidence': (feature.count / profile.totalUsageCount).clamp(0, 1),
          });
        }
      }
    }

    return patterns;
  }

  /// Get task context for a specific task type
  Future<Map<String, dynamic>> getTaskContext({
    required TaskType taskType,
    Map<String, dynamic>? userContext,
  }) async {
    final context = <String, dynamic>{};

    final profile = await profileManager.getUserProfile();

    // Add preference info if relevant
    context['preferences'] = profile.preferences;

    // Add recent activity summary
    context['recentActivity'] = profile.recentActivity.take(10).toList();

    // Add usage patterns
    context['topFeatures'] =
        profile.getMostUsedFeatures(limit: 5).map((f) => f.featureName).toList();

    // Add detected routines
    context['routines'] =
        profile.getMostFrequentRoutines(limit: 3).map((r) => r.name).toList();

    // Add user context if provided
    if (userContext != null) {
      context['userContext'] = userContext;
    }

    return context;
  }

  /// Get the user profile
  Future<UserProfile> getUserProfile() async {
    return profileManager.getUserProfile();
  }

  /// Check health of the personalization engine
  Future<HealthStatus> checkHealth() async {
    try {
      final profile = await getUserProfile();
      return profile.isEmpty
          ? HealthStatus.degraded
          : HealthStatus.healthy;
    } catch (e) {
      return HealthStatus.unhealthy('Personalization engine failure');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    _recentActivity.clear();
  }

  /// Get recent activity count
  int get recentActivityCount => _recentActivity.length;

  /// Clear recent activity (without clearing profile)
  void clearRecentActivity() {
    _recentActivity.clear();
  }

}
