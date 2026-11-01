/// Recommendation Engine
///
/// Suggests useful actions based on context and learned patterns.
/// Layer 3 of the personalization system - AI interpretation and suggestion.

import 'package:flutter/foundation.dart';
import 'personalization_engine.dart';
import 'profile_manager.dart';
import '../automation/action_registry.dart';

/// Recommendation configuration
class RecommendationConfig {
  /// Whether to use personalization for recommendations
  final bool usePersonalization;

  /// Whether to use context for recommendations
  final bool useContext;

  /// Maximum number of recommendations to generate
  final int maxRecommendations;

  /// Minimum confidence threshold for recommendations
  final double minConfidence;

  /// Whether to include suggestions based on routines
  final bool includeRoutineBased;

  /// Whether to include suggestions based on feature usage
  final bool includeFeatureBased;

  /// Frequency limit - minimum interval between same recommendation
  final Duration recommendationCooldown;

  const RecommendationConfig({
    this.usePersonalization = true,
    this.useContext = true,
    this.maxRecommendations = 5,
    this.minConfidence = 0.5,
    this.includeRoutineBased = true,
    this.includeFeatureBased = true,
    this.recommendationCooldown = const Duration(hours: 1),
  });
}

/// A recommendation for the user
@immutable
class Recommendation {
  /// Unique recommendation ID
  final String id;

  /// Type of recommendation
  final RecommendationType type;

  /// Title/headline
  final String title;

  /// Description of what's being recommended
  final String description;

  /// The action to take if accepted
  final String? actionId;

  /// Parameters for the action
  final Map<String, dynamic>? actionParameters;

  /// Confidence score (0-1)
  final double confidence;

  /// Why this recommendation was made
  final List<String> reasons;

  /// Context that triggered this recommendation
  final Map<String, dynamic>? context;

  /// When this recommendation was generated
  final DateTime generatedAt;

  /// How many times this recommendation has been shown
  final int timesShown;

  /// How many times this recommendation has been accepted
  final int timesAccepted;

  /// How many times this recommendation has been dismissed
  final int timesDismissed;

  /// Whether this recommendation is currently active
  final bool isActive;

  /// Suggested action text
  final String? suggestedAction;

  /// Category for grouping
  final String? category;

  Recommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.actionId,
    this.actionParameters,
    required this.confidence,
    this.reasons = const [],
    this.context,
    DateTime? generatedAt,
    this.timesShown = 0,
    this.timesAccepted = 0,
    this.timesDismissed = 0,
    this.isActive = true,
    this.suggestedAction,
    this.category,
  }) : generatedAt = generatedAt ?? DateTime.now();

  /// Acceptance rate
  double get acceptanceRate =>
      timesShown > 0 ? timesAccepted / timesShown : 0;

  /// Dismissal rate
  double get dismissalRate =>
      timesShown > 0 ? timesDismissed / timesShown : 0;

  /// Net score (acceptance - dismissal)
  double get netScore =>
      timesShown > 0 ? (timesAccepted - timesDismissed) / timesShown : 0;

  /// Check if this recommendation should be shown again
  bool get canBeReshown {
    if (!isActive) return false;
    if (timesDismissed > timesShown * 0.7) return false; // Too many dismissals
    return true;
  }

  /// Suggest reordering a product based on a routine.
  static Recommendation reorderSuggestion({
    required String productId,
    required String productName,
    required int typicalQuantity,
    String? scheduledTime,
  }) {
    return Recommendation(
      id: 'reorder_$productId',
      type: RecommendationType.routineBased,
      title: 'Time to reorder $productName?',
      description:
          'You usually reorder this product. Would you like to add it to your cart?',
      actionId: 'add_to_cart',
      actionParameters: {
        'productId': productId,
        'quantity': typicalQuantity,
      },
      confidence: 0.8,
      reasons: [
        'Based on your reordering pattern',
        'Typical quantity: $typicalQuantity',
        if (scheduledTime != null) 'Scheduled for: $scheduledTime',
      ],
      category: 'shopping',
      suggestedAction: 'Add to cart',
    );
  }

  /// Suggest creating a shortcut for a repeated workflow.
  static Recommendation shortcutSuggestion({
    required String workflowName,
    required List<String> actionIds,
    required int frequency,
  }) {
    return Recommendation(
      id: 'shortcut_$workflowName',
      type: RecommendationType.automation,
      title: 'Create a shortcut for "$workflowName"?',
      description:
          'You perform this workflow frequently. A shortcut can save time.',
      actionId: 'create_shortcut',
      actionParameters: {
        'workflowName': workflowName,
        'actionIds': actionIds,
      },
      confidence: (frequency / 10).clamp(0.5, 0.95),
      reasons: [
        'Performed $frequency times',
        'Can save time on repeated actions',
      ],
      category: 'automation',
      suggestedAction: 'Create shortcut',
    );
  }

  /// Create a copy with modified fields
  Recommendation copyWith({
    String? id,
    RecommendationType? type,
    String? title,
    String? description,
    String? actionId,
    Map<String, dynamic>? actionParameters,
    double? confidence,
    List<String>? reasons,
    Map<String, dynamic>? context,
    DateTime? generatedAt,
    int? timesShown,
    int? timesAccepted,
    int? timesDismissed,
    bool? isActive,
    String? suggestedAction,
    String? category,
  }) {
    return Recommendation(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      actionId: actionId ?? this.actionId,
      actionParameters: actionParameters ?? this.actionParameters,
      confidence: confidence ?? this.confidence,
      reasons: reasons ?? this.reasons,
      context: context ?? this.context,
      generatedAt: generatedAt ?? this.generatedAt,
      timesShown: timesShown ?? this.timesShown,
      timesAccepted: timesAccepted ?? this.timesAccepted,
      timesDismissed: timesDismissed ?? this.timesDismissed,
      isActive: isActive ?? this.isActive,
      suggestedAction: suggestedAction ?? this.suggestedAction,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'description': description,
        'actionId': actionId,
        'actionParameters': actionParameters,
        'confidence': confidence,
        'reasons': reasons,
        'context': context,
        'generatedAt': generatedAt.toIso8601String(),
        'timesShown': timesShown,
        'timesAccepted': timesAccepted,
        'timesDismissed': timesDismissed,
        'isActive': isActive,
        'suggestedAction': suggestedAction,
        'category': category,
      };

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'] as String,
      type: RecommendationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RecommendationType.general,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      actionId: json['actionId'] as String?,
      actionParameters: json['actionParameters'] as Map<String, dynamic>?,
      confidence: (json['confidence'] as num).toDouble(),
      reasons: (json['reasons'] as List<dynamic>?)
              ?.map((r) => r as String)
              .toList() ??
          [],
      context: json['context'] as Map<String, dynamic>?,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      timesShown: json['timesShown'] as int? ?? 0,
      timesAccepted: json['timesAccepted'] as int? ?? 0,
      timesDismissed: json['timesDismissed'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      suggestedAction: json['suggestedAction'] as String?,
      category: json['category'] as String?,
    );
  }

  @override
  String toString() => 'Recommendation($title, confidence: $confidence)';
}

/// Types of recommendations
enum RecommendationType {
  /// Suggest creating an automation for a repeated workflow
  automation,

  /// Suggest using a feature more efficiently
  efficiency,

  /// Suggest a feature the user might find useful
  featureDiscovery,

  /// Suggest based on time/context
  contextAware,

  /// Suggest based on detected routine
  routineBased,

  /// General suggestion
  general,

  /// Reorder/pre-fill based on history
  smartFill,

  /// Reminder based on patterns
  reminder,
}

/// Recommendation engine that generates suggestions
class RecommendationEngine {
  final PersonalizationEngine personalizationEngine;
  final ActionRegistry actionRegistry;

  RecommendationConfig _config;
  final Map<String, DateTime> _lastShown = {};
  final List<Recommendation> _recentRecommendations = [];

  RecommendationEngine({
    required this.personalizationEngine,
    required this.actionRegistry,
    RecommendationConfig? config,
  }) : _config = config ?? const RecommendationConfig();

  /// Update configuration
  void updateConfig(RecommendationConfig config) {
    _config = config;
  }

