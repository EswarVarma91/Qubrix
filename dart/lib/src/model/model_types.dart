/// Model types and data structures for the AI Model Manager

import 'package:flutter/foundation.dart';

/// Represents a model in the catalog
@immutable
class Model {
  /// Unique identifier for the model
  final String id;

  /// Human-readable name
  final String name;

  /// Description of what the model does
  final String description;

  /// Model version/revision
  final String version;

  /// Model architecture type
  final ModelArchitecture architecture;

  /// Supported quantization formats
  final List<QuantizationFormat> quantizationFormats;

  /// Download sizes for each quantization format
  final Map<QuantizationFormat, int> downloadSizes;

  /// Memory requirements for each format
  final Map<QuantizationFormat, int> memoryRequirements;

  /// Task types this model can handle
  final List<TaskType> supportedTaskTypes;

  /// Hardware compatibility requirements
  final HardwareRequirements hardwareRequirements;

  /// License information
  final ModelLicense license;

  /// Metadata tags
  final Map<String, String> metadata;

  /// Whether this is an edge/specialized model
  final bool isEdgeModel;

  /// Parent model ID if this is a fine-tuned variant
  final String? parentModelId;

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
    this.metadata = const {},
    this.isEdgeModel = false,
    this.parentModelId,
  });

  /// Get the smallest download size available
  int get smallestDownloadSize {
    if (downloadSizes.isEmpty) return 0;
    return downloadSizes.values.reduce((a, b) => a < b ? a : b);
  }

  /// Get the smallest memory requirement
  int get smallestMemoryRequirement {
    if (memoryRequirements.isEmpty) return 0;
    return memoryRequirements.values.reduce((a, b) => a < b ? a : b);
  }

  /// Check if this model supports a specific task
  bool supportsTask(TaskType taskType) {
    return supportedTaskTypes.contains(taskType);
  }

  /// Check if this model supports a specific quantization format
  bool supportsQuantization(QuantizationFormat format) {
    return quantizationFormats.contains(format);
  }

  /// Create a copy with some fields replaced
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
    Map<String, String>? metadata,
    bool? isEdgeModel,
    String? parentModelId,
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
      metadata: metadata ?? this.metadata,
      isEdgeModel: isEdgeModel ?? this.isEdgeModel,
      parentModelId: parentModelId ?? this.parentModelId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'version': version,
        'architecture': architecture.name,
        'quantizationFormats':
            quantizationFormats.map((q) => q.name).toList(),
        'downloadSizes': {
          for (final entry in downloadSizes.entries)
            entry.key.name: entry.value
        },
        'memoryRequirements': {
          for (final entry in memoryRequirements.entries)
            entry.key.name: entry.value
        },
        'supportedTaskTypes': supportedTaskTypes.map((t) => t.name).toList(),
        'hardwareRequirements': hardwareRequirements.toJson(),
        'license': license.toJson(),
        'metadata': metadata,
        'isEdgeModel': isEdgeModel,
        'parentModelId': parentModelId,
      };

  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      version: json['version'] as String,
      architecture: ModelArchitecture.values.firstWhere(
        (e) => e.name == json['architecture'],
        orElse: () => ModelArchitecture.unknown,
      ),
      quantizationFormats: (json['quantizationFormats'] as List<dynamic>)
          .map((q) =>
              QuantizationFormat.values.firstWhere(
                (e) => e.name == q,
                orElse: () => QuantizationFormat.unknown,
              ))
          .toList(),
      downloadSizes: (json['downloadSizes'] as Map<String, dynamic>)
          .map((k, v) =>
              MapEntry(
                  QuantizationFormat.values.firstWhere(
                    (e) => e.name == k,
                    orElse: () => QuantizationFormat.unknown,
                  ),
                  v as int)),
      memoryRequirements: (json['memoryRequirements'] as Map<String, dynamic>)
          .map((k, v) =>
              MapEntry(
                  QuantizationFormat.values.firstWhere(
                    (e) => e.name == k,
                    orElse: () => QuantizationFormat.unknown,
                  ),
                  v as int)),
      supportedTaskTypes: (json['supportedTaskTypes'] as List<dynamic>)
          .map((t) =>
              TaskType.values.firstWhere(
                (e) => e.name == t,
                orElse: () => TaskType.processing,
              ))
          .toList(),
      hardwareRequirements: HardwareRequirements.fromJson(
          json['hardwareRequirements'] as Map<String, dynamic>),
      license: ModelLicense.fromJson(json['license'] as Map<String, dynamic>),
      metadata: json['metadata'] as Map<String, String>? ?? {},
      isEdgeModel: json['isEdgeModel'] as bool? ?? false,
      parentModelId: json['parentModelId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Model &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          version == other.version;

  @override
  int get hashCode => id.hashCode ^ version.hashCode;

  @override
  String toString() => 'Model(id: $id, name: $name, version: $version)';
}

