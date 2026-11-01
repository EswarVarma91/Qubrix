/// Task orchestration and execution.
library;

import 'core/types.dart';
import 'model/model_manager.dart';
import 'model/model_types.dart';

/// Orchestration result from task execution.
class OrchestrationResult {
  final bool success;
  final String? errorMessage;
  final String taskId;
  final Duration? duration;
  final List<OrchestrationStep> steps;

  const OrchestrationResult({
    required this.success,
    this.errorMessage,
    required this.taskId,
    this.duration,
    this.steps = const [],
  });
}

/// A step in the orchestration process.
class OrchestrationStep {
  final StepType type;
  final bool success;
  final String? details;
  final Duration? duration;

  const OrchestrationStep({
    required this.type,
    required this.success,
    this.details,
    this.duration,
  });
}

enum StepType {
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

/// Task request for execution.
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
}

/// Task output result.
class TaskOutput {
  final String text;
  final Map<String, dynamic>? metadata;
  final double confidence;

  const TaskOutput({
    required this.text,
    this.metadata,
    this.confidence = 1.0,
  });
}

/// Task understanding context.
class TaskUnderstanding {
  final String taskId;
  final TaskType taskType;
  final Map<String, dynamic> context;

  const TaskUnderstanding({
    required this.taskId,
    required this.taskType,
    required this.context,
  });
}

/// Main task orchestrator.
class TaskOrchestrator {
  final ModelManager modelManager;

  TaskOrchestrator(this.modelManager);

  Future<OrchestrationResult> orchestrate(TaskRequest request) async {
    final steps = <OrchestrationStep>[];
    final stopwatch = Stopwatch()..start();

    try {
      // Step 1: Model selection
      final modelCandidate = await _selectModel(request.taskType);
      steps.add(OrchestrationStep(
        type: StepType.modelSelection,
        success: modelCandidate != null,
        details: modelCandidate?.id,
      ));

      if (modelCandidate == null) {
        return OrchestrationResult(
          success: false,
          errorMessage: 'No suitable model found for task type: ${request.taskType.name}',
          taskId: request.taskId,
          steps: steps,
        );
      }

      // Step 2: Execute with model
      final result = await _executeWithModel(modelCandidate, request);
      steps.add(OrchestrationStep(
        type: StepType.execution,
        success: result.success,
        details: result.errorMessage,
      ));

      stopwatch.stop();
      return OrchestrationResult(
        success: result.success,
        errorMessage: result.errorMessage,
        taskId: request.taskId,
        duration: stopwatch.elapsed,
        steps: steps,
      );
    } catch (e) {
      steps.add(OrchestrationStep(
        type: StepType.error,
        success: false,
        details: e.toString(),
      ));
      return OrchestrationResult(
        success: false,
        errorMessage: e.toString(),
        taskId: request.taskId,
        steps: steps,
      );
    }
  }

  Future<ModelCandidate?> _selectModel(TaskType taskType) async {
    // In production, this would check installed models and preferences
    // For now, return null (no model selected)
    return null;
  }

  Future<TaskOutput> _executeWithModel(ModelCandidate candidate, TaskRequest request) async {
    // In production, this would use the model for inference
    return TaskOutput(
      text: 'Task executed successfully',
      confidence: 0.9,
    );
  }
}
