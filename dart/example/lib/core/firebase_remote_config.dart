import 'package:qubrix/qubrix.dart';

/// Example app's Firebase Remote Config service.
///
/// Uses the SDK's own Firebase configuration for Remote Config.
/// The SDK manages its own Firebase, so the example app doesn't need
/// its own Firebase - it just uses the SDK's Firebase for fetching
/// the HuggingFace model URL.
class FirebaseRemoteConfigService {
  final SdkRemoteConfigService _remoteConfig = SdkRemoteConfigService();

  bool get isSdkFirebaseConfigured => _remoteConfig.isSdkFirebaseConfigured;

  Future<void> initialize() async {
    await _remoteConfig.initialize();
  }

  /// Get HuggingFace model URL from SDK's Firebase Remote Config.
  Future<String> getHuggingFaceUrl() async {
    return _remoteConfig.getModelUrlWithFallback();
  }

  /// Extract HuggingFace repo ID from URL.
  /// URL format: https://huggingface.co/<owner>/<repo>
  /// Returns: <owner>/<repo>
  Future<String?> getRepoIdFromUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.length >= 2) {
        final repoId = '${segments[segments.length - 2]}/${segments[segments.length - 1]}';
        return repoId.contains('@') ? repoId.split('@').first : repoId;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get the current model URL and repo ID combined.
  Future<Map<String, String>> getModelConfig() async {
    final url = await getHuggingFaceUrl();
    final repoId = await getRepoIdFromUrl(url);
    return {
      'url': url,
      'repo_id': repoId ?? '',
    };
  }

  /// Get all configured HuggingFace models (from Firebase).
  List<HuggingFaceModel> getConfiguredModels() {
    return [];
  }

  /// Log a custom event to Firebase Analytics.
  void logEvent(String name, {Map<String, dynamic>? parameters}) {
    _remoteConfig.logSdkEvent(name, parameters: parameters);
  }
}
