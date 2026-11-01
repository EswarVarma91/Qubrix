/// Core types used throughout the SDK.
library;

/// Task types supported by the SDK.
enum TaskType {
  classification,
  extraction,
  generation,
  summarization,
  completion,
  embedding,
  statistics,
  patternDetection,
  planning,
  complexReasoning,
  processing,
  search,
  unknown,
}

/// Extension on TaskType.
extension TaskTypeExtension on TaskType {
  /// Human readable label for the task type.
  String get label {
    return switch (this) {
      TaskType.classification => 'Classification',
      TaskType.extraction => 'Extraction',
      TaskType.generation => 'Generation',
      TaskType.summarization => 'Summarization',
      TaskType.completion => 'Completion',
      TaskType.embedding => 'Embedding',
      TaskType.statistics => 'Statistics',
      TaskType.patternDetection => 'Pattern detection',
      TaskType.planning => 'Planning',
      TaskType.complexReasoning => 'Complex reasoning',
      TaskType.processing => 'Processing',
      TaskType.search => 'Search',
      TaskType.unknown => 'Unknown',
    };
  }

  /// Parse a task type from its enum name.
  static TaskType fromString(String value) {
    final normalized = value.toLowerCase();
    return TaskType.values.firstWhere(
      (t) => t.name.toLowerCase() == normalized,
      orElse: () => TaskType.unknown,
    );
  }
}

/// How personalization data is allowed to leave the device.
enum PrivacyMode {
  /// Learn on device, allow anonymized sync when authorized.
  localFirst,

  /// Never leave the device.
  localOnly,

  /// Allow cloud processing for personalization.
  cloudAllowed,

  /// Combine on-device learning with cloud processing.
  hybrid,
}

/// Network connectivity types.
enum NetworkType {
  wifi,
  ethernet,
  cellular5g,
  cellular4g,
  cellular3g,
  cellular2g,
  none,
  unknown,
}

/// Device performance class.
enum DeviceClass {
  lowEnd,
  midRange,
  highEnd,
  unknown,
}

/// Device information used for compatibility checks.
class DeviceInfo {
  final String deviceId;
  final String deviceModel;
  final String manufacturer;
  final String os;
  final String osVersion;
  final String platform;
  final int totalMemory;
  final int availableMemory;
  final int totalStorage;
  final int availableStorage;
  final int cpuCores;
  final int cpuFrequencyHz;
  final bool supportsGpu;
  final String? gpuModel;
  final bool supportsNeuralEngine;
  final String? neuralEngineModel;
  final int screenWidth;
  final int screenHeight;
  final bool isRooted;
  final double batteryLevel;
  final bool isCharging;
  final NetworkType networkType;
  final bool powerSaveMode;

  const DeviceInfo({
    this.deviceId = '',
    this.deviceModel = 'Unknown',
    this.manufacturer = 'Unknown',
    this.os = 'Unknown',
    this.osVersion = '0',
    this.platform = 'Unknown',
    this.totalMemory = 4 * 1024 * 1024 * 1024,
    this.availableMemory = 2 * 1024 * 1024 * 1024,
    this.totalStorage = 64 * 1024 * 1024 * 1024,
    this.availableStorage = 32 * 1024 * 1024 * 1024,
    this.cpuCores = 4,
    this.cpuFrequencyHz = 2000000000,
    this.supportsGpu = false,
    this.gpuModel,
    this.supportsNeuralEngine = false,
    this.neuralEngineModel,
    this.screenWidth = 1080,
    this.screenHeight = 1920,
    this.isRooted = false,
    this.batteryLevel = 1.0,
    this.isCharging = false,
    this.networkType = NetworkType.unknown,
    this.powerSaveMode = false,
  });

  /// Number of logical processors (alias of [cpuCores]).
  int get processorCount => cpuCores;

  /// Performance class derived from the total amount of memory.
  DeviceClass get deviceClass {
    const gb = 1024 * 1024 * 1024;
    if (totalMemory < 2 * gb) return DeviceClass.lowEnd;
    if (totalMemory >= 6 * gb) return DeviceClass.highEnd;
    return DeviceClass.midRange;
  }

  bool get isLowEndDevice => deviceClass == DeviceClass.lowEnd;
  bool get isHighEndDevice => deviceClass == DeviceClass.highEnd;
}

/// Model operation types.
enum ModelOperationType {
  downloading,
  verifying,
  loading,
  initializing,
  unknown,
}

/// Extension on ModelOperationType.
extension ModelOperationTypeExtension on ModelOperationType {
  /// Human readable label for the operation.
  String get label {
    return switch (this) {
      ModelOperationType.downloading => 'Downloading',
      ModelOperationType.verifying => 'Verifying',
      ModelOperationType.loading => 'Loading',
      ModelOperationType.initializing => 'Initializing',
      ModelOperationType.unknown => 'Unknown',
    };
  }
}

/// Download progress information.
class DownloadProgress {
  final String modelId;
  final int bytesDownloaded;
  final int totalBytes;
  final double percent;
  final String? status;

  const DownloadProgress({
    this.modelId = '',
    required this.bytesDownloaded,
    required this.totalBytes,
    required this.percent,
    this.status,
  });

  /// Number of bytes downloaded (alias of [bytesDownloaded]).
  int get progress => bytesDownloaded;

  /// Total number of bytes (alias of [totalBytes]).
  int get total => totalBytes;

  ModelProgress toModelProgress() {
    return ModelProgress(
      modelId: modelId,
      operation: ModelOperationType.downloading,
      progress: bytesDownloaded,
      total: totalBytes,
      percent: percent,
      status: status,
    );
  }
}

/// Model progress for callbacks.
class ModelProgress {
  final String modelId;
  final ModelOperationType operation;
  final double percent;
  final int progress;
  final int total;
  final String? status;
  final String? detail;

  const ModelProgress({
    this.modelId = '',
    required this.operation,
    required this.percent,
    this.progress = 0,
    this.total = 0,
    this.status,
    this.detail,
  });

  @override
  String toString() =>
      'ModelProgress($modelId: ${operation.name} ${(percent * 100).toStringAsFixed(1)}%)';
}

/// Health status of an engine or component.
class HealthStatus {
  final bool isHealthy;
  final String message;
  final Map<String, String> components;

  const HealthStatus({
    required this.isHealthy,
    required this.message,
    this.components = const {},
  });

  static const healthy = HealthStatus(isHealthy: true, message: 'OK');
  static const degraded =
      HealthStatus(isHealthy: true, message: 'Degraded', components: {});
  static const unknown = HealthStatus(isHealthy: false, message: 'Unknown');

  static HealthStatus unhealthy(
    String message, {
    Map<String, String>? components,
  }) {
    return HealthStatus(
      isHealthy: false,
      message: message,
      components: components ?? {},
    );
  }
}

/// Generic result wrapper.
class Result<T> {
  final T? value;
  final String? errorMessage;
  final bool success;

  const Result._({this.value, this.errorMessage, required this.success});

  factory Result.success(T value) => Result._(value: value, success: true);
  factory Result.failure(String errorMessage) =>
      Result._(errorMessage: errorMessage, success: false);

  T getOrThrow() {
    if (!success || value == null) {
      throw StateError(errorMessage ?? 'Operation failed');
    }
    return value as T;
  }

  T getOrDefault(T defaultValue) =>
      success && value != null ? value as T : defaultValue;
}
