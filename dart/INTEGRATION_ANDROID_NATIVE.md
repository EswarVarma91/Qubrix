# AI SDK - Native Android Integration Guide

This guide explains how to integrate the AI SDK into a native Android application. The SDK has its own Firebase configuration for Remote Config, separate from the host app's Firebase.

## Table of Contents

1. [Overview](#overview)
2. [SDK Firebase Architecture](#sdk-firebase-architecture)
3. [Prerequisites](#prerequisites)
4. [Add SDK Dependencies](#add-sdk-dependencies)
5. [SDK Firebase Configuration](#sdk-firebase-configuration)
6. [Host App Firebase (Optional)](#host-app-firebase-optional)
7. [SDK Initialization](#sdk-initialization)
8. [Model Download](#model-download)
9. [Task Execution](#task-execution)
10. [Security Features](#security-features)
11. [Troubleshooting](#troubleshooting)

---

## Overview

The AI SDK is a Flutter/Dart package that provides adaptive AI capabilities. It can be integrated into native Android apps via platform channels or by building the Flutter module as an Android library.

The SDK includes its own Firebase configuration for Remote Config. This allows the SDK to fetch the HuggingFace model URL regardless of whether the host app has Firebase or not.

---

## SDK Firebase Architecture

The SDK has two potential Firebase configurations:

### 1. SDK's Firebase (Required for Remote Config)

The SDK manages its own Firebase app for Remote Config. This is configured in the SDK's own Firebase project.

**Purpose:** Fetch the HuggingFace model URL from Firebase Remote Config.

**Configuration:** `SdkFirebaseOptions` in the SDK's codebase.

**When used:** Always - the SDK needs this for Remote Config.

### 2. Host App's Firebase (Optional)

The host Android app may have its own Firebase project for its own features (analytics, auth, crashlytics, etc.).

**Purpose:** Host app features.

**Configuration:** Host app's Firebase project (google-services.json in app/).

**When used:** Only if the host app wants Firebase features.

### Firebase Configuration Hierarchy

1. If host app provides Firebase with Remote Config for model URL → SDK can use host app's Firebase (optional)
2. If host app has Firebase but no Remote Config for model URL → SDK uses its own Firebase
3. If host app has no Firebase → SDK uses its own Firebase

This ensures the SDK always has access to Remote Config for fetching the HuggingFace model URL.

---

## Prerequisites

- Android Studio or IntelliJ IDEA
- Android SDK (API 21+)
- Flutter SDK (if building as Flutter module)
- Firebase project for the SDK (for Remote Config)

---

## Add SDK Dependencies

### Option 1: Use SDK as a Flutter Module

If your Android app uses Flutter, add the SDK as a dependency in `pubspec.yaml`:

```yaml
dependencies:
  ai_sdk:
    path: ../path/to/ai_sdk
```

### Option 2: Use SDK via Platform Channel

If your Android app is pure native, you can communicate with the SDK via platform channels. The SDK would run as a Flutter module.

### Option 3: Build as AAR (Android Archive)

Build the Flutter module as an Android library (AAR) and include it in your app.

---

## SDK Firebase Configuration

### Step 1: Create Firebase Project for SDK

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project (e.g., "AI SDK Demo")
3. Add an Android app to the project
   - Package name: Use your app's package or a custom one for the SDK
4. Download `google-services.json`
5. Add an iOS app (if needed)
6. Download `GoogleService-Info.plist`

### Step 2: Configure Remote Config Parameter

In Firebase Console:
1. Go to **Remote Config**
2. Add a parameter:
   - **Parameter key:** `hf_model_url`
   - **Value:** HuggingFace model URL (e.g., `https://huggingface.co/facebook/opt-1.3b`)
3. Publish the changes

### Step 3: Update SDK Firebase Options

In the SDK's code, update `SdkFirebaseOptions` with your Firebase credentials:

```dart
class SdkFirebaseOptions {
  static String androidApiKey = 'AIza...';  // From google-services.json
  static String androidAppId = '1:...';     // From google-services.json
  static String androidProjectId = '...';   // Your project ID
  static String messagingSenderId = '...';  // From google-services.json
  // iOS and web options as needed
}
```

### Step 4: Add Firebase Config Files

**For Android (SDK's Firebase):**
- Place `google-services.json` in the appropriate location for the SDK's Firebase

**For the host app (if it has Firebase):**
- Place `google-services.json` in `app/` directory of the host app

---

## Host App Firebase (Optional)

If your Android app has its own Firebase:

1. Add your app to your Firebase project
2. Download `google-services.json`
3. Place it in `app/` directory of your Android project
4. Configure your app's Firebase features as needed

The SDK's Firebase is separate and doesn't conflict with your app's Firebase.

---

## SDK Initialization

### Kotlin/Java Initialization

```kotlin
// Initialize Firebase for the SDK
// This is done by the SDK's Flutter code automatically when
// the SDK is initialized. If you're using platform channels,
// the Flutter side handles this.

// The SDK initializes its Firebase like this:
// 1. Check if host app has Firebase
// 2. If yes, create SDK's Firebase app with different name
// 3. If no, initialize SDK's own Firebase
```

### SDK Initialization Flow

```dart
// The SDK's initialization (handled internally):
Future<void> initializeSdk() async {
  // Initialize SDK's Firebase
  await SdkFirebaseInitializer.initialize();

  // Initialize Remote Config
  final remoteConfig = SdkRemoteConfigService();
  await remoteConfig.initialize();

  // Initialize the main engine
  final engine = AdaptiveAgentEngine();
  await engine.initialize();

  // Fetch model URL from Firebase
  final modelUrl = await remoteConfig.getHuggingFaceModelUrl();
  // Use modelUrl to download the model
}
```

---

## Model Download

The SDK downloads models from HuggingFace. The model URL comes from Firebase Remote Config (SDK's Firebase).

### Download Flow

1. SDK fetches `hf_model_url` from Firebase Remote Config
2. SDK extracts repo ID from URL (e.g., `facebook/opt-1.3b`)
3. SDK downloads model from HuggingFace
4. SDK verifies model integrity
5. SDK loads model into memory
6. SDK is ready to run tasks

### Download with Progress

```dart
// The SDK provides progress callbacks:
await engine.downloadModel(
  modelId: 'model-id',
  onProgress: (progress) {
    // Called during downloading, verifying, loading, initializing
    print('${progress.operation} ${progress.percent}%');
  },
  onLoadProgress: (progress) {
    // Called during loading phase
    print('Loading: ${progress.percent}%');
  },
);
```

---

## Task Execution

Once a model is downloaded and loaded, you can execute tasks:

```dart
// Create a task request
final request = TaskRequest(
  taskId: 'task_1',
  description: 'Classify this text',
  input: {'text': 'Hello world'},
  taskType: TaskType.classification,
  context: {
    'screen': 'home',
    'timeOfDay': 'morning',
  },
);

// Execute the task
final result = await engine.executeTask(request);

// Handle result
if (result.success) {
  print('Result: ${result.output}');
} else {
  print('Error: ${result.errorMessage}');
}
```

---

## Security Features

The SDK includes comprehensive security features:

### Integrity Verification
- Verifies SDK code integrity at runtime
- Detects tampering attempts
- Checks for debuggers and emulation

### Data Protection
- Per-customer encryption keys (HKDF-derived)
- AES-256-GCM encryption for customer data
- Secure storage for sensitive data

### Permission Guard
- Permissions required for sensitive operations
- Payment/delete/modify operations require explicit user consent
- Remote config updates require user confirmation

### Tamper Detection
- Detects rooted/jailbroken devices
- Detects emulators
- Detects debugging tools
- Detects reverse engineering attempts

### Emergency Response
- Automatic lockout on tamper detection
- Secure logout and data deletion
- Remote wipe capability

---

## Troubleshooting

### Firebase Not Configured

If the SDK's Firebase is not configured:
- The SDK will use default values
- Model URL will be the default HuggingFace URL
- Analytics won't work

**Fix:** Configure the SDK's Firebase project and update `SdkFirebaseOptions`.

### Model Download Fails

- Check network connectivity
- Verify HuggingFace model URL is valid
- Check device storage availability
- Check if model ID is correct

### SDK Firebase Conflicts with Host App Firebase

If your host app has Firebase and the SDK also has Firebase, they operate independently:
- Host app Firebase handles host app features
- SDK Firebase handles SDK Remote Config
- They use different app names to avoid conflicts

---

## Summary

- **SDK has its own Firebase** for Remote Config (SDK's Firebase project)
- **Host app may have its own Firebase** for its features (host app's Firebase project)
- **SDK's Firebase is required** for fetching the HuggingFace model URL
- **Host app's Firebase is optional** - SDK works without it
- **Both can coexist** - SDK uses a separate Firebase app name

The SDK is self-contained with its own Firebase for Remote Config. The host app doesn't need to configure Firebase for the SDK to work.
