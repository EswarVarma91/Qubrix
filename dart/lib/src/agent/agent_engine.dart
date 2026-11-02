/// Adaptive AI Agent Engine
///
/// The core engine that combines model management with personalization.
///
/// This engine provides:
/// 1. Adaptive model delivery - smallest validated model for tasks
/// 2. Automatic compatibility management
/// 3. Personalized assistance - learns permitted in-app routines

import '../core/types.dart';
import '../task_orchestrator.dart';
import '../model/model_manager.dart';
import '../model/model_optimizer.dart';
import '../model/model_catalog.dart';
import '../model/model_types.dart';
import '../model/compatibility_engine.dart';
import '../automation/action_registry.dart';
import '../automation/permission_manager.dart';
import '../automation/automation_engine.dart';
import '../personalization/activity_event.dart';
import '../personalization/personalization_engine.dart';
import '../personalization/profile_manager.dart';
import '../personalization/recommendation_engine.dart';

/// Configuration for the [AdaptiveAgentEngine].
class AgentEngineConfig {
  /// Enable model management (download, install, unload).
  final bool enableModelManagement;

  /// Enable the personalization engine.
  final bool enablePersonalization;

  /// Enable the recommendation engine (requires personalization).
  final bool enableRecommendations;

  /// Enable the automation engine.
  final bool enableAutomation;

  /// Privacy mode used for personalization data.
  final PrivacyMode privacyMode;

  /// Maximum number of recent activity events kept in memory.
  final int maxRecentActivity;

  const AgentEngineConfig({
    this.enableModelManagement = true,
    this.enablePersonalization = true,
    this.enableRecommendations = true,
    this.enableAutomation = true,
    this.privacyMode = PrivacyMode.localFirst,
    this.maxRecentActivity = 1000,
  });
}

/// Types of events emitted by the engine.
enum AgentEventType {
  initialized,
  disposed,
  actionRegistered,
  modelDownloaded,
  modelUnloaded,
  taskCompleted,
  taskFailed,
  activityRecorded,
  recommendationGenerated,
  automationRegistered,
  securityEvent,
  error,
}