/// Model architecture types
enum ModelArchitecture {
  /// Unknown architecture
  unknown,

  /// Transformer-based models
  transformer,

  /// RNN/LSTM based models
  rnn,

  /// CNN-based models
  cnn,

  /// Decision tree ensembles
  decisionTree,

  /// Statistical models
  statistical,

  /// Custom/small specialized models
  specialized,

  /// Rule-based system
  rules,
}

/// Quantization formats for model optimization
enum QuantizationFormat {
  /// Original precision (typically float32)
  float32,

  /// Half precision
  float16,

  /// 8-bit integer quantization
  int8,

  /// 4-bit integer quantization
  int4,

  /// Dynamic quantization
  dynamic,

  /// GGUF format (for LLM inference)
  gguf,

  /// ONNX format
  onnx,

  /// TFLite format
  tflite,

  /// Unknown format
  unknown,
}

/// Hardware requirements for running a model
@immutable
class HardwareRequirements {
  /// Minimum RAM in MB
  final int minRamMb;

  /// Recommended RAM in MB
  final int? recommendedRamMb;

  /// Minimum storage in MB
  final int minStorageMb;

  /// Whether GPU is required
  final bool requiresGpu;

  /// Whether GPU is recommended
  final bool recommendsGpu;

  /// Minimum CPU cores
  final int minCpuCores;

  /// Whether NNAPI/Neural Engine is supported
  final bool supportsNeuralEngine;

  /// Whether the model can run on low-end devices
  final bool supportsLowEndDevices;

  /// Supported OS versions
  final List<String> supportedOSVersions;

  /// Device class compatibility
  final List<DeviceClass> compatibleDeviceClasses;

  const HardwareRequirements({
    required this.minRamMb,
    this.recommendedRamMb,
    required this.minStorageMb,
    this.requiresGpu = false,
    this.recommendsGpu = false,
    this.minCpuCores = 1,
    this.supportsNeuralEngine = false,
    this.supportsLowEndDevices = true,
    this.supportedOSVersions = const [],
    this.compatibleDeviceClasses = const [
      DeviceClass.lowEnd,
      DeviceClass.medium,
      DeviceClass.highEnd,
    ],
  });

  /// Check if device meets minimum requirements
  bool meetsMinimumRequirements(DeviceInfo deviceInfo) {
    if (deviceInfo.totalMemory < minRamMb * 1024 * 1024) {
      return false;
    }
    if (deviceInfo.totalStorage < minStorageMb * 1024 * 1024) {
      return false;
    }
    if (requiresGpu && !deviceInfo.supportsGpu) {
      return false;
    }
    if (deviceInfo.cpuCores < minCpuCores) {
      return false;
    }
    return true;
  }

  /// Check if device meets recommended requirements
  bool meetsRecommendedRequirements(DeviceInfo deviceInfo) {
    if (recommendedRamMb != null &&
        deviceInfo.totalMemory < recommendedRamMb! * 1024 * 1024) {
      return false;
    }
    if (recommendsGpu && !deviceInfo.supportsGpu) {
      return false;
    }
    return meetsMinimumRequirements(deviceInfo);
  }

