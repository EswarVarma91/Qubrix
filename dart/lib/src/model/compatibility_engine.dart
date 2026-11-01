/// Compatibility Engine
///
/// Validates models against device and runtime capabilities.
/// Checks hardware requirements, OS compatibility, and runtime support.

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/types.dart';
import 'model_catalog.dart';
import 'model_types.dart';

/// Compatibility check result
@immutable
class CompatibilityResult {
  /// Whether the model is compatible
  final bool isCompatible;

  /// Compatibility level
  final CompatibilityLevel level;

  /// Human-readable reason if not compatible
  final String? reason;

  /// Specific issues found
  final List<CompatibilityIssue> issues;

  /// Suggestions for making it compatible
  final List<String> suggestions;

  const CompatibilityResult({
    required this.isCompatible,
    required this.level,
    this.reason,
    this.issues = const [],
    this.suggestions = const [],
  });

  /// Create a successful compatibility result
  factory CompatibilityResult.compatible({
    CompatibilityLevel level = CompatibilityLevel.full,
    List<String> suggestions = const [],
  }) {
    return CompatibilityResult(
      isCompatible: true,
      level: level,
      suggestions: suggestions,
    );
  }

  /// Create a failed compatibility result
  factory CompatibilityResult.incompatible(String reason) {
    return CompatibilityResult(
      isCompatible: false,
      level: CompatibilityLevel.none,
      reason: reason,
      issues: [CompatibilityIssue.error(reason)],
    );
  }

  /// Check if compatible at minimum level
  bool get isMinimallyCompatible =>
      level.index >= CompatibilityLevel.minimal.index;

  /// Check if compatible at recommended level
  bool get isRecommendedCompatible =>
      level.index >= CompatibilityLevel.recommended.index;
}

/// Compatibility levels
enum CompatibilityLevel {
  /// Fully compatible - can use all features
  full,

  /// Recommended - works well with minor limitations
  recommended,

  /// Minimum - works but with significant limitations
  minimal,

  /// Not compatible
  none,
}

/// Specific compatibility issue
@immutable
class CompatibilityIssue {
  final IssueSeverity severity;
  final String message;
  final String? field;

  const CompatibilityIssue({
    required this.severity,
    required this.message,
    this.field,
  });

  factory CompatibilityIssue.error(String message) {
    return CompatibilityIssue(
      severity: IssueSeverity.error,
      message: message,
    );
  }

  factory CompatibilityIssue.warning(String message) {
    return CompatibilityIssue(
      severity: IssueSeverity.warning,
      message: message,
    );
  }

  factory CompatibilityIssue.info(String message) {
    return CompatibilityIssue(
      severity: IssueSeverity.info,
      message: message,
    );
  }
}

enum IssueSeverity {
  /// Critical issue - prevents operation
  error,

  /// Warning - operation may fail or be slow
  warning,

  /// Information only
  info,
}

/// Detailed compatibility information
@immutable
class DetailedCompatibility {
  final CompatibilityResult result;
  final DeviceInfo deviceInfo;
  final Model model;
  final ModelVariant? selectedVariant;

  /// Component-specific checks
  final Map<String, ComponentCompatibility> componentChecks;

  const DetailedCompatibility({
    required this.result,
    required this.deviceInfo,
    required this.model,
    this.selectedVariant,
    this.componentChecks = const {},
  });
}

/// Compatibility check for a specific component
@immutable
class ComponentCompatibility {
  final String componentName;
  final bool isCompatible;
  final String? reason;
  final Map<String, dynamic> details;

  const ComponentCompatibility({
    required this.componentName,
    required this.isCompatible,
    this.reason,
    this.details = const {},
  });
}

/// Compatibility engine for validating models against device capabilities
class CompatibilityEngine {
  /// Cache device info to avoid repeated queries
  DeviceInfo? _cachedDeviceInfo;
  DateTime? _deviceInfoCacheTime;

