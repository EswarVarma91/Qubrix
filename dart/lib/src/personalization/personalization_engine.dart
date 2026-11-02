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
  int _eventsSincePatternUpdate = 0;
  static const int _patternUpdateEventThreshold = 5;

  PersonalizationEngine({
    required this.profileManager,
    this.privacyMode = PrivacyMode.localFirst,
    int maxRecentActivity = 1000,
  }) : _maxRecentActivity = maxRecentActivity;

  /// Record an activity event.
  ///
  /// This is the SDK's listening entry point: every interaction the host app
  /// reports flows through here, which is what lets the engine learn the
  /// routines a user repeats and turn them into automations.
  Future<void> recordActivity(ActivityEvent event) async {
    if (!profileManager.isPersonalizationEnabled) return;

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
        event.eventType == ActivityEventType.taskExecution ||
        event.eventType == ActivityEventType.workflowStart ||
        event.eventType == ActivityEventType.workflowCompletion) {
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
      totalFeaturesUsed: featureUsage.length,
    );

    // Persist the statistics on the profile. These used to be dropped, so
    // feature usage never reached the recommendation or automation layers.
    await profileManager.updateUsageStats(stats);
  }

  /// Maybe update patterns.
  ///
  /// Detection is time debounced, but also runs after every
  /// [_patternUpdateEventThreshold] recorded events so a burst of activity in a
  /// single session is learned immediately instead of waiting a minute.
  Future<void> _maybeUpdatePatterns() async {
    _eventsSincePatternUpdate++;
    final now = DateTime.now();
    final intervalElapsed = _lastPatternUpdate == null ||
        now.difference(_lastPatternUpdate!) >= _patternUpdateInterval;

    if (!intervalElapsed &&
        _eventsSincePatternUpdate < _patternUpdateEventThreshold) {
      return;
    }

    _lastPatternUpdate = now;
    _eventsSincePatternUpdate = 0;
    await _updatePatterns();
  }

  /// Update detected patterns from recent activity and persist the result.
  Future<void> _updatePatterns() async {
    final profile = await profileManager.getUserProfile();
    if (!profile.config.personalizationEnabled) return;

    final routines = <String, DetectedRoutine>{
      for (final routine in profile.routines) routine.routineId: routine,
    };

    // Repeated action sequences (routines).
    for (final sequence in _detectSequentialPatterns(profile.config)) {
      _mergeRoutine(routines, sequence);
    }

    // Time-based habits.
    for (final temporal in _detectTemporalPatterns()) {
      _mergeRoutine(routines, temporal);
    }

    // Single actions the user repeats a lot.
    for (final usage in _detectUsagePatterns(profile)) {
      _mergeRoutine(routines, usage);
    }

    final sorted = routines.values.toList()
      ..sort((a, b) => b.frequency.compareTo(a.frequency));

    final limited = sorted.length > profile.config.maxRoutines
        ? sorted.take(profile.config.maxRoutines).toList()
        : sorted;

    // Persist routines, otherwise they are lost with the activity buffer.
    await profileManager.updateRoutines(limited);
  }

  /// Merge a freshly detected pattern into the routine map.
  ///
  /// Detection always runs over the whole activity window, so observation
  /// counts are compared rather than accumulated (accumulating would double
  /// count every pattern on each detection run).
  void _mergeRoutine(
    Map<String, DetectedRoutine> routines,
    Map<String, dynamic> pattern,
  ) {
    final key = pattern['key'] as String;
    final observed = (pattern['frequency'] as num?)?.toInt() ?? 1;
    final confidence =
        ((pattern['confidence'] as num?) ?? 0).toDouble().clamp(0.0, 1.0);
    final steps = pattern['steps'] as List<RoutineStep>?;
    final existing = routines[key];

    if (existing == null) {
      routines[key] = DetectedRoutine(
        routineId: key,
        name: pattern['name'] as String,
        description: pattern['description'] as String?,
        steps: steps ?? const [],
        frequency: observed,
        confidence: confidence,
        typicalDays: pattern['typicalDays'] as List<int>?,
        typicalTime: pattern['typicalTime'] as TimeRange?,
        detectedAt: DateTime.now(),
        lastObserved: DateTime.now(),
        status: RoutineStatus.observed,
      );
      return;
    }

    // Never reset a routine the user already automated or dismissed.
    final keepStatus = existing.status == RoutineStatus.automated ||
        existing.status == RoutineStatus.dismissed;

    routines[key] = existing.copyWith(
      steps: existing.steps.isNotEmpty ? existing.steps : steps,
      frequency:
          observed > existing.frequency ? observed : existing.frequency,
      confidence:
          confidence > existing.confidence ? confidence : existing.confidence,
      typicalDays: existing.typicalDays ?? pattern['typicalDays'] as List<int>?,
      typicalTime: existing.typicalTime ?? pattern['typicalTime'] as TimeRange?,
      lastObserved: DateTime.now(),
      status: keepStatus ? existing.status : RoutineStatus.observed,
    );
  }

  /// Detect repeated sequences of user actions.
  ///
  /// A sequence becomes a routine once it is repeated at least
  /// [ProfileConfig.minRoutineFrequency] times. Confidence grows with the
  /// number of repetitions (3 repeats -> 0.75, 5 -> 0.83, 10 -> 0.91).
  List<Map<String, dynamic>> _detectSequentialPatterns(ProfileConfig config) {
    final patterns = <Map<String, dynamic>>[];

    final actionSequence = _recentActivity
        .where(_isRoutineEvent)
        .map(_actionIdOf)
        .toList();

    if (actionSequence.length < 2) return patterns;

    final acceptedKeys = <String>[];

    // Longest sequences first so a shorter fragment of the same routine is not
    // reported as a second routine.
    for (var seqLength = 3; seqLength >= 2; seqLength--) {
      if (seqLength > actionSequence.length) continue;

      final sequenceCounts = <String, int>{};
      for (var i = 0; i <= actionSequence.length - seqLength; i++) {
        final sequence = actionSequence.sublist(i, i + seqLength);
        final key = sequence.join(' -> ');
        sequenceCounts[key] = (sequenceCounts[key] ?? 0) + 1;
      }

      for (final entry in sequenceCounts.entries) {
        if (entry.value < config.minRoutineFrequency) continue;

        final actions = entry.key.split(' -> ');

        // Repeating one action is captured by the shorter sequence.
        if (seqLength > 2 && actions.toSet().length == 1) continue;

        // Skip fragments of a longer routine that was already accepted.
        if (acceptedKeys.any((key) => key.contains(entry.key))) continue;

        final confidence = entry.value / (entry.value + 1);
        if (confidence < config.minPatternConfidence) continue;

        acceptedKeys.add(entry.key);
        patterns.add({
          'key': 'seq_${actions.map(_slug).join('_')}',
          'name': 'Repeated sequence: ${actions.join(' → ')}',
          'description': 'This sequence of ${actions.length} actions was '
              'performed ${entry.value} times and can be automated.',
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

    return patterns;
  }

  /// Whether an event participates in routine detection.
  bool _isRoutineEvent(ActivityEvent event) {
    return event.eventType == ActivityEventType.featureUsage ||
        event.eventType == ActivityEventType.taskExecution ||
        event.eventType == ActivityEventType.workflowStart ||
        event.eventType == ActivityEventType.workflowCompletion;
  }

  /// The action identity used for routine detection.
  String _actionIdOf(ActivityEvent event) {
    return event.actionId ?? event.taskType?.name ?? event.taskId ?? 'unknown';
  }

  /// Stable identifier fragment for routine ids.
  String _slug(String value) {
    final slug = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return slug.isEmpty ? 'unknown' : slug;
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
        final confidence =
            (entry.value.length / _recentActivity.length).clamp(0.0, 1.0);

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
            'key': 'time_${_slug(entry.key)}',
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

  /// Detect single actions the user repeats a lot.
  List<Map<String, dynamic>> _detectUsagePatterns(UserProfile profile) {
    final patterns = <Map<String, dynamic>>[];

    for (final feature in profile.getMostUsedFeatures(limit: 5)) {
      if (feature.count < 5) continue;

      patterns.add({
        'key': 'usage_${_slug(feature.featureId)}',
        'name': 'Frequent use of ${feature.featureName}',
        'description': 'You used ${feature.featureName} ' 
            '${feature.count} times; it can be automated as a shortcut.',
        'steps': [
          RoutineStep(
            actionId: feature.featureId,
            name: feature.featureName,
            order: 0,
          )
        ],
        'frequency': feature.count,
        // Repeated use of a single action is a confident habit.
        'confidence': 1.0,
      });
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
