# Flutter Integration Guide

This guide shows how to integrate the AI SDK into a Flutter application.

## Overview

The AI SDK is a Flutter/Dart package that provides an adaptive AI agent engine. This guide covers:

1. **Direct Package Integration** - Add the SDK as a dependency
2. **Example App Integration** - Use the provided example app as a reference
3. **Firebase Remote Config Setup** - Configure model URLs in Firebase

---

## Option 1: Direct Package Integration

### Step 1: Add AI SDK Dependency

In your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  ai_sdk:
    path: ../path/to/ai_sdk/dart  # Or use git/path dependency
  get: ^4.6.6
  get_it: ^7.6.7
```

Or use Git dependency:

```yaml
dependencies:
  ai_sdk:
    git:
      url: https://github.com/EswarVarma91/ai_sdk.git
      ref: main
      path: dart
```

### Step 2: Run Flutter Pub Get

```bash
flutter pub get
```

### Step 3: Initialize the SDK

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ai_sdk/ai_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase first (if using Firebase)
  // await Firebase.initializeApp();
  
  // Initialize AI SDK
  final aiSdk = AdaptiveAgentEngine();
  
  runApp(MyApp(aiSdk: aiSdk));
}

class MyApp extends StatelessWidget {
  final AdaptiveAgentEngine aiSdk;

  const MyApp({super.key, required this.aiSdk});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AI SDK Demo',
      home: HomeScreen(aiSdk: aiSdk),
    );
  }
}
```

### Step 4: Download and Use a Model

```dart
// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ai_sdk/ai_sdk.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class HomeScreen extends StatefulWidget {
  final AdaptiveAgentEngine aiSdk;
  const HomeScreen({super.key, required this.aiSdk});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDownloading = false;
  String? _status;
  ModelProgress? _progress;

  // Get HuggingFace URL from Firebase Remote Config
  Future<String> _getHuggingFaceUrl() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.fetchAndActivate();
    
    final url = remoteConfig.getString('hf_model_url');
    return url.isNotEmpty ? url : 'https://huggingface.co/models';
  }

  // Extract repo ID from HuggingFace URL
  String _extractRepoId(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.length >= 2) {
        return '${segments[segments.length - 2]}/${segments[segments.length - 1]}';
      }
    } catch (e) {
      // Invalid URL
    }
    return '';
  }

  Future<void> _downloadModel() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _status = 'Checking Firebase...';
    });

    // Only check Firebase if no model is installed
    final installedModels = widget.aiSdk.getInstalledModels();
    if (installedModels.isNotEmpty) {
      setState(() {
        _isDownloading = false;
        _status = 'Model already installed: ${installedModels.first.displayName}';
      });
      return;
    }

    // Fetch URL from Firebase
    final huggingFaceUrl = await _getHuggingFaceUrl();
    final repoId = _extractRepoId(huggingFaceUrl);

    if (repoId.isEmpty) {
      setState(() {
        _isDownloading = false;
        _status = 'Invalid HuggingFace URL: $huggingFaceUrl';
      });
      return;
    }

    setState(() {
      _status = 'Downloading model...';
    });

    try {
      final result = await widget.aiSdk.downloadModel(
        repoId,
        onProgress: (progress) {
          setState(() {
            _progress = progress;
            _status = '${progress.operation.name.toUpperCase()}: ${progress.percent.toStringAsFixed(1)}%';
          });
        },
        onLoadProgress: (progress) {
          setState(() {
            _progress = progress;
            _status = 'Loading: ${progress.percent.toStringAsFixed(1)}%';
          });
        },
      );

      setState(() {
        _isDownloading = false;
        _status = result.success
            ? 'Model ready: $repoId'
            : 'Download failed: ${result.errorMessage}';
      });
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI SDK')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isDownloading)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _downloadModel,
                icon: const Icon(Icons.cloud_download),
                label: const Text('Download Model'),
              ),
            if (_status != null) ...[
              const SizedBox(height: 16),
              Text(_status!),
            ],
            if (_progress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _progress!.percent / 100,
              ),
              Text(_progress!.status ?? ''),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## Option 2: Use the Example App

The `dart/example/` directory contains a complete Flutter app demonstrating SDK integration.

### Quick Start

1. Copy the example app structure
2. Add Firebase config files
3. Run the app

```bash
cd dart/example
flutter pub get
flutter run
```

### Key Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point, Firebase init, GetX setup |
| `lib/ui/controllers/home_controller.dart` | GetX controller for home screen |
| `lib/ui/screens/home_screen.dart` | Main home screen UI |
| `lib/core/firebase_remote_config.dart` | Firebase Remote Config service |
| `lib/core/bindings/app_bindings.dart` | Dependency injection setup |

---

## Firebase Remote Config Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing
3. Add Android/iOS app to the project

### Step 2: Add Config Files

**Android:**
- Download `google-services.json`
- Place in `android/app/`

**iOS:**
- Download `GoogleService-Info.plist`
- Place in `ios/Runner/`

### Step 3: Add Firebase Dependencies

In your `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_remote_config: ^4.3.0
```

### Step 4: Initialize Firebase

```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

