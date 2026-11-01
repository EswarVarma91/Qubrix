/// Task orchestration and execution.
///
/// The orchestrator is the single place where a [TaskRequest] is understood,
/// matched against deterministic rules, and (when needed) routed to the
/// smallest model that can handle it.
library;

import 'model/compatibility_engine.dart';
import 'model/model_manager.dart';
import 'model/model_optimizer.dart';
import 'model/model_types.dart';
import 'core/types.dart';

/// Steps in the orchestration pipeline.
enum StepType {
  understand,
  rules,
  modelSelection,
  modelDownload,
  modelLoading,
  ruleEvaluation,
  personalization,
  recommendation,
  automation,
  execution,
  error,
}

/// Configuration for task orchestration.
class OrchestrationConfig {
  final double minQualityThreshold;
  final bool preferRulesOverModels;
  final int maxModelCandidates;

  const OrchestrationConfig({
    this.minQualityThreshold = 0.7,
    this.preferRulesOverModels = true,
    this.maxModelCandidates = 5,
  });
}

/// A single step in the orchestration process.
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

  @override
  String toString() => 'OrchestrationStep($name: ${success ? "ok" : "failed"})';
}

/// Result of orchestrating a task.
class OrchestrationResult {
  final bool success;
  final String? errorMessage;
  final String taskId;
  final Duration? duration;
  final List<OrchestrationStep> steps;
  final TaskOutput? output;

  const OrchestrationResult({
    required this.success,
    this.errorMessage,
    required this.taskId,
    this.duration,
    this.steps = const [],
    this.output,
  });

  /// Convenience factory for a failed orchestration.
  factory OrchestrationResult.failure({
    required String taskId,
    required String errorMessage,
    List<OrchestrationStep> steps = const [],
  }) {
    return OrchestrationResult(
      success: false,
      taskId: taskId,
      errorMessage: errorMessage,
      steps: steps,
    );
  }
}

/// Types of task output.
enum OutputType {
  data,
  text,
  classification,
  embedding,
}

/// Output produced by a task.
class TaskOutput {
  final OutputType type;
  final Map<String, dynamic>? data;
  final String? text;
  final String? label;
  final double confidence;
  final Map<String, dynamic>? metadata;

  const TaskOutput({
    required this.type,
    this.data,
    this.text,
    this.label,
    this.confidence = 1.0,
    this.metadata,
  });

  factory TaskOutput.data(Map<String, dynamic> data) {
    return TaskOutput(type: OutputType.data, data: data);
  }

  factory TaskOutput.text(String text, {double confidence = 1.0}) {
    return TaskOutput(type: OutputType.text, text: text, confidence: confidence);
  }

  factory TaskOutput.classification(
    String label, {
    double confidence = 1.0,
    Map<String, dynamic>? metadata,
  }) {
    return TaskOutput(
      type: OutputType.classification,
      label: label,
      confidence: confidence,
      metadata: metadata,
    );
  }

  /// The most useful textual representation of this output.
  String get value {
    if (text != null) return text!;
    if (label != null) return label!;
    if (data != null) return data.toString();
    return '';
  }
}

/// A request to execute a task.
class TaskRequest {
  final String taskId;
  final String description;
  final Map<String, dynamic> input;
  final TaskType taskType;
  final Map<String, dynamic> context;
  final Map<String, dynamic> parameters;
  final bool useModel;

  const TaskRequest({
    required this.taskId,
    required this.description,
    required this.input,
    required this.taskType,
    this.context = const {},
    this.parameters = const {},
    this.useModel = true,
  });

  /// Create a text processing request.
  factory TaskRequest.text({
    required String taskId,
    required String text,
    String description = 'Process text',
    TaskType taskType = TaskType.generation,
  }) {
    return TaskRequest(
      taskId: taskId,
      description: description,
      input: {'text': text},
      taskType: taskType,
    );
  }

  /// Create a classification request.
  factory TaskRequest.classification({
    required String taskId,
    required String text,
    required List<String> categories,
    String description = 'Classify text',
  }) {
    return TaskRequest(
      taskId: taskId,
      description: description,
      input: {'text': text, 'categories': categories},
      taskType: TaskType.classification,
    );
  }

  factory TaskRequest.fromJson(Map<String, dynamic> json) {
    return TaskRequest(
      taskId: json['taskId'] as String,
      description: json['description'] as String? ?? '',
      input: json['input'] is Map<String, dynamic>
          ? json['input'] as Map<String, dynamic>
          : {'value': json['input']},
      taskType: json['taskType'] != null
          ? TaskTypeExtension.fromString(json['taskType'] as String)
          : TaskType.unknown,
      context: (json['context'] as Map<String, dynamic>?) ?? const {},
      parameters: (json['parameters'] as Map<String, dynamic>?) ?? const {},
      useModel: json['useModel'] as bool? ?? true,
    );
  }
}

