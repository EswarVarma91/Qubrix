import 'package:ai_sdk/ai_sdk.dart';

/// Repository for AI SDK operations
class AiRepository {
  final AdaptiveAgentEngine _engine;

  AiRepository(this._engine);

  // Engine access
  AdaptiveAgentEngine get engine => _engine;

  // Model operations
  Future<ModelCandidate?> getSmallestSuitableModel(
    TaskType taskType, {
    double? minQuality,
    DeviceInfo? deviceInfo,
  }) async {
    return await _engine.getSmallestSuitableModel(
      taskType,
      minQuality: minQuality,
      deviceInfo: deviceInfo,
    );
  }

  Future<ModelDownloadResult> downloadModel(
    String modelId, {
    ModelVariant? preferredVariant,
    void Function(ModelProgress)? onProgress,
    void Function(ModelProgress)? onLoadProgress,
  }) async {
    return await _engine.downloadModel(
      modelId,
      onProgress: onProgress,
      onLoadProgress: onLoadProgress,
    );
  }

  bool isModelInstalled(String modelId) =>
      _engine.isModelInstalled(modelId);

  bool isModelLoaded(String modelId) =>
      _engine.isModelLoaded(modelId);

  List<Model> getInstalledModels() => _engine.getInstalledModels();

  void unloadModel(String modelId) => _engine.unloadModel(modelId);

  void unloadAllModels() => _engine.unloadAllModels();

  ModelDownloadResult? getDownloadResult(String modelId) {
    // Not directly exposed, would need to track separately
    return null;
  }

  // Task operations
  Future<OrchestrationResult> executeTask(TaskRequest request) async {
    return await _engine.executeTask(request);
  }

  // Recommendation operations
  Future<Recommendation?> getRecommendation({
    required String contextType,
    Map<String, dynamic>? contextData,
  }) async {
    return await _engine.getRecommendation(
      contextType: contextType,
      contextData: contextData,
    );
  }

  Future<void> acceptRecommendation(String recommendationId) async {
    await _engine.acceptRecommendation(recommendationId);
  }

  void dismissRecommendation(String recommendationId) {
    _engine.dismissRecommendation(recommendationId);
  }

  // Automation operations
  Future<AutomationResult> executeAutomation(
    String workflowId, {
    Map<String, dynamic>? parameters,
    bool requireConfirmation = true,
  }) async {
    return await _engine.executeAutomation(
      workflowId,
      parameters: parameters,
      requireConfirmation: requireConfirmation,
    );
  }

  // Health check
  Future<EngineHealth> checkHealth() async {
    return await _engine.checkHealth();
  }

  // User profile
  Future<UserProfile?> getUserProfile() async {
    return await _engine.getUserProfile();
  }

  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    await _engine.updateUserPreferences(preferences);
  }

  Future<void> clearPersonalizationData() async {
    await _engine.clearPersonalizationData();
  }

  // Permissions
  Future<PermissionGrant> requestPermission(
    String actionId, {
    required PermissionLevel level,
    String? reason,
  }) async {
    return await _engine.requestPermission(
      actionId,
      level: level,
      reason: reason,
    );
  }

  bool hasPermission(String actionId, PermissionLevel level) =>
      _engine.hasPermission(actionId, level);
}
