/// Task Orchestrator - Unified layer coordinating all AI components
///
/// For every requested task, the orchestrator determines:
/// - What is the user trying to accomplish?
/// - Can deterministic code complete it?
/// - Does it require a model?
/// - Which model is the smallest validated option?
/// - Is the model already installed?
/// - Does the device support it?
/// - What information is required?
/// - What actions are available?
/// - Does the workflow require confirmation?
/// - How will success or failure be detected?

import '../model/model_manager.dart';
import '../model/compatibility_engine.dart';
import '../model/model_optimizer.dart';
import '../personalization/personalization_engine.dart';
import '../personalization/recommendation_engine.dart';
import '../automation/automation_engine.dart';
import '../automation/action_registry.dart';
import '../core/types.dart';

/// Result of orchestrating a task
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
    return OrchestrationResult(
      success: false,
      errorMessage: errorMessage,
    );
  }
}

/// A step in the orchestration process
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
  /// Task understanding and classification
  understand,

  /// Rule-based evaluation
  ruleEvaluation,

  /// Model selection
  modelSelection,

  /// Model loading
  modelLoading,

  /// Inference execution
  inference,

  /// Action validation
  actionValidation,

  /// Action execution
  actionExecution,

  /// User confirmation
  confirmation,

  /// Feedback recording
  feedback,
}

/// Configuration for task orchestration
class OrchestrationConfig {
  /// Minimum quality threshold for model selection
  final double minQualityThreshold;

  /// Whether to prefer rules over models when possible
  final bool preferRulesOverModels;

  /// Whether to use personalization for suggestions
  final bool usePersonalization;

  /// Whether to use recommendations
  final bool useRecommendations;

  /// Maximum number of model candidates to evaluate
  final int maxModelCandidates;

  /// Timeout for the entire orchestration
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

/// Main task orchestrator that coordinates all AI components
class TaskOrchestrator {
  final ModelManager modelManager;
  final CompatibilityEngine compatibilityEngine;
  final ModelOptimizer modelOptimizer;
  final PersonalizationEngine? personalizationEngine;
  final RecommendationEngine? recommendationEngine;
  final AutomationEngine? automationEngine;
  final ActionRegistry? actionRegistry;

  OrchestrationConfig _config;

  TaskOrchestrator({
    required this.modelManager,
    required this.compatibilityEngine,
    required this.modelOptimizer,
    this.personalizationEngine,
    this.recommendationEngine,
    this.automationEngine,
    this.actionRegistry,
    OrchestrationConfig? config,
  }) : _config = config ?? const OrchestrationConfig();

  /// Update configuration
  void updateConfig(OrchestrationConfig config) {
    _config = config;
  }

