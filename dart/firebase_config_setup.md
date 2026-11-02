# SDK Firebase Configuration Setup

This document explains how to set up the SDK's Firebase configuration.

## Overview

The SDK has its own Firebase configuration for Remote Config. This is separate from the host app's Firebase.

## Firebase Project Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project"
3. Enter project name (e.g., "Qubrix Demo")
4. Follow the setup wizard

### Step 2: Add Apps to Firebase Project

#### Android App

1. In Firebase Console, go to Project Settings
2. Click "Add app" → Android
3. Enter package name (e.g., `com.varma.qubrix`)
4. Download `google-services.json`
5. Place the file in the appropriate location

#### iOS App

1. In Firebase Console, go to Project Settings
2. Click "Add app" → iOS
3. Enter bundle ID (e.g., `com.varma.qubrix`)
4. Download `GoogleService-Info.plist`
5. Place the file in the appropriate location

### Step 3: Enable Remote Config

1. In Firebase Console, go to Remote Config
2. Click "Add parameter"
3. Set:
   - Parameter key: `hf_model_url`
   - Value: HuggingFace model URL (e.g., `https://huggingface.co/facebook/opt-1.3b`)
4. Publish changes

### Step 4: Keep SDK Firebase Options in sync

`SdkFirebaseOptions` (`lib/src/firebase/sdk_firebase_options.dart`) already
holds the credentials of the SDK's Firebase project `qubrix-77954`, matching
the committed config files. Update the constants only if the project or the
registered apps change:

```dart
class SdkFirebaseOptions {
  // Android
  static const String androidApiKey = 'AIza...';        // From google-services.json
  static const String androidAppId = '1:...:android:...'; // From google-services.json
  static const String androidProjectId = '...';          // Your Firebase project ID

  // iOS
  static const String iosApiKey = 'AIza...';             // From GoogleService-Info.plist
  static const String iosAppId = '1:...:ios:...';        // From GoogleService-Info.plist
  static const String iosBundleId = 'com.varma.qubrix';  // Registered iOS bundle ID

  // Common
  static const String messagingSenderId = '...';         // From config files
  static const String measurementId = 'G-...';           // Optional
}
```

## File Locations

### Android

- SDK's Firebase config: `example/android/app/google-services.json` (tracked, package `com.varma.qubrix`)
- Host app Firebase config: Place `google-services.json` in `android/app/` of the host app

### iOS

- SDK's Firebase config: `example/ios/Runner/GoogleService-Info.plist` (tracked, bundle `com.varma.qubrix`)
- Host app Firebase config: Place `GoogleService-Info.plist` in `ios/Runner/` of the host app

## Multiple Firebase Apps

If the host app has its own Firebase, both the SDK's Firebase and the host app's Firebase can coexist:

- Host app Firebase handles host app features (analytics, auth, etc.)
- SDK Firebase handles SDK Remote Config (model URL)
- They use different Firebase app names to avoid conflicts

The SDK handles this automatically by checking if the host app has Firebase and creating a separate Firebase app for the SDK if needed.

## Testing

To test the SDK's Firebase:

1. Configure the Remote Config parameter `hf_model_url` in Firebase Console
2. Run the example app or your app with the SDK
3. Check that the SDK fetches the model URL from Firebase
4. Verify that the model download works

## Troubleshooting

### SDK Firebase Not Configured

If the SDK's Firebase is not configured:
- The SDK will use default values
- The model URL will be the default HuggingFace URL
- Analytics won't work

To check config status:
```dart
SdkFirebaseOptions.printConfigStatus();
```

### Firebase Config Conflicts

If you see conflicts between SDK Firebase and host app Firebase:
- The SDK always initializes a *named* app: `SdkFirebaseOptions.firebaseAppName` (`qubrix`)
- The host app keeps the default app (whatever name it initialized)
- Both configurations can be active at the same time, and the SDK reuses its
  existing app instead of initializing a second one

## API Keys Security

Firebase client config (`google-services.json`, `GoogleService-Info.plist` and
the values in `SdkFirebaseOptions`) is not a secret: it ships inside every app
binary. What must stay out of version control is privileged material such as
service account keys, the Firebase Admin SDK credentials and signing keys.

- The tracked client configs belong to the SDK's own project (`qubrix-77954`)
- Keep the app restricted with Firebase Security Rules / API key restrictions in Google Cloud
- Use separate Firebase projects for staging and production when needed

## Multiple Environments

For development, staging, and production:

1. Create separate Firebase projects for each environment
2. Use build flavors or environment variables to switch between configs
3. Configure different Remote Config parameters for each environment

## Relation to Q&A training (do not mix)

This file is the single source of truth for the **model URL** (`hf_model_url` → `SdkFirebaseOptions`). Q&A training never touches Firebase: hosts sync Q&A through their own backend and call `ingestKnowledge` / `askKnowledge`. See `../docs/SDK_TRAINING_GUIDE.md` (section 5) and `../docs/MAIN_APP_SYNC_COMPANION.md`.

## Summary

- The SDK has its own Firebase project for Remote Config
- Host app may have its own Firebase project
- Both can coexist without conflicts
- The SDK's Firebase is required for the Remote Config feature
- The host app's Firebase is optional