  /// Cache duration for device info
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Get current device information
  Future<DeviceInfo> getDeviceInfo() async {
    // Return cached info if still valid
    if (_cachedDeviceInfo != null &&
        _deviceInfoCacheTime != null &&
        DateTime.now().difference(_deviceInfoCacheTime!) < _cacheDuration) {
      return _cachedDeviceInfo!;
    }

    // In a real Flutter implementation, this would use:
    // - device_info_plus for device details
    // - memory_info for memory info
    // - Various platform channels for hardware details

    final deviceInfo = await _collectDeviceInfo();
    _cachedDeviceInfo = deviceInfo;
    _deviceInfoCacheTime = DateTime.now();

    return deviceInfo;
  }

  /// Collect device information from the platform
  Future<DeviceInfo> _collectDeviceInfo() async {
    // In a real implementation, this would query platform-specific APIs

    // Simulating device info for demonstration
    return DeviceInfo(
      totalMemory: 4 * 1024 * 1024 * 1024, // 4 GB
      availableMemory: 2 * 1024 * 1024 * 1024, // 2 GB available
      totalStorage: 64 * 1024 * 1024 * 1024, // 64 GB
      availableStorage: 32 * 1024 * 1024 * 1024, // 32 GB available
      cpuCores: Platform.isAndroid ? 8 : 6,
      cpuFrequencyHz: 2400000000, // 2.4 GHz
      supportsGpu: true,
      gpuModel: Platform.isAndroid ? 'Adreno 640' : 'Apple GPU',
      supportsNeuralEngine: Platform.isIOS,
      neuralEngineModel: Platform.isIOS ? 'Apple Neural Engine' : null,
      os: Platform.isAndroid ? 'Android' : 'iOS',
      osVersion: Platform.isAndroid ? '13' : '17',
      deviceModel: Platform.isAndroid ? 'Pixel 7' : 'iPhone 15',
      manufacturer: Platform.isAndroid ? 'Google' : 'Apple',
      screenWidth: 1080,
      screenHeight: 2400,
      isRooted: false,
      batteryLevel: 0.8,
      isCharging: false,
      networkType: NetworkType.wifi,
      powerSaveMode: false,
    );
  }

  /// Check model compatibility with device
  Future<CompatibilityResult> checkModelCompatibility(
    Model model,
    DeviceInfo deviceInfo, {
    ModelVariant? variant,
    QuantizationFormat? preferredQuantization,
  }) async {
    final issues = <CompatibilityIssue>[];
    final suggestions = <String>[];

    // Check hardware requirements
    final hwCheck = _checkHardwareRequirements(
      model.hardwareRequirements,
      deviceInfo,
    );
    if (!hwCheck.isCompatible) {
      issues.add(CompatibilityIssue.error(
        'Hardware requirements not met: ${hwCheck.reason}',
      ));
    } else {
      if (hwCheck.notes.isNotEmpty) {
        suggestions.addAll(hwCheck.notes);
      }
    }

    // Check OS compatibility
    final osCheck = _checkOSCompatibility(model, deviceInfo);
    if (!osCheck.isCompatible) {
      issues.add(CompatibilityIssue.error(
        'OS compatibility issue: ${osCheck.reason}',
      ));
    }

    // Check quantization format support
    if (preferredQuantization != null) {
      final quantCheck = _checkQuantizationSupport(
        model,
        deviceInfo,
        preferredQuantization,
      );
      if (!quantCheck.isCompatible) {
        issues.add(CompatibilityIssue.warning(
          quantCheck.warning ??
              'Quantization format is not fully supported on this device',
        ));
        suggestions.add('Consider using a different quantization format');
      }
    }

    // Check license restrictions
    final licenseCheck = _checkLicenseCompatibility(model, deviceInfo);
    if (!licenseCheck.isCompatible) {
      issues.add(CompatibilityIssue.warning(
        licenseCheck.reason ?? 'Model license is not compatible with this device',
      ));
    }

    // Determine overall compatibility
    final hasErrors = issues.any((i) => i.severity == IssueSeverity.error);
    final hasWarnings = issues.any((i) => i.severity == IssueSeverity.warning);

    CompatibilityLevel level;
    if (hasErrors) {
      level = CompatibilityLevel.none;
    } else if (hasWarnings) {
      level = CompatibilityLevel.minimal;
    } else {
      level = CompatibilityLevel.full;
    }

    // Refine level based on checks
    if (level != CompatibilityLevel.none) {
      if (!hwCheck.recommended) {
        level = CompatibilityLevel.minimal;
      } else if (hasWarnings) {
        level = CompatibilityLevel.recommended;
      }
    }

    return CompatibilityResult(
      isCompatible: !hasErrors,
      level: level,
      reason: hasErrors ? issues.firstWhere(
        (i) => i.severity == IssueSeverity.error,
        orElse: () => CompatibilityIssue.error('Unknown error'),
      ).message : null,
      issues: issues,
      suggestions: suggestions,
    );
  }

