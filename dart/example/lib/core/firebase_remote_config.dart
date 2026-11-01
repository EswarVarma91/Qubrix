// Firebase Remote Config Model Service
// Only fetches the HuggingFace model URL from Firebase Remote Config.
// All model configuration comes from Firebase Remote Config.
// No user input required.

import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Service that fetches model configuration from Firebase Remote Config
/// Only the HuggingFace URL is stored in Firebase - no model selection UI needed
class FirebaseRemoteConfigService {
  static const String _modelsParamKey = 'hf_model_url';
  static const String _defaultHuggingFaceUrl = 'https://huggingface.co/models';

  FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  String? _cachedHuggingFaceUrl;
  DateTime? _lastFetchTime;

  /// Initialize Firebase Remote Config
  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    // Set defaults
    await _remoteConfig.setDefaults(<String, dynamic>{
      _modelsParamKey: '',
    });
  }

  /// Fetch latest config from Firebase
  Future<bool> fetchConfig() async {
    try {
      await _remoteConfig.fetchAndActivate();
      _lastFetchTime = DateTime.now();
      return true;
    } catch (e) {
      debugPrint('Firebase Remote Config fetch failed: $e');
      return false;
    }
  }

  /// Get the HuggingFace model URL from Firebase Remote Config
  /// Returns empty string if Firebase not configured or times out
  String getHuggingFaceModelUrl() {
    final url = _remoteConfig.getString(_modelsParamKey);
    _cachedHuggingFaceUrl = url;
    return url;
  }

  /// Get cached HuggingFace URL (may be stale)
  String? get cachedHuggingFaceUrl => _cachedHuggingFaceUrl;

  /// Check if Firebase Remote Config is available
  bool get isConfigured {
    return _remoteConfig.getData(_modelsParamKey) != null;
  }

  /// Get last fetch time
  DateTime? get lastFetchTime => _lastFetchTime;

  /// Refresh config and return true if updated
  Future<bool> refresh() async {
    final updated = await fetchConfig();
    return updated;
  }

  /// Clear cached config
  Future<void> clearConfig() async {
    await _remoteConfig.clear();
    _cachedHuggingFaceUrl = null;
    _lastFetchTime = null;
  }
}

/// Service that returns model config from Firebase Remote Config
/// Falls back to local defaults if Firebase not configured
class ModelConfigService {
  final FirebaseRemoteConfigService _firebaseConfig;

  // Local default HuggingFace URL
  static const String _defaultHuggingFaceUrl =
      'https://huggingface.co/models';

  ModelConfigService({
    FirebaseRemoteConfigService? firebaseConfig,
  }) : _firebaseConfig = firebaseConfig ?? FirebaseRemoteConfigService();

  /// Get the HuggingFace model URL
  /// Priority: Firebase Remote Config > Local default
  String getHuggingFaceUrl() {
    final url = _firebaseConfig.getHuggingFaceModelUrl();
    if (url.isNotEmpty) {
      return url;
    }
    return _defaultHuggingFaceUrl;
  }

  /// Check if using Firebase config
  bool get isUsingFirebase => _firebaseConfig.isConfigured;

  /// Refresh from Firebase
  Future<void> refresh() async {
    await _firebaseConfig.refresh();
  }

  /// Get last fetch time
  DateTime? get lastFetchTime => _firebaseConfig.lastFetchTime;
}