/// Event emitted by the [AdaptiveAgentEngine].
class AgentEvent {
  final AgentEventType type;
  final String? message;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  AgentEvent({
    required this.type,
    this.message,
    this.data = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'AgentEvent(${type.name}: ${message ?? ""})';
}

/// Main Adaptive AI Agent Engine
///
/// This is the primary entry point for developers integrating the SDK.
class AdaptiveAgentEngine {
  final AgentEngineConfig config;

  late final ModelCatalog _modelCatalog;
  late final CompatibilityEngine _compatibilityEngine;
  late final ModelManager _modelManager;
  late final ModelOptimizer _modelOptimizer;
  late final TaskOrchestrator _taskOrchestrator;
  late final AutomationEngine _automationEngine;

  final ActionRegistry _actionRegistry = ActionRegistry();
  final PermissionManager _permissionManager = PermissionManager();
  final List<void Function(AgentEvent)> _listeners = [];

  PersonalizationEngine? _personalizationEngine;
  RecommendationEngine? _recommendationEngine;
  ProfileManager? _profileManager;

  bool _initialized = false;
  bool _disposed = false;

  AdaptiveAgentEngine({AgentEngineConfig? config})
      : config = config ?? const AgentEngineConfig() {
    _modelCatalog = ModelCatalog();
    _compatibilityEngine = CompatibilityEngine();
    _modelManager = ModelManager(
      catalog: _modelCatalog,
      compatibilityEngine: _compatibilityEngine,
    );
    _modelOptimizer = ModelOptimizer(catalog: _modelCatalog);
    _taskOrchestrator = TaskOrchestrator(
      modelManager: _modelManager,
      compatibilityEngine: _compatibilityEngine,
      modelOptimizer: _modelOptimizer,
    );
    _automationEngine = AutomationEngine(
      actionRegistry: _actionRegistry,
      permissionManager: _permissionManager,
    );
  }

  /// Initialize the engine and all enabled subsystems.
  Future<void> initialize() async {
    if (_initialized || _disposed) return;

    if (config.enableModelManagement) {
      await _modelManager.initialize();
    }

    if (config.enablePersonalization) {
      _profileManager = ProfileManager();
      _personalizationEngine = PersonalizationEngine(
        profileManager: _profileManager!,
        privacyMode: config.privacyMode,
        maxRecentActivity: config.maxRecentActivity,
      );
    }

    if (config.enableRecommendations && _personalizationEngine != null) {
      _recommendationEngine = RecommendationEngine(
        personalizationEngine: _personalizationEngine!,
        actionRegistry: _actionRegistry,
        onAutomationAccepted: _registerAutomationFromRecommendation,
      );
    }

    _initialized = true;
    _emit(AgentEventType.initialized, message: 'Engine initialized');
  }

  /// Execute a task through the orchestration pipeline.
  Future<OrchestrationResult> executeTask(TaskRequest request) async {
    _ensureUsable();
    final result = await _taskOrchestrator.orchestrateTask(request);
    _emit(
      result.success ? AgentEventType.taskCompleted : AgentEventType.taskFailed,
      message: result.errorMessage ?? 'Task ${request.taskId} completed',
      data: {'taskId': request.taskId},
    );
    return result;
  }

  /// Register an application action that the automation engine can use.
  void registerAction(ActionDefinition action) {
    _actionRegistry.registerAction(action);
    _emit(
      AgentEventType.actionRegistered,
      message: 'Action registered: ${action.id}',
      data: {'actionId': action.id},
    );
  }

  /// Record an observed user interaction.
  ///
  /// This is the listening half of the personalization loop: report the
  /// interactions that matter and the SDK learns the routines the user repeats
  /// so they can be automated.
  Future<void> recordActivity(ActivityEvent event) async {
    _ensureUsable();
    await _personalizationEngine?.recordActivity(event);
    _emit(
      AgentEventType.activityRecorded,
      message: event.eventType.name,
      data: {
        'eventId': event.eventId,
        'actionId': event.actionId,
        'taskType': event.taskType?.name,
      },
    );
  }

  /// Report a repeated app action (a feature tap, a command, ...).
  Future<void> trackAction(
    String actionId, {
    String? name,
    int durationMs = 0,
    Map<String, dynamic>? context,
  }) {
    return recordActivity(ActivityEvent(
      eventType: ActivityEventType.featureUsage,
      actionId: actionId,
      durationMs: durationMs,
      context: {
        'featureName': name ?? actionId,
        ...?context,
      },
    ));
  }

  /// Routines learned from repeated user activity, most frequent first.
  Future<List<DetectedRoutine>> getDetectedRoutines({int limit = 10}) async {
    final profile = await _profileManager?.getUserProfile();
    return profile?.getMostFrequentRoutines(limit: limit) ?? const [];
  }

  /// Detected routines that are frequent and confident enough to automate.
  Future<List<DetectedRoutine>> getAutomationCandidates({int limit = 5}) async {
    final routines = await getDetectedRoutines(limit: 50);
    return routines
        .where((r) => r.steps.isNotEmpty && r.isReadyForSuggestion)
        .take(limit)
        .toList();
  }

  /// Build and register an automation workflow from a learned routine.
  ///
  /// The workflow defaults to [AutomationLevel.suggest], so nothing runs until
  /// the host app executes it explicitly.
  Future<WorkflowDefinition?> registerRoutineAutomation(
    String routineId, {
    AutomationLevel level = AutomationLevel.suggest,
  }) async {
    _ensureUsable();

    final profile = await _profileManager?.getUserProfile();
    if (profile == null) return null;

    final index = profile.routines.indexWhere((r) => r.routineId == routineId);
    if (index < 0) return null;

    final routine = profile.routines[index];
    if (routine.steps.isEmpty) return null;

    final workflow = _workflowFromRoutine(routine, level: level);
    _automationEngine.registerWorkflow(workflow);
    await _profileManager?.upsertRoutine(
      routine.copyWith(status: RoutineStatus.automated),
    );

    _emit(
      AgentEventType.automationRegistered,
      message: workflow.name,
      data: {'workflowId': workflow.id, 'routineId': routineId},
    );
    return workflow;
  }

  /// Run a registered automation workflow.
  Future<WorkflowResult> runAutomation(
    String workflowId, {
    Map<String, dynamic> parameters = const {},
    AutomationLevel level = AutomationLevel.execute,
    bool requireConfirmation = true,
  }) {
    _ensureUsable();
    return _automationEngine.executeWorkflow(
      workflowId,
      parameters: parameters,
      level: level,
      requireConfirmation: requireConfirmation,
    );
  }

  /// Accept a generated recommendation, creating its automation if it has one.
  Future<void> acceptRecommendation(String recommendationId) async {
    _ensureUsable();
    await _recommendationEngine?.acceptRecommendation(recommendationId);
  }

  /// Dismiss a generated recommendation.
  void dismissRecommendation(String recommendationId) {
    _recommendationEngine?.dismissRecommendation(recommendationId);
  }

  /// Request permission to perform an action.
  Future<PermissionGrant> requestPermission({
    required String actionId,
    required PermissionLevel level,
    String? reason,
  }) {
    return _permissionManager.requestPermission(
      actionId: actionId,
      level: level,
      reason: reason,
    );
  }

  /// Whether permission is granted for an action at the given level.
  bool hasPermission(String actionId, PermissionLevel level) {
    return _permissionManager.hasPermission(actionId, level);
  }

  /// Download and install a model.
  Future<ModelDownloadResult> downloadModel(
    String modelId, {
    void Function(ModelProgress)? onProgress,
    void Function(ModelProgress)? onLoadProgress,
  }) async {
    _ensureUsable();
    final deviceInfo = await _compatibilityEngine.getDeviceInfo();
    final result = await _modelManager.downloadModel(
      modelId,
      deviceInfo,
      onProgress: onProgress,
      onLoadProgress: onLoadProgress,
    );
    if (result.success) {
      _emit(
        AgentEventType.modelDownloaded,
        message: 'Model installed: $modelId',
        data: {'modelId': modelId},
      );
    }
    return result;
  }

  bool isModelOperationInProgress(String modelId) =>
      _modelManager.isDownloading(modelId);

  ModelProgress? getModelProgress(String modelId) =>
      _modelManager.getDownloadProgress(modelId)?.toModelProgress();

  bool isModelLoaded(String modelId) => _modelManager.isModelLoaded(modelId);

  void unloadModel(String modelId) {
    _modelManager.unloadModel(modelId);
    _emit(AgentEventType.modelUnloaded, data: {'modelId': modelId});
  }

  void unloadAllModels() {
    _modelManager.unloadAllModels();
  }

  bool isModelInstalled(String modelId) =>
      _modelManager.isModelInstalled(modelId);

  List<Model> getInstalledModels() => _modelManager.installedModels;

  /// Find the smallest model suitable for a task type.
  Future<ModelCandidate?> getSmallestSuitableModel(
    TaskType taskType, {
    double? minQuality,
    DeviceInfo? deviceInfo,
  }) async {
    final info = deviceInfo ?? await _compatibilityEngine.getDeviceInfo();
    return _modelOptimizer.findSmallestSuitableModel(
      taskType: taskType,
      deviceInfo: info,
      minQuality: minQuality ?? 0.7,
    );
  }

  /// Ranked model recommendations for a set of task requirements.
  Future<List<ModelRecommendation>> getModelRecommendations(
    TaskRequirements requirements,
  ) {
    return _modelOptimizer.getRecommendations(requirements);
  }

  /// Generate a personalized recommendation, if enough data is available.
  Future<Recommendation?> getRecommendation({
    required String contextType,
    Map<String, dynamic>? contextData,
  }) async {
    final engine = _recommendationEngine;
    if (engine == null) return null;
    final recommendation = await engine.generateRecommendation(
      contextType: contextType,
      contextData: contextData,
    );
    if (recommendation != null) {
      _emit(
        AgentEventType.recommendationGenerated,
        message: recommendation.title,
        data: {'recommendationId': recommendation.id},
      );
    }
    return recommendation;
  }

  /// Get the current user profile.
  Future<UserProfile?> getUserProfile() =>
      _profileManager?.getUserProfile() ?? Future<UserProfile?>.value(null);

  /// Update user preferences used for personalization.
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    await _profileManager?.updatePreferences(preferences);
  }

  /// Clear all personalization data.
  Future<void> clearPersonalizationData() async {
    await _profileManager?.clearAllData();
    _personalizationEngine?.clearRecentActivity();
  }

  /// Check the health of every enabled subsystem.
  Future<EngineHealth> checkHealth() async {
    final modelStatus = await _modelManager.checkHealth();
    final personalizationStatus = await _personalizationEngine?.checkHealth();

    final components = <String, bool>{
      'models': modelStatus.isHealthy,
      if (personalizationStatus != null)
        'personalization': personalizationStatus.isHealthy,
    };

    final healthy = components.values.every((value) => value);

    return EngineHealth(
      isHealthy: healthy,
      message: healthy ? 'All engines healthy' : 'One or more engines degraded',
      installedModels: _modelManager.installedModels.length,
      components: components,
    );
  }

  /// Register a listener for engine events.
  void addEventListener(void Function(AgentEvent event) listener) {
    _listeners.add(listener);
  }

  /// Remove a previously registered listener.
  void removeEventListener(void Function(AgentEvent event) listener) {
    _listeners.remove(listener);
  }

  /// Build a workflow from a learned routine.
  WorkflowDefinition _workflowFromRoutine(
    DetectedRoutine routine, {
    required AutomationLevel level,
  }) {
    final workflowId = 'routine_${_slug(routine.routineId)}';
    final steps = routine.steps.asMap().entries.map((entry) {
      final step = entry.value;
      return WorkflowStep(
        id: '${workflowId}_step_${entry.key}',
        actionId: step.actionId,
        name: step.name,
        parameters: step.typicalParameters,
        dependsOn: entry.key == 0
            ? const []
            : ['${workflowId}_step_${entry.key - 1}'],
        level: level,
        requiresConfirmation: step.requiresConfirmation,
        order: step.order,
      );
    }).toList();

    return WorkflowDefinition(
      id: workflowId,
      name: 'Automate ${routine.name}',
      description: routine.description,
      steps: steps,
      defaultLevel: level,
      createdAt: DateTime.now(),
      metadata: {
        'routineId': routine.routineId,
        'frequency': routine.frequency,
        'confidence': routine.confidence,
      },
    );
  }

  /// Register an automation when the user accepts an automation recommendation.
  Future<void> _registerAutomationFromRecommendation(
    Recommendation recommendation,
  ) async {
    final parameters = recommendation.actionParameters;
    final actionIds =
        (parameters?['actionIds'] as List<dynamic>?)
            ?.map((id) => id.toString())
            .toList() ??
        [if (recommendation.actionId != null) recommendation.actionId!];
    if (actionIds.isEmpty) return;

    final workflowId = 'rec_${_slug(recommendation.id)}';
    if (_automationEngine.getWorkflow(workflowId) != null) return;

    final steps = actionIds.asMap().entries.map((entry) {
      final actionId = entry.value;
      return WorkflowStep(
        id: '${workflowId}_step_${entry.key}',
        actionId: actionId,
        name: _actionRegistry.getAction(actionId)?.name ?? actionId,
        dependsOn: entry.key == 0
            ? const []
            : ['${workflowId}_step_${entry.key - 1}'],
        order: entry.key,
      );
    }).toList();

    _automationEngine.registerWorkflow(WorkflowDefinition(
      id: workflowId,
      name: recommendation.title,
      description: recommendation.description,
      steps: steps,
      defaultLevel: AutomationLevel.suggest,
      metadata: {
        'recommendationId': recommendation.id,
        if (parameters?['routineId'] != null)
          'routineId': parameters!['routineId'],
      },
    ));

    final routineId = parameters?['routineId'];
    if (routineId is String) {
      final profile = await _profileManager?.getUserProfile();
      final index =
          profile?.routines.indexWhere((r) => r.routineId == routineId) ?? -1;
      if (profile != null && index >= 0) {
        await _profileManager?.upsertRoutine(
          profile.routines[index].copyWith(status: RoutineStatus.automated),
        );
      }
    }

    _emit(
      AgentEventType.automationRegistered,
      message: recommendation.title,
      data: {
        'workflowId': workflowId,
        'recommendationId': recommendation.id,
      },
    );
  }

  String _slug(String value) {
    final slug = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return slug.isEmpty ? 'item' : slug;
  }

  void _emit(
    AgentEventType type, {
    String? message,
    Map<String, dynamic> data = const {},
  }) {
    if (_listeners.isEmpty) return;
    final event = AgentEvent(type: type, message: message, data: data);
    for (final listener in List.of(_listeners)) {
      listener(event);
    }
  }

  void _ensureUsable() {
    if (!_initialized) throw StateError('Engine not initialized');
    if (_disposed) throw StateError('Engine has been disposed');
  }

  Future<void> dispose() async {
    if (_disposed) return;
    await _personalizationEngine?.dispose();
    await _automationEngine.dispose();
    _modelManager.unloadAllModels();
    _disposed = true;
    _initialized = false;
    _emit(AgentEventType.disposed, message: 'Engine disposed');
  }

  bool get isInitialized => _initialized;
  bool get isDisposed => _disposed;

  AgentEngineConfig get agentConfig => config;
  ModelCatalog get modelCatalog => _modelCatalog;
  ModelManager get modelManager => _modelManager;
  CompatibilityEngine get compatibilityEngine => _compatibilityEngine;
  ModelOptimizer get modelOptimizer => _modelOptimizer;
  TaskOrchestrator get taskOrchestrator => _taskOrchestrator;
  ActionRegistry get actionRegistry => _actionRegistry;
  PermissionManager get permissionManager => _permissionManager;
  AutomationEngine get automationEngine => _automationEngine;
  PersonalizationEngine? get personalizationEngine => _personalizationEngine;
  RecommendationEngine? get recommendationEngine => _recommendationEngine;
  ProfileManager? get profileManager => _profileManager;
}
