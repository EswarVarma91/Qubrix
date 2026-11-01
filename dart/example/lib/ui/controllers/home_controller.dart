import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:ai_sdk/ai_sdk.dart';
import '../../core/constants/app_strings.dart';
import '../../core/model_catalog.dart';
import '../../core/firebase_remote_config.dart';
import '../../core/utils/router.dart';
import '../../data/repositories/ai_repository.dart';
import '../../core/bindings/app_bindings.dart';

/// Home controller - HuggingFace URL comes from Firebase Remote Config
/// Background task - user just taps download, no model selection UI
class HomeController extends GetxController {
  final AdaptiveAgentEngine _engine;
  final AiRepository _repository;
  final ModelConfigService _modelConfig;

  HomeController(this._engine, this._repository, this._modelConfig);

  // Observable state
  final _status = ''.obs;
  final _isInitialized = false.obs;
  final _isDownloading = false.obs;
  final _isLoading = false.obs;
  final _progress = Rxn<ModelProgress>();
  final _installedModelsCount = 0.obs;
  final _isModelLoaded = false.obs;
  final _healthStatus = ''.obs;
  final _securityStatus = ''.obs;
  final _tamperWarning = false.obs;
  final _integrityStatus = ''.obs;
  final _usingFirebase = false.obs;
  final _lastFirebaseFetchTime = Rxn<DateTime>();
  final _huggingFaceUrl = ''.obs;

  // Getters
  String get status => _status.value;
  bool get isInitialized => _isInitialized.value;
  bool get isDownloading => _isDownloading.value;
  bool get isLoading => _isLoading.value;
  ModelProgress? get progress => _progress.value;
  int get installedModelsCount => _installedModelsCount.value;
  bool get isModelLoaded => _isModelLoaded.value;
  String get healthStatus => _healthStatus.value;
  String get securityStatus => _securityStatus.value;
  bool get tamperWarning => _tamperWarning.value;
  String get integrityStatus => _integrityStatus.value;
  bool get usingFirebase => _usingFirebase.value;

  @override
  void onInit() {
    super.onInit();
    _checkSecurityStatus();
    _updateModelStatus();
    // Don't fetch Firebase on init - only when needed
    // Firebase is only checked when there's no model downloaded
  }

  void _checkSecurityStatus() {
    final tamperDetector = getIt<TamperDetector>();
    
    _securityStatus.value = tamperDetector.isSdkIntegrityVerified
        ? 'Security: Protected'
        : 'Security: Compromised!';
    
    _tamperWarning.value = !tamperDetector.isSdkIntegrityVerified;
    _integrityStatus.value = tamperDetector.getIntegrityReport();
  }

  Future<void> refreshSecurityStatus() async {
    final tamperDetector = getIt<TamperDetector>();
    final status = await tamperDetector.verifySdkIntegrity();
    
    _securityStatus.value = status.ok
        ? 'Security: Protected'
        : 'Security: Compromised!';
    _tamperWarning.value = !status.ok;
    _integrityStatus.value = tamperDetector.getIntegrityReport();
    
    if (!status.ok) {
      showSnackbar('Security warning: ${status.message}', isSuccessful: false);
    }
  }