  Map<String, dynamic> toJson() => {
        'minRamMb': minRamMb,
        'recommendedRamMb': recommendedRamMb,
        'minStorageMb': minStorageMb,
        'requiresGpu': requiresGpu,
        'recommendsGpu': recommendsGpu,
        'minCpuCores': minCpuCores,
        'supportsNeuralEngine': supportsNeuralEngine,
        'supportsLowEndDevices': supportsLowEndDevices,
        'supportedOSVersions': supportedOSVersions,
        'compatibleDeviceClasses':
            compatibleDeviceClasses.map((d) => d.name).toList(),
      };

  factory HardwareRequirements.fromJson(Map<String, dynamic> json) {
    return HardwareRequirements(
      minRamMb: json['minRamMb'] as int,
      recommendedRamMb: json['recommendedRamMb'] as int?,
      minStorageMb: json['minStorageMb'] as int,
      requiresGpu: json['requiresGpu'] as bool? ?? false,
      recommendsGpu: json['recommendsGpu'] as bool? ?? false,
      minCpuCores: json['minCpuCores'] as int? ?? 1,
      supportsNeuralEngine: json['supportsNeuralEngine'] as bool? ?? false,
      supportsLowEndDevices: json['supportsLowEndDevices'] as bool? ?? true,
      supportedOSVersions:
          (json['supportedOSVersions'] as List<dynamic>?)
                  ?.map((s) => s as String)
                  .toList() ??
              [],
      compatibleDeviceClasses: (json['compatibleDeviceClasses']
              as List<dynamic>?)
          ?.map((d) =>
              DeviceClass.values.firstWhere(
                (e) => e.name == d,
                orElse: () => DeviceClass.unknown,
              ))
          .toList() ??
      [
        DeviceClass.lowEnd,
        DeviceClass.medium,
        DeviceClass.highEnd,
      ],
    );
  }

  @override
  String toString() =>
      'HardwareRequirements(minRam: ${minRamMb}MB, minStorage: ${minStorageMb}MB)';
}

/// Model license information
@immutable
class ModelLicense {
  /// License type
  final LicenseType type;

  /// License name (e.g., "Apache 2.0", "MIT")
  final String name;

  /// URL to license text
  final String? licenseUrl;

  /// Whether commercial use is allowed
  final bool allowsCommercialUse;

  /// Whether modification is allowed
  final bool allowsModification;

  /// Whether distribution is allowed
  final bool allowsDistribution;

  /// Attribution requirements
  final AttributionRequirement attributionRequirement;

  /// Any restrictions
  final List<String> restrictions;

  const ModelLicense({
    required this.type,
    required this.name,
    this.licenseUrl,
    this.allowsCommercialUse = true,
    this.allowsModification = true,
    this.allowsDistribution = true,
    this.attributionRequirement = AttributionRequirement.none,
    this.restrictions = const [],
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'name': name,
        'licenseUrl': licenseUrl,
        'allowsCommercialUse': allowsCommercialUse,
        'allowsModification': allowsModification,
        'allowsDistribution': allowsDistribution,
        'attributionRequirement': attributionRequirement.name,
        'restrictions': restrictions,
      };

  factory ModelLicense.fromJson(Map<String, dynamic> json) {
    return ModelLicense(
      type: LicenseType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LicenseType.other,
      ),
      name: json['name'] as String,
      licenseUrl: json['licenseUrl'] as String?,
      allowsCommercialUse: json['allowsCommercialUse'] as bool? ?? true,
      allowsModification: json['allowsModification'] as bool? ?? true,
      allowsDistribution: json['allowsDistribution'] as bool? ?? true,
      attributionRequirement: AttributionRequirement.values.firstWhere(
        (e) => e.name == json['attributionRequirement'],
        orElse: () => AttributionRequirement.none,
      ),
      restrictions: (json['restrictions'] as List<dynamic>?)
              ?.map((r) => r as String)
              .toList() ??
          [],
    );
  }

  @override
  String toString() => 'ModelLicense(type: ${type.name}, name: $name)';
}

enum LicenseType {
  /// Permissive open source
  permissive,

  /// Copyleft open source
  copyleft,

  /// Proprietary
  proprietary,

  /// Creative Commons
  creativeCommons,

  /// Academic/research only
  academic,

  /// Other license
  other,
}

