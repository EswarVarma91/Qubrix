/// Adaptive AI Agent Engine
///
/// The core engine that combines model management, personalization,
/// recommendations, and automation into a unified platform.
///
/// This engine provides:
/// 1. Adaptive model delivery - smallest validated model for tasks
/// 2. Automatic compatibility management
/// 3. Personalized assistance - learns permitted in-app routines
/// 4. Safe application automation - combines developer-defined actions

import '../model/model_manager.dart';
import '../model/compatibility_engine.dart';
import '../model/model_optimizer.dart';
import '../model/model_catalog.dart';
import '../personalization/personalization_engine.dart';
import '../personalization/recommendation_engine.dart';
import '../personalization/profile_manager.dart';
import '../automation/automation_engine.dart';
import '../automation/action_registry.dart';
import '../automation/permission_manager.dart';
import '../core/task_orchestrator.dart';
import '../core/types.dart';

/// Configuration for the AI Agent Engine
class AgentEngineConfig {
  /// Enable model management
  final bool enableModelManagement;

  /// Enable personalization
  final bool enablePersonalization;

  /// Enable recommendations
  final bool enableRecommendations;

  /// Enable automation
  final bool enableAutomation;

  /// Privacy mode - controls data handling
  final PrivacyMode privacyMode;

  /// Minimum quality threshold for model selection
  final double minModelQuality;

  /// Default timeout for operations
  final Duration defaultTimeout;

  /// Whether to use cloud services when available
  final bool useCloudFailover;

  const AgentEngineConfig({
    this.enableModelManagement = true,
    this.enablePersonalization = true,
    this.enableRecommendations = true,
    this.enableAutomation = true,
    this.privacyMode = PrivacyMode.localFirst,
    this.minModelQuality = 0.7,
    this.defaultTimeout = const Duration(seconds: 30),
    this.useCloudFailover = true,
  });
}

enum PrivacyMode {
  /// All processing happens on-device
  localOnly,

  /// Prefer local, use cloud as fallback
  localFirst,

  /// Balanced use of local and cloud
  balanced,

  /// Cloud preferred when available
  cloudFirst,
}

/// Callback types for engine events
typedef EngineEventCallback = void Function(AgentEvent event);

/// Types of engine events
enum AgentEventType {
  /// A model was downloaded or installed
  modelInstalled,

  /// A model was removed
  modelRemoved,

  /// A task was executed
  taskExecuted,

  /// A recommendation was made
  recommendationMade,

  /// A recommendation was accepted
  recommendationAccepted,

  /// A recommendation was dismissed
  recommendationDismissed,

  /// An automation was created
  automationCreated,

  /// An automation was executed
  automationExecuted,

  /// An automation was disabled
  automationDisabled,

  /// A pattern was detected
  patternDetected,

  /// Error occurred
  error,
}

