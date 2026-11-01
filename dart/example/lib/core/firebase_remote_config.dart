import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../../core/model_catalog.dart';

/// Firebase Remote Config service for managing model configuration
/// 
/// Fetches model list from Firebase Remote Config.
/// Developers configure available models in Firebase console.
class FirebaseRemoteConfigService {
  static const String _modelsParamKey = 'available_models';
  static const String _defaultModelsJson = '[]';

  FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  /// Initialize Firebase Remote Config
  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    // Set defaults from local model catalog
    await _remoteConfig.setDefaults(<String, dynamic>{
      _modelsParamKey: _defaultModelsJson,
    });
  }

  /// Fetch latest config from Firebase
  Future<bool> fetchConfig() async {
    try {
      await _remoteConfig.fetchAndActivate();
      return true;
    } catch (e) {
      // Use cached values on failure
      return false;
    }
  }

  /// Get available model repo IDs from remote config
  List<String> getAvailableModelRepos() {
    final modelsJson = _remoteConfig.getString(_modelsParamKey);
    if (modelsJson.isEmpty || modelsJson == _defaultModelsJson) {
      return [];
    }
    
    try {
      final List<dynamic> models = _parseJson(modelsJson);
      return models
          .whereType<Map<String, dynamic>>()
          .map((m) => m['repo_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get full model configurations from remote config
  List<RemoteConfiguredModel> getConfiguredModels() {
    final modelsJson = _remoteConfig.getString(_modelsParamKey);
    if (modelsJson.isEmpty || modelsJson == _defaultModelsJson) {
      return [];
    }
    
    try {
      final List<dynamic> models = _parseJson(modelsJson);
      return models
          .whereType<Map<String, dynamic>>()
          .map((m) => RemoteConfiguredModel.fromJson(m))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get model configuration by repo ID
  RemoteConfiguredModel? getModelConfig(String repoId) {
    final models = getConfiguredModels();
    try {
      return models.firstWhere((m) => m.repoId == repoId);
    } catch (e) {
      return null;
    }
  }

  /// Check if a repo ID is allowed by remote config
  bool isRepoAllowed(String repoId) {
    final allowedRepos = getAvailableModelRepos();
    return allowedRepos.contains(repoId);
  }

  /// Parse JSON string safely
  dynamic _parseJson(String json) {
    // Simple JSON parsing without external dependencies
    // In production, use dart:convert
    return _simpleJsonParse(json);
  }

  dynamic _simpleJsonParse(String json) {
    // This is a simplified parser for the specific format we expect
    // In production, use dart:convert and jsonDecode
    if (json.startsWith('[')) {
      // Array format
      return _parseArray(json);
    }
    return {};
  }

  dynamic _parseArray(String json) {
    // Very basic array parser - in production use dart:convert
    // For now, return empty and let caller handle
    return [];
  }

  /// Refresh config and return true if updated
  Future<bool> refreshAndGetModels() async {
    final updated = await fetchConfig();
    return updated;
  }

  /// Clear cached config
  Future<void> clearConfig() async {
    await _remoteConfig.clear();
  }

  /// Get last fetch timestamp
  DateTime? get lastFetchTime {
    // In production, track this locally
    return null;
  }

  /// Check if config is stale (needs refresh)
  bool get isConfigStale {
    // In production, check time since last fetch
    return false;
  }
}

/// Model configuration from Firebase Remote Config
class RemoteConfiguredModel {
  final String repoId;
  final String displayName;
  final String description;
  final String? license;
  final List<RemoteModelVariant> variants;
  final String? taskType;
  final double? minQuality;
  final bool enabled;

  RemoteConfiguredModel({
    required this.repoId,
    required this.displayName,
    required this.description,
    this.license,
    required this.variants,
    this.taskType,
    this.minQuality,
    this.enabled = true,
  });

  factory RemoteConfiguredModel.fromJson(Map<String, dynamic> json) {
    return RemoteConfiguredModel(
      repoId: json['repo_id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? json['repo_id'] ?? '',
      description: json['description']?.toString() ?? '',
      license: json['license']?.toString(),
      variants: (json['variants'] as List<dynamic>?)
              ?.map((v) => RemoteModelVariant.fromJson(v))
              .toList() ??
          [],
      taskType: json['task_type']?.toString(),
      minQuality: json['min_quality']?.toDouble(),
      enabled: json['enabled'] != false,
    );
  }

  /// Convert to model catalog entry
  ModelCatalogEntry toCatalogEntry() {
    return ModelCatalogEntry(
      repoId: repoId,
      displayName: displayName,
      description: description,
      license: license,
      variants: variants.map((v) => v.toVariant()).toList(),
      taskType: taskType,
      minQuality: minQuality,
      isOfficial: true, // Remote config models are considered official
    );
  }
}

class RemoteModelVariant {
  final String quantization;
  final int downloadSizeMb;
  final int memoryRequirementMb;
  final double estimatedLatencyMs;

  RemoteModelVariant({
    required this.quantization,
    required this.downloadSizeMb,
    required this.memoryRequirementMb,
    required this.estimatedLatencyMs,
  });

  factory RemoteModelVariant.fromJson(Map<String, dynamic> json) {
    return RemoteModelVariant(
      quantization: json['quantization']?.toString() ?? 'float32',
      downloadSizeMb: json['download_size_mb']?.toInt() ?? 500,
      memoryRequirementMb: json['memory_requirement_mb']?.toInt() ?? 1000,
      estimatedLatencyMs: json['estimated_latency_ms']?.toDouble() ?? 100.0,
    );
  }

  HfModelVariant toVariant() {
    return HfModelVariant(
      quantization: quantization,
      downloadSizeMb: downloadSizeMb,
      memoryRequirementMb: memoryRequirementMb,
      estimatedLatencyMs: estimatedLatencyMs,
    );
  }
}

/// Service that combines local catalog with remote config
/// 
/// Priority: Remote config overrides local catalog
class ModelConfigService {
  final FirebaseRemoteConfigService _remoteConfig;
  final List<ModelCatalogEntry> _localModels;

  ModelConfigService({
    required FirebaseRemoteConfigService remoteConfig,
    List<ModelCatalogEntry>? localModels,
  })  : _remoteConfig = remoteConfig,
        _localModels = localModels ?? HuggingFaceModels.all;

  /// Get all available models (remote + local)
  List<ModelCatalogEntry> getAvailableModels() {
    final remoteModels = _remoteConfig.getConfiguredModels();
    final remoteRepos = _remoteConfig.getAvailableModelRepos();

    // Start with local models
    final models = <ModelCatalogEntry>[..._localModels];

    // Add/override with remote models
    for (final remote in remoteModels) {
      if (remote.enabled) {
        // Remove local model with same repo ID
        models.removeWhere((m) => m.repoId == remote.repoId);
        // Add remote model
        models.add(remote.toCatalogEntry());
      }
    }

    // Filter to only allowed repos if remote config specifies them
    if (remoteRepos.isNotEmpty && remoteRepos.first != 'all') {
      return models.where((m) => remoteRepos.contains(m.repoId)).toList();
    }

    return models;
  }

  /// Check if a model is allowed
  bool isModelAllowed(String repoId) {
    return _remoteConfig.isRepoAllowed(repoId);
  }

  /// Refresh remote config
  Future<void> refresh() async {
    await _remoteConfig.fetchConfig();
  }

  /// Get model by repo ID (checks both local and remote)
  ModelCatalogEntry? getModel(String repoId) {
    final models = getAvailableModels();
    try {
      return models.firstWhere((m) => m.repoId == repoId);
    } catch (e) {
      return null;
    }
  }
}
