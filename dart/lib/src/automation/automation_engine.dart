/// Automation Engine
///
/// Executes approved actions through the application's supported interfaces.
/// Combines developer-defined actions into useful workflows.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'action_registry.dart';
import 'permission_manager.dart';
import '../core/types.dart';

/// Automation configuration
class AutomationConfig {
  /// Whether to require confirmation for actions with side effects
  final bool requireConfirmationForSideEffects;

  /// Maximum number of concurrent workflows
  final int maxConcurrentWorkflows;

  /// Default workflow timeout
  final Duration defaultWorkflowTimeout;

  /// Whether to allow background execution
  final bool allowBackgroundExecution;

  /// Retry configuration
  final RetryConfig retryConfig;

  /// Idempotency handling
  final bool enableIdempotency;

  const AutomationConfig({
    this.requireConfirmationForSideEffects = true,
    this.maxConcurrentWorkflows = 3,
    this.defaultWorkflowTimeout = const Duration(minutes: 5),
    this.allowBackgroundExecution = false,
    this.retryConfig = const RetryConfig(),
    this.enableIdempotency = true,
  });
}

/// Retry configuration
@immutable
class RetryConfig {
  /// Maximum number of retry attempts
  final int maxAttempts;

  /// Initial delay between retries
  final Duration initialDelay;

  /// Maximum delay between retries
  final Duration maxDelay;

  /// Whether to use exponential backoff
  final bool exponentialBackoff;

  /// Jitter factor (0-1) for randomization
  final double jitter;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.exponentialBackoff = true,
    this.jitter = 0.1,
  });
}

/// Automation level
enum AutomationLevel {
  /// Just suggest the action
  suggest,

  /// Prepare the action for review
  prepare,

  /// Execute the action
  execute,
}

/// Workflow definition
@immutable
class WorkflowDefinition {
  final String id;
  final String name;
  final String? description;
  final List<WorkflowStep> steps;
  final AutomationLevel defaultLevel;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;

  const WorkflowDefinition({
    required this.id,
    required this.name,
    this.description,
    required this.steps,
    this.defaultLevel = AutomationLevel.suggest,
    this.metadata,
    this.createdAt,
  });

  /// Check if workflow is valid
  bool get isValid =>
      steps.isNotEmpty &&
      steps.every((s) => s.isValid) &&
      _hasNoCycles();

  /// Check that dependencies resolve and contain no cycles.
  bool _hasNoCycles() {
    final stepIds = steps.map((s) => s.id).toSet();

    // A dependency on a step that does not exist makes the workflow invalid.
    for (final step in steps) {
      for (final dependency in step.dependsOn) {
        if (!stepIds.contains(dependency)) return false;
      }
    }

    final visiting = <String>{};
    final visited = <String>{};

    bool visit(String stepId) {
      if (visited.contains(stepId)) return true;
      if (visiting.contains(stepId)) return false; // Cycle detected

      visiting.add(stepId);
      final step = steps.firstWhere((s) => s.id == stepId);

      for (final dependency in step.dependsOn) {
        if (!visit(dependency)) return false;
      }

      visiting.remove(stepId);
      visited.add(stepId);
      return true;
    }

    for (final step in steps) {
      if (!visit(step.id)) return false;
    }

    return true;
  }

