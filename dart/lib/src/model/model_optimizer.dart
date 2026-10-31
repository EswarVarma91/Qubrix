/// Model Optimizer - Smallest-Capable Model Selection Engine
///
/// Finds the smallest model that meets task requirements.
/// Selects models based on measured task performance, not just parameter count.

import 'package:flutter/foundation.dart';
import 'model_types.dart';
import 'model_catalog.dart';
import 'compatibility_engine.dart';

/// Model candidate for a task
class ModelCandidate {
  final Model model;
  final QuantizationFormat quantizationFormat;
  final int downloadSize;
  final int memoryRequirement;
  final double estimatedQuality;
  final double estimatedLatencyMs;
  final double estimatedThroughput;
  final bool isInstalled;
  final bool isCompatible;
  final String? compatibilityReason;

  const ModelCandidate({
    required this.model,
    required this.quantizationFormat,
    required this.downloadSize,
    required this.memoryRequirement,
    required this.estimatedQuality,
    required this.estimatedLatencyMs,
    required this.estimatedThroughput,
    required this.isInstalled,
    required this.isCompatible,
    this.compatibilityReason,
  });

  /// Score combining quality and resource efficiency
  /// Higher is better - balances quality with minimal resource usage
  double get efficiencyScore {
    // Quality score (0-1) weighted at 60%
    // Resource efficiency (1 - normalized resource usage) weighted at 40%
    final resourceScore = 1.0 -
        ((downloadSize / 1024 / 1024) / 1000) - // Normalize to 0-1 scale
        ((memoryRequirement / 1024 / 1024) / 1000);

    return estimatedQuality * 0.6 + (resourceScore.clamp(0, 1)) * 0.4;
  }

  /// Check if this candidate meets minimum quality requirements
  bool meetsQualityThreshold(double minQuality) {
    return estimatedQuality >= minQuality;
  }

  /// Check if this candidate is the smallest that meets requirements
  bool isSmallestAmong(List<ModelCandidate> candidates) {
    final sameQuality = candidates.where((c) =>
        c.estimatedQuality >= estimatedQuality - 0.05 && // Within 5%
        c.estimatedQuality <= estimatedQuality + 0.05);

    if (sameQuality.isEmpty) return false;

    return downloadSize == sameQuality
        .map((c) => c.downloadSize)
        .reduce((a, b) => a < b ? a : b);
  }

  @override
  String toString() =>
      'ModelCandidate(${model.id}, quality: ${estimatedQuality.toStringAsFixed(2)}, size: ${downloadSize ~/ 1024 ~/ 1024}MB)';
}

/// Evaluated model candidate with detailed metrics
class EvaluatedCandidate extends ModelCandidate {
  final double measuredAccuracy;
  final double measuredPrecision;
  final double measuredRecall;
  final double failureRate;
  final int initializationTimeMs;
  final int memoryUsageMb;
  final int peakMemoryUsageMb;
  final int energyConsumptionMah;
  final String benchmarkSource;

  const EvaluatedCandidate({
    required Model model,
    required QuantizationFormat quantizationFormat,
    required int downloadSize,
    required int memoryRequirement,
    required double estimatedQuality,
    required double estimatedLatencyMs,
    required double estimatedThroughput,
    required bool isInstalled,
    required bool isCompatible,
    String? compatibilityReason,
    required this.measuredAccuracy,
    required this.measuredPrecision,
    required this.measuredRecall,
    required this.failureRate,
    required this.initializationTimeMs,
    required this.memoryUsageMb,
    required this.peakMemoryUsageMb,
    required this.energyConsumptionMah,
    required this.benchmarkSource,
  }) : super(
          model: model,
          quantizationFormat: quantizationFormat,
          downloadSize: downloadSize,
          memoryRequirement: memoryRequirement,
          estimatedQuality: estimatedQuality,
          estimatedLatencyMs: estimatedLatencyMs,
          estimatedThroughput: estimatedThroughput,
          isInstalled: isInstalled,
          isCompatible: isCompatible,
          compatibilityReason: compatibilityReason,
        );

  /// Combined quality score from measured metrics
  double get measuredQualityScore {
    // Weighted combination of accuracy, precision, recall, and failure rate
    return (measuredAccuracy * 0.4 +
            measuredPrecision * 0.2 +
            measuredRecall * 0.2 +
            (1.0 - failureRate / 100) * 0.2);
  }

  @override
  String toString() =>
      'EvaluatedCandidate(${model.id}: accuracy=${measuredAccuracy.toStringAsFixed(2)}, size=${downloadSize ~/ 1024 ~/ 1024}MB)';
}

