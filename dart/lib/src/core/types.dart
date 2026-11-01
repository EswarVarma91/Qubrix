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
  unknown,
}

/// Extension on TaskType.
extension TaskTypeExtension on TaskType {
  String get name {
    return switch (this) {
      TaskType.classification => 'classification',
      TaskType.extraction => 'extraction',
      TaskType.generation => 'generation',
      TaskType.summarization => 'summarization',
      TaskType.completion => 'completion',
      TaskType.embedding => 'embedding',
      TaskType.unknown => 'unknown',
    };
  }

  static TaskType fromString(String value) {
    return TaskType.values.firstWhere(
      (t) => t.name == value.toLowerCase(),
      orElse: () => TaskType.unknown,
    );
  }
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
  String get name {
    return switch (this) {
      ModelOperationType.downloading => 'downloading',
      ModelOperationType.verifying => 'verifying',
      ModelOperationType.loading => 'loading',
      ModelOperationType.initializing => 'initializing',
      ModelOperationType.unknown => 'unknown',
    };
  }
}

/// Download progress information.
class DownloadProgress {
  final int progress;
  final int total;
  final double percent;
  final String status;

  const DownloadProgress({
    required this.progress,
    required this.total,
    required this.percent,
    required this.status,
  });

  ModelProgress toModelProgress() {
    return ModelProgress(
      operation: ModelOperationType.downloading,
      percent: percent,
      progress: progress,
      total: total,
      status: status,
    );
  }
}

/// Model progress for callbacks.
class ModelProgress {
  final ModelOperationType operation;
  final double percent;
  final int progress;
  final int total;
  final String? status;
  final String? detail;

  const ModelProgress({
    required this.operation,
    required this.percent,
    this.progress = 0,
    this.total = 0,
    this.status,
    this.detail,
  });
}

/// Device information for compatibility.
class DeviceInfo {
  final String deviceId;
  final String deviceModel;
  final String osVersion;
  final int totalMemory;
  final int availableMemory;
  final int processorCount;
  final String platform;

  const DeviceInfo({
    required this.deviceId,
    required this.deviceModel,
    required this.osVersion,
    required this.totalMemory,
    required this.availableMemory,
    required this.processorCount,
    required this.platform,
  });

  bool get isLowEndDevice => totalMemory < 2 * 1024 * 1024 * 1024;
  bool get isHighEndDevice => totalMemory >= 4 * 1024 * 1024 * 1024;
}

/// Permission levels.
enum PermissionLevel {
  user,
  trustedService,
  admin,
  system,
}

/// Health status.
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
  static HealthStatus unhealthy(String message, {Map<String, String>? components}) {
    return HealthStatus(isHealthy: false, message: message, components: components ?? {});
  }

  static const unknown = HealthStatus(isHealthy: false, message: 'Unknown');
}

/// Generic result wrapper.
class Result<T> {
  final T? value;
  final String? errorMessage;
  final bool success;

  const Result._({this.value, this.errorMessage, required this.success});

  factory Result.success(T value) => Result._(value: value, success: true);
  factory Result.failure(String errorMessage) => Result._(errorMessage: errorMessage, success: false);

  T getOrThrow() {
    if (!success || value == null) throw StateError(errorMessage ?? 'Operation failed');
    return value!;
  }

  T getOrDefault(T defaultValue) => success && value != null ? value! : defaultValue;
}