enum AttributionRequirement {
  /// No attribution required
  none,

  /// Attribution recommended
  recommended,

  /// Attribution required
  required,

  /// Attribution with specific requirements
  specific,
}

/// Device class for compatibility
enum DeviceClass {
  /// Low-end devices
  lowEnd,

  /// Medium-end devices
  medium,

  /// High-end devices
  highEnd,

  /// Unknown
  unknown,
}

/// Device information for compatibility checking
@immutable
class DeviceInfo {
  /// Total memory in bytes
  final int totalMemory;

  /// Available memory in bytes
  final int availableMemory;

  /// Storage capacity in bytes
  final int totalStorage;

  /// Available storage in bytes
  final int availableStorage;

  /// Number of CPU cores
  final int cpuCores;

  /// CPU frequency in Hz
  final int cpuFrequencyHz;

  /// Whether GPU is available
  final bool supportsGpu;

  /// GPU model name (if available)
  final String? gpuModel;

  /// Whether neural engine/NPU is available
  final bool supportsNeuralEngine;

  /// Neural engine name (if available)
  final String? neuralEngineModel;

  /// Operating system
  final String os;

  /// OS version
  final String osVersion;

  /// Device model
  final String deviceModel;

  /// Device manufacturer
  final String manufacturer;

  /// Screen resolution
  final int screenWidth;
  final int screenHeight;

  /// Is the device rooted/jailbroken
  final bool isRooted;

  /// Battery level (0.0 to 1.0)
  final double batteryLevel;

  /// Is device charging
  final bool isCharging;

  /// Network type
  final NetworkType networkType;

  /// Is device in power save mode
  final bool powerSaveMode;

  const DeviceInfo({
    required this.totalMemory,
    required this.availableMemory,
    required this.totalStorage,
    required this.availableStorage,
    required this.cpuCores,
    required this.cpuFrequencyHz,
    required this.supportsGpu,
    this.gpuModel,
    required this.supportsNeuralEngine,
    this.neuralEngineModel,
    required this.os,
    required this.osVersion,
    required this.deviceModel,
    required this.manufacturer,
    required this.screenWidth,
    required this.screenHeight,
    required this.isRooted,
    required this.batteryLevel,
    required this.isCharging,
    required this.networkType,
    required this.powerSaveMode,
  });

  /// Calculate device class
  DeviceClass get deviceClass {
    // Simple heuristic based on RAM
    if (totalMemory >= 8 * 1024 * 1024 * 1024) {
      return DeviceClass.highEnd;
    } else if (totalMemory >= 4 * 1024 * 1024 * 1024) {
      return DeviceClass.medium;
    } else {
      return DeviceClass.lowEnd;
    }
  }

  /// Check if device is suitable for on-device AI
  bool get isSuitableForOnDeviceAI {
    return totalMemory >= 2 * 1024 * 1024 * 1024 &&
        cpuCores >= 4 &&
        !powerSaveMode;
  }

  Map<String, dynamic> toJson() => {
        'totalMemory': totalMemory,
        'availableMemory': availableMemory,
        'totalStorage': totalStorage,
        'availableStorage': availableStorage,
        'cpuCores': cpuCores,
        'cpuFrequencyHz': cpuFrequencyHz,
        'supportsGpu': supportsGpu,
        'gpuModel': gpuModel,
        'supportsNeuralEngine': supportsNeuralEngine,
        'neuralEngineModel': neuralEngineModel,
        'os': os,
        'osVersion': osVersion,
        'deviceModel': deviceModel,
        'manufacturer': manufacturer,
        'screenWidth': screenWidth,
        'screenHeight': screenHeight,
        'isRooted': isRooted,
        'batteryLevel': batteryLevel,
        'isCharging': isCharging,
        'networkType': networkType.name,
        'powerSaveMode': powerSaveMode,
      };
}

enum NetworkType {
  /// No network
  none,

  /// Wi-Fi
  wifi,

  /// Cellular (4G/LTE)
  cellular4g,

  /// Cellular (5G)
  cellular5g,

  /// Cellular (3G)
  cellular3g,

  /// Cellular (2G)
  cellular2g,
}