/// An event from the engine
class AgentEvent {
  final AgentEventType type;
  final String? taskId;
  final String? modelId;
  final String? actionId;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  const AgentEvent({
    required this.type,
    this.taskId,
    this.modelId,
    this.actionId,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Main Adaptive AI Agent Engine
///
/// This is the primary entry point for developers integrating the SDK.
/// It orchestrates all subsystems and provides a unified API.
class AdaptiveAgentEngine {
  /// Model management
  late final ModelManager _modelManager;

  /// Compatibility checking
  late final CompatibilityEngine _compatibilityEngine;

  /// Model selection optimization
  late final ModelOptimizer _modelOptimizer;

  /// Model catalog
  late final ModelCatalog _modelCatalog;

  /// Task orchestration
  late final TaskOrchestrator _taskOrchestrator;

  /// Personalization (optional)
  PersonalizationEngine? _personalizationEngine;

  /// Recommendation engine (optional)
  RecommendationEngine? _recommendationEngine;

  /// Automation engine (optional)
  AutomationEngine? _automationEngine;

  /// Action registry
  late final ActionRegistry _actionRegistry;

  /// Permission management
  late final PermissionManager _permissionManager;

  /// Profile management
  ProfileManager? _profileManager;

  /// Configuration
  AgentEngineConfig _config;

  /// Event listeners
  final List<EngineEventCallback> _eventListeners = [];

  /// Whether the engine is initialized
  bool _initialized = false;

  /// Whether the engine is disposed
  bool _disposed = false;

  /// Create a new Adaptive Agent Engine
  AdaptiveAgentEngine({
    AgentEngineConfig? config,
  }) : _config = config ?? const AgentEngineConfig() {
    // Initialize core components
    _modelCatalog = ModelCatalog();
    _modelManager = ModelManager(
      catalog: _modelCatalog,
      compatibilityEngine: null, // Will be set after creation
    );
    _compatibilityEngine = CompatibilityEngine();
    _modelManager = ModelManager(
      catalog: _modelCatalog,
      compatibilityEngine: _compatibilityEngine,
    );
    _modelOptimizer = ModelOptimizer(catalog: _modelCatalog);
    _actionRegistry = ActionRegistry();
    _permissionManager = PermissionManager();

    // Create task orchestrator with core components
    _taskOrchestrator = TaskOrchestrator(
      modelManager: _modelManager,
      compatibilityEngine: _compatibilityEngine,
      modelOptimizer: _modelOptimizer,
      config: TaskOrchestrationConfig(
        minQualityThreshold: _config.minModelQuality,
        timeout: _config.defaultTimeout,
      ),
    );
  }

  /// Initialize the engine
  Future<void> initialize() async {
    if (_initialized) return;
    if (_disposed) {
      throw StateError('Engine has been disposed');
    }

    // Initialize model manager
    await _modelManager.initialize();

    // Initialize optional components based on config
    if (_config.enablePersonalization) {
      _initializePersonalization();
    }

    if (_config.enableAutomation) {
      _initializeAutomation();
    }

    _initialized = true;
  }

  /// Initialize personalization components
  void _initializePersonalization() {
    _profileManager = ProfileManager(
      privacyMode: _config.privacyMode,
    );

    _personalizationEngine = PersonalizationEngine(
      profileManager: _profileManager!,
      privacyMode: _config.privacyMode,
    );

    _recommendationEngine = RecommendationEngine(
      personalizationEngine: _personalizationEngine!,
      actionRegistry: _actionRegistry,
      config: RecommendationConfig(
        usePersonalization: _config.enablePersonalization,
        useContext: true,
      ),
    );

    // Update orchestrator with personalization
    _taskOrchestrator.updateConfig(
      TaskOrchestrationConfig(
        minQualityThreshold: _config.minModelQuality,
        preferRulesOverModels: true,
        usePersonalization: true,
        useRecommendations: _config.enableRecommendations,
        timeout: _config.defaultTimeout,
      ),
    );
  }

  /// Initialize automation components
  void _initializeAutomation() {
    _automationEngine = AutomationEngine(
      actionRegistry: _actionRegistry,
      permissionManager: _permissionManager,
      config: AutomationConfig(
        requireConfirmationForSideEffects: true,
        maxConcurrentWorkflows: 3,
      ),
    );
  }

  /// Register an application action that the automation engine can use
  void registerAction(ActionDefinition action) {
    if (!_initialized) {
      throw StateError('Engine not initialized');
    }
    if (_disposed) {
      throw StateError('Engine has been disposed');
    }

    _actionRegistry.registerAction(action);

    // Notify listeners
    _notifyEvent(AgentEvent(
      type: AgentEventType.automationCreated,
      actionId: action.id,
      data: {'action': action.name},
    ));
  }

  /// Register multiple actions
  void registerActions(List<ActionDefinition> actions) {
    for (final action in actions) {
      registerAction(action);
    }
  }

  /// Unregister an action
  void unregisterAction(String actionId) {
    _actionRegistry.unregisterAction(actionId);
  }

  /// Request permission for an action type
  Future<PermissionGrant> requestPermission(
    String actionId, {
    required PermissionLevel level,
    String? reason,
  }) async {
    if (!_initialized) {
      throw StateError('Engine not initialized');
    }

    return await _permissionManager.requestPermission(
      actionId: actionId,
      level: level,
      reason: reason,
    );
  }

  /// Check if permission is granted
  bool hasPermission(String actionId, PermissionLevel level) {
    return _permissionManager.hasPermission(actionId, level);
  }

  /// Execute a task through the orchestrator
  Future<OrchestrationResult> executeTask(TaskRequest request) async {
    if (!_initialized) {
      throw StateError('Engine not initialized');
    }
    if (_disposed) {
      throw StateError('Engine has been disposed');
    }

    // Add personalization context if available
    Map<String, dynamic> enhancedContext = {};
    if (_config.enablePersonalization && _personalizationEngine != null) {
      final profile = await _personalizationEngine!.getUserProfile();
      enhancedContext['userProfile'] = profile;
    }

    final enhancedRequest = TaskRequest(
      taskId: request.taskId,
      description: request.description,
      input: request.input,
      taskType: request.taskType,
      context: {
        ...request.context,
        ...enhancedContext,
      },
      parameters: request.parameters,
      actionId: request.actionId,
      useModel: request.useModel,
    );

    // Execute task
    final result = await _taskOrchestrator.orchestrateTask(enhancedRequest);

    // Record activity for personalization
    if (_config.enablePersonalization && _personalizationEngine != null) {
      await _personalizationEngine!.recordActivity(
        ActivityEvent(
          eventType: ActivityEventType.taskExecution,
          taskType: request.taskType,
          taskId: request.taskId,
          success: result.success,
          duration: result.duration ?? Duration.zero,
          context: request.context,
          metadata: {
            'modelsConsidered': result.steps
                .where((s) => s.type == StepType.modelSelection)
                .map((s) => s.details)
                .toList(),
            'approach': _determineApproach(result),
          },
        ),
      );
    }

    // Notify listeners
    _notifyEvent(AgentEvent(
      type: AgentEventType.taskExecuted,
      taskId: request.taskId,
      data: {
        'success': result.success,
        'duration': result.duration?.inMilliseconds,
      },
    ));

    return result;
  }

  /// Determine which approach was used for a task
  String _determineApproach(OrchestrationResult result) {
    final modelSelectionStep = result.steps
        .where((s) => s.type == StepType.modelSelection)
        .firstOrNull;

    if (modelSelectionStep != null && modelSelectionStep.success) {
      return 'model';
    }
    return 'rules';
  }

  /// Get a recommendation based on current context
  Future<Recommendation?> getRecommendation({
    required String contextType,
    Map<String, dynamic>? contextData,
  }) async {
    if (!_config.enableRecommendations ||
        _recommendationEngine == null) {
      return null;
    }

    final recommendation = await _recommendationEngine!.generateRecommendation(
      contextType: contextType,
      contextData: contextData,
    );

    if (recommendation != null) {
      _notifyEvent(AgentEvent(
        type: AgentEventType.recommendationMade,
        data: {
          'recommendationId': recommendation.id,
          'type': recommendation.type.name,
        },
      ));
    }

    return recommendation;
  }

  /// Accept a recommendation
  Future<void> acceptRecommendation(String recommendationId) async {
    if (_recommendationEngine == null) return;

    await _recommendationEngine!.acceptRecommendation(recommendationId);

    _notifyEvent(AgentEvent(
      type: AgentEventType.recommendationAccepted,
      data: {'recommendationId': recommendationId},
    ));
  }

  /// Dismiss a recommendation
  void dismissRecommendation(String recommendationId) {
    if (_recommendationEngine == null) return;

    _recommendationEngine!.dismissRecommendation(recommendationId);

    _notifyEvent(AgentEvent(
      type: AgentEventType.recommendationDismissed,
      data: {'recommendationId': recommendationId},
    ));
  }

  /// Execute an automation workflow
  Future<AutomationResult> executeAutomation(
    String workflowId, {
    Map<String, dynamic>? parameters,
    bool requireConfirmation = true,
  }) async {
    if (!_config.enableAutomation || _automationEngine == null) {
      return AutomationResult(
        success: false,
        message: 'Automation is not enabled',
      );
    }

    // Check permissions
    final actionId = _getActionIdForWorkflow(workflowId);
    if (actionId != null && !_permissionManager.hasPermission(
      actionId,
      PermissionLevel.execute,
    )) {
      return AutomationResult(
        success: false,
        message: 'Permission not granted for this automation',
      );
    }

    final result = await _automationEngine!.executeWorkflow(
      workflowId,
      parameters ?? {},
      requireConfirmation: requireConfirmation,
    );

    if (result.success) {
      _notifyEvent(AgentEvent(
        type: AgentEventType.automationExecuted,
        actionId: actionId,
        data: {'workflowId': workflowId},
      ));
    }

    return result;
  }

  /// Get the action ID associated with a workflow
  String? _getActionIdForWorkflow(String workflowId) {
    // In a real implementation, this would look up the workflow definition
    return null;
  }

  /// Download a model for a specific task
  Future<ModelDownloadResult> downloadModel(
    String modelId, {
    String? taskType,
    ModelVariant? preferredVariant,
  }) async {
    if (!_initialized) {
      throw StateError('Engine not initialized');
    }

    final deviceInfo = await _compatibilityEngine.getDeviceInfo();

    return await _modelManager.downloadModel(
      modelId,
      deviceInfo,
      preferredVariant: preferredVariant,
    );
  }

  /// Check if a model is installed
  bool isModelInstalled(String modelId) {
    return _modelManager.isModelInstalled(modelId);
  }

  /// Get installed models
  List<Model> getInstalledModels() {
    return _modelManager.installedModels;
  }

  /// Remove a model
  Future<bool> removeModel(String modelId) async {
    final result = await _modelManager.removeModel(modelId);

    if (result) {
      _notifyEvent(AgentEvent(
        type: AgentEventType.modelRemoved,
        modelId: modelId,
      ));
    }

    return result;
  }

  /// Get the smallest model suitable for a task
  Future<ModelCandidate?> getSmallestSuitableModel(
    TaskType taskType, {
    double? minQuality,
    DeviceInfo? deviceInfo,
  }) async {
    final info = deviceInfo ?? await _compatibilityEngine.getDeviceInfo();

    return await _modelOptimizer.findSmallestSuitableModel(
      taskType: taskType,
      deviceInfo: info,
      minQuality: minQuality ?? _config.minModelQuality,
    );
  }

  /// Get model recommendations based on task requirements
  Future<List<ModelRecommendation>> getModelRecommendations(
    TaskRequirements requirements,
  ) async {
    return await _modelOptimizer.getRecommendations(requirements);
  }

  /// Get the user profile (for personalization)
  Future<UserProfile?> getUserProfile() async {
    if (_profileManager == null) return null;
    return await _profileManager.getUserProfile();
  }

  /// Update user profile preferences
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    if (_profileManager == null) return;
    await _profileManager.updatePreferences(preferences);
  }

  /// Clear user personalization data
  Future<void> clearPersonalizationData() async {
    if (_profileManager == null) return;
    await _profileManager.clearAllData();

    // Notify listeners
    _notifyEvent(AgentEvent(
      type: AgentEventType.patternDetected,
      data: {'action': 'cleared_personalization'},
    ));
  }

  /// Enable or disable personalization
  void setPersonalizationEnabled(bool enabled) {
    if (!_config.enablePersonalization) return;

    // This would toggle personalization in the profile manager
    if (_profileManager != null) {
      // Implementation would go here
    }
  }

  /// Enable or disable recommendations
  void setRecommendationsEnabled(bool enabled) {
    // Update config
    _config = AgentEngineConfig(
      ..._configToMap(_config),
      enableRecommendations: enabled,
    );

    // Update orchestrator
    _taskOrchestrator.updateConfig(
      TaskOrchestrationConfig(
        minQualityThreshold: _config.minModelQuality,
        useRecommendations: enabled,
      ),
    );
  }

  /// Enable or disable automation
  void setAutomationEnabled(bool enabled) {
    _config = AgentEngineConfig(
      ..._configToMap(_config),
      enableAutomation: enabled,
    );

    if (!enabled && _automationEngine != null) {
      _automationEngine!.pauseAllWorkflows();
    }
  }

  /// Convert config to map for copying
  Map<String, dynamic> _configToMap(AgentEngineConfig config) {
    return {
      'enableModelManagement': config.enableModelManagement,
      'enablePersonalization': config.enablePersonalization,
      'enableRecommendations': config.enableRecommendations,
      'enableAutomation': config.enableAutomation,
      'privacyMode': config.privacyMode,
      'minModelQuality': config.minModelQuality,
      'defaultTimeout': config.defaultTimeout,
      'useCloudFailover': config.useCloudFailover,
    };
  }

  /// Add an event listener
  void addEventListener(EngineEventCallback callback) {
    _eventListeners.add(callback);
  }

  /// Remove an event listener
  void removeEventListener(EngineEventCallback callback) {
    _eventListeners.remove(callback);
  }

  /// Notify all listeners of an event
  void _notifyEvent(AgentEvent event) {
    for (final listener in List.from(_eventListeners)) {
      try {
        listener(event);
      } catch (e) {
        // Log error but don't propagate
      }
    }
  }

  /// Check engine health
  Future<EngineHealth> checkHealth() async {
    final modelStatus = await _modelManager.checkHealth();
    final personalizationStatus =
        _personalizationEngine?.checkHealth() ?? HealthStatus.unknown;
    final automationStatus =
        _automationEngine?.checkHealth() ?? HealthStatus.unknown;

    return EngineHealth(
      isHealthy: modelStatus == HealthStatus.healthy,
      components: {
        'modelManager': modelStatus,
        'personalization': personalizationStatus,
        'automation': automationStatus,
      },
      installedModels: _modelManager.installedModels.length,
      timestamp: DateTime.now(),
    );
  }

  /// Dispose the engine and release resources
  Future<void> dispose() async {
    if (_disposed) return;

    // Cancel any running workflows
    await _automationEngine?.dispose();
    await _personalizationEngine?.dispose();

    _disposed = true;
    _initialized = false;
  }

  /// Get engine configuration
  AgentEngineConfig get config => _config;

  /// Check if engine is initialized
  bool get isInitialized => _initialized;

  /// Check if engine is disposed
  bool get isDisposed => _disposed;

  /// Access model manager
  ModelManager get modelManager => _modelManager;

  /// Access compatibility engine
  CompatibilityEngine get compatibilityEngine => _compatibilityEngine;

  /// Access model optimizer
  ModelOptimizer get modelOptimizer => _modelOptimizer;

  /// Access action registry
  ActionRegistry get actionRegistry => _actionRegistry;

  /// Access permission manager
  PermissionManager get permissionManager => _permissionManager;

  /// Access personalization engine
  PersonalizationEngine? get personalizationEngine => _personalizationEngine;

  /// Access recommendation engine
  RecommendationEngine? get recommendationEngine => _recommendationEngine;

  /// Access automation engine
  AutomationEngine? get automationEngine => _automationEngine;
}
