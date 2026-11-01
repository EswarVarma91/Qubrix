/// Compatibility Engine
///
/// Validates models against device and runtime capabilities.
/// Checks hardware requirements, OS compatibility, and runtime support.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'model_types.dart' show RichModel, QuantizationFormat, ModelLicense, LicenseType, DeviceClass, HardwareRequirements;
import '../core/types.dart' show DeviceInfo;
import 'model_catalog.dart' show ModelCatalog;

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
  final ModelCatalog? _catalog;

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
    return DeviceInfo(
      deviceId: 'demo-device',
      deviceModel: Platform.isAndroid ? 'Pixel 7' : 'iPhone 15',
      osVersion: Platform.isAndroid ? '13' : '17',
      totalMemory: 4 * 1024 * 1024 * 1024,
      availableMemory: 2 * 1024 * 1024 * 1024,
      processorCount: Platform.isAndroid ? 8 : 6,
      platform: Platform.isAndroid ? 'android' : 'ios',
    );
  }

  /// Check model compatibility with device
  CompatibilityResult checkModelCompatibility(
    RichModel model,
    DeviceInfo deviceInfo, {
    QuantizationFormat? preferredQuantization,
  }) {
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

    // Check license restrictions
    final licenseCheck = _checkLicenseCompatibility(model, deviceInfo);
    if (!licenseCheck.isCompatible) {
      if (licenseCheck.reason != null) {
        issues.add(CompatibilityIssue.warning(licenseCheck.reason!));
      }
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

    return CompatibilityResult(
      isCompatible: !hasErrors,
      level: hasErrors ? CompatibilityLevel.none : (hasWarnings ? CompatibilityLevel.minimal : CompatibilityLevel.full),
      reason: hasErrors ? issues.first.message ?? 'Unknown error' : '',
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
        reason: 'Insufficient RAM: need ${requirements.minRamMb}MB',
      );
    }

    if (requirements.recommendedRamMb != null &&
        deviceInfo.totalMemory < requirements.recommendedRamMb! * 1024 * 1024) {
      notes.add('Below recommended RAM');
    }

    // Storage check
    if (deviceInfo.totalMemory < requirements.minStorageMb * 1024 * 1024) {
      return _HardwareCheckResult(
        isCompatible: false,
        reason: 'Insufficient storage: need ${requirements.minStorageMb}MB',
      );
    }

    return _HardwareCheckResult(
      isCompatible: true,
      recommended: notes.isEmpty,
      notes: notes,
    );
  }


  /// Check license compatibility
  _LicenseCheckResult _checkLicenseCompatibility(
    RichModel model,
    DeviceInfo deviceInfo,
  ) {
    final license = model.license;
    if (!license.allowsCommercialUse) {
      return _LicenseCheckResult(
        isCompatible: false,
        reason: 'Model license does not allow commercial use',
      );
    }
    return _LicenseCheckResult(isCompatible: true);
  }

  bool _isCommercialDevice(DeviceInfo deviceInfo) => false;

  CompatibilityEngine({ModelCatalog? catalog}) : _catalog = catalog;

  /// Get device info (alias for getDeviceInfo)
  Future<DeviceInfo> getDeviceCapabilities() => getDeviceInfo();

  /// Check if the device is suitable for on-device AI in general
  Future<bool> isDeviceSuitableForAI() async {
    final deviceInfo = await getDeviceInfo();

    // Basic requirements for any on-device AI
    if (deviceInfo.totalMemory < 2 * 1024 * 1024 * 1024) {
      return false; // Less than 2GB RAM
    }

    if (deviceInfo.processorCount < 4) {
      return false;
    }

    return true;

    return true;
  }

  /// Get recommended models for this device
  Future<List<RichModel>> getRecommendedModels() async {
    final deviceInfo = await getDeviceInfo();
    final cat = _catalog ?? ModelCatalog();
    return cat.models.where((model) {
      final result = checkModelCompatibility(model, deviceInfo);
      return result.isCompatible;
    }).toList();
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

/// Results of license check
class _LicenseCheckResult {
  final bool isCompatible;
  final String? reason;

  _LicenseCheckResult({
    required this.isCompatible,
    this.reason = '',
  });
}

