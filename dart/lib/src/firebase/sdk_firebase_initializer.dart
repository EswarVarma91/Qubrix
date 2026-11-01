import 'package:firebase_core/firebase_core.dart';
import 'sdk_firebase_options.dart';

/// SDK Firebase Initializer.
///
/// This handles the SDK's Firebase setup. The SDK owns its own Firebase
/// configuration for Remote Config. The host app may or may not have
/// its own Firebase - the SDK works regardless.
///
/// ## Firebase Configuration Hierarchy
///
/// 1. If the host app provides a Firebase app with Remote Config initialized,
///    the SDK can use it (optional integration)
/// 2. If the host app has Firebase but didn't set up Remote Config for the
///    model URL, the SDK uses its own Firebase app
/// 3. If the host app has no Firebase at all, the SDK initializes its own
///
/// This ensures the SDK always has access to Remote Config for fetching
/// the HuggingFace model URL.
class SdkFirebaseInitializer {
  SdkFirebaseInitializer._();

  static bool _sdkAppInitialized = false;
  static bool _hostAppHasFirebase = false;

  /// Whether the SDK's Firebase app is initialized
  static bool get isSdkAppInitialized => _sdkAppInitialized;

  /// Whether the host app has Firebase initialized
  static bool get hostAppHasFirebase => _hostAppHasFirebase;

  /// Initialize the SDK's Firebase.
  ///
  /// A dedicated named Firebase app ([SdkFirebaseOptions.firebaseAppName]) is
  /// created, so it can coexist with a host app that owns the default app.
  ///
  /// Returns the Firebase app instance to use for the SDK.
  static Future<FirebaseApp> initialize({
    String appName = SdkFirebaseOptions.firebaseAppName,
  }) async {
    _hostAppHasFirebase =
        Firebase.apps.any((app) => app.name != appName);

    // Reuse the SDK app if it was already created.
    for (final app in Firebase.apps) {
      if (app.name == appName) {
        _sdkAppInitialized = true;
        return app;
      }
    }

    final app = await Firebase.initializeApp(
      options: _getSdkOptions(),
      name: appName,
    );

    _sdkAppInitialized = true;
    return app;
  }

  /// Get the current Firebase app for the SDK.
  static FirebaseApp getSdkApp({
    String appName = SdkFirebaseOptions.firebaseAppName,
  }) {
    for (final app in Firebase.apps) {
      if (app.name == appName) return app;
    }
    throw StateError(
      'SDK Firebase not initialized. Call SdkFirebaseInitializer.initialize() first.',
    );
  }

  /// Check if the SDK Firebase app is ready for use.
  static Future<bool> isFirebaseReady() async {
    try {
      await initialize();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get SDK Firebase options.
  ///
  /// Credentials live in [SdkFirebaseOptions] (Firebase project qubrix-77954).
  static FirebaseOptions _getSdkOptions() {
    // Single source of truth: values from google-services.json /
    // GoogleService-Info.plist, kept in SdkFirebaseOptions.
    return SdkFirebaseOptions.currentPlatform;
  }

  /// Reset SDK initialization state.
  ///
  /// Use this for testing or if you need to reinitialize.
  static void reset() {
    _sdkAppInitialized = false;
    _hostAppHasFirebase = false;
  }
}