  /// Orchestrate a task from understanding to execution
  Future<OrchestrationResult> orchestrateTask(
    TaskRequest request, {
    List<OrchestrationStep>? recordedSteps,
  }) async {
    final stopwatch = Stopwatch()..start();
    final steps = recordedSteps ?? <OrchestrationStep>[];

    try {
      // Step 1: Understand the request
      final understanding = await _understandRequest(request);
      steps.add(OrchestrationStep(
        name: 'Understand request',
        type: StepType.understand,
        success: understanding != null,
        details: understanding?.description,
      ));

      if (understanding == null) {
        return OrchestrationResult.failure('Could not understand request');
      }

      // Step 2: Check if rules can solve it
      if (_config.preferRulesOverModels) {
        final ruleResult = await _tryRules(understanding, request);
        steps.add(OrchestrationStep(
          name: 'Evaluate rules',
          type: StepType.ruleEvaluation,
          success: ruleResult != null,
          details: ruleResult?.toString(),
        ));

        if (ruleResult != null && ruleResult.isSuccess) {
          return OrchestrationResult.success(
            output: ruleResult.output ?? TaskOutput.data(ruleResult.data),
            steps: steps,
            duration: stopwatch.elapsed,
          );
        }
      }

      // Step 3: Select appropriate model if needed
      Model? selectedModel;
      if (understanding.requiresModel) {
        selectedModel = await _selectModel(
          understanding,
          request.context,
        );
        steps.add(OrchestrationStep(
          name: 'Model selection',
          type: StepType.modelSelection,
          success: selectedModel != null,
          details: selectedModel?.id,
        ));

        if (selectedModel == null) {
          return OrchestrationResult.failure(
            'No suitable model found for task requirements',
          );
        }
      }

      // Step 4: Execute the task
      final executionResult = await _executeTask(
        understanding,
        selectedModel,
        request,
      );
      steps.add(OrchestrationStep(
        name: 'Execute task',
        type: understanding.requiresModel
            ? StepType.inference
            : StepType.ruleEvaluation,
        success: executionResult.success,
        details: executionResult.message,
        duration: executionResult.duration,
      ));

      if (!executionResult.success) {
        return OrchestrationResult.failure(
          executionResult.message ?? 'Task execution failed',
        );
      }

      // Step 5: If automation is involved, handle it
      if (request.actionId != null && automationEngine != null) {
        final automationResult = await _handleAutomation(
          understanding,
          request,
          executionResult.output,
        );
        steps.add(OrchestrationStep(
          name: 'Handle automation',
          type: StepType.actionExecution,
          success: automationResult.success,
          details: automationResult.message,
        ));

        if (!automationResult.success) {
          return OrchestrationResult.failure(automationResult.message);
        }
      }

      // Step 6: Record feedback
      await _recordFeedback(request, understanding, executionResult);

      steps.add(OrchestrationStep(
        name: 'Record feedback',
        type: StepType.feedback,
        success: true,
      ));

      return OrchestrationResult.success(
        output: executionResult.output,
        steps: steps,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      return OrchestrationResult.failure(
        'Unexpected error: $e',
      );
    } finally {
      stopwatch.stop();
    }
  }

  /// Understand what the user is trying to accomplish
  Future<TaskUnderstanding?> _understandRequest(TaskRequest request) async {
    // Classify the task type
    final taskType = await _classifyTask(request);

    // Determine task requirements
    final requirements = _identifyRequirements(taskType, request);

    return TaskUnderstanding(
      taskId: request.taskId,
      taskType: taskType,
      description: request.description,
      requirements: requirements,
      requiresModel: requirements.requiresModel,
      complexity: requirements.complexity,
      context: request.context,
    );
  }

  /// Classify the incoming task
  Future<TaskType> _classifyTask(TaskRequest request) async {
    // Use lightweight classification
    // This could be rule-based or a small classifier model
    if (request.taskType != null) {
      return request.taskType!;
    }

    // Default classification based on description keywords
    final description = request.description.toLowerCase();

    if (description.contains('classify') ||
        description.contains('category') ||
        description.contains('label')) {
      return TaskType.classification;
    }

    if (description.contains('extract') ||
        description.contains('parse') ||
        description.contains('structure')) {
      return TaskType.extraction;
    }

    if (description.contains('summarize') ||
        description.contains('summary') ||
        description.contains('brief')) {
      return TaskType.summarization;
    }

    if (description.contains('search') ||
        description.contains('find') ||
        description.contains('recommend')) {
      return TaskType.search;
    }

    if (description.contains('plan') ||
        description.contains('workflow') ||
        description.contains('sequence')) {
      return TaskType.planning;
    }

    if (description.contains('generate') ||
        description.contains('create') ||
        description.contains('write')) {
      return TaskType.generation;
    }

    // Default to lightweight processing
    return TaskType.processing;
  }

  /// Identify task requirements
  TaskRequirements _identifyRequirements(TaskType taskType, TaskRequest request) {
    switch (taskType) {
      case TaskType.statistics:
      case TaskType.patternDetection:
        return const TaskRequirements(
          requiresModel: false,
          complexity: TaskComplexity.low,
          minQuality: 0.6,
          preferredApproach: 'rules',
        );

      case TaskType.classification:
      case TaskType.extraction:
        return TaskRequirements(
          requiresModel: request.useModel ?? true,
          complexity: TaskComplexity.low,
          minQuality: _config.minQualityThreshold,
          preferredApproach: request.useModel == false ? 'rules' : 'model',
        );

      case TaskType.summarization:
      case TaskType.search:
        return TaskRequirements(
          requiresModel: true,
          complexity: TaskComplexity.medium,
          minQuality: _config.minQualityThreshold,
          preferredApproach: 'model',
        );

      case TaskType.planning:
      case TaskType.generation:
      case TaskType.complexReasoning:
        return TaskRequirements(
          requiresModel: true,
          complexity: TaskComplexity.high,
          minQuality: _config.minQualityThreshold + 0.1,
          preferredApproach: 'model',
        );

      case TaskType.processing:
      default:
        return const TaskRequirements(
          requiresModel: false,
          complexity: TaskComplexity.low,
          minQuality: 0.5,
          preferredApproach: 'rules',
        );
    }
  }

  /// Try to solve the task using rules and deterministic code
  Future<RuleResult?> _tryRules(
    TaskUnderstanding understanding,
    TaskRequest request,
  ) async {
    if (!understanding.requiresModel &&
        understanding.requirements.preferredApproach == 'rules') {
      // Apply rule-based logic
      return _applyRules(understanding, request);
    }

    // Check if there are simple rules that can help even for model tasks
    if (understanding.requirements.complexity == TaskComplexity.low) {
      final ruleResult = _applySimpleRules(understanding, request);
      if (ruleResult != null && ruleResult.confidence > 0.8) {
        return ruleResult;
      }
    }

    return null;
  }

  /// Apply rule-based logic
  RuleResult _applyRules(
    TaskUnderstanding understanding,
    TaskRequest request,
  ) {
    // Implement specific rule logic based on task type
    switch (understanding.taskType) {
      case TaskType.statistics:
        return _handleStatistics(request);
      case TaskType.patternDetection:
        return _handlePatternDetection(request);
      default:
        return RuleResult(
          isSuccess: false,
          message: 'No applicable rules for this task type',
          confidence: 0,
        );
    }
  }

  /// Apply simple rules that might solve the task
  RuleResult? _applySimpleRules(
    TaskUnderstanding understanding,
    TaskRequest request,
  ) {
    // For simple classification tasks, check if rules can handle it
    if (understanding.taskType == TaskType.classification &&
        request.inputType == 'notification') {
      // Simple notification classification rules
      final input = request.input.toString();
      if (input.contains('urgent') || input.contains('important')) {
        return RuleResult(
          isSuccess: true,
          data: {'category': 'priority', 'confidence': 0.9},
          message: 'Classified as priority notification',
          confidence: 0.9,
        );
      }
      if (input.contains('promotion') || input.contains('offer')) {
        return RuleResult(
          isSuccess: true,
          data: {'category': 'promotional', 'confidence': 0.85},
          message: 'Classified as promotional notification',
          confidence: 0.85,
        );
      }
    }
    return null;
  }

  /// Select the smallest suitable model for the task
  Future<Model?> _selectModel(
    TaskUnderstanding understanding,
    TaskContext context,
  ) async {
    // Get candidate models from optimizer
    final candidates = await modelOptimizer.findCandidateModels(
      taskType: understanding.taskType,
      requirements: understanding.requirements,
      deviceInfo: context.deviceInfo,
      existingModels: modelManager.installedModels,
    );

    if (candidates.isEmpty) {
      return null;
    }

    // Evaluate candidates
    final evaluated = await modelOptimizer.evaluateCandidates(
      candidates,
      taskRequirements: understanding.requirements,
      deviceInfo: context.deviceInfo,
    );

    // Select the smallest model that meets requirements
    final selected = modelOptimizer.selectSmallestQualified(
      evaluated,
      minQuality: understanding.requirements.minQuality,
    );

    if (selected == null) {
      return null;
    }

    // Ensure model is available
    if (!modelManager.isModelInstalled(selected.id)) {
      await modelManager.downloadModel(selected.id, context.deviceInfo);
    }

    return modelManager.getModel(selected.id);
  }

  /// Execute the task with the selected model or rules
  Future<ExecutionResult> _executeTask(
    TaskUnderstanding understanding,
    Model? model,
    TaskRequest request,
  ) async {
    // Add context from personalization if available
    Map<String, dynamic> executionContext = {};
    if (_config.usePersonalization &&
        personalizationEngine != null) {
      final context = await personalizationEngine!.getTaskContext(
        taskType: understanding.taskType,
        userContext: request.context,
      );
      executionContext.addAll(context);
    }

    // Execute based on whether we have a model
    if (model != null) {
      return await _executeWithModel(model, request, executionContext);
    } else {
      return _executeWithRules(request, executionContext, understanding);
    }
  }

  /// Execute using a model
  Future<ExecutionResult> _executeWithModel(
    Model model,
    TaskRequest request,
    Map<String, dynamic> context,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Prepare input for the model
      final modelInput = _prepareModelInput(request, context);

      // Run inference
      final output = await modelManager.runInference(
        model.id,
        modelInput,
        taskType: request.taskType,
      );

      stopwatch.stop();

      return ExecutionResult(
        success: true,
        output: output,
        message: 'Inference completed successfully',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return ExecutionResult(
        success: false,
        message: 'Model inference failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Execute using rules
  ExecutionResult _executeWithRules(
    TaskRequest request,
    Map<String, dynamic> context,
    TaskUnderstanding understanding,
  ) {
    // Implement rule-based execution
    final result = _applyRules(understanding, request);

    if (result.isSuccess) {
      return ExecutionResult(
        success: true,
        output: TaskOutput.data(result.data),
        message: result.message,
      );
    }

    return ExecutionResult(
      success: false,
      message: 'Rule-based execution failed',
    );
  }

  /// Handle automation if requested
  Future<AutomationResult> _handleAutomation(
    TaskUnderstanding understanding,
    TaskRequest request,
    TaskOutput? output,
  ) async {
    if (automationEngine == null || actionRegistry == null) {
      return AutomationResult(
        success: false,
        message: 'Automation engine not available',
      );
    }

    return await automationEngine!.executeWorkflow(
      request.actionId!,
      request.parameters ?? {},
      output: output?.data,
    );
  }

  /// Record feedback for learning
  Future<void> _recordFeedback(
    TaskRequest request,
    TaskUnderstanding understanding,
    ExecutionResult result,
  ) async {
    if (personalizationEngine == null) return;

    await personalizationEngine!.recordActivity(
      ActivityEvent(
        eventType: ActivityEventType.taskExecution,
        taskType: understanding.taskType,
        taskId: request.taskId,
        success: result.success,
        duration: result.duration ?? Duration.zero,
        context: request.context,
        metadata: {
          'modelUsed': result.modelId,
          'approach': result.usedModel ? 'model' : 'rules',
        },
      },
    );
  }

  /// Prepare input for model inference
  Map<String, dynamic> _prepareModelInput(
    TaskRequest request,
    Map<String, dynamic> context,
  ) {
    final input = <String, dynamic>{
      'task': request.taskType?.name ?? 'unknown',
      'description': request.description,
      'input': request.input,
      'context': request.context,
      'parameters': request.parameters,
    };

    // Add personalization context if available
    if (context.isNotEmpty) {
      input['personalization'] = context;
    }

    return input;
  }

  /// Handle statistics tasks with rules
  RuleResult _handleStatistics(TaskRequest request) {
    final input = request.input;
    if (input is! Map<String, dynamic>) {
      return const RuleResult(
        isSuccess: false,
        message: 'Invalid input for statistics',
        confidence: 0,
      );
    }

    final data = input['data'];
    if (data is! List) {
      return const RuleResult(
        isSuccess: false,
        message: 'No data provided for statistics',
        confidence: 0,
      );
    }

    if (data.isEmpty) {
      return const RuleResult(
        isSuccess: false,
        message: 'Empty data set',
        confidence: 0,
      );
    }

    // Calculate basic statistics
    final numbers = data
        .whereType<num>()
        .toList();

    if (numbers.isEmpty) {
      return const RuleResult(
        isSuccess: false,
        message: 'No numeric data found',
        confidence: 0,
      );
    }

    final sum = numbers.reduce((a, b) => a + b);
    final mean = sum / numbers.length;
    final sorted = List<num>.from(numbers)..sort();
    final median =
        numbers.length.isOdd
            ? sorted[numbers.length ~/ 2]
            : (sorted[numbers.length ~/ 2 - 1] +
                    sorted[numbers.length ~/ 2]) /
                2;

    return RuleResult(
      isSuccess: true,
      data: {
        'count': numbers.length,
        'sum': sum,
        'mean': mean,
        'median': median,
        'min': sorted.first,
        'max': sorted.last,
      },
      message: 'Statistics calculated successfully',
      confidence: 1.0,
    );
  }

  /// Handle pattern detection tasks
  RuleResult _handlePatternDetection(TaskRequest request) {
    final input = request.input;
    if (input is! Map<String, dynamic>) {
      return const RuleResult(
        isSuccess: false,
        message: 'Invalid input for pattern detection',
        confidence: 0,
      );
    }

    final events = input['events'];
    if (events is! List) {
      return const RuleResult(
        isSuccess: false,
        message: 'No events provided for pattern detection',
        confidence: 0,
      );
    }

    if (events.length < 2) {
      return const RuleResult(
        isSuccess: false,
        message: 'Insufficient events for pattern detection',
        confidence: 0,
      );
    }

    // Simple pattern detection: check for repeated sequences
    final patterns = <String, int>{};
    final eventStrings = events.map((e) => e.toString()).toList();

    // Detect consecutive repetition
    for (var i = 0; i < eventStrings.length - 1; i++) {
      final pattern = '${eventStrings[i]} -> ${eventStrings[i + 1]}';
      patterns[pattern] = (patterns[pattern] ?? 0) + 1;
    }

    // Find most common pattern
    String? mostCommonPattern;
    int maxCount = 0;
    for (final entry in patterns.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostCommonPattern = entry.key;
      }
    }

    if (mostCommonPattern != null && maxCount >= 2) {
      final confidence = (maxCount / (events.length - 1)).clamp(0.0, 1.0);
      return RuleResult(
        isSuccess: true,
        data: {
          'pattern': mostCommonPattern,
          'frequency': maxCount,
          'confidence': confidence,
        },
        message: 'Detected repeated pattern',
        confidence: confidence,
      );
    }

    return const RuleResult(
      isSuccess: false,
      message: 'No significant patterns detected',
      confidence: 0,
    );
  }

  /// Get orchestrator configuration
  OrchestrationConfig get config => _config;

  /// Get model manager reference
  ModelManager get modelManagerRef => modelManager;

  /// Get personalization engine reference
  PersonalizationEngine? get personalizationEngineRef => personalizationEngine;

  /// Get recommendation engine reference
  RecommendationEngine? get recommendationEngineRef => recommendationEngine;

  /// Get automation engine reference
  AutomationEngine? get automationEngineRef => automationEngine;
}
