import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ai_sdk/ai_sdk.dart';
import '../../core/constants/app_strings.dart';
import '../../core/firebase_remote_config.dart';
import '../../core/utils/router.dart';
import '../../data/repositories/ai_repository.dart';

/// Home controller - HuggingFace URL from SDK's Firebase Remote Config
/// Background task - user just taps download, no model selection UI
class HomeController extends GetxController {
  final AiRepository _repository = Get.find<AiRepository>();
  final FirebaseRemoteConfigService _modelConfig = Get.find<FirebaseRemoteConfigService>();

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
  final List<HuggingFaceModel> _customModels = [];

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
  }

  void _checkSecurityStatus() {
    final tamperDetector = TamperDetector(SecurityConfig());
    _securityStatus.value = tamperDetector.isSdkIntegrityVerified
        ? 'Security: Protected'
        : 'Security: Compromised!';
    _tamperWarning.value = !tamperDetector.isSdkIntegrityVerified;
    _integrityStatus.value = tamperDetector.getIntegrityReport();
  }

  Future<void> refreshSecurityStatus() async {
    final tamperDetector = TamperDetector(SecurityConfig());
    final status = await tamperDetector.verifySdkIntegrity();
    _securityStatus.value = status.ok ? 'Security: Protected' : 'Security: Compromised!';
    _tamperWarning.value = !status.ok;
    _integrityStatus.value = tamperDetector.getIntegrityReport();
    if (!status.ok) {
      showSnackbar('Security warning: ${status.message}', isSuccessful: false);
    }
  }

  /// Download model from HuggingFace
  /// Only fetches from SDK Firebase when no model is installed
  Future<void> downloadModel() async {
    if (_isDownloading.value) return;

    // Check if any model is already installed
    final installedModels = _repository.getInstalledModels();
    if (installedModels.isNotEmpty) {
      _isDownloading.value = true;
      _setStatus('Model already installed: ${installedModels.first.displayName}');
      _updateModelStatus();
      return;
    }

    // No model installed - fetch HuggingFace URL from SDK's Firebase
    final huggingFaceUrl = await _modelConfig.getHuggingFaceUrl();
    final repoId = await _modelConfig.getRepoIdFromUrl(huggingFaceUrl);

    if (repoId == null || repoId.isEmpty) {
      _setStatus('Invalid HuggingFace URL from Firebase: $huggingFaceUrl');
      _isDownloading.value = false;
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
        _setStatus('${AppStrings.modelReady} (${result.bytesDownloaded} bytes)');
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

  /// Run a task
  Future<void> runTask() async {
    _isLoading.value = true;
    _setStatus(AppStrings.pleaseWait);

    try {
      final result = await _repository.executeTask(
        TaskRequest(
          taskId: 'task_${DateTime.now().millisecondsSinceEpoch}',
          description: 'Classify this notification',
          input: {'text': 'Your order #12345 has been shipped!'},
          taskType: TaskType.classification,
          context: {'screen': 'notifications', 'timeOfDay': 'morning'},
        ),
      );

      if (result.success) {
        _setStatus('${AppStrings.taskCompleted}: ${result.errorMessage ?? "Success"}');
      } else {
        _setStatus('${AppStrings.taskFailed}: ${result.errorMessage}');
      }
    } catch (e) {
      _setStatus('Error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get recommendation
  Future<void> getRecommendation() async {
    _isLoading.value = true;
    _setStatus(AppStrings.pleaseWait);

    try {
      final recommendation = await _repository.getRecommendation(
        contextType: 'time_of_day',
        contextData: {'hour': DateTime.now().hour},
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

  /// Check model status
  void checkModelStatus() {
    _updateModelStatus();
    final installed = _repository.getInstalledModels();
    if (installed.isEmpty) {
      _setStatus(AppStrings.noModelsInstalled);
    } else {
      _setStatus('Installed: ${installed.length} models');
    }
  }

  /// Check health
  Future<void> checkHealth() async {
    _isLoading.value = true;
    try {
      final health = await _repository.checkHealth();
      _healthStatus.value = health.isHealthy
          ? 'Health: OK (${health.installedModels} models)'
          : 'Health: ${health.message}';
      _setStatus(_healthStatus.value);
    } catch (e) {
      _setStatus('Error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Unload model
  void unloadModel() {
    _repository.unloadAllModels();
    _isModelLoaded.value = false;
    _setStatus('Model unloaded from memory');
    _updateModelStatus();
  }

  /// Clear personalization data
  Future<void> clearPersonalizationData() async {
    await _repository.clearPersonalizationData();
    _setStatus('Personalization data cleared');
  }

  // Navigation methods (GetX)
  void navigateToSettings() => Get.toNamed(AppRoutes.settings);
  void navigateBack() => Get.back();
  void navigateToHome() => Get.offAllNamed(AppRoutes.home);
  void navigateToSecurity() => showSnackbar('Security: ${_integrityStatus.value}', isSuccessful: !_tamperWarning.value);
  void navigateToModels() => showSnackbar('${installedModelsCount} models installed', isSuccessful: true);
  void showAbout() => showSnackbar('AI SDK Demo v${AppStrings.appVersion}', isSuccessful: true);

  void clearModelCache() async {
    _isLoading.value = true;
    try {
      await _repository.clearPersonalizationData();
      _updateModelStatus();
      showSnackbar('Model cache cleared', isSuccessful: true);
    } catch (e) {
      showSnackbar('Failed to clear cache: $e', isSuccessful: false);
    } finally {
      _isLoading.value = false;
    }
  }

  void showStorageInfo() => showSnackbar('Storage info: models=${installedModelsCount}', isSuccessful: true);

  /// Refresh the HuggingFace model URL from Firebase Remote Config.
  Future<void> refreshRemoteConfig() async {
    _isLoading.value = true;
    try {
      final url = await _modelConfig.getHuggingFaceUrl();
      _huggingFaceUrl.value = url;
      _lastFirebaseFetchTime.value = DateTime.now();
      _setStatus('Remote Config refreshed: $url');
    } catch (e) {
      _setStatus('Error refreshing Remote Config: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Show the models that are currently installed.
  void showModelPickerDialog() {
    final installed = _repository.getInstalledModels();
    showSnackbar(
      installed.isEmpty
          ? 'No models installed. Download the Firebase-configured model first.'
          : 'Installed: ${installed.map((m) => m.displayName).join(', ')}',
    );
  }

  /// Register a custom HuggingFace model with the example app.
  void addCustomModel(HuggingFaceModel model) {
    _customModels.add(model);
    _updateModelStatus();
    _setStatus('Custom model added: ${model.displayName}');
    showSnackbar('Added ${model.displayName}');
  }

  void showSnackbar(String message, {bool isSuccessful = true}) {
    Get.snackbar(
      'AI SDK',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      backgroundColor: isSuccessful ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      isDismissible: true,
    );
  }

  void _setStatus(String message) => _status.value = message;

  void _updateModelStatus() {
    _installedModelsCount.value = _repository.getInstalledModels().length;
    _isModelLoaded.value = _repository.getInstalledModels().any(
      (m) => _repository.isModelLoaded(m.id),
    );
  }

  @override
  void onClose() {
    super.onClose();
  }
}