/// Model recommendation with explanation
class ModelRecommendation {
  final ModelCandidate candidate;
  final String explanation;
  final int rank;
  final List<String> reasons;
  final List<String> tradeoffs;

  const ModelRecommendation({
    required this.candidate,
    required this.explanation,
    required this.rank,
    this.reasons = const [],
    this.tradeoffs = const [],
  });

  @override
  String toString() => 'ModelRecommendation(rank: $rank, ${candidate.model.id})';
}

/// Model selection pipeline result
class ModelSelectionResult {
  final ModelCandidate selected;
  final List<ModelCandidate> considered;
  final List<ModelCandidate> rejected;
  final String reason;
  final Duration selectionTime;

  const ModelSelectionResult({
    required this.selected,
    required this.considered,
    required this.rejected,
    required this.reason,
    required this.selectionTime,
  });

  @override
  String toString() =>
      'ModelSelectionResult(selected: ${selected.model.id}, considered: ${considered.length}, rejected: ${rejected.length})';
}

/// Task requirements for model selection
class TaskRequirements {
  final bool requiresModel;
  final TaskComplexity complexity;
  final double minQuality;
  final String preferredApproach;
  final List<TaskType> relevantTaskTypes;
  final Map<String, dynamic> additionalConstraints;

  const TaskRequirements({
    required this.requiresModel,
    required this.complexity,
    required this.minQuality,
    required this.preferredApproach,
    this.relevantTaskTypes = const [],
    this.additionalConstraints = const {},
  });

  /// Copy with modified values
  TaskRequirements copyWith({
    bool? requiresModel,
    TaskComplexity? complexity,
    double? minQuality,
    String? preferredApproach,
    List<TaskType>? relevantTaskTypes,
    Map<String, dynamic>? additionalConstraints,
  }) {
    return TaskRequirements(
      requiresModel: requiresModel ?? this.requiresModel,
      complexity: complexity ?? this.complexity,
      minQuality: minQuality ?? this.minQuality,
      preferredApproach: preferredApproach ?? this.preferredApproach,
      relevantTaskTypes: relevantTaskTypes ?? this.relevantTaskTypes,
      additionalConstraints: additionalConstraints ?? this.additionalConstraints,
    );
  }
}

enum TaskComplexity {
  /// Simple tasks - basic rules or tiny model suffices
  low,

  /// Medium tasks - small to medium model needed
  medium,

  /// Complex tasks - larger model may be required
  high,

  /// Very complex tasks - maximum capability needed
  veryHigh,
}

/// Model optimizer that finds the smallest capable model for tasks
class ModelOptimizer {
  final ModelCatalog catalog;

  // Cache for evaluated candidates
  final Map<String, List<EvaluatedCandidate>> _evaluationCache = {};

  ModelOptimizer({required this.catalog});

  /// Find candidate models for a task
  List<ModelCandidate> findCandidateModels({
    required TaskType taskType,
    required TaskRequirements requirements,
    required DeviceInfo deviceInfo,
    List<Model>? existingModels,
  }) {
    final candidates = <ModelCandidate>[];

    // Get models that support this task
    final compatibleModels = catalog.getModelsForTask(taskType)
      ..retainWhere((m) =>
          m.hardwareRequirements.meetsMinimumRequirements(deviceInfo));

    // If existing models provided, prioritize those
    if (existingModels != null && existingModels.isNotEmpty) {
      final existingIds = existingModels.map((m) => m.id).toSet();

      for (final model in compatibleModels) {
        if (existingIds.contains(model.id)) {
          // Use the installed variant
          final variant = _getInstalledVariant(model);
          candidates.add(ModelCandidate(
            model: model,
            quantizationFormat: variant.quantizationFormat,
            downloadSize: variant.downloadSize,
            memoryRequirement: variant.memoryRequirement,
            estimatedQuality: _estimateQuality(model, taskType),
            estimatedLatencyMs: variant.estimatedLatencyMs,
            estimatedThroughput: variant.estimatedThroughput,
            isInstalled: true,
            isCompatible: true,
          ));
        }
      }
    }

    // Add other compatible models
    for (final model in compatibleModels) {
      if (candidates.any((c) => c.model.id == model.id)) continue;

      // Get the best variant for this device
      final variant = _selectBestVariant(model, deviceInfo, requirements);
      if (variant == null) continue;

      candidates.add(ModelCandidate(
        model: model,
        quantizationFormat: variant.quantizationFormat,
        downloadSize: variant.downloadSize,
        memoryRequirement: variant.memoryRequirement,
        estimatedQuality: _estimateQuality(model, taskType),
        estimatedLatencyMs: variant.estimatedLatencyMs,
        estimatedThroughput: variant.estimatedThroughput,
        isInstalled: false,
        isCompatible: true,
      ));
    }

    // Sort by download size (ascending) for consideration
    candidates.sort((a, b) => a.downloadSize.compareTo(b.downloadSize));

    return candidates;
  }