  /// Check hardware requirements
  _HardwareCheckResult _checkHardwareRequirements(
    HardwareRequirements requirements,
    DeviceInfo deviceInfo,
  ) {
    final notes = <String>[];

    // RAM check
    if (deviceInfo.totalMemory < requirements.minRamMb * 1024 * 1024) {
      return _HardwareCheckResult(
        isCompatible: false,
        reason: 'Insufficient RAM: need ${requirements.minRamMb}MB, have ${deviceInfo.totalMemory ~/ (1024 * 1024)}MB',
      );
    }

    if (requirements.recommendedRamMb != null &&
        deviceInfo.totalMemory < requirements.recommendedRamMb! * 1024 * 1024) {
      notes.add('Below recommended RAM (${requirements.recommendedRamMb}MB)');
    }

    // Storage check
    if (deviceInfo.totalStorage < requirements.minStorageMb * 1024 * 1024) {
      return _HardwareCheckResult(
        isCompatible: false,
        reason: 'Insufficient storage: need ${requirements.minStorageMb}MB',
      );
    }

    // CPU check
    if (deviceInfo.cpuCores < requirements.minCpuCores) {
      return _HardwareCheckResult(
        isCompatible: false,
        reason: 'Insufficient CPU cores: need ${requirements.minCpuCores}, have ${deviceInfo.cpuCores}',
      );
    }

    // GPU check
    if (requirements.requiresGpu && !deviceInfo.supportsGpu) {
      return _HardwareCheckResult(
        isCompatible: false,
        reason: 'GPU required but not available',
      );
    }

    // Neural engine check
    if (requirements.supportsNeuralEngine && !deviceInfo.supportsNeuralEngine) {
      notes.add('Model benefits from neural engine but device does not have one');
    }

    // Device class check
    if (!requirements.allowsDeviceClass(deviceInfo.deviceClass)) {
      notes.add('Device class ${deviceInfo.deviceClass.name} not in compatible list');
    }

    return _HardwareCheckResult(
      isCompatible: true,
      recommended: notes.isEmpty,
      notes: notes,
    );
  }

  /// Check OS compatibility
  _OSCheckResult _checkOSCompatibility(Model model, DeviceInfo deviceInfo) {
    final minVersion = model.hardwareRequirements.supportedOSVersions.isNotEmpty
        ? model.hardwareRequirements.supportedOSVersions.first
        : null;

    if (minVersion != null) {
      // Parse version strings and compare
      final deviceVersionParts = deviceInfo.osVersion.split('.').map(int.parse).toList();
      final minVersionParts = minVersion.split('.').map(int.parse).toList();

      for (var i = 0; i < deviceVersionParts.length && i < minVersionParts.length; i++) {
        if (deviceVersionParts[i] < minVersionParts[i]) {
          return _OSCheckResult(
            isCompatible: false,
            reason: '${deviceInfo.os} version ${deviceInfo.osVersion} is below minimum required ${minVersion}',
          );
        }
      }
    }

    // Check for any OS-specific restrictions
    if (deviceInfo.os == 'iOS' && model.hardwareRequirements.supportsLowEndDevices == false) {
      // iOS devices are generally high-end, so this is usually fine
    }

    return const _OSCheckResult(isCompatible: true);
  }

