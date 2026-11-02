import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// SDK's Firebase options.
///
/// These are the credentials for the SDK's own Firebase project
/// (`qubrix-77954`), matching the committed `google-services.json` and
/// `GoogleService-Info.plist` for the `com.varma.qubrix` Android app and iOS
/// bundle. The SDK ships with its own Firebase configuration so it can fetch
/// Remote Config (the HuggingFace model URL) regardless of whether the host
/// app has Firebase or not.
///
/// ## Setup Instructions
///
/// 1. Create a Firebase project at https://console.firebase.google.com
/// 2. Add an Android app with package name `com.varma.qubrix`
/// 3. Download google-services.json
/// 4. Add an iOS app with bundle ID `com.varma.qubrix`
/// 5. Download GoogleService-Info.plist
/// 6. Update the values below if the project or app IDs change
///
/// ## File Locations
///
/// - Android: `example/android/app/google-services.json`
/// - iOS: `example/ios/Runner/GoogleService-Info.plist`
///
/// Both files are tracked because they are the SDK's own client
/// configuration, not the host app's.
///
/// ## Host App Firebase
///
/// The host app may have its own Firebase configuration for its own features
/// (analytics, auth, crashlytics, etc.). The SDK's Firebase is separate and
/// only used for Remote Config (fetching the model URL).
///
/// If the host app already has Firebase with Remote Config configured for
/// the model URL, the SDK can optionally use the host app's Firebase instead.
/// See [SdkFirebaseInitializer] for more details.
class SdkFirebaseOptions {
  SdkFirebaseOptions._();

  /// Name of the Firebase app the SDK initializes.
  ///
  /// A named app is used so the SDK and the host app can each hold their own
  /// Firebase configuration at the same time.
  static const String firebaseAppName = 'qubrix';

  // MARK: - Android Configuration
  /// Android API Key
  ///
  /// Replace with your own Firebase project's API key.
  /// See https://console.firebase.google.com
  static const String androidApiKey = 'YOUR_FIREBASE_ANDROID_API_KEY';

  /// Android App ID
  static const String androidAppId =
      '1:532964963634:android:80b4ed67c62ab6609dd32b';

  /// Firebase Project ID (shared by the Android and iOS apps)
  static const String androidProjectId = 'qubrix-77954';

  // MARK: - iOS Configuration
  /// iOS API Key
  ///
  /// Replace with your own Firebase project's API key.
  /// See https://console.firebase.google.com
  static const String iosApiKey = 'YOUR_FIREBASE_IOS_API_KEY';

  /// iOS App ID
  static const String iosAppId = '1:532964963634:ios:2143973eaf264a7c9dd32b';

  /// iOS bundle identifier registered in Firebase
  static const String iosBundleId = 'com.varma.qubrix';

  // MARK: - Web Configuration
  /// Web API Key
  ///
  /// No web app has been registered for this project yet, so these stay empty
  /// and [currentPlatform] throws on web instead of sending invalid options.
  static const String webApiKey = '';

  /// Web App ID
  static const String webAppId = '';

  // MARK: - Common Configuration
  /// Messaging Sender ID (shared across platforms)
  static const String messagingSenderId = '532964963634';

  /// Cloud Storage bucket
  static const String storageBucket = 'qubrix-77954.firebasestorage.app';

  /// Measurement ID (for Analytics).
  ///
  /// No web app / Analytics measurement ID was issued for this project,
  /// so leave this empty; [currentPlatform] omits it when empty.
  static const String measurementId = '';

  // MARK: - Firebase Options Factory

  /// Get Firebase options for the current platform.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: webApiKey,
        appId: webAppId,
        messagingSenderId: messagingSenderId,
        projectId: androidProjectId,
        authDomain: '$androidProjectId.firebaseapp.com',
        storageBucket: storageBucket,
        measurementId: measurementId.isEmpty ? null : measurementId,
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return FirebaseOptions(
          apiKey: androidApiKey,
          appId: androidAppId,
          messagingSenderId: messagingSenderId,
          projectId: androidProjectId,
          storageBucket: storageBucket,
          measurementId: measurementId.isEmpty ? null : measurementId,
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return FirebaseOptions(
          apiKey: iosApiKey,
          appId: iosAppId,
          messagingSenderId: messagingSenderId,
          projectId: androidProjectId,
          iosBundleId: iosBundleId,
          storageBucket: storageBucket,
          measurementId: measurementId.isEmpty ? null : measurementId,
        );
      default:
        throw UnsupportedError(
          'Unsupported platform for Firebase options: $defaultTargetPlatform',
        );
    }
  }

  /// Check if the config has real values (not placeholders).
  static bool get isConfigured {
    final options = currentPlatform;
    return !options.apiKey.startsWith('YOUR_') &&
        !options.appId.startsWith('YOUR_') &&
        !options.projectId.startsWith('YOUR_');
  }

  /// Print config status for debugging.
  static void printConfigStatus() {
    if (isConfigured) {
      print('✓ SDK Firebase is configured (project: $androidProjectId)');
    } else {
      print('✗ SDK Firebase NOT configured - placeholder values detected');
      print('  Please replace placeholder values in SdkFirebaseOptions');
      print('  See https://console.firebase.google.com to create a project');
    }
  }
}