/// Understanding of a task produced by the first orchestration step.
class TaskUnderstanding {
  final String taskId;
  final TaskType taskType;
  final String description;
  final Map<String, dynamic> context;

  const TaskUnderstanding({
    required this.taskId,
    required this.taskType,
    required this.description,
    this.context = const {},
  });
}

/// Execution context passed between engines.
class TaskContext {
  final String contextId;
  final Map<String, dynamic> data;

  const TaskContext({
    required this.contextId,
    this.data = const {},
  });
}

/// Result of deterministic rule evaluation.
class RuleResult {
  final bool handled;
  final TaskOutput? output;
  final String? rule;

  const RuleResult({
    required this.handled,
    this.output,
    this.rule,
  });

  factory RuleResult.notHandled() => const RuleResult(handled: false);

  factory RuleResult.handled(TaskOutput output, {String? rule}) {
    return RuleResult(handled: true, output: output, rule: rule);
  }
}

/// Result of a model execution.
class ExecutionResult {
  final bool success;
  final TaskOutput? output;
  final String? errorMessage;
  final Model? model;
  final Duration? duration;

  const ExecutionResult({
    required this.success,
    this.output,
    this.errorMessage,
    this.model,
    this.duration,
  });

  factory ExecutionResult.failure(String errorMessage) {
    return ExecutionResult(success: false, errorMessage: errorMessage);
  }
}

/// Result of running an automation workflow for a task.
class AutomationResult {
  final bool success;
  final bool executed;
  final String? errorMessage;
  final List<String> actionIds;

  const AutomationResult({
    required this.success,
    this.executed = false,
    this.errorMessage,
    this.actionIds = const [],
  });
}

/// Health of the agent engine.
class EngineHealth {
  final bool isHealthy;
  final String message;
  final int installedModels;
  final Map<String, bool> components;

  const EngineHealth({
    required this.isHealthy,
    required this.message,
    this.installedModels = 0,
    this.components = const {},
  });

  @override
  String toString() =>
      'EngineHealth(${isHealthy ? "healthy" : "unhealthy"}: $message)';
}

/// Main task orchestrator.
///
/// The pipeline is:
/// 1. Understand the task ([StepType.understand])
/// 2. Try deterministic rules ([StepType.ruleEvaluation])
/// 3. Select the smallest suitable model ([StepType.modelSelection])
/// 4. Execute and report ([StepType.execution])
class TaskOrchestrator {
  final ModelManager modelManager;
  final CompatibilityEngine? compatibilityEngine;
  final ModelOptimizer? modelOptimizer;
  final OrchestrationConfig config;

  TaskOrchestrator({
    required this.modelManager,
    this.compatibilityEngine,
    this.modelOptimizer,
    this.config = const OrchestrationConfig(),
  });

  /// Alias kept for backwards compatibility.
  Future<OrchestrationResult> orchestrate(TaskRequest request) =>
      orchestrateTask(request);

