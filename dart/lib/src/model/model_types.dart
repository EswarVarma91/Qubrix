/// Model types used throughout the SDK.
library;

import '../core/types.dart';

/// HuggingFace model representation.
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

  String get modelId => repoId;
}

/// Model variant representation.
class ModelVariant {
  final String modelId;
  final String variantName;
  final double sizeMb;
  final String description;
  final List<TaskType> supportedTaskTypes;

  const ModelVariant({
    required this.modelId,
    required this.variantName,
    required this.sizeMb,
    required this.description,
    required this.supportedTaskTypes,
  });

  ModelVariant copyWith({
    String? modelId,
    String? variantName,
    double? sizeMb,
    String? description,
    List<TaskType>? supportedTaskTypes,
  }) {
    return ModelVariant(
      modelId: modelId ?? this.modelId,
      variantName: variantName ?? this.variantName,
      sizeMb: sizeMb ?? this.sizeMb,
      description: description ?? this.description,
      supportedTaskTypes: supportedTaskTypes ?? this.supportedTaskTypes,
    );
  }
}

/// Model download result.
class ModelDownloadResult {
  final bool success;
  final String? errorMessage;
  final int bytesDownloaded;
  final int totalBytes;
  final String? downloadedPath;

  const ModelDownloadResult({
    required this.success,
    this.errorMessage,
    required this.bytesDownloaded,
    required this.totalBytes,
    this.downloadedPath,
  });
}

/// Loaded model representation.
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

/// Installed/Loaded model representation.
class Model {
  final String id;
  final String displayName;
  final String repoId;
  final double sizeMb;
  final DateTime installedAt;
  final bool isLoaded;
  final List<String> variants;
  final Map<TaskType, double> qualityScores;

  const Model({
    required this.id,
    required this.displayName,
    required this.repoId,
    required this.sizeMb,
    required this.installedAt,
    this.isLoaded = false,
    this.variants = const [],
    this.qualityScores = const {},
  });

  Model copyWith({
    String? id,
    String? displayName,
    String? repoId,
    double? sizeMb,
    DateTime? installedAt,
    bool? isLoaded,
    List<String>? variants,
    Map<TaskType, double>? qualityScores,
  }) {
    return Model(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      repoId: repoId ?? this.repoId,
      sizeMb: sizeMb ?? this.sizeMb,
      installedAt: installedAt ?? this.installedAt,
      isLoaded: isLoaded ?? this.isLoaded,
      variants: variants ?? this.variants,
      qualityScores: qualityScores ?? this.qualityScores,
    );
  }
}

/// Model compatibility result.
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
  static ModelCompatibilityResult incompatible(String reason, {List<String>? missingRequirements}) {
    return ModelCompatibilityResult(
      isCompatible: false,
      reason: reason,
      missingRequirements: missingRequirements ?? [],
    );
  }
}

/// Quantization format for model variants.
enum QuantizationFormat {
  float32,
  float16,
  int8,
  int4,
  gguf,
  unknown,
}

/// Model architecture type.
enum ModelArchitecture {
  transformer,
  lstm,
  cnn,
  specialized,
  statistical,
  unknown,
}

/// Device class for model compatibility.
enum DeviceClass {
  lowEnd,
  midRange,
  highEnd,
  unknown,
}

/// License type.
enum LicenseType {
  permissive,
  copyleft,
  proprietary,
  unknown,
}

/// Model license info.
class ModelLicense {
  final LicenseType type;
  final String name;
  final bool allowsCommercialUse;
  final bool allowsModification;
  final bool requiresAttribution;

  const ModelLicense({
    required this.type,
    required this.name,
    this.allowsCommercialUse = true,
    this.allowsModification = true,
    this.requiresAttribution = true,
  });
}

/// Hardware requirements for a model.
class HardwareRequirements {
  final int minRamMb;
  final int? recommendedRamMb;
  final int minStorageMb;
  final bool supportsLowEndDevices;
  final bool supportsNeuralEngine;
  final bool supportsGpu;

  const HardwareRequirements({
    required this.minRamMb,
    this.recommendedRamMb,
    required this.minStorageMb,
    this.supportsLowEndDevices = false,
    this.supportsNeuralEngine = false,
    this.supportsGpu = false,
  });

  bool meetsMinimumRequirements(DeviceInfo deviceInfo) {
    return deviceInfo.totalMemory >= minRamMb * 1024 * 1024 &&
        deviceInfo.availableStorage >= minStorageMb * 1024 * 1024;
  }
}

/// Rich Model class with full metadata.
class RichModel {
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

  const RichModel({
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
  });

  int get smallestDownloadSize => downloadSizes.values.reduce((a, b) => a < b ? a : b);
  int get smallestMemoryRequirement => memoryRequirements.values.reduce((a, b) => a < b ? a : b);
  int get availableStorage => 0;

  RichModel copyWith({
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
  }) {
    return RichModel(
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
    );
  }
}