  /// Select the best variant for a device
  ModelVariant? _selectBestVariant(
    Model model,
    DeviceInfo deviceInfo,
    TaskRequirements requirements,
  ) {
    final variants = model.variants.where((v) {
      // Check if download size fits available storage
      if (v.downloadSize > deviceInfo.availableStorage) return false;

      // Check quantization format support
      if (!model.quantizationFormats.contains(v.quantizationFormat)) {
        return false;
      }

      return true;
    }).toList();

    if (variants.isEmpty) return null;

    // If complexity is low, prefer smallest variant
    if (requirements.complexity == TaskComplexity.low) {
      return variants.reduce((a, b) =>
          a.downloadSize < b.downloadSize ? a : b);
    }

    // For higher complexity, prefer better quality (larger variant)
    // but still try to minimize resources
    return variants.reduce((a, b) {
      // Compare quality-to-size ratio
      final aRatio = a.estimatedThroughput / a.downloadSize;
      final bRatio = b.estimatedThroughput / b.downloadSize;
      return aRatio > bRatio ? a : b;
    });
  }

  /// Get installed variant (for already installed models)
  ModelVariant _getInstalledVariant(Model model) {
    // In a real implementation, this would check what variant was installed
    // For now, return the first/lightest variant
    return model.variants
        .reduce((a, b) => a.downloadSize < b.downloadSize ? a : b);
  }

  /// Estimate quality of a model for a task
  double _estimateQuality(Model model, TaskType taskType) {
    // Check if we have benchmark data
    final benchmark = catalog.getBenchmark(model.id);
    if (benchmark != null && benchmark.taskType == taskType) {
      return benchmark.accuracy;
    }

    // Heuristic estimation based on model type
    switch (taskType) {
      case TaskType.classification:
      case TaskType.extraction:
        if (model.isEdgeModel && model.architecture == ModelArchitecture.specialized) {
          return 0.85; // Specialized edge models are good at these tasks
        }
        if (model.architecture == ModelArchitecture.transformer) {
          return model.smallestDownloadSize < 100 * 1024 * 1024 ? 0.75 : 0.90;
        }
        return 0.65;

      case TaskType.summarization:
        if (model.architecture == ModelArchitecture.transformer) {
          return model.smallestDownloadSize < 100 * 1024 * 1024 ? 0.65 : 0.85;
        }
        return 0.40; // Statistical models not great at summarization

      case TaskType.generation:
      case TaskType.complexReasoning:
        if (model.architecture == ModelArchitecture.transformer) {
          return model.smallestDownloadSize > 500 * 1024 * 1024 ? 0.85 : 0.60;
        }
        return 0.20; // Non-transformer models struggle here

      case TaskType.planning:
        if (model.architecture == ModelArchitecture.transformer) {
          return model.smallestDownloadSize > 300 * 1024 * 1024 ? 0.75 : 0.55;
        }
        return 0.30;

      case TaskType.statistics:
      case TaskType.patternDetection:
        if (model.architecture == ModelArchitecture.statistical ||
            model.isEdgeModel) {
          return 0.90; // Statistical models excel at this
        }
        return 0.60;

      case TaskType.search:
        return 0.70; // Most models can handle search tasks

      case TaskType.processing:
      default:
        return 0.75;
    }
  }

  /// Evaluate candidates against task requirements
  Future<List<EvaluatedCandidate>> evaluateCandidates(
    List<ModelCandidate> candidates, {
    required TaskRequirements taskRequirements,
    required DeviceInfo deviceInfo,
  }) async {
    final evaluated = <EvaluatedCandidate>[];

    for (final candidate in candidates) {
      // Check if we have cached evaluation
      final cacheKey = '${candidate.model.id}_${candidate.quantizationFormat.name}_${taskRequirements.taskType?.name}';
      if (_evaluationCache.containsKey(cacheKey)) {
        final cached = _evaluationCache[cacheKey]!.firstWhere(
          (c) => c.model.id == candidate.model.id,
          orElse: () => throw Exception('Not found'),
        );
        evaluated.add(cached);
        continue;
      }

      // Perform evaluation (simulated)
      final evaluation = await _evaluateCandidate(
        candidate,
        taskRequirements,
        deviceInfo,
      );
      evaluated.add(evaluation);

      // Cache the result
      if (!_evaluationCache.containsKey(cacheKey)) {
        _evaluationCache[cacheKey] = [];
      }
      _evaluationCache[cacheKey]!.add(evaluation);
    }

    return evaluated;
  }

