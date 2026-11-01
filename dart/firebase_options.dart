import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Default Firebase options for the AI SDK.
///
/// These are the SDK's own Firebase configuration.
/// The SDK uses these to initialize its own Firebase instance
/// for Remote Config (fetching hf_model_url).
///
/// The host app may have its own Firebase configuration too,
/// but the SDK manages its own Firebase for Remote Config purposes.
///
/// TODO: Replace with actual Firebase project credentials.
/// For development, create a Firebase project, add an Android/iOS app,
/// download google-services.json / GoogleService-Info.plist, and update
/// these values.
class SdkFirebaseOptions {
  static FirebaseOptions get currentPlatform {
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

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return FirebaseOptions(
          apiKey: 'YOUR_ANDROID_API_KEY',
          appId: 'YOUR_ANDROID_APP_ID',
          messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
          projectId: 'YOUR_PROJECT_ID',
          databaseURL: 'https://YOUR_PROJECT_ID.firebaseio.com',
          storageBucket: 'YOUR_PROJECT_ID.appspot.com',
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
        );
      default:
        throw UnsupportedError(
          'Unsupported platform for Firebase options: $defaultTargetPlatform',
        );
    }
  }

  /// Check if the SDK Firebase is properly configured.
  static bool get isConfigured {
    final android = currentPlatform;
    if (android.apiKey.startsWith('YOUR_') ||
        android.appId.startsWith('YOUR_')) {
      return false;
    }
    return true;
  }
}
