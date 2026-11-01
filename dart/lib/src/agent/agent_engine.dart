/// Adaptive AI Agent Engine
///
/// The core engine that combines model management with personalization.
///
/// This engine provides:
/// 1. Adaptive model delivery - smallest validated model for tasks
/// 2. Automatic compatibility management
/// 3. Personalized assistance - learns permitted in-app routines

import '../model/model_manager.dart';
import '../model/model_optimizer.dart';
import '../model/model_catalog.dart';
import '../model/model_types.dart';
import '../model/compatibility_engine.dart';
import '../personalization/personalization_engine.dart';
import '../personalization/recommendation_engine.dart';
import '../personalization/profile_manager.dart';
import '../core/types.dart';
import '../core/task_orchestrator.dart';

/// Main Adaptive AI Agent Engine
///
/// This is the primary entry point for developers integrating the SDK.
class AdaptiveAgentEngine {
  late final ModelManager _modelManager;
  late final CompatibilityEngine _compatibilityEngine;
  late final ModelOptimizer _modelOptimizer;
  late final ModelCatalog _modelCatalog;
  late final TaskOrchestrator _taskOrchestrator;
  PersonalizationEngine? _personalizationEngine;
  RecommendationEngine? _recommendationEngine;
  ProfileManager? _profileManager;
  bool _initialized = false;
  bool _disposed = false;

  AdaptiveAgentEngine() {
    _modelCatalog = ModelCatalog();
    _compatibilityEngine = CompatibilityEngine();
    _modelManager = ModelManager(catalog: _modelCatalog, compatibilityEngine: _compatibilityEngine);
    _modelOptimizer = ModelOptimizer(catalog: _modelCatalog);
    _taskOrchestrator = TaskOrchestrator(_modelManager);
  }

  Future<void> initialize() async {
    if (_initialized || _disposed) return;
    await _modelManager.initialize();
    _personalizationEngine = PersonalizationEngine(profileManager: ProfileManager());
    _recommendationEngine = RecommendationEngine(personalizationEngine: _personalizationEngine!);
    _initialized = true;
  }

  Future<OrchestrationResult> executeTask(TaskRequest request) async {
    if (!_initialized) throw StateError('Engine not initialized');
    if (_disposed) throw StateError('Engine has been disposed');
    return _taskOrchestrator.orchestrate(request);
  }

  Future<ModelDownloadResult> downloadModel(String modelId, {void Function(ModelProgress)? onProgress, void Function(ModelProgress)? onLoadProgress}) async {
    if (!_initialized) throw StateError('Engine not initialized');
    final deviceInfo = await _compatibilityEngine.getDeviceInfo();
    return _modelManager.downloadModel(modelId, deviceInfo, onProgress: onProgress, onLoadProgress: onLoadProgress);
  }

  bool isModelOperationInProgress(String modelId) => _modelManager.isDownloading(modelId);
  ModelProgress? getModelProgress(String modelId) => _modelManager.getDownloadProgress(modelId)?.toModelProgress();
  bool isModelLoaded(String modelId) => _modelManager.isModelLoaded(modelId);
  void unloadModel(String modelId) => _modelManager.unloadModel(modelId);
  void unloadAllModels() => _modelManager.unloadAllModels();
  bool isModelInstalled(String modelId) => _modelManager.isModelInstalled(modelId);
  List<Model> getInstalledModels() => _modelManager.installedModels;

  Future<ModelCandidate?> getSmallestSuitableModel(TaskType taskType, {double? minQuality, DeviceInfo? deviceInfo}) async {
    final info = deviceInfo ?? await _compatibilityEngine.getDeviceInfo();
    return _modelOptimizer.findSmallestSuitableModel(taskType: taskType, deviceInfo: info, minQuality: minQuality ?? 0.7);
  }

  Future<UserProfile?> getUserProfile() async => _profileManager?.getUserProfile();
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    await _profileManager?.updatePreferences(preferences);
  }
  Future<void> clearPersonalizationData() async {
    await _profileManager?.clearAllData();
  }

  Future<EngineHealth> checkHealth() async {
    final modelStatus = await _modelManager.checkHealth();
    return EngineHealth(
      isHealthy: modelStatus == HealthStatus.healthy,
      message: modelStatus.message,
      installedModels: _modelManager.installedModels.length,
    );
  }

  Future<void> dispose() async {
    _disposed = true;
    _initialized = false;
  }

  bool get isInitialized => _initialized;
  ModelManager get modelManager => _modelManager;
  CompatibilityEngine get compatibilityEngine => _compatibilityEngine;
  ModelOptimizer get modelOptimizer => _modelOptimizer;
}