  /// Run the full orchestration pipeline for [request].
  Future<OrchestrationResult> orchestrateTask(TaskRequest request) async {
    final steps = <OrchestrationStep>[];
    final stopwatch = Stopwatch()..start();

    try {
      // Step 1: Understand the task.
      final understanding = _understand(request);
      steps.add(OrchestrationStep(
        name: 'Understand task',
        type: StepType.understand,
        success: true,
        details: '${understanding.taskType.name}: ${understanding.description}',
      ));

      // Step 2: Deterministic rules (cheap, always preferred when possible).
      final ruleResult = _evaluateRules(request);
      steps.add(OrchestrationStep(
        name: 'Evaluate rules',
        type: StepType.ruleEvaluation,
        success: true,
        details: ruleResult.handled
            ? 'Handled by ${ruleResult.rule}'
            : 'No rule matched, model required',
      ));

      if (ruleResult.handled && ruleResult.output != null) {
        stopwatch.stop();
        return OrchestrationResult(
          success: true,
          taskId: request.taskId,
          duration: stopwatch.elapsed,
          steps: steps,
          output: ruleResult.output,
        );
      }

      // Step 3: Select the smallest suitable model.
      final selectionStart = stopwatch.elapsed;
      final candidate = await _selectModel(request);
      steps.add(OrchestrationStep(
        name: 'Select model',
        type: StepType.modelSelection,
        success: candidate != null,
        details: candidate == null
            ? 'No compatible model available'
            : '${candidate.model.id} (${candidate.quantizationFormat.name}, '
                '${candidate.downloadSize ~/ (1024 * 1024)}MB)',
        duration: stopwatch.elapsed - selectionStart,
      ));

      if (candidate == null) {
        stopwatch.stop();
        return OrchestrationResult(
          success: false,
          taskId: request.taskId,
          errorMessage:
              'No suitable model available for ${request.taskType.name} tasks. '
              'Download a compatible model first.',
          duration: stopwatch.elapsed,
          steps: steps,
        );
      }

      // Step 4: Execute.
      final executionStart = stopwatch.elapsed;
      final result = await _executeWithModel(candidate, request);
      steps.add(OrchestrationStep(
        name: 'Execute task',
        type: StepType.execution,
        success: result.success,
        details: result.success
            ? 'Completed with ${candidate.model.id}'
            : result.errorMessage,
        duration: stopwatch.elapsed - executionStart,
      ));

      stopwatch.stop();
      return OrchestrationResult(
        success: result.success,
        errorMessage: result.errorMessage,
        taskId: request.taskId,
        duration: stopwatch.elapsed,
        steps: steps,
        output: result.output,
      );
    } catch (e) {
      steps.add(OrchestrationStep(
        name: 'Orchestration failed',
        type: StepType.error,
        success: false,
        details: e.toString(),
      ));
      stopwatch.stop();
      return OrchestrationResult(
        success: false,
        errorMessage: e.toString(),
        taskId: request.taskId,
        duration: stopwatch.elapsed,
        steps: steps,
      );
    }
  }

  TaskUnderstanding _understand(TaskRequest request) {
    var taskType = request.taskType;

    // Infer the task type when the caller did not provide one.
    if (taskType == TaskType.unknown) {
      final text = (request.input['text'] ?? request.description).toString();
      final lower = text.toLowerCase();
      if (lower.contains('classif') || lower.contains('categor')) {
        taskType = TaskType.classification;
      } else if (lower.contains('summar')) {
        taskType = TaskType.summarization;
      } else if (lower.contains('search') || lower.contains('find')) {
        taskType = TaskType.search;
      } else if (request.input.containsKey('data')) {
        taskType = TaskType.statistics;
      } else {
        taskType = TaskType.generation;
      }
    }

    return TaskUnderstanding(
      taskId: request.taskId,
      taskType: taskType,
      description: request.description,
      context: request.context,
    );
  }

  /// Deterministic rules that need no model.
  RuleResult _evaluateRules(TaskRequest request) {
    if (request.taskType == TaskType.statistics) {
      final data = request.input['data'];
      if (data is List && data.isNotEmpty) {
        final values = data.whereType<num>().map((v) => v.toDouble()).toList();
        if (values.isEmpty) return RuleResult.notHandled();

        final sum = values.reduce((a, b) => a + b);
        final sorted = [...values]..sort();

        return RuleResult.handled(
          TaskOutput.data({
            'count': values.length,
            'sum': sum,
            'mean': sum / values.length,
            'min': sorted.first,
            'max': sorted.last,
            'median': sorted[sorted.length ~/ 2],
          }),
          rule: 'statistics',
        );
      }
    }

    if (request.taskType == TaskType.extraction) {
      final text = request.input['text'];
      if (text is String && text.trim().isNotEmpty) {
        return RuleResult.handled(
          TaskOutput.data({
            'length': text.length,
            'words': text.trim().split(RegExp(r'\s+')).length,
          }),
          rule: 'text_length',
        );
      }
    }

    return RuleResult.notHandled();
  }

  Future<ModelCandidate?> _selectModel(TaskRequest request) async {
    final optimizer = modelOptimizer;
    if (optimizer == null) return null;

    final deviceInfo = await (compatibilityEngine?.getDeviceInfo() ??
        Future<DeviceInfo>.value(const DeviceInfo()));

    return optimizer.findSmallestSuitableModel(
      taskType: request.taskType,
      deviceInfo: deviceInfo,
      minQuality: config.minQualityThreshold,
      preferInstalled: !request.useModel,
    );
  }

  Future<ExecutionResult> _executeWithModel(
    ModelCandidate candidate,
    TaskRequest request,
  ) async {
    // Inference is delegated to the model backend. Until a backend is
    // registered the orchestrator reports that the model was selected but the
    // task could not be executed on-device.
    return ExecutionResult(
      success: false,
      model: candidate.model,
      errorMessage:
          'Inference backend unavailable for ${candidate.model.id}. '
          'Register an inference backend before executing model tasks.',
    );
  }
}
