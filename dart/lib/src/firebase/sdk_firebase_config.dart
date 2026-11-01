import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../_exports.dart' as sdk exports;

/// SDK's Firebase Remote Config service.
///
/// The SDK manages its own Firebase configuration for Remote Config.
/// This allows the SDK to fetch the HuggingFace model URL from Firebase
/// Remote Config regardless of whether the host app has its own Firebase
/// configuration or not.
///
/// The host app may have its own Firebase configuration too (for their
/// features like analytics, auth, etc.), but the SDK's Firebase is
/// separate and handles the model configuration internally.
///
/// ## Usage
///
/// ```dart
/// // Initialize the SDK's Firebase (this happens automatically when
/// // AdaptiveAgentEngine is initialized, or can be done explicitly)
/// final configService = SdkRemoteConfigService();
/// await configService.initialize();
///
/// // Fetch model URL from Firebase
/// final modelUrl = await configService.getHuggingFaceModelUrl();
/// ```
class SdkRemoteConfigService {
  FirebaseApp? _app;
  FirebaseRemoteConfig? _remoteConfig;
  FirebaseAnalytics? _analytics;

  bool _isInitialized = false;
  String? _lastModelUrl;
  DateTime? _lastFetchTime;

  /// Whether the SDK's Firebase is initialized
  bool get isInitialized => _isInitialized;

  /// The last fetched HuggingFace model URL
  String? get lastModelUrl => _lastModelUrl;

  /// When the model URL was last fetched
  DateTime? get lastFetchTime => _lastFetchTime;

  /// Get the Firebase app instance
  FirebaseApp? get app => _app;

  /// Get the Remote Config instance
  FirebaseRemoteConfig? get remoteConfig => _remoteConfig;

  /// Get the Analytics instance
  FirebaseAnalytics? get analytics => _analytics;

  /// Initialize the SDK's Firebase with Remote Config
  ///
  /// This creates a separate Firebase app instance for the SDK.
  /// The host app may have its own Firebase app too, but this is
  /// the SDK's own Firebase for Remote Config.
  ///
  /// Returns the [FirebaseApp] instance.
  Future<FirebaseApp> initialize() async {
    if (_isInitialized && _app != null) {
      return _app!;
    }

    // Initialize Firebase for the SDK
    // If the host app already has Firebase initialized, we can
    // use the existing app or create a separate one.
    // Using a separate app with a different name ensures we don't
    // conflict with the host app's Firebase.

    final options = _getSdkFirebaseOptions();

    // Try to use existing Firebase app if available, otherwise create new
    if (Firebase.apps.isNotEmpty) {
      // Check if we already created an app with our name
      try {
        _app = Firebase.app('ai_sdk_remote_config');
      } catch (e) {
        // App doesn't exist, create a new one
        _app = Firebase.initializeApp(
          options,
          name: 'ai_sdk_remote_config',
        );
      }
    } else {
      // No Firebase apps exist, initialize new one
      _app = await Firebase.initializeApp(
        options,
        name: 'ai_sdk_remote_config',
      );
    }

    // Configure Remote Config
    _remoteConfig = FirebaseRemoteConfig.instance;

    // Set up Remote Config settings
    await _remoteConfig!.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    // Set default values for Remote Config parameters
    await _remoteConfig!.setDefaults({
      'hf_model_url': 'https://huggingface.co/facebook/opt-1.3b',
    });

    // Initialize Analytics (optional, for SDK usage tracking)
    try {
      _analytics = FirebaseAnalytics.instance;
    } catch (e) {
      // Analytics may not be available; continue without it
      _analytics = null;
    }

    _isInitialized = true;

    return _app!;
  }

  /// Get the SDK Firebase options.
  ///
  /// These should be replaced with actual Firebase project credentials
  /// before deployment. See [SdkFirebaseOptions] for the structure.
  FirebaseOptions _getSdkFirebaseOptions() {
    // Try to use the default options if available
    try {
      return SdkFirebaseOptions.currentPlatform;
    } catch (e) {
      // Fallback to minimal options
      return FirebaseOptions(
        apiKey: 'YOUR_API_KEY',
        appId: 'YOUR_APP_ID',
        messagingSenderId: 'YOUR_SENDER_ID',
        projectId: 'YOUR_PROJECT_ID',
        databaseURL: 'https://YOUR_PROJECT_ID.firebaseio.com',
        storageBucket: 'YOUR_PROJECT_ID.appspot.com',
      );
    }
  }