  /// Evaluate a single candidate
  Future<EvaluatedCandidate> _evaluateCandidate(
    ModelCandidate candidate,
    TaskRequirements requirements,
    DeviceInfo deviceInfo,
  ) async {
    // Simulate benchmark-based evaluation
    // In a real implementation, this would use actual benchmarks or run tests

    final baseQuality = candidate.estimatedQuality;

    // Adjust quality based on device compatibility
    double adjustedQuality = baseQuality;
    int memoryUsage = candidate.memoryRequirement;
    int initializationTime = 100; // Default
    double latency = candidate.estimatedLatencyMs;
    int energy = 50; // Default mAh

    // Fine-tune based on device characteristics
    if (deviceInfo.deviceClass == DeviceClass.lowEnd) {
      // Low-end devices may have slightly lower effective quality
      adjustedQuality *= 0.95;
      memoryUsage = (memoryUsage * 1.1).toInt(); // Higher memory pressure
      initializationTime = (initializationTime * 1.5).toInt();
    } else if (deviceInfo.deviceClass == DeviceClass.highEnd) {
      // High-end devices can leverage hardware acceleration
      if (deviceInfo.supportsNeuralEngine) {
        adjustedQuality *= 1.02;
        latency *= 0.8;
        energy = (energy * 0.7).toInt();
      }
      if (deviceInfo.supportsGpu) {
        latency *= 0.9;
      }
    }

    // Ensure quality doesn't exceed 1.0
    adjustedQuality = adjustedQuality.clamp(0.0, 1.0);

    // Calculate failure rate (inversely related to quality)
    final failureRate = ((1.0 - adjustedQuality) * 100).toInt();

    return EvaluatedCandidate(
      model: candidate.model,
      quantizationFormat: candidate.quantizationFormat,
      downloadSize: candidate.downloadSize,
      memoryRequirement: candidate.memoryRequirement,
      estimatedQuality: adjustedQuality,
      estimatedLatencyMs: latency,
      estimatedThroughput: candidate.estimatedThroughput,
      isInstalled: candidate.isInstalled,
      isCompatible: candidate.isCompatible,
      compatibilityReason: candidate.compatibilityReason,
      measuredAccuracy: adjustedQuality,
      measuredPrecision: adjustedQuality * 0.95,
      measuredRecall: adjustedQuality * 0.95,
      failureRate: failureRate,
      initializationTimeMs: initializationTime,
      memoryUsageMb: memoryUsage ~/ (1024 * 1024),
      peakMemoryUsageMb: (memoryUsage * 1.2) ~/ (1024 * 1024),
      energyConsumptionMah: energy,
      benchmarkSource: 'simulated',
    );
  }

  /// Select the smallest model that meets quality requirements
  EvaluatedCandidate? selectSmallestQualified(
    List<EvaluatedCandidate> candidates, {
    required double minQuality,
    bool preferInstalled = false,
  }) {
    // Filter candidates that meet quality threshold
    var qualified = candidates.where((c) =>
        c.measuredQualityScore >= minQuality &&
        c.isCompatible).toList();

    if (qualified.isEmpty) {
      // Try with relaxed quality requirement
      qualified = candidates.where((c) =>
          c.measuredQualityScore >= minQuality * 0.9 &&
          c.isCompatible).toList();
    }

    if (qualified.isEmpty) return null;

    // Filter for installed models if preferred
    if (preferInstalled) {
      final installed = qualified.where((c) => c.isInstalled).toList();
      if (installed.isNotEmpty) {
        qualified = installed;
      }
    }

    // Sort by download size (ascending) - smallest first
    qualified.sort((a, b) => a.downloadSize.compareTo(b.downloadSize));

    // Select the smallest qualified model
    return qualified.first;
  }

  /// Get the smallest suitable model for a task
  Future<ModelCandidate?> findSmallestSuitableModel({
    required TaskType taskType,
    required DeviceInfo deviceInfo,
    double? minQuality,
    bool preferInstalled = false,
  }) async {
    final requirements = TaskRequirements(
      requiresModel: true,
      complexity: TaskComplexity.medium,
      minQuality: minQuality ?? 0.7,
      preferredApproach: 'model',
      relevantTaskTypes: [taskType],
    );

    final candidates = findCandidateModels(
      taskType: taskType,
      requirements: requirements,
      deviceInfo: deviceInfo,
    );

    if (candidates.isEmpty) return null;

    final evaluated = await evaluateCandidates(
      candidates,
      taskRequirements: requirements,
      deviceInfo: deviceInfo,
    );

    return selectSmallestQualified(
      evaluated,
      minQuality: requirements.minQuality,
      preferInstalled: preferInstalled,
    );
  }

