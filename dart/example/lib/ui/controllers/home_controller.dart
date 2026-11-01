import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:ai_sdk/ai_sdk.dart';
import '../../core/utils/router.dart';
import '../../data/repositories/ai_repository.dart';

/// GetX Controller for the home screen
/// Manages all state without setState, using Rx variables
class HomeController extends GetxController {
  final AdaptiveAgentEngine _engine;
  final AiRepository _repository;

  HomeController(this._engine, this._repository);

  // Observable state
  final _status = ''.obs;
  final _isInitialized = false.obs;
  final _isDownloading = false.obs;
  final _isLoading = false.obs;
  final _progress = Rxn<ModelProgress>();
  final _installedModelsCount = 0.obs;
  final _isModelLoaded = false.obs;
  final _healthStatus = ''.obs;

  // Getters
  String get status => _status.value;
  bool get isInitialized => _isInitialized.value;
  bool get isDownloading => _isDownloading.value;
  bool get isLoading => _isLoading.value;
  ModelProgress? get progress => _progress.value;
  int get installedModelsCount => _installedModelsCount.value;
  bool get isModelLoaded => _isModelLoaded.value;
  String get healthStatus => _healthStatus.value;

  @override
  void onInit() {
    super.onInit();
    _updateModelStatus();
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

  // Set status with color
  void _setStatus(String message) {
    _status.value = message;
  }

  // Update model status
  void _updateModelStatus() {
    _installedModelsCount.value = _repository.getInstalledModels().length;
    _isModelLoaded.value = _repository.getInstalledModels().any(
      (m) => _repository.isModelLoaded(m.id),
    );
  }

  // Download and load model with progress
  Future<void> downloadModel() async {
    if (_isDownloading.value) return;

    _isDownloading.value = true;
    _setStatus('${AppStrings.downloading}...');

    try {
      // Get the smallest suitable model
      final deviceInfo = await _engine.compatibilityEngine.getDeviceInfo();
      final model = await _repository.getSmallestSuitableModel(
        TaskType.classification,
        deviceInfo: deviceInfo,
        minQuality: 0.8,
      );

      if (model == null) {
        _setStatus(AppStrings.noSuitableModel);
        _isDownloading.value = false;
        return;
      }

      // Download with progress tracking
      final result = await _repository.downloadModel(
        model.model.id,
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
        _setStatus('${AppStrings.modelReady}: '
            '${(result.bytesDownloaded ?? 0)} bytes in '
            '${(result.duration?.inSeconds ?? 0)}s');
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

  @override
  void onClose() {
    super.onClose();
  }
}
