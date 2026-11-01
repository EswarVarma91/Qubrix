import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// SDK's Firebase options.
///
/// These are placeholder values that need to be replaced with actual
/// Firebase project credentials. The SDK ships with its own Firebase
/// configuration so it can fetch Remote Config (the HuggingFace model URL)
/// regardless of whether the host app has Firebase or not.
///
/// ## Setup Instructions
///
/// 1. Create a Firebase project at https://console.firebase.google.com
/// 2. Add an Android app to the project (com.example.ai_sdk or your package)
/// 3. Download google-services.json
/// 4. Add an iOS app to the project
/// 5. Download GoogleService-Info.plist
/// 6. Update the values below with your actual Firebase credentials
///
/// ## File Locations
///
/// - Android: Place google-services.json in the host app's android/app/
///   directory (the SDK's build process can include this)
/// - iOS: Place GoogleService-Info.plist in the host app's ios/Runner/
///   directory (the SDK's build process can include this)
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
  // MARK: - Android Configuration
  /// Android API Key
  static String androidApiKey = 'YOUR_ANDROID_API_KEY';

  /// Android App ID
  static String androidAppId = 'YOUR_ANDROID_APP_ID';

  /// Android Project ID
  static String androidProjectId = 'YOUR_PROJECT_ID';

  // MARK: - iOS Configuration
  /// iOS API Key
  static String iosApiKey = 'YOUR_IOS_API_KEY';

  /// iOS App ID
  static String iosAppId = 'YOUR_IOS_APP_ID';

  // MARK: - Web Configuration
  /// Web API Key
  static String webApiKey = 'YOUR_WEB_API_KEY';

  /// Web App ID
  static String webAppId = 'YOUR_WEB_APP_ID';

  // MARK: - Common Configuration
  /// Messaging Sender ID (shared across platforms)
  static String messagingSenderId = 'YOUR_MESSAGING_SENDER_ID';

  /// Measurement ID (for Analytics)
  static String measurementId = 'YOUR_MEASUREMENT_ID';

  // MARK: - Firebase Options Factory

  /// Get Firebase options for the current platform.
  ///
  /// Replace the placeholder values above with your actual Firebase
  /// credentials before deploying.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: webApiKey,
        appId: webAppId,
        messagingSenderId: messagingSenderId,
        projectId: androidProjectId,
        authDomain: '${androidProjectId}.firebaseapp.com',
        databaseURL: 'https://${androidProjectId}.firebaseio.com',
        storageBucket: '${androidProjectId}.appspot.com',
        measurementId: measurementId,
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return FirebaseOptions(
          apiKey: androidApiKey,
          appId: androidAppId,
          messagingSenderId: messagingSenderId,
          projectId: androidProjectId,
          databaseURL: 'https://${androidProjectId}.firebaseio.com',
          storageBucket: '${androidProjectId}.appspot.com',
          deepLinkURLScheme: null,
        );
      case TargetPlatform.iOS:
        return FirebaseOptions(
          apiKey: iosApiKey,
          appId: iosAppId,
          messagingSenderId: messagingSenderId,
          projectId: androidProjectId,
          databaseURL: 'https://${androidProjectId}.firebaseio.com',
          storageBucket: '${androidProjectId}.appspot.com',
        );
      default:
        throw UnsupportedError(
          'Unsupported platform for Firebase options: $defaultTargetPlatform',
        );
    }
  }

  /// Check if the config has real values (not placeholders).
  static bool get isConfigured {
    // Check a few key fields
    if (androidApiKey.startsWith('YOUR_')) return false;
    if (androidAppId.startsWith('YOUR_')) return false;
    if (androidProjectId.startsWith('YOUR_')) return false;
    return true;
  }

  /// Print config status for debugging.
  static void printConfigStatus() {
    if (isConfigured) {
      print('✓ SDK Firebase is configured');
    } else {
      print('✗ SDK Firebase NOT configured - placeholder values detected');
      print('  Please replace placeholder values in SdkFirebaseOptions');
      print('  See https://console.firebase.google.com to create a project');
    }
  }
}
