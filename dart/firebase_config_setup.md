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

### Step 4: Update SDK Firebase Options

Update the `SdkFirebaseOptions` class with your Firebase credentials:

```dart
class SdkFirebaseOptions {
  // Android
  static String androidApiKey = 'AIza...';      // From google-services.json
  static String androidAppId = '1:...:android:...'; // From google-services.json
  static String androidProjectId = '...';       // Your Firebase project ID

  // iOS
  static String iosApiKey = 'AIza...';          // From GoogleService-Info.plist
  static String iosAppId = '1:...:ios:...';     // From GoogleService-Info.plist

  // Common
  static String messagingSenderId = '...';      // From config files
  static String measurementId = 'G-...';        // From config files (optional)
}
```

## File Locations

### Android

- SDK's Firebase config: Place `google-services.json` in the SDK's Android directory
- Host app Firebase config: Place `google-services.json` in `android/app/` of the host app

### iOS

- SDK's Firebase config: Place `GoogleService-Info.plist` in the SDK's iOS directory
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
- Ensure they use different Firebase app names
- The SDK uses `qubrix` as the default app name
- The host app should use its own app name

## API Keys Security

**Important:** Never commit actual API keys or credentials to version control.

- The `SdkFirebaseOptions` class contains placeholder values
- Replace placeholders with actual values in your secure environment
- Use environment-specific config files or build flavors for different environments
- Consider using Flutter's `--dart-define` for build-time config

## Multiple Environments

For development, staging, and production:

1. Create separate Firebase projects for each environment
2. Use build flavors or environment variables to switch between configs
3. Configure different Remote Config parameters for each environment

## Summary

- The SDK has its own Firebase project for Remote Config
- Host app may have its own Firebase project
- Both can coexist without conflicts
- The SDK's Firebase is required for the Remote Config feature
- The host app's Firebase is optional
