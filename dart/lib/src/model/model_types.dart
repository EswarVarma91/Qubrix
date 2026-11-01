/// Model types used throughout the SDK.
library;

import '../core/types.dart';

/// Underlying architecture of a model.
enum ModelArchitecture {
  transformer,
  statistical,
  specialized,
  cnn,
  rnn,
  hybrid,
}

/// Quantization formats a model can be shipped in.
enum QuantizationFormat {
  float32,
  float16,
  int8,
  int4,
  gguf,
  unknown,
}

/// Type of license a model is distributed under.
enum LicenseType {
  permissive,
  copyleft,
  proprietary,
  unknown,
}

/// Attribution requirements of a model license.
enum AttributionRequirement {
  none,
  requested,
  required,
}

/// Hardware requirements for running a model.
class HardwareRequirements {
  final int minRamMb;
  final int? recommendedRamMb;
  final int minStorageMb;
  final int minCpuCores;
  final bool requiresGpu;
  final bool supportsNeuralEngine;
  final bool supportsLowEndDevices;
  final List<String> supportedOSVersions;
  final List<DeviceClass> compatibleDeviceClasses;

  const HardwareRequirements({
    this.minRamMb = 0,
    this.recommendedRamMb,
    this.minStorageMb = 0,
    this.minCpuCores = 1,
    this.requiresGpu = false,
    this.supportsNeuralEngine = false,
    this.supportsLowEndDevices = true,
    this.supportedOSVersions = const [],
    this.compatibleDeviceClasses = const [],
  });

  /// Whether the device meets the minimum requirements.
  bool meetsMinimumRequirements(DeviceInfo deviceInfo) {
    const mb = 1024 * 1024;
    if (deviceInfo.totalMemory < minRamMb * mb) return false;
    if (deviceInfo.totalStorage < minStorageMb * mb) return false;
    if (deviceInfo.cpuCores < minCpuCores) return false;
    if (requiresGpu && !deviceInfo.supportsGpu) return false;
    return true;
  }

  /// Whether the device class is allowed (an empty list allows every class).
  bool allowsDeviceClass(DeviceClass deviceClass) {
    return compatibleDeviceClasses.isEmpty ||
        compatibleDeviceClasses.contains(deviceClass);
  }
}

/// License attached to a model.
class ModelLicense {
  final LicenseType type;
  final String name;
  final bool allowsCommercialUse;
  final bool allowsDistribution;
  final AttributionRequirement attributionRequirement;
  final String? url;

  const ModelLicense({
    required this.type,
    required this.name,
    this.allowsCommercialUse = true,
    this.allowsDistribution = true,
    this.attributionRequirement = AttributionRequirement.none,
    this.url,
  });
}

/// A model variant: a concrete quantization of a model.
class ModelVariant {
  final String id;
  final String name;
  final String version;
  final QuantizationFormat quantizationFormat;
  final int downloadSize;
  final int memoryRequirement;
  final double estimatedLatencyMs;
  final double estimatedThroughput;
  final bool supportsGpu;
  final bool supportsNeuralEngine;
  final String? downloadUrl;
  final String? checksum;

  const ModelVariant({
    required this.id,
    required this.name,
    this.version = '1.0.0',
    required this.quantizationFormat,
    required this.downloadSize,
    required this.memoryRequirement,
    required this.estimatedLatencyMs,
    required this.estimatedThroughput,
    this.supportsGpu = false,
    this.supportsNeuralEngine = false,
    this.downloadUrl,
    this.checksum,
  });
}

/// A model in the catalog.
class Model {
  final String id;
  final String name;
  final String description;
  final String version;
  final ModelArchitecture architecture;
  final List<QuantizationFormat> quantizationFormats;
  final Map<QuantizationFormat, int> downloadSizes;
  final Map<QuantizationFormat, int> memoryRequirements;
  final List<TaskType> supportedTaskTypes;
  final HardwareRequirements hardwareRequirements;
  final ModelLicense license;
  final bool isEdgeModel;
  final String? repoId;
  final String? huggingFaceUrl;

  const Model({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.architecture,
    required this.quantizationFormats,
    required this.downloadSizes,
    required this.memoryRequirements,
    required this.supportedTaskTypes,
    required this.hardwareRequirements,
    required this.license,
    this.isEdgeModel = false,
    this.repoId,
    this.huggingFaceUrl,
  });

  /// Display name (alias of [name]).
  String get displayName => name;

  /// Smallest download size across all quantization formats.
  int get smallestDownloadSize {
    if (downloadSizes.isEmpty) return 0;
    return downloadSizes.values.reduce((a, b) => a < b ? a : b);
  }

  /// Smallest memory requirement across all quantization formats.
  int get smallestMemoryRequirement {
    if (memoryRequirements.isEmpty) return 0;
    return memoryRequirements.values.reduce((a, b) => a < b ? a : b);
  }

  /// Whether this model supports the given task type.
  bool supportsTask(TaskType taskType) =>
      supportedTaskTypes.contains(taskType);