  /// Generate a recommendation based on current context
  Future<Recommendation?> generateRecommendation({
    required String contextType,
    Map<String, dynamic>? contextData,
  }) async {
    // Get personalization data
    final profile = await personalizationEngine.getUserProfile();

    if (profile.isEmpty) {
      return null; // Nothing to base recommendations on yet
    }

    final recommendations = <Recommendation>[];

    // Generate routine-based recommendations
    if (_config.includeRoutineBased) {
      recommendations.addAll(
        _generateRoutineBasedRecommendations(profile),
      );
    }

    // Generate feature-based recommendations
    if (_config.includeFeatureBased) {
      recommendations.addAll(
        _generateFeatureBasedRecommendations(profile),
      );
    }

    // Generate context-based recommendations
    if (_config.useContext) {
      recommendations.addAll(
        _generateContextBasedRecommendations(contextType, contextData),
      );
    }

    // Filter and score recommendations
    final filtered = recommendations.where((r) {
      // Check cooldown
      if (_lastShown.containsKey(r.id)) {
        final lastShown = _lastShown[r.id]!;
        if (DateTime.now().difference(lastShown) < _config.recommendationCooldown) {
          return false;
        }
      }

      // Check confidence
      if (r.confidence < _config.minConfidence) return false;

      // Check if already shown too many times
      if (r.timesShown > 10 && r.acceptanceRate < 0.2) return false;

      return true;
    }).toList();

    // Sort by confidence
    filtered.sort((a, b) => b.confidence.compareTo(a.confidence));

    // Return top recommendation
    if (filtered.isEmpty) return null;

    return filtered.first;
  }

  /// Generate recommendations based on detected routines
  List<Recommendation> _generateRoutineBasedRecommendations(
    UserProfile profile,
  ) {
    final recommendations = <Recommendation>[];

    // Get routines that are ready for automation
    final routines = profile.getMostFrequentRoutines(limit: 5)
      ..retainWhere((r) => r.isReadyForSuggestion);

    for (final routine in routines) {
      // Check if we can map this routine to an action
      final actionId = _findActionForRoutine(routine);

      if (actionId != null) {
        recommendations.add(Recommendation(
          id: 'routine_${routine.routineId}',
          type: RecommendationType.automation,
          title: 'Automate "${routine.name}"?',
          description:
              'You perform this sequence regularly. Would you like to create a shortcut?',
          actionId: actionId,
          confidence: routine.confidence,
          reasons: [
            'Performed ${routine.frequency} times',
            'Pattern detected with ${routine.confidence.toStringAsFixed(0) * 100}% confidence',
          ],
          category: 'automation',
          suggestedAction: 'Create automation',
        ));
      } else {
        // Suggest as a routine even without a specific action
        recommendations.add(Recommendation(
          id: 'routine_${routine.routineId}_info',
          type: RecommendationType.routineBased,
          title: 'Notice: "${routine.name}"',
          description:
              'We noticed you frequently do this. We may be able to help automate it.',
          confidence: routine.confidence * 0.8,
          reasons: [
            'Performed ${routine.frequency} times',
          ],
          category: 'routines',
        ));
      }
    }

    return recommendations;
  }

  /// Find an action that matches a routine
  String? _findActionForRoutine(DetectedRoutine routine) {
    // Check if any registered action matches the routine's first step
    for (final action in actionRegistry.registeredActions) {
      // Check if action ID matches any step
      for (final step in routine.steps) {
        if (action.id == step.actionId || action.name.toLowerCase() == step.name.toLowerCase()) {
          return action.id;
        }
      }
    }

    // Check for semantic matching
    final firstStep = routine.steps.isNotEmpty ? routine.steps.first : null;
    if (firstStep != null) {
      for (final action in actionRegistry.registeredActions) {
        if (_actionsMatchSemantically(action, firstStep)) {
          return action.id;
        }
      }
    }

    return null;
  }

  /// Check if actions match semantically
  bool _actionsMatchSemantically(ActionDefinition action, RoutineStep step) {
    // Simple keyword matching
    final actionKeywords = action.name.toLowerCase().split(' ');
    final stepKeywords = step.name.toLowerCase().split(' ');

    int matches = 0;
    for (final ak in actionKeywords) {
      for (final sk in stepKeywords) {
        if (ak == sk || ak.contains(sk) || sk.contains(ak)) {
          matches++;
          break;
        }
      }
    }

    // Consider matching if >50% of keywords match
    final minKeywords = [actionKeywords.length, stepKeywords.length]
        .reduce((a, b) => a < b ? a : b);
    return matches >= (minKeywords / 2).ceil();
  }

