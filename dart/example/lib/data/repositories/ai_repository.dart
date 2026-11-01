import 'package:ai_sdk/ai_sdk.dart';
import '../../core/firebase_remote_config.dart';

/// Repository for AI SDK operations
class AiRepository {
  final AdaptiveAgentEngine _engine;
  final FirebaseRemoteConfigService? _firebaseService;

  AiRepository(this._engine, [this._firebaseService]);

  // Model operations
  Future<ModelCandidate?> getSmallestSuitableModel(
    TaskType taskType, {
    double? minQuality,
    DeviceInfo? deviceInfo,
  }) async {
    return _engine.getSmallestSuitableModel(taskType, minQuality: minQuality, deviceInfo: deviceInfo);
  }

  Future<ModelDownloadResult> downloadModel(
    String modelId, {
    void Function(ModelProgress)? onProgress,
    void Function(ModelProgress)? onLoadProgress,
  }) async {
    return _engine.downloadModel(
      modelId,
      onProgress: onProgress,
      onLoadProgress: onLoadProgress,
    );
  }

  bool isModelInstalled(String modelId) => _engine.isModelInstalled(modelId);
  bool isModelLoaded(String modelId) => _engine.isModelLoaded(modelId);
  List<Model> getInstalledModels() => _engine.getInstalledModels();
  void unloadModel(String modelId) => _engine.unloadModel(modelId);
  void unloadAllModels() => _engine.unloadAllModels();

  // Task operations
  Future<OrchestrationResult> executeTask(TaskRequest request) async {
    return _engine.executeTask(request);
  }

  // Health check
  Future<EngineHealth> checkHealth() async {
    return _engine.checkHealth();
  }

  // User profile
  Future<UserProfile?> getUserProfile() async {
    return _engine.getUserProfile();
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
    return _engine.requestPermission(
      actionId: actionId,
      level: level,
      reason: reason,
    );
  }

  /// Get a personalized recommendation from the SDK.
  Future<Recommendation?> getRecommendation({
    required String contextType,
    Map<String, dynamic>? contextData,
  }) {
    return _engine.getRecommendation(
      contextType: contextType,
      contextData: contextData,
    );
  }

  bool hasPermission(String actionId, PermissionLevel level) =>
      _engine.hasPermission(actionId, level);

  // Firebase integration
  Future<String?> getHuggingFaceUrl() async {
    if (_firebaseService != null) {
      return _firebaseService!.getHuggingFaceUrl();
    }
    return 'https://huggingface.co/facebook/opt-1.3b';
  }

  Future<String?> getRepoIdFromUrl(String url) async {
    if (_firebaseService != null) {
      return _firebaseService!.getRepoIdFromUrl(url);
    }
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.length >= 2) {
        return '${segments[segments.length - 2]}/${segments[segments.length - 1]}';
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}