  WorkflowDefinition copyWith({
    String? id,
    String? name,
    String? description,
    List<WorkflowStep>? steps,
    AutomationLevel? defaultLevel,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return WorkflowDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      defaultLevel: defaultLevel ?? this.defaultLevel,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'steps': steps.map((s) => s.toJson()).toList(),
        'defaultLevel': defaultLevel.name,
        'metadata': metadata,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory WorkflowDefinition.fromJson(Map<String, dynamic> json) {
    return WorkflowDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      steps: (json['steps'] as List<dynamic>)
          .map((s) => WorkflowStep.fromJson(s as Map<String, dynamic>))
          .toList(),
      defaultLevel: AutomationLevel.values.firstWhere(
        (e) => e.name == json['defaultLevel'],
        orElse: () => AutomationLevel.suggest,
      ),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  @override
  String toString() => 'WorkflowDefinition($name, ${steps.length} steps)';
}

/// Step in a workflow
@immutable
class WorkflowStep {
  final String id;
  final String actionId;
  final String name;
  final String? description;
  final Map<String, dynamic>? parameters;
  final List<String> dependsOn;
  final AutomationLevel level;
  final bool requiresConfirmation;
  final bool isCritical;
  final int order;

  const WorkflowStep({
    required this.id,
    required this.actionId,
    required this.name,
    this.description,
    this.parameters,
    this.dependsOn = const [],
    this.level = AutomationLevel.execute,
    this.requiresConfirmation = false,
    this.isCritical = false,
    this.order = 0,
  });

  /// Check if step is valid
  bool get isValid => actionId.isNotEmpty && name.isNotEmpty;

  WorkflowStep copyWith({
    String? id,
    String? actionId,
    String? name,
    String? description,
    Map<String, dynamic>? parameters,
    List<String>? dependsOn,
    AutomationLevel? level,
    bool? requiresConfirmation,
    bool? isCritical,
    int? order,
  }) {
    return WorkflowStep(
      id: id ?? this.id,
      actionId: actionId ?? this.actionId,
      name: name ?? this.name,
      description: description ?? this.description,
      parameters: parameters ?? this.parameters,
      dependsOn: dependsOn ?? this.dependsOn,
      level: level ?? this.level,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      isCritical: isCritical ?? this.isCritical,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'actionId': actionId,
        'name': name,
        'description': description,
        'parameters': parameters,
        'dependsOn': dependsOn,
        'level': level.name,
        'requiresConfirmation': requiresConfirmation,
        'isCritical': isCritical,
        'order': order,
      };

  factory WorkflowStep.fromJson(Map<String, dynamic> json) {
    return WorkflowStep(
      id: json['id'] as String,
      actionId: json['actionId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      parameters: json['parameters'] as Map<String, dynamic>?,
      dependsOn: (json['dependsOn'] as List<dynamic>?)
              ?.map((d) => d as String)
              .toList() ??
          [],
      level: AutomationLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => AutomationLevel.execute,
      ),
      requiresConfirmation: json['requiresConfirmation'] as bool? ?? false,
      isCritical: json['isCritical'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
    );
  }

  @override
  String toString() => 'WorkflowStep($name)';
}

/// Workflow execution state
enum WorkflowState {
  /// Workflow is pending (waiting for confirmation)
  pending,

  /// Workflow is running
  running,

  /// Workflow completed successfully
  completed,

  /// Workflow failed
  failed,

  /// Workflow was cancelled
  cancelled,

  /// Workflow requires confirmation for a step
  awaitingConfirmation,

  /// Workflow is paused (e.g., waiting for background conditions)
  paused,
}

/// Workflow execution result
@immutable
class WorkflowResult {
  final String workflowId;
  final bool success;
  final String? errorMessage;
  final List<StepResult> stepResults;
  final Duration duration;
  final DateTime completedAt;

  const WorkflowResult({
    required this.workflowId,
    required this.success,
    this.errorMessage,
    this.stepResults = const [],
    required this.duration,
    required this.completedAt,
  });

  /// Get step result by action ID
  StepResult? getStepResult(String actionId) {
    try {
      return stepResults.firstWhere((s) => s.actionId == actionId);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'workflowId': workflowId,
        'success': success,
        'errorMessage': errorMessage,
        'stepResults': stepResults.map((s) => s.toJson()).toList(),
        'duration': duration.inMilliseconds,
        'completedAt': completedAt.toIso8601String(),
      };

  factory WorkflowResult.fromJson(Map<String, dynamic> json) {
    return WorkflowResult(
      workflowId: json['workflowId'] as String,
      success: json['success'] as bool,
      errorMessage: json['errorMessage'] as String?,
      stepResults: (json['stepResults'] as List<dynamic>)
          .map((s) => StepResult.fromJson(s as Map<String, dynamic>))
          .toList(),
      duration: Duration(milliseconds: json['duration'] as int),
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }

  @override
  String toString() =>
      'WorkflowResult($workflowId: ${success ? "success" : "failed"})';
}

/// Result of a single step execution
@immutable
class StepResult {
  final String stepId;
  final String actionId;
  final bool success;
  final String? errorMessage;
  final dynamic output;
  final Duration duration;
  final Map<String, dynamic>? context;

  const StepResult({
    required this.stepId,
    required this.actionId,
    required this.success,
    this.errorMessage,
    this.output,
    required this.duration,
    this.context,
  });

  Map<String, dynamic> toJson() => {
        'stepId': stepId,
        'actionId': actionId,
        'success': success,
        'errorMessage': errorMessage,
        'output': output,
        'duration': duration.inMilliseconds,
        'context': context,
      };

  factory StepResult.fromJson(Map<String, dynamic> json) {
    return StepResult(
      stepId: json['stepId'] as String,
      actionId: json['actionId'] as String,
      success: json['success'] as bool,
      errorMessage: json['errorMessage'] as String?,
      output: json['output'],
      duration: Duration(milliseconds: json['duration'] as int),
      context: json['context'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() =>
      'StepResult($actionId: ${success ? "ok" : "failed"})';
}

/// Automation execution plan
@immutable
class ExecutionPlan {
  final String goal;
  final List<PlannedStep> steps;
  final String? generatedBy;

  const ExecutionPlan({
    required this.goal,
    required this.steps,
    this.generatedBy,
  });

  /// Validate the plan
  bool get isValid => steps.isNotEmpty && steps.every((s) => s.isValid);
}

/// A planned step in an execution plan
@immutable
class PlannedStep {
  final int sequence;
  final String actionId;
  final String description;
  final bool requiresApproval;
  final Map<String, dynamic>? parameters;
  final String? rationale;

  const PlannedStep({
    required this.sequence,
    required this.actionId,
    required this.description,
    required this.requiresApproval,
    this.parameters,
    this.rationale,
  });

  bool get isValid => actionId.isNotEmpty && description.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'sequence': sequence,
        'actionId': actionId,
        'description': description,
        'requiresApproval': requiresApproval,
        'parameters': parameters,
        'rationale': rationale,
      };

  factory PlannedStep.fromJson(Map<String, dynamic> json) {
    return PlannedStep(
      sequence: json['sequence'] as int,
      actionId: json['actionId'] as String,
      description: json['description'] as String,
      requiresApproval: json['requiresApproval'] as bool,
      parameters: json['parameters'] as Map<String, dynamic>?,
      rationale: json['rationale'] as String?,
    );
  }

  @override
  String toString() => 'PlannedStep($sequence: $description)';
}

/// Automation engine that executes workflows
class AutomationEngine {
  final ActionRegistry actionRegistry;
  final PermissionManager permissionManager;

  AutomationConfig _config;
  final Map<String, WorkflowDefinition> _workflows = {};
  final Map<String, WorkflowState> _workflowStates = {};
  final Map<String, WorkflowResult> _idempotentResults = {};
  final Map<String, List<DateTime>> _executionHistory = {};

  AutomationEngine({
    required this.actionRegistry,
    required this.permissionManager,
    AutomationConfig? config,
  }) : _config = config ?? const AutomationConfig();

  /// Update configuration
  void updateConfig(AutomationConfig config) {
    _config = config;
  }

  /// Execute a workflow
  Future<WorkflowResult> executeWorkflow(
    String workflowId, {
    required Map<String, dynamic> parameters,
    AutomationLevel level = AutomationLevel.execute,
    bool requireConfirmation = true,
    String? idempotencyKey,
  }) async {
    final stopwatch = Stopwatch()..start();

    final workflow = getWorkflow(workflowId);
    if (workflow == null) {
      return WorkflowResult(
        workflowId: workflowId,
        success: false,
        errorMessage: 'Workflow not found: $workflowId',
        duration: stopwatch.elapsed,
        completedAt: DateTime.now(),
      );
    }

    // Permissions are granted per action, so a workflow-level record is
    // optional; when one exists it must not be denied.
    final workflowPermission = permissionManager.getPermission(workflowId);
    if (workflowPermission != null && !workflowPermission.granted) {
      return WorkflowResult(
        workflowId: workflowId,
        success: false,
        errorMessage: 'Permission denied for workflow: $workflowId',
        duration: stopwatch.elapsed,
        completedAt: DateTime.now(),
      );
    }

    // Suggest and prepare stop before executing anything.
    if (level != AutomationLevel.execute) {
      return _previewWorkflow(workflow, level: level, stopwatch: stopwatch);
    }

    // Replay the previous result instead of running the steps twice.
    if (_config.enableIdempotency && idempotencyKey != null) {
      final cached = _idempotentResults[idempotencyKey];
      if (cached != null) {
        if (DateTime.now().difference(cached.completedAt) <
            const Duration(minutes: 5)) {
          return cached;
        }
        _idempotentResults.remove(idempotencyKey);
      }
    }

    // Set workflow state
    _workflowStates[workflowId] = WorkflowState.running;

    try {
      final stepResults = <StepResult>[];

      // Execute each step in dependency order
      for (final step in _orderedSteps(workflow)) {
        // A step that needs approval stops the workflow instead of silently
        // running anyway.
        final action = actionRegistry.getAction(step.actionId);
        final needsApproval = step.requiresConfirmation ||
            (action?.requiresStrongConfirmation ?? false);

        if (requireConfirmation && needsApproval) {
          _workflowStates[workflowId] = WorkflowState.awaitingConfirmation;
          stopwatch.stop();
          return WorkflowResult(
            workflowId: workflowId,
            success: false,
            errorMessage: 'Confirmation required before step "${step.name}". '
                'Re-run with requireConfirmation: false once approved.',
            stepResults: stepResults,
            duration: stopwatch.elapsed,
            completedAt: DateTime.now(),
          );
        }

        // Check permission for this step
        if (!permissionManager.hasPermission(step.actionId, PermissionLevel.execute)) {
          stepResults.add(StepResult(
            stepId: step.id,
            actionId: step.actionId,
            success: false,
            errorMessage: 'Permission denied',
            duration: Duration.zero,
          ));
          _workflowStates[workflowId] = WorkflowState.failed;
          break;
        }

        // Execute the step
        final stepResult = await _executeStep(
          step,
          parameters,
          idempotencyKey: idempotencyKey,
        );
        stepResults.add(stepResult);

        // Check if step failed
        if (!stepResult.success) {
          _workflowStates[workflowId] = WorkflowState.failed;
          break;
        }

        // Record permission usage
        permissionManager.recordUsage(step.actionId);
      }

      stopwatch.stop();

      final success = stepResults.isNotEmpty &&
          stepResults.every((s) => s.success);

      final result = WorkflowResult(
        workflowId: workflowId,
        success: success,
        errorMessage: success ? null : 'One or more steps failed',
        stepResults: stepResults,
        duration: stopwatch.elapsed,
        completedAt: DateTime.now(),
      );

      if (success) {
        _workflowStates[workflowId] = WorkflowState.completed;
        _executionHistory
            .putIfAbsent(workflowId, () => <DateTime>[])
            .add(result.completedAt);

        // Keep a real cached result for idempotent replays.
        if (_config.enableIdempotency && idempotencyKey != null) {
          _idempotentResults[idempotencyKey] = result;
        }
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      _workflowStates[workflowId] = WorkflowState.failed;
      return WorkflowResult(
        workflowId: workflowId,
        success: false,
        errorMessage: 'Workflow execution failed: $e',
        duration: stopwatch.elapsed,
        completedAt: DateTime.now(),
      );
    }
  }

  /// Execute a single workflow step
  Future<StepResult> _executeStep(
    WorkflowStep step,
    Map<String, dynamic> workflowParameters, {
    String? idempotencyKey,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Get the action
      final action = actionRegistry.getAction(step.actionId);
      if (action == null) {
        return StepResult(
          stepId: step.id,
          actionId: step.actionId,
          success: false,
          errorMessage: 'Action not found: ${step.actionId}',
          duration: stopwatch.elapsed,
        );
      }

      // Merge parameters
      final params = <String, dynamic>{
        ...action.defaultParameters ?? {},
        ...step.parameters ?? {},
        ...workflowParameters,
      };

      // Execute the action (async handlers are supported too)
      var output = actionRegistry.executeAction(
        step.actionId,
        params,
        idempotencyKey: step.isCritical && _config.enableIdempotency
            ? idempotencyKey
            : null,
      );
      if (output is Future) {
        output = await output;
      }

      stopwatch.stop();

      return StepResult(
        stepId: step.id,
        actionId: step.actionId,
        success: true,
        output: output,
        duration: stopwatch.elapsed,
        context: {'action': action.name},
      );
    } catch (e) {
      stopwatch.stop();
      return StepResult(
        stepId: step.id,
        actionId: step.actionId,
        success: false,
        errorMessage: 'Step failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Register a workflow so it can be executed.
  void registerWorkflow(WorkflowDefinition workflow) {
    if (!workflow.isValid) {
      throw ArgumentError(
        'Invalid workflow "${workflow.id}": steps must be non-empty, valid '
        'and free of cycles or unknown dependencies.',
      );
    }
    _workflows[workflow.id] = workflow;
  }

  /// Remove a registered workflow.
  bool unregisterWorkflow(String workflowId) {
    _workflowStates.remove(workflowId);
    return _workflows.remove(workflowId) != null;
  }

  /// Get a registered workflow.
  WorkflowDefinition? getWorkflow(String workflowId) =>
      _workflows[workflowId];

  /// All registered workflows.
  List<WorkflowDefinition> get workflows =>
      List.unmodifiable(_workflows.values);

  /// Suggest or prepare a workflow without executing any step.
  Future<WorkflowResult> _previewWorkflow(
    WorkflowDefinition workflow, {
    required AutomationLevel level,
    required Stopwatch stopwatch,
  }) async {
    final stepResults = <StepResult>[];

    for (final step in _orderedSteps(workflow)) {
      final action = actionRegistry.getAction(step.actionId);
      final permitted = permissionManager.hasPermission(
        step.actionId,
        PermissionLevel.execute,
      );
      final ready = action != null && permitted;

      stepResults.add(StepResult(
        stepId: step.id,
        actionId: step.actionId,
        success: ready,
        errorMessage: action == null
            ? 'Action not found: ${step.actionId}'
            : permitted
                ? null
                : 'Permission denied',
        duration: Duration.zero,
        context: {
          'prepared': ready,
          'level': level.name,
          'description': step.description,
        },
      ));
    }

    _workflowStates[workflow.id] = WorkflowState.pending;
    stopwatch.stop();

    final ready = stepResults.every((s) => s.success);

    return WorkflowResult(
      workflowId: workflow.id,
      // A suggestion always succeeds; a prepared plan only succeeds when every
      // step is ready to run.
      success: level == AutomationLevel.suggest ? true : ready,
      errorMessage: level == AutomationLevel.suggest || ready
          ? null
          : 'Workflow is not ready to run',
      stepResults: stepResults,
      duration: stopwatch.elapsed,
      completedAt: DateTime.now(),
    );
  }

  /// Order steps by dependency, then by [WorkflowStep.order].
  List<WorkflowStep> _orderedSteps(WorkflowDefinition workflow) {
    final remaining = List<WorkflowStep>.from(workflow.steps);
    final ordered = <WorkflowStep>[];
    final placed = <String>{};

    while (remaining.isNotEmpty) {
      final ready = remaining
          .where((s) => s.dependsOn.every(placed.contains))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      if (ready.isEmpty) {
        // Unreachable for registered (validated) workflows, but never drop
        // steps silently.
        ordered.addAll(remaining);
        break;
      }

      for (final step in ready) {
        ordered.add(step);
        placed.add(step.id);
        remaining.remove(step);
      }
    }

    return ordered;
  }

  /// Create a workflow from an execution plan
  Future<WorkflowResult> executePlan(
    ExecutionPlan plan, {
    Map<String, dynamic>? additionalParameters,
    bool requireConfirmation = true,
  }) async {
    // Convert plan to workflow
    final workflow = WorkflowDefinition(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      name: plan.goal,
      steps: plan.steps.asMap().entries.map((e) {
        return WorkflowStep(
          id: 'step_${e.key}',
          actionId: e.value.actionId,
          name: e.value.description,
          parameters: e.value.parameters,
          level: e.value.requiresApproval
              ? AutomationLevel.prepare
              : AutomationLevel.execute,
          requiresConfirmation: e.value.requiresApproval,
        );
      }).toList(),
      createdAt: DateTime.now(),
    );

    // Plans produce dynamic workflows, so register before executing them.
    registerWorkflow(workflow);

    return executeWorkflow(
      workflow.id,
      parameters: additionalParameters ?? {},
      requireConfirmation: requireConfirmation,
    );
  }

  /// Generate an execution plan for a goal
  Future<ExecutionPlan?> generatePlan(String goal) async {
    // In a real implementation, this would use AI to generate a plan
    // For now, return null (no plan generation capability)

    // Example: Parse simple goals
    final lowerGoal = goal.toLowerCase();

    final mentionsReport = lowerGoal.contains('report');
    final wantsCreation = lowerGoal.contains('create') ||
        lowerGoal.contains('generate') ||
        lowerGoal.contains('prepare');

    if (mentionsReport && wantsCreation) {
      return ExecutionPlan(
        goal: 'Prepare report',
        steps: [
          PlannedStep(
            sequence: 1,
            actionId: 'create_report',
            description: 'Create the report',
            requiresApproval: false,
            parameters: {'type': 'weekly'},
          ),
          PlannedStep(
            sequence: 2,
            actionId: 'open_report',
            description: 'Open the report for review',
            requiresApproval: false,
          ),
        ],
        generatedBy: 'rule_based',
      );
    }

    if (lowerGoal.contains('reorder') || lowerGoal.contains('restock')) {
      return ExecutionPlan(
        goal: 'Prepare reorder',
        steps: [
          PlannedStep(
            sequence: 1,
            actionId: 'search_product',
            description: 'Find the product',
            requiresApproval: true,
            parameters: {'name': 'regular item'},
          ),
          PlannedStep(
            sequence: 2,
            actionId: 'add_to_cart',
            description: 'Add to cart',
            requiresApproval: true,
          ),
        ],
        generatedBy: 'rule_based',
      );
    }

    return null;
  }

  /// Pause all running workflows
  void pauseAllWorkflows() {
    for (final entry in _workflowStates.entries) {
      if (entry.value == WorkflowState.running) {
        _workflowStates[entry.key] = WorkflowState.paused;
      }
    }
  }

  /// Cancel a workflow
  Future<void> cancelWorkflow(String workflowId) async {
    _workflowStates[workflowId] = WorkflowState.cancelled;
  }

  /// Get workflow state
  WorkflowState? getWorkflowState(String workflowId) {
    return _workflowStates[workflowId];
  }

  /// Check if a workflow is running
  bool isWorkflowRunning(String workflowId) {
    return _workflowStates[workflowId] == WorkflowState.running;
  }

  /// Get workflow execution history
  List<DateTime> getExecutionHistory(String workflowId) {
    return List.unmodifiable(
      _executionHistory[workflowId] ?? const <DateTime>[],
    );
  }

  /// Check engine health
  Future<HealthStatus> checkHealth() async {
    return HealthStatus.healthy;
  }

  /// Dispose resources
  Future<void> dispose() async {
    pauseAllWorkflows();
    _workflowStates.clear();
    _workflows.clear();
    _idempotentResults.clear();
    _executionHistory.clear();
  }

  /// Get configuration
  AutomationConfig get config => _config;

  /// Get active workflow count
  int get activeWorkflowCount {
    return _workflowStates.values
        .where((s) => s == WorkflowState.running || s == WorkflowState.pending)
        .length;
  }
}