  /// Fetch the HuggingFace model URL from Remote Config.
  ///
  /// This fetches the latest value from Firebase and returns the
  /// HuggingFace model URL. Returns the in-app default if no value
  /// is set in Firebase.
  ///
  /// Returns null if initialization failed or fetch fails.
  Future<String?> getHuggingFaceModelUrl() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_remoteConfig == null) {
      return null;
    }

    try {
      // Fetch and activate Remote Config
      final fetchResult = await _remoteConfig!.fetchAndActivate();

      if (fetchResult) {
        _lastFetchTime = DateTime.now();
      }

      // Get the model URL parameter
      final url = _remoteConfig!.getString('hf_model_url');

      if (url.isNotEmpty) {
        _lastModelUrl = url;
        return url;
      }

      // Fallback to default
      return _remoteConfig!.getString('hf_model_url');
    } catch (e) {
      // If fetch fails, return the cached or default value
      return _lastModelUrl ?? 'https://huggingface.co/facebook/opt-1.3b';
    }
  }

  /// Get the HuggingFace model URL with fallback to default.
  ///
  /// This is the main method to get the model URL. It fetches from
  /// Firebase Remote Config and returns the URL. If no URL is available
  /// from Firebase, it returns a default URL.
  ///
  /// The URL is used to download models from HuggingFace. The format
  /// should be: https://huggingface.co/<owner>/<repo>
  Future<String> getModelUrlWithFallback() async {
    final url = await getHuggingFaceModelUrl();
    return url ?? 'https://huggingface.co/facebook/opt-1.3b';
  }

  /// Extract HuggingFace repo ID from URL.
  ///
  /// URL format: https://huggingface.co/<owner>/<repo>
  /// Returns: <owner>/<repo>
  String? extractRepoIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.length >= 2) {
        final repoId = '${segments[segments.length - 2]}/${segments[segments.length - 1]}';
        // Handle @digest suffix
        return repoId.contains('@') ? repoId.split('@').first : repoId;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get the repo ID from the current HuggingFace model URL.
  ///
  /// Combines getHuggingFaceModelUrl() and extractRepoIdFromUrl().
  Future<String?> getCurrentRepoId() async {
    final url = await getHuggingFaceModelUrl();
    if (url == null) return null;
    return extractRepoIdFromUrl(url);
  }

  /// Check if the SDK Firebase is properly configured.
  bool get isSdkFirebaseConfigured {
    try {
      final options = SdkFirebaseOptions.currentPlatform;
      return !options.apiKey.startsWith('YOUR_') &&
          !options.appId.startsWith('YOUR_');
    } catch (e) {
      return false;
    }
  }

  /// Log SDK usage events to Firebase Analytics (if available).
  void logSdkEvent(String eventName, {Map<String, dynamic>? parameters}) {
    if (_analytics != null) {
      _analytics!.logEvent(
        name: eventName,
        parameters: parameters,
      );
    }
  }

  /// Log model download start event.
  void logModelDownloadStart(String repoId) {
    logSdkEvent('model_download_start', parameters: {
      'repo_id': repoId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log model download complete event.
  void logModelDownloadComplete(String repoId, int sizeBytes) {
    logSdkEvent('model_download_complete', parameters: {
      'repo_id': repoId,
      'size_bytes': sizeBytes,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log task execution event.
  void logTaskExecution(String taskId, String taskType) {
    logSdkEvent('task_execution', parameters: {
      'task_id': taskId,
      'task_type': taskType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log recommendation event.
  void logRecommendation(String recommendationId, String contextType) {
    logSdkEvent('recommendation_received', parameters: {
      'recommendation_id': recommendationId,
      'context_type': contextType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Clear the SDK's Firebase app.
  ///
  /// Use this if you need to reinitialize the SDK's Firebase.
  void clear() {
    _remoteConfig = null;
    _analytics = null;
    _lastModelUrl = null;
    _lastFetchTime = null;
    _isInitialized = false;
  }
}
