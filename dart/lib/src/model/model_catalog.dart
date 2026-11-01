/// Model Catalog
///
/// Maintains a validated catalog of models and their measured capabilities.
/// Stores model metadata, benchmarks, and performance characteristics.

import 'package:flutter/foundation.dart';
import '../core/types.dart';
import 'model_types.dart';

/// Model catalog that maintains the validated model inventory
class ModelCatalog {
  final List<Model> _models = [];
  final Map<String, ModelBenchmark> _benchmarks = {};

  /// Initialize with built-in models
  ModelCatalog() {
    _initializeBuiltInModels();
  }

  /// Initialize built-in model catalog
  void _initializeBuiltInModels() {
    // Add built-in models for demonstration
    // In a real implementation, these would come from a remote catalog

    // Small classification model
    _models.add(Model(
      id: 'small-classifier',
      name: 'Small Classifier',
      description: 'Lightweight text classification model for simple categorization tasks',
      version: '1.0.0',
      architecture: ModelArchitecture.specialized,
      quantizationFormats: const [
        QuantizationFormat.int8,
        QuantizationFormat.int4,
      ],
      downloadSizes: const {
        QuantizationFormat.int8: 15 * 1024 * 1024, // 15 MB
        QuantizationFormat.int4: 8 * 1024 * 1024, // 8 MB
      },
      memoryRequirements: const {
        QuantizationFormat.int8: 50 * 1024 * 1024, // 50 MB
        QuantizationFormat.int4: 30 * 1024 * 1024, // 30 MB
      },
      supportedTaskTypes: const [
        TaskType.classification,
        TaskType.extraction,
      ],
      hardwareRequirements: const HardwareRequirements(
        minRamMb: 256,
        minStorageMb: 10,
        supportsLowEndDevices: true,
      ),
      license: const ModelLicense(
        type: LicenseType.permissive,
        name: 'MIT',
        allowsCommercialUse: true,
      ),
      isEdgeModel: true,
    ));

    // Medium summarization model
    _models.add(Model(
      id: 'medium-summarizer',
      name: 'Medium Summarizer',
      description: 'Text summarization model for document and conversation summaries',
      version: '1.0.0',
      architecture: ModelArchitecture.transformer,
      quantizationFormats: const [
        QuantizationFormat.float16,
        QuantizationFormat.int8,
      ],
      downloadSizes: const {
        QuantizationFormat.float16: 150 * 1024 * 1024, // 150 MB
        QuantizationFormat.int8: 80 * 1024 * 1024, // 80 MB
      },
      memoryRequirements: const {
        QuantizationFormat.float16: 200 * 1024 * 1024, // 200 MB
        QuantizationFormat.int8: 120 * 1024 * 1024, // 120 MB
      },
      supportedTaskTypes: const [
        TaskType.summarization,
        TaskType.extraction,
      ],
      hardwareRequirements: const HardwareRequirements(
        minRamMb: 512,
        recommendedRamMb: 1024,
        minStorageMb: 80,
        supportsLowEndDevices: false,
      ),
      license: const ModelLicense(
        type: LicenseType.permissive,
        name: 'Apache 2.0',
        allowsCommercialUse: true,
      ),
    ));

    // Small language model for general tasks
    _models.add(Model(
      id: 'small-language',
      name: 'Small Language Model',
      description: 'Compact language model for general text understanding and generation',
      version: '1.0.0',
      architecture: ModelArchitecture.transformer,
      quantizationFormats: const [
        QuantizationFormat.int8,
        QuantizationFormat.int4,
        QuantizationFormat.gguf,
      ],
      downloadSizes: const {
        QuantizationFormat.int8: 350 * 1024 * 1024, // 350 MB
        QuantizationFormat.int4: 180 * 1024 * 1024, // 180 MB
        QuantizationFormat.gguf: 200 * 1024 * 1024, // 200 MB
      },
      memoryRequirements: const {
        QuantizationFormat.int8: 500 * 1024 * 1024, // 500 MB
        QuantizationFormat.int4: 300 * 1024 * 1024, // 300 MB
        QuantizationFormat.gguf: 350 * 1024 * 1024, // 350 MB
      },
      supportedTaskTypes: const [
        TaskType.classification,
        TaskType.extraction,
        TaskType.summarization,
        TaskType.processing,
      ],
      hardwareRequirements: const HardwareRequirements(
        minRamMb: 512,
        recommendedRamMb: 1024,
        minStorageMb: 180,
        supportsLowEndDevices: false,
        supportsNeuralEngine: true,
      ),
      license: const ModelLicense(
        type: LicenseType.permissive,
        name: 'MIT',
        allowsCommercialUse: true,
      ),
      isEdgeModel: true,
    ));

    // Larger language model for complex tasks
    _models.add(Model(
      id: 'medium-language',
      name: 'Medium Language Model',
      description: 'More capable language model for complex reasoning and generation',
      version: '1.0.0',
      architecture: ModelArchitecture.transformer,
      quantizationFormats: const [
        QuantizationFormat.float16,
        QuantizationFormat.int8,
      ],
      downloadSizes: const {
        QuantizationFormat.float16: 1500 * 1024 * 1024, // 1.5 GB
        QuantizationFormat.int8: 800 * 1024 * 1024, // 800 MB
      },
      memoryRequirements: const {
        QuantizationFormat.float16: 2000 * 1024 * 1024, // 2 GB
        QuantizationFormat.int8: 1200 * 1024 * 1024, // 1.2 GB
      },
      supportedTaskTypes: const [
        TaskType.classification,
        TaskType.extraction,
        TaskType.summarization,
        TaskType.generation,
        TaskType.planning,
        TaskType.complexReasoning,
      ],
      hardwareRequirements: const HardwareRequirements(
        minRamMb: 2048,
        recommendedRamMb: 4096,
        minStorageMb: 800,
        supportsLowEndDevices: false,
        supportsNeuralEngine: true,
      ),
      license: const ModelLicense(
        type: LicenseType.permissive,
        name: 'Apache 2.0',
        allowsCommercialUse: true,
      ),
    ));

    // Ultra-small statistical model
    _models.add(Model(
      id: 'nano-stats',
      name: 'Nano Statistics',
      description: 'Tiny statistical model for basic pattern detection and statistics',
      version: '1.0.0',
      architecture: ModelArchitecture.statistical,
      quantizationFormats: const [
        QuantizationFormat.int8,
      ],
      downloadSizes: const {
        QuantizationFormat.int8: 500 * 1024, // 500 KB
      },
      memoryRequirements: const {
        QuantizationFormat.int8: 10 * 1024 * 1024, // 10 MB
      },
      supportedTaskTypes: const [
        TaskType.statistics,
        TaskType.patternDetection,
      ],
      hardwareRequirements: const HardwareRequirements(
        minRamMb: 32,
        minStorageMb: 1,
        supportsLowEndDevices: true,
      ),
      license: const ModelLicense(
        type: LicenseType.permissive,
        name: 'MIT',
        allowsCommercialUse: true,
      ),
      isEdgeModel: true,
    ));
  }