  /// Generate recommendations based on feature usage
  List<Recommendation> _generateFeatureBasedRecommendations(
    UserProfile profile,
  ) {
    final recommendations = <Recommendation>[];

    final topFeatures = profile.getMostUsedFeatures(limit: 5);

    for (final feature in topFeatures) {
      // Check if there's a related action that could be automated
      final action = actionRegistry.getAction(feature.featureId);
      if (action != null) {
        // Suggest efficiency improvements
        if (feature.count > 10) {
          recommendations.add(Recommendation(
            id: 'efficiency_${feature.featureId}',
            type: RecommendationType.efficiency,
            title: 'You use ${feature.featureName} frequently',
            description:
                'Would you like to set up a quick access method for this?',
            actionId: action.id,
            confidence: (feature.count / profile.totalUsageCount).clamp(0, 1),
            reasons: [
              'Used ${feature.count} times',
              'Average of ${feature.averageDurationMs.toStringAsFixed(0)}ms per use',
            ],
            category: 'efficiency',
            suggestedAction: 'Set up shortcut',
          ));
        }
      }

      // Suggest related features
      final relatedActions = _findRelatedActions(feature.featureId);
      if (relatedActions.isNotEmpty && feature.count > 5) {
        final suggestion = relatedActions.first;
        recommendations.add(Recommendation(
          id: 'discovery_${feature.featureId}_${suggestion.id}',
          type: RecommendationType.featureDiscovery,
          title: 'You might also like ${suggestion.name}',
          description: suggestion.description,
          actionId: suggestion.id,
          confidence: 0.5,
          reasons: [
            'Similar to ${feature.featureName} which you use often',
          ],
          category: 'discovery',
        ));
      }
    }

    return recommendations;
  }

  /// Find actions related to a feature
  List<ActionDefinition> _findRelatedActions(String featureId) {
    // Simple relatedness based on category or keywords
    final featureAction = actionRegistry.getAction(featureId);
    if (featureAction == null) return [];

    return actionRegistry.registeredActions
        .where((a) =>
            a.id != featureId &&
            _actionsAreRelated(a, featureAction))
        .toList();
  }

  /// Check if two actions are related
  bool _actionsAreRelated(ActionDefinition a, ActionDefinition b) {
    // Same category
    if (a.category == b.category && a.category != null) {
      return true;
    }

    // Keyword overlap
    final aWords = a.name.toLowerCase().split(' ');
    final bWords = b.name.toLowerCase().split(' ');

    int common = 0;
    for (final aw in aWords) {
      for (final bw in bWords) {
        if (aw == bw || aw.contains(bw) || bw.contains(aw)) {
          common++;
          break;
        }
      }
    }

    return common >= 1;
  }