  /// Concrete variants generated from the supported quantization formats.
  List<ModelVariant> get variants {
    return quantizationFormats.map((format) {
      return ModelVariant(
        id: '${id}_${format.name}',
        name: '$name (${format.name})',
        version: version,
        quantizationFormat: format,
        downloadSize: downloadSizes[format] ?? smallestDownloadSize,
        memoryRequirement:
            memoryRequirements[format] ?? smallestMemoryRequirement,
        estimatedLatencyMs: format == QuantizationFormat.float32 ? 100.0 : 50.0,
        estimatedThroughput: format == QuantizationFormat.float32 ? 10.0 : 20.0,
        supportsGpu: false,
        supportsNeuralEngine: hardwareRequirements.supportsNeuralEngine,
        downloadUrl: huggingFaceUrl,
      );
    }).toList();
  }

  Model copyWith({
    String? id,
    String? name,
    String? description,
    String? version,
    ModelArchitecture? architecture,
    List<QuantizationFormat>? quantizationFormats,
    Map<QuantizationFormat, int>? downloadSizes,
    Map<QuantizationFormat, int>? memoryRequirements,
    List<TaskType>? supportedTaskTypes,
    HardwareRequirements? hardwareRequirements,
    ModelLicense? license,
    bool? isEdgeModel,
    String? repoId,
    String? huggingFaceUrl,
  }) {
    return Model(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      architecture: architecture ?? this.architecture,
      quantizationFormats: quantizationFormats ?? this.quantizationFormats,
      downloadSizes: downloadSizes ?? this.downloadSizes,
      memoryRequirements: memoryRequirements ?? this.memoryRequirements,
      supportedTaskTypes: supportedTaskTypes ?? this.supportedTaskTypes,
      hardwareRequirements: hardwareRequirements ?? this.hardwareRequirements,
      license: license ?? this.license,
      isEdgeModel: isEdgeModel ?? this.isEdgeModel,
      repoId: repoId ?? this.repoId,
      huggingFaceUrl: huggingFaceUrl ?? this.huggingFaceUrl,
    );
  }

  @override
  String toString() => 'Model($id v$version)';
}

/// HuggingFace model representation (remote model source).
class HuggingFaceModel {
  final String repoId;
  final String displayName;
  final String huggingFaceUrl;
  final double sizeMb;
  final String description;
  final List<ModelVariant> variants;
  final bool isLocked;
  final String? downloadHash;

  const HuggingFaceModel({
    required this.repoId,
    required this.displayName,
    required this.huggingFaceUrl,
    required this.sizeMb,
    required this.description,
    this.variants = const [],
    this.isLocked = false,
    this.downloadHash,
  });

  /// Model identifier (alias of [repoId]).
  String get modelId => repoId;

  HuggingFaceModel copyWith({
    String? repoId,
    String? displayName,
    String? huggingFaceUrl,
    double? sizeMb,
    String? description,
    List<ModelVariant>? variants,
    bool? isLocked,
    String? downloadHash,
  }) {
    return HuggingFaceModel(
      repoId: repoId ?? this.repoId,
      displayName: displayName ?? this.displayName,
      huggingFaceUrl: huggingFaceUrl ?? this.huggingFaceUrl,
      sizeMb: sizeMb ?? this.sizeMb,
      description: description ?? this.description,
      variants: variants ?? this.variants,
      isLocked: isLocked ?? this.isLocked,
      downloadHash: downloadHash ?? this.downloadHash,
    );
  }
}

/// Result of a model download operation.
class ModelDownloadResult {
  final bool success;
  final String? modelId;
  final String? errorMessage;
  final int bytesDownloaded;
  final int totalBytes;
  final Duration? duration;
  final Model? model;
  final String? downloadedPath;

  const ModelDownloadResult({
    required this.success,
    this.modelId,
    this.errorMessage,
    this.bytesDownloaded = 0,
    this.totalBytes = 0,
    this.duration,
    this.model,
    this.downloadedPath,
  });

  factory ModelDownloadResult.success({
    required String modelId,
    required Model model,
    int? bytesDownloaded,
    int? totalBytes,
    Duration? duration,
  }) {
    return ModelDownloadResult(
      success: true,
      modelId: modelId,
      model: model,
      bytesDownloaded: bytesDownloaded ?? 0,
      totalBytes: totalBytes ?? 0,
      duration: duration,
    );
  }

  factory ModelDownloadResult.failure(String errorMessage) {
    return ModelDownloadResult(success: false, errorMessage: errorMessage);
  }
}

/// A model loaded into memory.
class LoadedModel {
  final String modelId;
  final String variantId;
  final DateTime loadedAt;
  final double memoryUsed;
  final bool isReady;

  const LoadedModel({
    required this.modelId,
    required this.variantId,
    required this.loadedAt,
    required this.memoryUsed,
    required this.isReady,
  });
}

/// Result of a model compatibility check.
class ModelCompatibilityResult {
  final bool isCompatible;
  final String? reason;
  final List<String> missingRequirements;

  const ModelCompatibilityResult({
    required this.isCompatible,
    this.reason,
    this.missingRequirements = const [],
  });

  static const compatible = ModelCompatibilityResult(isCompatible: true);

  static ModelCompatibilityResult incompatible(
    String reason, {
    List<String>? missingRequirements,
  }) {
    return ModelCompatibilityResult(
      isCompatible: false,
      reason: reason,
      missingRequirements: missingRequirements ?? [],
    );
  }
}