  // Initialize engine
  Future<void> initializeEngine() async {
    if (_isInitialized.value) return;

    _setStatus(AppStrings.loading);
    _isLoading.value = true;

    try {
      _isInitialized.value = true;
      _setStatus(AppStrings.engineInitialized);
      _updateModelStatus();
    } catch (e) {
      _setStatus('Error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // Download model from HuggingFace
  // Only fetches from Firebase when no model is installed
  // Otherwise uses cached URL
  Future<void> downloadModel() async {
    if (_isDownloading.value) return;

    // Check if any model is already installed
    final installedModels = _repository.getInstalledModels();
    if (installedModels.isNotEmpty) {
      // Model already downloaded - no need to check Firebase
      _isDownloading.value = true;
      _setStatus('Model already installed: ${installedModels.first.displayName}');
      _updateModelStatus();
      return;
    }

    // No model installed - fetch HuggingFace URL from Firebase
    // This is the only time we check Firebase
    final huggingFaceUrl = _modelConfig.getHuggingFaceUrl();

    // Extract repo ID from HuggingFace URL
    // URL format: https://huggingface.co/<owner>/<repo>
    final repoId = _extractRepoIdFromUrl(huggingFaceUrl);
    if (repoId.isEmpty) {
      _setStatus('Invalid HuggingFace URL from Firebase: $huggingFaceUrl');
      return;
    }

    _isDownloading.value = true;
    _setStatus('${AppStrings.downloading}...');
    _huggingFaceUrl.value = huggingFaceUrl;
    _lastFirebaseFetchTime.value = DateTime.now();

    try {
      final result = await _repository.downloadModel(
        repoId,
        onProgress: (progress) {
          _progress.value = progress;
          _setStatus('${progress.operation.name.toUpperCase()}: '
              '${progress.percent.toStringAsFixed(1)}% '
              '(${(progress.progress ~/ 1024 / 1024)}MB / ${(progress.total ~/ 1024 / 1024)}MB)'
              '${progress.status != null ? ' - ${progress.status}' : ''}');
        },
        onLoadProgress: (progress) {
          _progress.value = progress;
          _setStatus('${AppStrings.loading.toUpperCase()}: '
              '${progress.percent.toStringAsFixed(1)}% '
              '- ${progress.detail ?? 'Loading...'}');
        },
      );

      if (result.success) {
        _updateModelStatus();
        _setStatus('${AppStrings.modelReady} (${(result.bytesDownloaded ?? 0)} bytes)');
      } else {
        _setStatus('${AppStrings.taskFailed}: ${result.errorMessage}');
      }
    } catch (e) {
      _setStatus('Error: $e');
    } finally {
      _isDownloading.value = false;
      _progress.value = null;
    }
  }

  // Run a task
  Future<void> runTask() async {
    _isLoading.value = true;
    _setStatus(AppStrings.pleaseWait);

    try {
      final result = await _repository.executeTask(
        TaskRequest(
          taskId: 'task_${DateTime.now().millisecondsSinceEpoch}',
          description: 'Classify this notification',
          input: {
            'text': 'Your order #12345 has been shipped!',
          },
          taskType: TaskType.classification,
          context: {
            'screen': 'notifications',
            'timeOfDay': 'morning',
          },
        ),
      );

      if (result.success) {
        _setStatus('${AppStrings.taskCompleted}: ${result.output?.text ?? "Success"}');
      } else {
        _setStatus('${AppStrings.taskFailed}: ${result.errorMessage}');
      }
    } catch (e) {
      _setStatus('Error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // Get recommendation
  Future<void> getRecommendation() async {
    _isLoading.value = true;
    _setStatus(AppStrings.pleaseWait);

    try {
      final recommendation = await _repository.getRecommendation(
        contextType: 'time_of_day',
        contextData: {
          'hour': DateTime.now().hour,
        },
      );

      if (recommendation != null) {
        _setStatus('Recommendation: ${recommendation.title}');
      } else {
        _setStatus(AppStrings.noRecommendation);
      }
    } catch (e) {
      _setStatus('Error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // Check model status
  void checkModelStatus() {
    _updateModelStatus();
    final installed = _repository.getInstalledModels();
    if (installed.isEmpty) {
      _setStatus(AppStrings.noModelsInstalled);
    } else {
      _setStatus('Installed: ${installed.length} models, '
          'Loaded: ${_isModelLoaded.value ? 'yes' : 'no'}');
    }
  }

  // Check health
  Future<void> checkHealth() async {
    _isLoading.value = true;

    try {
      final health = await _repository.checkHealth();
      _healthStatus.value = health.isHealthy
          ? 'Health: OK (${health.installedModels} models installed)'
          : 'Health: ${health.components.values.join(", ")}';
      _setStatus(_healthStatus.value);
    } catch (e) {
      _setStatus('Error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // Unload model
  void unloadModel() {
    _repository.unloadAllModels();
    _isModelLoaded.value = false;
    _setStatus('Model unloaded from memory');
    _updateModelStatus();
  }

  // Clear personalization data
  Future<void> clearPersonalizationData() async {
    await _repository.clearPersonalizationData();
    _setStatus('Personalization data cleared');
  }

  // Navigation methods (GetX)
  void navigateToSettings() {
    Get.toNamed(AppRoutes.settings);
  }

  void navigateBack() {
    Get.back();
  }

  void navigateToHome() {
    Get.offAllNamed(AppRoutes.home);
  }

  void navigateToSecurity() {
    showSnackbar('Security details: ${_integrityStatus.value}', isSuccessful: !_tamperWarning.value);
  }

  void navigateToModels() {
    showSnackbar('${installedModelsCount} models installed', isSuccessful: true);
  }

  void showAbout() {
    showSnackbar('AI SDK Demo v${AppStrings.appVersion}', isSuccessful: true);
  }

  void clearModelCache() async {
    _isLoading.value = true;
    try {
      await _repository.clearModelCache();
      _updateModelStatus();
      showSnackbar('Model cache cleared', isSuccessful: true);
    } catch (e) {
      showSnackbar('Failed to clear cache: $e', isSuccessful: false);
    } finally {
      _isLoading.value = false;
    }
  }

  void showStorageInfo() {
    showSnackbar('Storage info: models=${installedModelsCount}', isSuccessful: true);
  }

  void showSnackbar(String message, {bool isSuccessful = true}) {
    Get.snackbar(
      'AI SDK',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      backgroundColor: isSuccessful ? AppColors.success : AppColors.error,
      colorText: AppColors.onError,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      isDismissible: true,
    );
  }

  void _setStatus(String message) {
    _status.value = message;
  }

  void _updateModelStatus() {
    _installedModelsCount.value = _repository.getInstalledModels().length;
    _isModelLoaded.value = _repository.getInstalledModels().any(
      (m) => _repository.isModelLoaded(m.id),
    );
  }

  /// Extract HuggingFace repo ID from URL
  /// URL format: https://huggingface.co/<owner>/<repo>
  String _extractRepoIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      // Get the last two path segments: owner/repo
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2) {
        final repoId = '${pathSegments[pathSegments.length - 2]}/${pathSegments[pathSegments.length - 1]}';
        return repoId.contains('@') ? repoId.split('@').first : repoId;
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
