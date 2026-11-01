import 'package:ai_sdk/ai_sdk.dart';

/// Example app's Firebase Remote Config service.
///
/// This uses the SDK's Firebase configuration for Remote Config.
/// The SDK manages its own Firebase, so the example app doesn't need
/// its own Firebase - it just uses the SDK's Firebase for fetching
/// the HuggingFace model URL.
///
/// The SDK's Firebase is configured in the SDK's own Firebase project.
/// The host app (this example) may have its own Firebase too for other
/// features, but for the model URL, it uses the SDK's Firebase.
class FirebaseRemoteConfigService {
  final SdkRemoteConfigService _remoteConfig = SdkRemoteConfigService();

  /// Initialize the SDK's Firebase.
  ///
  /// This initializes the SDK's own Firebase app for Remote Config.
  /// The host app may have its own Firebase too, but this is separate.
  Future<void> initialize() async {
    await _remoteConfig.initialize();
  }

  /// Check if the SDK's Firebase is configured.
  bool get isSdkFirebaseConfigured => _remoteConfig.isSdkFirebaseConfigured;

  /// Get the HuggingFace model URL from the SDK's Firebase Remote Config.
  ///
  /// This fetches the model URL from the SDK's Firebase project.
  /// The URL format is: https://huggingface.co/<owner>/<repo>
  ///
  /// Returns the URL or a default if not configured.
  Future<String> getHuggingFaceUrl() async {
    return _remoteConfig.getModelUrlWithFallback();
  }

  /// Get the HuggingFace repo ID from the model URL.
  ///
  /// Extracts repo ID from URL like:
  /// https://huggingface.co/facebook/opt-1.3b → facebook/opt-1.3b
  String? getRepoIdFromUrl(String url) {
    return _remoteConfig.extractRepoIdFromUrl(url);
  }

  /// Get the current model URL and repo ID combined.
  Future<Map<String, String>> getModelConfig() async {
    final url = await getHuggingFaceUrl();
    final repoId = getRepoIdFromUrl(url);
    return {
      'url': url,
      'repo_id': repoId ?? '',
    };
  }

  /// Get all configured HuggingFace models (from Firebase).
  ///
  /// In the SDK's Firebase, you can configure multiple model URLs.
  /// This returns them as a list of HuggingFaceModel entries.
  List<HuggingFaceModel> getConfiguredModels() {
    // In this simplified setup, we have one model from Firebase config.
    // The host app can have additional models configured locally.
    final url = _remoteConfig.getModelUrlWithFallback();
    final repoId = _remoteConfig.extractRepoIdFromUrl(url);

    if (repoId != null) {
      return [
        HuggingFaceModel(
          repoId: repoId,
          displayName: 'Firebase Model',
          huggingFaceUrl: url,
          sizeMb: 0,
          description: 'Configured via Firebase Remote Config',
        ),
      ];
    }
    return [];
  }

  /// Log a custom event to Firebase Analytics.
  void logEvent(String name, {Map<String, dynamic>? parameters}) {
    _remoteConfig.logSdkEvent(name, parameters: parameters);
  }
}
