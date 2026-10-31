/// Core types for the AI SDK

import 'package:flutter/foundation.dart';

/// Task types that the system can handle
enum TaskType {
  /// Statistical calculations
  statistics,

  /// Pattern detection in user behavior
  patternDetection,

  /// Classify content into categories
  classification,

  /// Extract structured information from text
  extraction,

  /// Summarize text/documents
  summarization,

  /// Search and find relevant content
  search,

  /// Plan multi-step workflows
  planning,

  /// Generate content
  generation,

  /// Complex reasoning tasks
  complexReasoning,

  /// General text processing
  processing,
}

/// Task request from the application
@immutable
class TaskRequest {
  /// Unique task identifier
  final String taskId;

  /// Description of what to accomplish
  final String description;

  /// Input data for the task
  final dynamic input;

  /// Type of task (if known)
  final TaskType? taskType;

  /// Context about the current situation
  final Map<String, dynamic> context;

  /// Parameters for the task
  final Map<String, dynamic>? parameters;

  /// Optional action ID for automation
  final String? actionId;

  /// Whether to use a model (vs rules)
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

  /// Create a simple text processing request
  factory TaskRequest.text({
    required String taskId,
    required String text,
    required String description,
    TaskType? taskType,
    Map<String, dynamic>? parameters,
  }) {
    return TaskRequest(
      taskId: taskId,
      description: description,
      input: {'text': text},
      taskType: taskType,
      parameters: parameters,
    );
  }

  /// Create a classification request
  factory TaskRequest.classification({
    required String taskId,
    required String text,
    required List<String> categories,
  }) {
    return TaskRequest(
      taskId: taskId,
      description: 'Classify text into categories',
      input: {
        'text': text,
        'categories': categories,
      },
      taskType: TaskType.classification,
    );
  }

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'description': description,
        'input': input,
        'taskType': taskType?.name,
        'context': context,
        'parameters': parameters,
        'actionId': actionId,
        'useModel': useModel,
      };

  factory TaskRequest.fromJson(Map<String, dynamic> json) {
    return TaskRequest(
      taskId: json['taskId'] as String,
      description: json['description'] as String,
      input: json['input'],
      taskType: json['taskType'] != null
          ? TaskType.values.firstWhere(
              (e) => e.name == json['taskType'],
              orElse: () => TaskType.processing,
            )
          : null,
      context: (json['context'] as Map<String, dynamic>?) ?? {},
      parameters: json['parameters'] as Map<String, dynamic>?,
      actionId: json['actionId'] as String?,
      useModel: json['useModel'] as bool?,
    );
  }

  @override
  String toString() => 'TaskRequest($taskId: $description)';
}

/// Task output/result
@immutable
class TaskOutput {
  final OutputType type;
  final dynamic data;
  final String? text;
  final double? confidence;
  final Map<String, dynamic>? metadata;

  const TaskOutput({
    required this.type,
    required this.data,
    this.text,
    this.confidence,
    this.metadata,
  });

  /// Create a data output
  factory TaskOutput.data(dynamic data, {Map<String, dynamic>? metadata}) {
    return TaskOutput(
      type: OutputType.data,
      data: data,
      metadata: metadata,
    );
  }

  /// Create a text output
  factory TaskOutput.text(String text, {double? confidence}) {
    return TaskOutput(
      type: OutputType.text,
      data: text,
      text: text,
      confidence: confidence,
    );
  }

  /// Create a classification output
  factory TaskOutput.classification(
    String category, {
    double confidence = 1.0,
    Map<String, double>? alternatives,
  }) {
    return TaskOutput(
      type: OutputType.classification,
      data: {'category': category, 'confidence': confidence},
      text: category,
      confidence: confidence,
      metadata: alternatives != null ? {'alternatives': alternatives} : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'data': data,
        'text': text,
        'confidence': confidence,
        'metadata': metadata,
      };

  factory TaskOutput.fromJson(Map<String, dynamic> json) {
    return TaskOutput(
      type: OutputType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => OutputType.data,
      ),
      data: json['data'],
      text: json['text'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() => 'TaskOutput(${type.name}: ${text ?? data})';
}

enum OutputType {
  data,
  text,
  classification,
  list,
  error,
}

/// Task understanding/interpretation
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

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'taskType': taskType.name,
        'description': description,
        'requirements': requirements.toJson(),
        'requiresModel': requiresModel,
        'complexity': complexity.name,
        'context': context,
      };
}

/// Rule-based task result
@immutable
class RuleResult {
  final bool isSuccess;
  final dynamic data;
  final String? message;
  final double confidence;

  const RuleResult({
    required this.isSuccess,
    this.data,
    this.message,
    this.confidence = 1.0,
  });
}

/// Execution result
@immutable
class ExecutionResult {
  final bool success;
  final TaskOutput? output;
  final String? message;
  final String? modelId;
  final bool usedModel;
  final Duration? duration;

  const ExecutionResult({
    required this.success,
    this.output,
    this.message,
    this.modelId,
    this.usedModel = false,
    this.duration,
  });
}

/// Automation result
@immutable
class AutomationResult {
  final bool success;
  final String? message;
  final String? workflowId;
  final Map<String, dynamic>? output;

  const AutomationResult({
    required this.success,
    this.message,
    this.workflowId,
    this.output,
  });
}

/// Health status
enum HealthStatus {
  /// Operating normally
  healthy,

  /// Operating with some issues
  degraded,

  /// Unable to operate
  unhealthy,

  /// Status unknown
  unknown,
}

/// Engine health information
@immutable
class EngineHealth {
  final bool isHealthy;
  final Map<String, HealthStatus> components;
  final int installedModels;
  final DateTime timestamp;

  const EngineHealth({
    required this.isHealthy,
    this.components = const {},
    this.installedModels = 0,
    required this.timestamp,
  });
}