  /// Generate context-based recommendations
  List<Recommendation> _generateContextBasedRecommendations(
    String contextType,
    Map<String, dynamic>? contextData,
  ) {
    final recommendations = <Recommendation>[];

    switch (contextType) {
      case 'time_of_day':
        // Suggest based on time
        final hour = contextData?['hour'] as int? ?? DateTime.now().hour;

        if (hour >= 8 && hour < 12) {
          // Morning suggestions
          final morningActions = actionRegistry.registeredActions
              .where((a) => a.tags.contains('morning'))
              .toList();
          if (morningActions.isNotEmpty) {
            recommendations.add(Recommendation(
              id: 'morning_${DateTime.now().millisecondsSinceEpoch}',
              type: RecommendationType.contextAware,
              title: 'Good morning!',
              description: morningActions.first.description,
              actionId: morningActions.first.id,
              confidence: 0.6,
              reasons: ['Morning routine'],
              category: 'morning',
            ));
          }
        } else if (hour >= 17 && hour < 20) {
          // Evening suggestions
          final eveningActions = actionRegistry.registeredActions
              .where((a) => a.tags.contains('evening'))
              .toList();
          if (eveningActions.isNotEmpty) {
            recommendations.add(Recommendation(
              id: 'evening_${DateTime.now().millisecondsSinceEpoch}',
              type: RecommendationType.contextAware,
              title: 'Good evening!',
              description: eveningActions.first.description,
              actionId: eveningActions.first.id,
              confidence: 0.6,
              reasons: ['Evening routine'],
              category: 'evening',
            ));
          }
        }
        break;

      case 'location':
        // Suggest based on location
        final location = contextData?['location'] as String?;
        if (location != null) {
          final locationActions = actionRegistry.registeredActions
              .where((a) =>
                  a.contextTriggers?.containsKey('location') == true)
              .toList();
          if (locationActions.isNotEmpty) {
            recommendations.add(Recommendation(
              id: 'location_${location}_${DateTime.now().millisecondsSinceEpoch}',
              type: RecommendationType.contextAware,
              title: 'You\'re at $location',
              description: locationActions.first.description,
              actionId: locationActions.first.id,
              confidence: 0.7,
              reasons: ['Location-based suggestion'],
              context: contextData,
            ));
          }
        }
        break;

      case 'workflow_start':
        // Suggest next steps in a workflow
        final currentWorkflow = contextData?['workflow'] as String?;
        if (currentWorkflow != null) {
          final nextSteps = _suggestNextSteps(currentWorkflow);
          for (final step in nextSteps) {
            recommendations.add(Recommendation(
              id: 'workflow_${currentWorkflow}_${step.id}_${DateTime.now().millisecondsSinceEpoch}',
              type: RecommendationType.smartFill,
              title: step.title,
              description: step.description,
              actionId: step.actionId,
              actionParameters: step.parameters,
              confidence: step.confidence,
              reasons: ['Continuation of ${currentWorkflow}'],
              category: 'workflow',
            ));
          }
        }
        break;
    }

    return recommendations;
  }

  /// Suggest next steps in a workflow
  List<_WorkflowStepSuggestion> _suggestNextSteps(String workflowId) {
    // Get actions related to this workflow
    final actions = actionRegistry.registeredActions
        .where((a) => a.tags.contains(workflowId) || a.category == workflowId)
        .toList();

    if (actions.isEmpty) return [];

    // Prioritize actions not yet completed
    return actions.map((a) {
      return _WorkflowStepSuggestion(
        id: a.id,
        title: a.name,
        description: a.description,
        actionId: a.id,
        parameters: a.defaultParameters,
        confidence: 0.7,
      );
    }).toList();
  }

  /// Accept a recommendation
  Future<void> acceptRecommendation(String recommendationId) async {
    final rec = _recentRecommendations.firstWhere(
      (r) => r.id == recommendationId,
      orElse: () => throw Exception('Recommendation not found'),
    );

    // Update tracking
    _trackRecommendation(recommendationId, accepted: true);

    // If this is an automation recommendation, create the automation
    if (rec.type == RecommendationType.automation && rec.actionId != null) {
      await _createAutomationFromRecommendation(rec);
    }

    // Update personalization with acceptance
    // This helps the system learn which recommendations are useful
  }

  /// Dismiss a recommendation
  void dismissRecommendation(String recommendationId) {
    _trackRecommendation(recommendationId, dismissed: true);

    // Update personalization to reduce future similar recommendations
    // This helps the system learn which recommendations are not useful
  }

  /// Track a recommendation interaction
  void _trackRecommendation(
    String recommendationId, {
    bool accepted = false,
    bool dismissed = false,
  }) {
    final now = DateTime.now();
    _lastShown[recommendationId] = now;

    final index = _recentRecommendations.indexWhere((r) => r.id == recommendationId);
    if (index >= 0) {
      final rec = _recentRecommendations[index];
      _recentRecommendations[index] = rec.copyWith(
        timesShown: rec.timesShown + 1,
        timesAccepted: accepted ? rec.timesAccepted + 1 : rec.timesAccepted,
        timesDismissed: dismissed ? rec.timesDismissed + 1 : rec.timesDismissed,
      );
    }
  }

  /// Create an automation from a recommendation
  Future<void> _createAutomationFromRecommendation(Recommendation rec) async {
    // In a real implementation, this would create an automation workflow
    // using the automation engine
  }