  /// Get all models in the catalog
  List<Model> get models => List.unmodifiable(_models);

  /// Get a model by ID
  Model? getModel(String modelId) {
    try {
      return _models.firstWhere((m) => m.id == modelId);
    } catch (e) {
      return null;
    }
  }

  /// Get the latest version of a model
  Model? getLatestVersion(String modelId) {
    final versions = _models
        .where((m) => m.id == modelId)
        .toList()
      ..sort((a, b) => b.version.compareTo(a.version));
    return versions.isNotEmpty ? versions.first : null;
  }

  /// Get models that support a specific task type
  List<Model> getModelsForTask(TaskType taskType) {
    return _models
        .where((m) => m.supportedTaskTypes.contains(taskType))
        .toList()
      ..sort((a, b) => a.smallestDownloadSize.compareTo(b.smallestDownloadSize));
  }

  /// Get models compatible with a device
  List<Model> getModelsForDevice(DeviceInfo deviceInfo) {
    return _models.where((model) {
      return model.hardwareRequirements.meetsMinimumRequirements(deviceInfo);
    }).toList();
  }

  /// Get models in a size range
  List<Model> getModelsInSizeRange({
    int? minSizeBytes,
    int? maxSizeBytes,
    QuantizationFormat? format,
  }) {
    return _models.where((model) {
      final size = format != null
          ? (model.downloadSizes[format] ?? model.smallestDownloadSize)
          : model.smallestDownloadSize;
      return (minSizeBytes == null || size >= minSizeBytes) &&
          (maxSizeBytes == null || size <= maxSizeBytes);
    }).toList();
  }

