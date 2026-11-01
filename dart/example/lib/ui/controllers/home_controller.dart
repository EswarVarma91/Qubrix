import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:ai_sdk/ai_sdk.dart';
import '../../core/constants/app_strings.dart';
import '../../core/model_catalog.dart';
import '../../core/utils/router.dart';
import '../../data/repositories/ai_repository.dart';
import '../../core/bindings/app_bindings.dart';

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
  final _securityStatus = ''.obs;
  final _tamperWarning = false.obs;
  final _integrityStatus = ''.obs;
  final _availableModels = <ModelCatalogEntry>[].obs;
  final _selectedModelRepo = ''.obs;
  final _showModelPicker = false.obs;

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
  List<ModelCatalogEntry> get availableModels => _availableModels.value;
  String get selectedModelRepo => _selectedModelRepo.value;
  bool get showModelPicker => _showModelPicker.value;

  @override
  void onInit() {
    super.onInit();
    _checkSecurityStatus();
    _updateModelStatus();
    _loadAvailableModels();
  }

  void _loadAvailableModels() {
    // Load all available HuggingFace models
    _availableModels.value = HuggingFaceModels.all;
    if (_availableModels.isEmpty) {
      // Fallback: add a custom model entry
      _availableModels.add(HuggingFaceModels.custom(
        repoId: 'microsoft/DialogGPT-small',
        displayName: 'Custom Model',
        description: 'Add your HuggingFace repo ID',
      ));
    }
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
  // Downloads a HuggingFace model by repo ID.
  // The developer specifies which model to download.
  Future<void> downloadModel() async {
    if (_isDownloading.value) return;

    final repoId = _selectedModelRepo.value;
    if (repoId.isEmpty) {
      // No model selected, show picker
      _showModelPicker.value = true;
      return;
    }

    _isDownloading.value = true;
    _setStatus('${AppStrings.downloading} $repoId...');

    try {
      // Download the specified HuggingFace model
      // The SDK handles discovery from the repo, variant selection, etc.
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
        _setStatus('${AppStrings.modelReady}: $repoId '
            '(${(result.bytesDownloaded ?? 0)} bytes in '
            '${(result.duration?.inSeconds ?? 0)}s)');
        _showModelPicker.value = false;
      } else {
        _setStatus('${AppStrings.taskFailed}: ${result.errorMessage}');
        _showModelPicker.value = false;
      }
    } catch (e) {
      _setStatus('Error: $e');
      _showModelPicker.value = false;
    } finally {
      _isDownloading.value = false;
      _progress.value = null;
    }
  }

  // Select a model to download
  void selectModel(ModelCatalogEntry model) {
    _selectedModelRepo.value = model.repoId;
    _showModelPicker.value = false;
    _setStatus('Selected: ${model.displayName} (${_selectedModelRepo.value})');
  }

  // Show model picker dialog
  void showModelPickerDialog() {
    _selectedModelRepo.value = '';
    _showModelPicker.value = true;
  }

  // Set model picker visibility
  void setShowModelPicker(bool show) {
    _showModelPicker.value = show;
  }

  // Add a custom model to the available models list
  void addCustomModel(ModelCatalogEntry model) {
    // Remove existing model with same repo ID if present
    _availableModels.removeWhere((m) => m.repoId == model.repoId);
    _availableModels.add(model);
    _availableModels.refresh();
  }

  // Set selected model by repo ID
  void setSelectedModel(String repoId) {
    _selectedModelRepo.value = repoId;
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
    // Navigate to security details screen (could be in settings)
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
      // Clear all downloaded models
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

  @override
  void onClose() {
    super.onClose();
  }
}