  /// Get recent recommendations
  List<Recommendation> getRecentRecommendations() {
    return List.unmodifiable(_recentRecommendations);
  }

  /// Get recommendation statistics
  Map<String, int> getRecommendationStats() {
    return {
      'total_shown': _recentRecommendations.fold<int>(
        0,
        (sum, r) => sum + r.timesShown,
      ),
      'total_accepted': _recentRecommendations.fold<int>(
        0,
        (sum, r) => sum + r.timesAccepted,
      ),
      'total_dismissed': _recentRecommendations.fold<int>(
        0,
        (sum, r) => sum + r.timesDismissed,
      ),
    };
  }

  /// Update configuration
  RecommendationConfig get config => _config;

  /// Clear recommendation history
  void clearHistory() {
    _recentRecommendations.clear();
    _lastShown.clear();
  }
}

/// Helper class for workflow step suggestions
class _WorkflowStepSuggestion {
  final String id;
  final String title;
  final String description;
  final String actionId;
  final Map<String, dynamic>? parameters;
  final double confidence;

  _WorkflowStepSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.actionId,
    this.parameters,
    required this.confidence,
  });
}

/// Extension to add recommendation helpers to Recommendation
extension RecommendationExtensions on Recommendation {
  /// Create a suggestion for reordering a product
  static Recommendation reorderSuggestion({
    required String productId,
    required String productName,
    required int typicalQuantity,
    required String? scheduledTime,
  }) {
    return Recommendation(
      id: 'reorder_$productId',
      type: RecommendationType.routineBased,
      title: 'Time to reorder $productName?',
      description:
          'You usually reorder this product. Would you like to add it to your cart?',
      actionId: 'add_to_cart',
      actionParameters: {
        'productId': productId,
        'quantity': typicalQuantity,
      },
      confidence: 0.8,
      reasons: [
        'Based on your reordering pattern',
        'Typical quantity: $typicalQuantity',
        if (scheduledTime != null) 'Scheduled for: $scheduledTime',
      ],
      category: 'shopping',
      suggestedAction: 'Add to cart',
    );
  }

  /// Create a suggestion for reusing booking preferences
  static Recommendation bookingPreferenceSuggestion({
    required String bookingType,
    required List<String> typicalPreferences,
  }) {
    return Recommendation(
      id: 'booking_prefs_$bookingType',
      type: RecommendationType.smartFill,
      title: 'Reuse your $bookingType preferences?',
      description: 'Your typical preferences are ready to pre-fill.',
      actionId: 'prefill_booking',
      actionParameters: {
        'bookingType': bookingType,
        'preferences': typicalPreferences,
      },
      confidence: 0.85,
      reasons: [
        'Based on your previous bookings',
      ],
      category: 'booking',
      suggestedAction: 'Apply preferences',
    );
  }

  /// Create a suggestion for creating a shortcut
  static Recommendation shortcutSuggestion({
    required String workflowName,
    required List<String> actionIds,
    required int frequency,
  }) {
    return Recommendation(
      id: 'shortcut_$workflowName',
      type: RecommendationType.automation,
      title: 'Create a shortcut for "$workflowName"?',
      description:
          'You perform this workflow frequently. A shortcut can save time.',
      actionId: 'create_shortcut',
      actionParameters: {
        'workflowName': workflowName,
        'actionIds': actionIds,
      },
      confidence: (frequency / 10).clamp(0.5, 0.95),
      reasons: [
        'Performed $frequency times',
        'Can save time on repeated actions',
      ],
      category: 'automation',
      suggestedAction: 'Create shortcut',
    );
  }

  /// Create a suggestion for relevant help topic
  static Recommendation helpTopicSuggestion({
    required String topic,
    required String category,
    required String relevantContext,
  }) {
    return Recommendation(
      id: 'help_$topic',
      type: RecommendationType.featureDiscovery,
      title: 'Need help with $topic?',
      description: 'Based on your recent activity, this might be helpful.',
      actionId: 'open_help_topic',
      actionParameters: {
        'topic': topic,
        'category': category,
      },
      confidence: 0.6,
      reasons: [
        'Relevant to your recent activity: $relevantContext',
      ],
      category: 'help',
      suggestedAction: 'Show help topic',
    );
  }
}