  /// Check quantization format support
  _QuantizationCheckResult _checkQuantizationSupport(
    Model model,
    DeviceInfo deviceInfo,
    QuantizationFormat preferred,
  ) {
    if (!model.quantizationFormats.contains(preferred)) {
      return _QuantizationCheckResult(
        isCompatible: false,
        warning: 'Model does not support ${preferred.name} quantization',
      );
    }

    // Check device support for the format
    // Some formats may need specific hardware or runtime support
    if (preferred == QuantizationFormat.int4 &&
        deviceInfo.deviceClass == DeviceClass.lowEnd) {
      return _QuantizationCheckResult(
        isCompatible: true,
        warning: 'int4 quantization on low-end device may have stability issues',
      );
    }

    // Check if neural engine can accelerate this format
    if (preferred == QuantizationFormat.int8 &&
        deviceInfo.supportsNeuralEngine &&
        !model.hardwareRequirements.supportsNeuralEngine) {
      // The model doesn't claim neural engine support, but the device has one
      // This is a potential optimization opportunity
      return _QuantizationCheckResult(
        isCompatible: true,
        optimization: 'Neural engine may accelerate int8 operations',
      );
    }

    return const _QuantizationCheckResult(isCompatible: true);
  }

  /// Check license compatibility
  _LicenseCheckResult _checkLicenseCompatibility(
    Model model,
    DeviceInfo deviceInfo,
  ) {
    final license = model.license;

    // Check commercial use if applicable
    if (!license.allowsCommercialUse && _isCommercialDevice(deviceInfo)) {
      return _LicenseCheckResult(
        isCompatible: false,
        reason: 'Model license does not allow commercial use',
      );
    }

    // Check distribution rights
    if (!license.allowsDistribution) {
      return _LicenseCheckResult(
        isCompatible: false,
        reason: 'Model license does not allow distribution',
      );
    }

    // Check attribution requirements
    if (license.attributionRequirement == AttributionRequirement.required) {
      return _LicenseCheckResult(
        isCompatible: true,
        attributionRequired: true,
        attributionInfo: license.name,
      );
    }

    return const _LicenseCheckResult(isCompatible: true);
  }

  bool _isCommercialDevice(DeviceInfo deviceInfo) {
    // In a real implementation, this might check device enrollment status
    // or other indicators. For now, assume personal use.
    return false;
  }

  /// Get device info (alias for getDeviceInfo)
  Future<DeviceInfo> getDeviceCapabilities() => getDeviceInfo();

  /// Check if the device is suitable for on-device AI in general
  Future<bool> isDeviceSuitableForAI() async {
    final deviceInfo = await getDeviceInfo();

    // Basic requirements for any on-device AI
    if (deviceInfo.totalMemory < 2 * 1024 * 1024 * 1024) {
      return false; // Less than 2GB RAM
    }

    if (deviceInfo.cpuCores < 4) {
      return false; // Less than 4 cores
    }

    if (deviceInfo.powerSaveMode) {
      return false; // Power save mode may limit AI capabilities
    }

    if (deviceInfo.availableStorage < 500 * 1024 * 1024) {
      return false; // Less than 500MB free storage
    }

    return true;
  }

  /// Get recommended models for this device
  Future<List<Model>> getRecommendedModels() async {
    final deviceInfo = await getDeviceInfo();

    // Filter models that are compatible with this device
    final catalog = ModelCatalog();
    final compatible = <Model>[];
    for (final model in catalog.models) {
      final result = await checkModelCompatibility(model, deviceInfo);
      if (result.isCompatible) compatible.add(model);
    }
    return compatible;
  }

}

/// Results of hardware check
class _HardwareCheckResult {
  final bool isCompatible;
  final bool recommended;
  final String? reason;
  final List<String> notes;

  _HardwareCheckResult({
    required this.isCompatible,
    this.recommended = true,
    this.reason,
    this.notes = const [],
  });
}

/// Results of OS check
class _OSCheckResult {
  final bool isCompatible;
  final String? reason;

  const _OSCheckResult({required this.isCompatible, this.reason});
}

/// Results of quantization check
class _QuantizationCheckResult {
  final bool isCompatible;
  final String? warning;
  final String? optimization;

  const _QuantizationCheckResult({
    required this.isCompatible,
    this.warning,
    this.optimization,
  });
}

/// Results of license check
class _LicenseCheckResult {
  final bool isCompatible;
  final String? reason;
  final bool attributionRequired;
  final String? attributionInfo;

  const _LicenseCheckResult({
    required this.isCompatible,
    this.reason,
    this.attributionRequired = false,
    this.attributionInfo,
  });
}

// Fix typo - should be QuantizationFormat
// Re-export with correct name

