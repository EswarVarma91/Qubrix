import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import '../_exports.dart' as sdk exports;

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
  static bool _sdkAppInitialized = false;
  static bool _hostAppHasFirebase = false;

  /// Whether the SDK's Firebase app is initialized
  static bool get isSdkAppInitialized => _sdkAppInitialized;

  /// Whether the host app has Firebase initialized
  static bool get hostAppHasFirebase => _hostAppHasFirebase;

  /// Initialize the SDK's Firebase.
  ///
  /// This checks if the host app has Firebase. If it does, we note it
  /// but still ensure the SDK has its own Remote Config configured.
  /// If the host app doesn't have Firebase, we initialize the SDK's
  /// own Firebase instance.
  ///
  /// Returns the Firebase app instance to use for the SDK.
  static Future<FirebaseApp> initialize({String appName = 'ai_sdk'}) async {
    // Check if host app has Firebase
    _hostAppHasFirebase = Firebase.apps.isNotEmpty;

    // If SDK app already initialized, return it
    if (_sdkAppInitialized) {
      try {
        return Firebase.app(appName);
      } catch (e) {
        // Fall through to reinitialize
      }
    }

    // Get SDK Firebase options
    final options = _getSdkOptions();

    // If host app has Firebase, create SDK app with a different name
    // to avoid conflicts. This way both host app Firebase and SDK
    // Firebase can coexist.
    if (_hostAppHasFirebase) {
      // Check if our SDK app already exists
      try {
        final existingApp = Firebase.app(appName);
        _sdkAppInitialized = true;
        return existingApp;
      } catch (e) {
        // SDK app doesn't exist, create it
      }
    }

    // Initialize or create the SDK's Firebase app
    FirebaseApp app;
    if (_hostAppHasFirebase) {
      // Host has Firebase - create a secondary app for SDK
      try {
        app = Firebase.app(appName);
      } catch (e) {
        app = await Firebase.initializeApp(
          options,
          name: appName,
        );
      }
    } else {
      // No host Firebase - initialize SDK's own Firebase
      app = await Firebase.initializeApp(
        options,
        name: appName,
      );
    }

    _sdkAppInitialized = true;
    return app;
  }

  /// Get the current Firebase app for the SDK.
  static FirebaseApp getSdkApp({String appName = 'ai_sdk'}) {
    try {
      return Firebase.app(appName);
    } catch (e) {
      throw StateError(
        'SDK Firebase not initialized. Call SdkFirebaseInitializer.initialize() first.',
      );
    }
  }

  /// Check if Firebase is ready for use.
  static Future<bool> isFirebaseReady() async {
    try {
      await Firebase.initializeApp();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get SDK Firebase options.
  ///
  /// These need to be replaced with actual Firebase credentials.
  static FirebaseOptions _getSdkOptions() {
    // Web platform
    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: 'YOUR_WEB_API_KEY',
        appId: 'YOUR_WEB_APP_ID',
        messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
        projectId: 'YOUR_PROJECT_ID',
        authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
        databaseURL: 'https://YOUR_PROJECT_ID.firebaseio.com',
        storageBucket: 'YOUR_PROJECT_ID.appspot.com',
        measurementId: 'YOUR_MEASUREMENT_ID',
      );
    }

    // Mobile platforms
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return FirebaseOptions(
          apiKey: 'YOUR_ANDROID_API_KEY',
          appId: 'YOUR_ANDROID_APP_ID',
          messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
          projectId: 'YOUR_PROJECT_ID',
          databaseURL: 'https://YOUR_PROJECT_ID.firebaseio.com',
          storageBucket: 'YOUR_PROJECT_ID.appspot.com',
          messagingClusterId: null,
          isRunningOnChromeOS: false,
          deepLinkURLScheme: null,
        );
      case TargetPlatform.iOS:
        return FirebaseOptions(
          apiKey: 'YOUR_IOS_API_KEY',
          appId: 'YOUR_IOS_APP_ID',
          messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
          projectId: 'YOUR_PROJECT_ID',
          databaseURL: 'https://YOUR_PROJECT_ID.firebaseio.com',
          storageBucket: 'YOUR_PROJECT_ID.appspot.com',
          messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
        );
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  /// Reset SDK initialization state.
  ///
  /// Use this for testing or if you need to reinitialize.
  static void reset() {
    _sdkAppInitialized = false;
    _hostAppHasFirebase = false;
  }
}