  /// Get model recommendations with explanations
  Future<List<ModelRecommendation>> getRecommendations(
    TaskRequirements requirements,
  ) async {
    final deviceInfo = await _getCurrentDeviceInfo();
    final candidates = findCandidateModels(
      taskType: requirements.relevantTaskTypes.isNotEmpty
          ? requirements.relevantTaskTypes.first
          : TaskType.processing,
      requirements: requirements,
      deviceInfo: deviceInfo,
    );

    final evaluated = await evaluateCandidates(
      candidates,
      taskRequirements: requirements,
      deviceInfo: deviceInfo,
    );

    final recommendations = <ModelRecommendation>[];

    // Sort by efficiency score
    evaluated.sort((a, b) => b.efficiencyScore.compareTo(a.efficiencyScore));

    for (var i = 0; i < evaluated.length; i++) {
      final candidate = evaluated[i];
      final reasons = <String>[];
      final tradeoffs = <String>[];

      // Generate explanation
      if (candidate.isInstalled) {
        reasons.add('Already installed - no download needed');
      }

      if (candidate.downloadSize < 100 * 1024 * 1024) {
        reasons.add('Small footprint (${candidate.downloadSize ~/ 1024 ~/ 1024}MB)');
      } else if (candidate.downloadSize < 500 * 1024 * 1024) {
        tradeoffs.add('Moderate download size');
      }

      if (candidate.estimatedQuality >= requirements.minQuality) {
        reasons.add('Meets quality requirements');
      } else {
        tradeoffs.add('Quality below target threshold');
      }

      if (candidate.isSmallestAmong(evaluated)) {
        reasons.add('Smallest model meeting requirements');
      }

      final explanation = _generateExplanation(
        candidate,
        reasons,
        tradeoffs,
        requirements,
      );

      recommendations.add(ModelRecommendation(
        candidate: candidate,
        explanation: explanation,
        rank: i + 1,
        reasons: reasons,
        tradeoffs: tradeoffs,
      ));
    }

    return recommendations;
  }

  /// Generate explanation for a recommendation
  String _generateExplanation(
    EvaluatedCandidate candidate,
    List<String> reasons,
    List<String> tradeoffs,
    TaskRequirements requirements,
  ) {
    final parts = <String>[];

    parts.add('${candidate.model.name} (${candidate.model.version})');

    if (candidate.isInstalled) {
      parts.add('is already installed');
    } else {
      parts.add('requires ${candidate.downloadSize ~/ 1024 ~/ 1024}MB download');
    }

    parts.add('provides ${candidate.measuredQualityScore.toStringAsFixed(0) * 100}% task accuracy');

    if (candidate.memoryRequirement < 100 * 1024 * 1024) {
      parts.add('uses minimal memory (${candidate.memoryRequirement ~/ 1024 ~/ 1024}MB)');
    }

    if (tradeoffs.isNotEmpty) {
      parts.add('Tradeoffs: ${tradeoffs.join(', ')}');
    }

    if (requirements.complexity == TaskComplexity.low &&
        candidate.downloadSize < 50 * 1024 * 1024) {
      parts.add(
          'Suitable for this simple task - no need for larger models');
    }

    return parts.join('. ');
  }

  /// Clear evaluation cache
  void clearCache() {
    _evaluationCache.clear();
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'entries': _evaluationCache.length,
      'cachedCandidates': _evaluationCache.values.fold<int>(
        0,
        (sum, list) => sum + list.length,
      ),
    };
  }

  /// Simulated device info for when we can't get real device info
  Future<DeviceInfo> _getCurrentDeviceInfo() async {
    // This would be provided by the compatibility engine
    // For now, return a default
    return DeviceInfo(
      totalMemory: 4 * 1024 * 1024 * 1024,
      availableMemory: 2 * 1024 * 1024 * 1024,
      totalStorage: 64 * 1024 * 1024 * 1024,
      availableStorage: 32 * 1024 * 1024 * 1024,
      cpuCores: 6,
      cpuFrequencyHz: 2400000000,
      supportsGpu: true,
      supportsNeuralEngine: false,
      os: 'Android',
      osVersion: '13',
      deviceModel: 'Demo Device',
      manufacturer: 'Demo',
      screenWidth: 1080,
      screenHeight: 2400,
      isRooted: false,
      batteryLevel: 0.8,
      isCharging: false,
      networkType: NetworkType.wifi,
      powerSaveMode: false,
    );
  }
}