  /// Search models by name or description
  List<Model> searchModels(String query) {
    final lowerQuery = query.toLowerCase();
    return _models.where((model) {
      return model.name.toLowerCase().contains(lowerQuery) ||
          model.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Add a custom model to the catalog
  void addModel(Model model) {
    // Check if model with same ID exists
    final existingIndex = _models.indexWhere((m) => m.id == model.id);
    if (existingIndex >= 0) {
      // Replace if new version is higher
      if (_models[existingIndex].version.compareTo(model.version) < 0) {
        _models[existingIndex] = model;
      }
    } else {
      _models.add(model);
    }
  }

  /// Remove a model from the catalog
  bool removeModel(String modelId) {
    final index = _models.indexWhere((m) => m.id == modelId);
    if (index >= 0) {
      _models.removeAt(index);
      return true;
    }
    return false;
  }

  /// Add or update benchmark results for a model
  void addBenchmark(String modelId, ModelBenchmark benchmark) {
    _benchmarks[modelId] = benchmark;
  }

  /// Get benchmark results for a model
  ModelBenchmark? getBenchmark(String modelId) {
    return _benchmarks[modelId];
  }

  /// Get all benchmark data
  Map<String, ModelBenchmark> get benchmarks => Map.unmodifiable(_benchmarks);

  /// Get the total number of models
  int get modelCount => _models.length;

  /// Get models grouped by task type
  Map<TaskType, List<Model>> getModelsByTask() {
    final grouped = <TaskType, List<Model>>{};
    for (final model in _models) {
      for (final taskType in model.supportedTaskTypes) {
        grouped.putIfAbsent(taskType, () => []).add(model);
      }
    }
    // Sort each group by size
    for (final list in grouped.values) {
      list.sort((a, b) => a.smallestDownloadSize.compareTo(b.smallestDownloadSize));
    }
    return grouped;
  }

  /// Get the smallest model for a task
  Model? getSmallestModelForTask(TaskType taskType) {
    final candidates = getModelsForTask(taskType);
    if (candidates.isEmpty) return null;
    return candidates.first;
  }

  /// Get models that support a specific quantization format
  List<Model> getModelsWithQuantization(QuantizationFormat format) {
    return _models.where((m) => m.quantizationFormats.contains(format)).toList();
  }

  /// Update model catalog from remote source
  Future<void> updateFromRemote() async {
    // In a real implementation, this would fetch from a remote catalog API
    // and merge/update the local catalog
  }

  /// Export catalog metadata (without full model details)
  Map<String, dynamic> exportMetadata() {
    return {
      'modelCount': _models.length,
      'models': _models.map((m) => {
        'id': m.id,
        'name': m.name,
        'version': m.version,
        'size': m.smallestDownloadSize,
        'taskTypes': m.supportedTaskTypes.map((t) => t.name).toList(),
      }).toList(),
    };
  }
}

/// Benchmark results for a model
@immutable
class ModelBenchmark {
  final String modelId;
  final String revision;
  final QuantizationFormat quantizationFormat;
  final String runtimeVersion;
  final DeviceClass deviceClass;
  final TaskType taskType;

  /// Task-specific accuracy metrics
  final double accuracy;
  final double precision;
  final double recall;
  final double f1Score;

  /// Performance metrics
  final int memoryUsageMb;
  final int peakMemoryUsageMb;
  final int initializationTimeMs;
  final int inferenceLatencyMs;
  final double throughputTokensPerSecond;
  final int failureRate;

  /// Energy consumption (mAh) if measurable
  final int? energyConsumptionMah;

  /// Hardware used during benchmarking
  final String? hardwareDescription;

  final DateTime benchmarkDate;

  const ModelBenchmark({
    required this.modelId,
    required this.revision,
    required this.quantizationFormat,
    required this.runtimeVersion,
    required this.deviceClass,
    required this.taskType,
    required this.accuracy,
    required this.precision,
    required this.recall,
    required this.f1Score,
    required this.memoryUsageMb,
    required this.peakMemoryUsageMb,
    required this.initializationTimeMs,
    required this.inferenceLatencyMs,
    required this.throughputTokensPerSecond,
    required this.failureRate,
    this.energyConsumptionMah,
    this.hardwareDescription,
    required this.benchmarkDate,
  });

  /// Create a copy with some fields replaced
  ModelBenchmark copyWith({
    String? modelId,
    String? revision,
    QuantizationFormat? quantizationFormat,
    String? runtimeVersion,
    DeviceClass? deviceClass,
    TaskType? taskType,
    double? accuracy,
    double? precision,
    double? recall,
    double? f1Score,
    int? memoryUsageMb,
    int? peakMemoryUsageMb,
    int? initializationTimeMs,
    int? inferenceLatencyMs,
    double? throughputTokensPerSecond,
    int? failureRate,
    int? energyConsumptionMah,
    String? hardwareDescription,
    DateTime? benchmarkDate,
  }) {
    return ModelBenchmark(
      modelId: modelId ?? this.modelId,
      revision: revision ?? this.revision,
      quantizationFormat: quantizationFormat ?? this.quantizationFormat,
      runtimeVersion: runtimeVersion ?? this.runtimeVersion,
      deviceClass: deviceClass ?? this.deviceClass,
      taskType: taskType ?? this.taskType,
      accuracy: accuracy ?? this.accuracy,
      precision: precision ?? this.precision,
      recall: recall ?? this.recall,
      f1Score: f1Score ?? this.f1Score,
      memoryUsageMb: memoryUsageMb ?? this.memoryUsageMb,
      peakMemoryUsageMb: peakMemoryUsageMb ?? this.peakMemoryUsageMb,
      initializationTimeMs: initializationTimeMs ?? this.initializationTimeMs,
      inferenceLatencyMs: inferenceLatencyMs ?? this.inferenceLatencyMs,
      throughputTokensPerSecond:
          throughputTokensPerSecond ?? this.throughputTokensPerSecond,
      failureRate: failureRate ?? this.failureRate,
      energyConsumptionMah: energyConsumptionMah ?? this.energyConsumptionMah,
      hardwareDescription: hardwareDescription ?? this.hardwareDescription,
      benchmarkDate: benchmarkDate ?? this.benchmarkDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'modelId': modelId,
        'revision': revision,
        'quantizationFormat': quantizationFormat.name,
        'runtimeVersion': runtimeVersion,
        'deviceClass': deviceClass.name,
        'taskType': taskType.name,
        'accuracy': accuracy,
        'precision': precision,
        'recall': recall,
        'f1Score': f1Score,
        'memoryUsageMb': memoryUsageMb,
        'peakMemoryUsageMb': peakMemoryUsageMb,
        'initializationTimeMs': initializationTimeMs,
        'inferenceLatencyMs': inferenceLatencyMs,
        'throughputTokensPerSecond': throughputTokensPerSecond,
        'failureRate': failureRate,
        'energyConsumptionMah': energyConsumptionMah,
        'hardwareDescription': hardwareDescription,
        'benchmarkDate': benchmarkDate.toIso8601String(),
      };

  factory ModelBenchmark.fromJson(Map<String, dynamic> json) {
    return ModelBenchmark(
      modelId: json['modelId'] as String,
      revision: json['revision'] as String,
      quantizationFormat: QuantizationFormat.values.firstWhere(
        (e) => e.name == json['quantizationFormat'],
        orElse: () => QuantizationFormat.unknown,
      ),
      runtimeVersion: json['runtimeVersion'] as String,
      deviceClass: DeviceClass.values.firstWhere(
        (e) => e.name == json['deviceClass'],
        orElse: () => DeviceClass.unknown,
      ),
      taskType: TaskType.values.firstWhere(
        (e) => e.name == json['taskType'],
        orElse: () => TaskType.processing,
      ),
      accuracy: (json['accuracy'] as num).toDouble(),
      precision: (json['precision'] as num).toDouble(),
      recall: (json['recall'] as num).toDouble(),
      f1Score: (json['f1Score'] as num).toDouble(),
      memoryUsageMb: json['memoryUsageMb'] as int,
      peakMemoryUsageMb: json['peakMemoryUsageMb'] as int,
      initializationTimeMs: json['initializationTimeMs'] as int,
      inferenceLatencyMs: json['inferenceLatencyMs'] as int,
      throughputTokensPerSecond: (json['throughputTokensPerSecond'] as num).toDouble(),
      failureRate: json['failureRate'] as int,
      energyConsumptionMah: json['energyConsumptionMah'] as int?,
      hardwareDescription: json['hardwareDescription'] as String?,
      benchmarkDate: DateTime.parse(json['benchmarkDate'] as String),
    );
  }

  @override
  String toString() =>
      'ModelBenchmark(${modelId}: acc=${accuracy.toStringAsFixed(2)})';
}
