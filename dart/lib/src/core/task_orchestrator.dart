/// Task Orchestrator Types
///
/// Core types for task orchestration.

import 'package:flutter/foundation.dart';

/// Task Request
@immutable
class TaskRequest {
  final String taskId;
  final String description;
  final dynamic input;
  final TaskType? taskType;
  final Map<String, dynamic> context;
  final Map<String, dynamic>? parameters;
  final String? actionId;
  final bool? useModel;

  const TaskRequest({
    required this.taskId,
    required this.description,
    required this.input,
    this.taskType,
    this.context = const {},
    this.parameters,
    this.actionId,
    this.useModel,
  });
}

/// Task Output
@immutable
class TaskOutput {
  final OutputType type;
  final dynamic data;
  final String? text;
  final double? confidence;

  const TaskOutput({
    required this.type,
    required this.data,
    this.text,
    this.confidence,
  });

  factory TaskOutput.data(dynamic data) {
    return TaskOutput(type: OutputType.data, data: data);
  }

  factory TaskOutput.text(String text, {double? confidence}) {
    return TaskOutput(
      type: OutputType.text,
      data: text,
      text: text,
      confidence: confidence,
    );
  }
}

enum OutputType {
  data,
  text,
  classification,
  list,
  error,
}

/// Task Understanding
@immutable
class TaskUnderstanding {
  final String taskId;
  final TaskType taskType;
  final String description;
  final TaskRequirements requirements;
  final bool requiresModel;
  final TaskComplexity complexity;
  final Map<String, dynamic> context;

  const TaskUnderstanding({
    required this.taskId,
    required this.taskType,
    required this.description,
    required this.requirements,
    required this.requiresModel,
    required this.complexity,
    required this.context,
  });
}

/// Task Requirements
@immutable
class TaskRequirements {
  final bool requiresModel;
  final TaskComplexity complexity;
  final double minQuality;
  final String preferredApproach;

  const TaskRequirements({
    required this.requiresModel,
    required this.complexity,
    required this.minQuality,
    required this.preferredApproach,
  });
}

/// Task Type
enum TaskType {
  statistics,
  patternDetection,
  classification,
  extraction,
  summarization,
  search,
  planning,
  generation,
  complexReasoning,
  processing,
}

/// Task Complexity
enum TaskComplexity {
  low,
  medium,
  high,
  veryHigh,
}

/// Orchestration Config
@immutable
class OrchestrationConfig {
  final double minQualityThreshold;
  final bool preferRulesOverModels;
  final bool usePersonalization;
  final bool useRecommendations;
  final int maxModelCandidates;
  final Duration? timeout;

  const OrchestrationConfig({
    this.minQualityThreshold = 0.7,
    this.preferRulesOverModels = true,
    this.usePersonalization = true,
    this.useRecommendations = true,
    this.maxModelCandidates = 5,
    this.timeout,
  });
}

/// Orchestration Result
@immutable
class OrchestrationResult {
  final bool success;
  final String? errorMessage;
  final TaskOutput? output;
  final List<OrchestrationStep> steps;
  final Duration? duration;

  const OrchestrationResult({
    required this.success,
    this.errorMessage,
    this.output,
    this.steps = const [],
    this.duration,
  });

  factory OrchestrationResult.success({
    TaskOutput? output,
    List<OrchestrationStep> steps = const [],
    Duration? duration,
  }) {
    return OrchestrationResult(
      success: true,
      output: output,
      steps: steps,
      duration: duration,
    );
  }

  factory OrchestrationResult.failure(String errorMessage) {
    return const OrchestrationResult(
      success: false,
      errorMessage: errorMessage,
    );
  }
}

/// Orchestration Step
@immutable
class OrchestrationStep {
  final String name;
  final StepType type;
  final bool success;
  final String? details;
  final Duration? duration;

  const OrchestrationStep({
    required this.name,
    required this.type,
    required this.success,
    this.details,
    this.duration,
  });
}

enum StepType {
  understand,
  ruleEvaluation,
  modelSelection,
  modelLoading,
  inference,
  actionValidation,
  actionExecution,
  confirmation,
  feedback,
}
