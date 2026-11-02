# Qubrix - Flutter Integration Guide

This guide explains how to integrate Qubrix into a Flutter application. The SDK has its own Firebase configuration for Remote Config, separate from the host app's Firebase.

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
11. [Example App](#example-app)
12. [Troubleshooting](#troubleshooting)

---

## Overview

Qubrix is a Flutter/Dart package that provides adaptive AI capabilities including:
- Model management (download, verify, load, unload)
- Task execution with multiple task types
- Personalization engine (3-layer)
- Recommendation engine
- Automation engine (3 levels: Suggest/Prepare/Execute)
- Comprehensive security layer

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

The host Flutter app may have its own Firebase project for its own features (analytics, auth, crashlytics, etc.).

**Purpose:** Host app features.

**Configuration:** Host app's Firebase project (google-services.json / GoogleService-Info.plist in host app).

**When used:** Only if the host app wants Firebase features.

### Firebase Configuration Hierarchy

1. If host app provides Firebase with Remote Config for model URL → SDK can use host app's Firebase (optional)
2. If host app has Firebase but no Remote Config for model URL → SDK uses its own Firebase
3. If host app has no Firebase → SDK uses its own Firebase

This ensures the SDK always has access to Remote Config for fetching the HuggingFace model URL.

---

## Prerequisites

- Flutter SDK (>= 3.16.0)
- Dart SDK (>= 3.0.0)
- Firebase project for the SDK (for Remote Config)
- Android Studio or VS Code (for development)

---

## Add SDK Dependencies

### Step 1: Add SDK to pubspec.yaml

Add the SDK as a dependency in your Flutter project's `pubspec.yaml`:

**For local development:**
```yaml
dependencies:
  qubrix:
    path: ../path/to/qubrix
```

**For published version:**
```yaml
dependencies:
  qubrix: ^1.0.0
```

**For Git repository:**
```yaml
dependencies:
  qubrix:
    git:
      url: https://github.com/your-org/qubrix.git
      ref: main
```

### Step 2: Get Dependencies

```bash
flutter pub get
```

### Step 3: Run Pod Install (iOS)

```bash
cd ios
pod install
cd ..
```

---

## SDK Firebase Configuration

### Step 1: Create Firebase Project for SDK

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project (e.g., "Qubrix Demo")
3. Add Android and iOS apps to the project
   - Android: Use your app's package name or a custom one
   - iOS: Use your app's bundle ID or a custom one
4. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
5. Configure Remote Config:
   - Go to **Remote Config**
   - Add parameter: `hf_model_url`
   - Value: HuggingFace model URL (e.g., `https://huggingface.co/facebook/opt-1.3b`)
   - Publish changes

### Step 2: Update SDK Firebase Options

In the SDK's code, update `SdkFirebaseOptions` with your Firebase credentials:

```dart
class SdkFirebaseOptions {
  // Android
  static String androidApiKey = 'AIza...';
  static String androidAppId = '1:...:android:...';
  static String androidProjectId = '...';

  // iOS
  static String iosApiKey = 'AIza...';
  static String iosAppId = '1:...:ios:...';

  // Common
  static String messagingSenderId = '...';
  static String measurementId = 'G-...';
}
```

### Step 3: Add Firebase Config Files

**For Android (SDK's Firebase):**
- Place `google-services.json` in the SDK's Android configuration

**For iOS (SDK's Firebase):**
- Place `GoogleService-Info.plist` in the SDK's iOS configuration

**For Host App (if it has Firebase):**
- Android: Place `google-services.json` in `android/app/`
- iOS: Place `GoogleService-Info.plist` in `ios/Runner/`

---

## Host App Firebase (Optional)

If your Flutter app has its own Firebase:

### Step 1: Add Firebase to Flutter App

```bash
flutter pub add firebase_core firebase_analytics
flutterfire configure
```

### Step 2: Initialize Firebase in main.dart

```dart
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

The SDK's Firebase is separate and doesn't conflict with your app's Firebase.

---

## SDK Initialization

### Basic Initialization

```dart
import 'package:qubrix/qubrix.dart';

// Initialize the SDK
final engine = AdaptiveAgentEngine();
await engine.initialize();

// The SDK automatically:
// 1. Initializes its own Firebase (if not already initialized)
// 2. Sets up Remote Config for fetching model URL
// 3. Initializes all engines (ModelManager, CompatibilityEngine, etc.)
// 4. Fetches the HuggingFace model URL from Firebase
```

### With Custom Firebase App Name

```dart
// If you want the SDK to use a specific Firebase app name:
await SdkFirebaseInitializer.initialize(appName: 'my_sdk_firebase');
```

### Checking SDK Firebase Status

```dart
// Check if SDK's Firebase is configured
if (SdkFirebaseOptions.isConfigured) {
  print('SDK Firebase is configured');
} else {
  print('SDK Firebase NOT configured - using defaults');
}

// Check if SDK's Firebase app is initialized
if (SdkFirebaseInitializer.isSdkAppInitialized) {
  print('SDK Firebase app is initialized');
}
```

---

## Model Download

The SDK downloads models from HuggingFace. The model URL comes from Firebase Remote Config (SDK's Firebase).

### Automatic Download

```dart
// The SDK can automatically download the model from Firebase config
final repoId = await engine.getModelRepoIdFromFirebase();
if (repoId != null) {
  await engine.downloadModel(repoId, onProgress: (progress) {
    print('${progress.operation}: ${progress.percent}%');
  });
}
```

### Manual Download

```dart
// Or specify the model ID directly
await engine.downloadModel(
  modelId: 'facebook/opt-1.3b',
  onProgress: (progress) {
    print('${progress.operation}: ${progress.percent}%');
  },
  onLoadProgress: (progress) {
    print('Loading: ${progress.percent}%');
  },
);
```

### Download Flow

1. SDK fetches `hf_model_url` from Firebase Remote Config
2. SDK extracts repo ID from URL (e.g., `facebook/opt-1.3b`)
3. SDK downloads model from HuggingFace
4. SDK verifies model integrity
5. SDK loads model into memory
6. SDK is ready to run tasks

### Progress Callbacks

The SDK provides two types of progress callbacks:

- **`onProgress`**: Called during downloading, verifying, loading, initializing phases
  - Includes `operation`, `percent`, `progress`, `total`, `status`
  
- **`onLoadProgress`**: Called during the loading phase only
  - Includes `percent`, `status`

---

## Task Execution

Once a model is downloaded and loaded, you can execute tasks:

### Classification Task

```dart
final result = await engine.executeTask(
  TaskRequest(
    taskId: 'task_1',
    description: 'Classify this text',
    input: {'text': 'I love this product!'},
    taskType: TaskType.classification,
    context: {
      'screen': 'home',
      'timeOfDay': 'morning',
    },
    options: TaskOptions(
      maxTokens: 100,
      temperature: 0.7,
    ),
  ),
);

if (result.success) {
  print('Classification: ${result.output}');
} else {
  print('Error: ${result.errorMessage}');
}
```

### Task Types

The SDK supports various task types:
- `TaskType.classification` - Text classification
- `TaskType.extraction` - Information extraction
- `TaskType.generation` - Text generation
- `TaskType.summarization` - Text summarization
- `TaskType.completion` - Text completion

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

### Using Security Features

```dart
// Check SDK integrity
final tamperDetector = TamperDetector();
final isSecure = tamperDetector.isSdkIntegrityVerified;

// Check permissions
final guard = PermissionGuard();
final hasPermission = guard.hasPermission(
  'can_modify_profile',
  PermissionLevel.user,
);

// Encrypt customer data
final protector = DataProtector();
final encrypted = protector.encryptCustomerData(
  customerId: 'cust_123',
  data: {'email': 'user@example.com'},
);

// Delete data securely
final deleteManager = SecureDeleteManager();
await deleteManager.secureDelete(
  customerId: 'cust_123',
  dataKey: 'user_data',
);
```

---

## Example App

The SDK includes a complete example app in `example/` directory.

### Running the Example App

```bash
cd example
flutter pub get
flutter run
```

### Example App Features

- GetX state management
- get_it dependency injection
- Responsive UI (mobile single column, tablet 2-column)
- Reusable widgets (AdaptiveButton, StatusCard, ActionGrid, ModelProgressIndicator)
- Security status display
- Model download with progress
- Task execution
- Settings screen

### Example App Firebase Setup

The example app uses the SDK's Firebase for Remote Config. It doesn't need its own Firebase for the model download feature.

If you want to add Firebase features to the example app (analytics, etc.), you can add the host app's Firebase config separately.

### Example App User Flow

1. User opens app → sees "Download Model" button (cloud icon)
2. User taps "Download Model"
3. App uses SDK's Firebase Remote Config to get model URL
4. SDK extracts repo ID from URL
5. SDK downloads model from HuggingFace
6. Model verified → loaded → user can run tasks

The user never selects a model - it's a background task.

---

## Training / Q&A (host-owned sync, SDK-owned learning)

The model stays SDK-owned via Firebase Remote Config `hf_model_url` (see `firebase_config_setup.md` — no change). Q&A training is host-owned:

- Host converts any file (JSON/XML/CSV/MD/DOC) to `QaTrainingBundle` and calls `engine.ingestKnowledge(bundle)` / `upsertQaPairs` / `removeQaPairs`; answers come from `engine.askKnowledge(question, lang: locale)` in the same language (en/hi/te/nl/fr/es).
- Host owns all sync: upload only `synced==false` Q&A (no PII), mark `synced=true` after server ACK, download the merged A-Z bundle, apply it, sync on launch/daily.
- Full contract: `../docs/SDK_TRAINING_GUIDE.md` (what to send) + `../docs/MAIN_APP_SYNC_COMPANION.md` (upload/download/`synced` flow). Firebase config for the model URL is separate and unchanged.

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

### Platform-Specific Issues

#### Android
- Ensure minSdkVersion is 21 or higher
- Check ProGuard rules if using R8/ProGuard
- Ensure google-services.json is in the right place

#### iOS
- Ensure deployment target is iOS 12.0 or higher
- Run pod install after adding dependencies
- Check that GoogleService-Info.plist is in the right place

---

## Summary

- **SDK has its own Firebase** for Remote Config (SDK's Firebase project)
- **Host app may have its own Firebase** for its features (host app's Firebase project)
- **SDK's Firebase is required** for fetching the HuggingFace model URL
- **Host app's Firebase is optional** - SDK works without it
- **Both can coexist** - SDK uses a separate Firebase app name

The SDK is self-contained with its own Firebase for Remote Config. The host app doesn't need to configure Firebase for the SDK to work.

If you have any questions or need help with integration, please refer to the example app or contact the SDK maintainers.
