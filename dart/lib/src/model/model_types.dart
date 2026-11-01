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