### Step 5: Configure Remote Config Parameter

In Firebase Console:

1. Go to **Remote Config**
2. Add parameter:
   - Key: `hf_model_url`
   - Type: String
   - Value: Your HuggingFace model URL (e.g., `https://huggingface.co/facebook/demo-model`)
3. Publish changes

### Step 6: Fetch Model URL in App

```dart
import 'package:firebase_remote_config/firebase_remote_config.dart';

Future<String> getHuggingFaceUrl() async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  
  // Set defaults
  await remoteConfig.setDefaults({
    'hf_model_url': 'https://huggingface.co/models'
  });
  
  // Fetch and activate
  await remoteConfig.fetchAndActivate();
  
  // Get URL
  return remoteConfig.getString('hf_model_url');
}
```

---

## User Flow (No Model Selection)

```
User opens app
    │
    ▼
User sees home screen with "Download Model" button (cloud icon)
    │
    ▼
User taps "Download Model"
    │
    ├─── If model already installed:
    │       └──> Show "Model already installed" - skip everything
    │
    └─── If no model installed:
            │
            ▼
            Fetch HuggingFace URL from Firebase Remote Config
            (Parameter: hf_model_url)
            │
            ▼
            Extract repo ID from URL
            (e.g., https://huggingface.co/facebook/demo-model → facebook/demo-model)
            │
            ▼
            Download model from HuggingFace
            │
            ├──> Show download progress
            ├──> Show verification progress
            ├──> Show loading progress
            │
            ▼
            Model ready - user can now run tasks
```

**The user never sees or selects a model - it's a background task.**

---

## State Management

The example app uses **GetX** for state management:

```dart
// Controller
class HomeController extends GetxController {
  final AdaptiveAgentEngine _engine;
  
  // Observable state
  final _status = ''.obs;
  final _isDownloading = false.obs;
  
  // Getters
  String get status => _status.value;
  bool get isDownloading => _isDownloading.value;
  
  void downloadModel() async {
    // Implementation
  }
}

// View
class HomeScreen extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Reactive UI
    });
  }
}
```

---

## Dependency Injection with get_it

```dart
// lib/core/bindings/app_bindings.dart
import 'package:get_it/get_it.dart';
import 'package:ai_sdk/ai_sdk.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // SDK
  getIt.registerSingleton<AdaptiveAgentEngine>(AdaptiveAgentEngine());
  
  // Repositories
  getIt.registerLazySingleton<AiRepository>(
    () => AiRepository(getIt<AdaptiveAgentEngine>()),
  );
  
  // Firebase config
  getIt.registerLazySingleton<ModelConfigService>(
    () => ModelConfigService(),
  );
}
```

---

## Summary

| Component | Flutter Implementation |
|-----------|----------------------|
| SDK | `ai_sdk` package (path or git dependency) |
| State Management | GetX (`get` package) |
| DI | get_it package |
| Firebase | firebase_core, firebase_remote_config |
| Remote Config | `hf_model_url` parameter |
| UI | Responsive (mobile + tablet), reusable widgets |

---

## Troubleshooting

**Package not found:**
- Run `flutter pub get`
- Check pubspec.yaml path is correct
- Try `flutter clean` and rebuild

**Firebase not initializing:**
- Add config files (google-services.json, GoogleService-Info.plist)
- Call `Firebase.initializeApp()` before `runApp()`
- Ensure Firebase project is properly set up

**Model download fails:**
- Check model repo ID is accessible on HuggingFace
- Verify internet connection
- Check device has enough storage

**Firebase Remote Config returns empty:**
- Publish changes in Firebase Console
- Check parameter key matches exactly (`hf_model_url`)
- Check app is connected to Firebase correctly
