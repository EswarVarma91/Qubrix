# Android Native Integration Guide

This guide shows how to integrate the AI SDK into a native Android (Kotlin/Java) application.

## Overview

The AI SDK is a Flutter/Dart package. For native Android integration, you have two options:

1. **Flutter Module** - Embed the Flutter example app as a module in your Android app
2. **Platform Channels** - Create a Flutter plugin that exposes SDK functionality via platform channels

This guide covers Option 1 (Flutter Module) as it's the simplest approach.

---

## Option 1: Flutter Module Integration

### Step 1: Create Flutter Module

```bash
# In your project directory
flutter create -t module --org com.yourcompany ai_sdk_module
```

This creates `ai_sdk_module/` with:
- `lib/` - Dart code
- `android/` - Android wrapper
- `ios/` - iOS wrapper

### Step 2: Add AI SDK to Flutter Module

Edit `ai_sdk_module/pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  ai_sdk:
    path: ../path/to/ai_sdk/dart
  get: ^4.6.6
  get_it: ^7.6.7
```

### Step 3: Add Flutter Module to Android Project

In your Android app's `settings.gradle`:

```gradle
include ':ai_sdk_module'
project(':ai_sdk_module').projectDir = new File(settingsDir, '../ai_sdk_module')
```

In your app's `build.gradle`:

```gradle
dependencies {
    implementation project(':ai_sdk_module')
}
```

### Step 4: Initialize Flutter Engine

In your Android Activity:

```kotlin
// MainActivity.kt
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

class MainActivity : FlutterActivity() {
    private var flutterEngine: FlutterEngine? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Create Flutter engine once and reuse
        if (flutterEngine == null) {
            flutterEngine = FlutterEngine(this)
            val dartExecutable = DartExecutor.DartEntrypoint(
                projectReference,
                "main"
            )
            flutterEngine?.dartExecutor?.executeDartEntrypoint(dartExecutable)
        }

        // Optionally push route
        val controller = flutterEngine?.stringChannelRegistry?.getController("route")
        controller?.send("home")
    }

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return flutterEngine
    }
}
```

### Step 5: Add Firebase to Android

1. **Download google-services.json** from Firebase Console
2. **Place in `android/app/`** (or `ai_sdk_module/android/app/` if using module)
3. **Add to project-level build.gradle**:

```gradle
// android/build.gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

4. **Add to app-level build.gradle**:

```gradle
// android/app/build.gradle
plugins {
    id 'com.android.application'
    id 'kotlin-android'
    id 'com.google.gms.google-services'  // Add this
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-core'
    implementation 'com.google.firebase:firebase-remoteconfig'
}
```

### Step 6: Configure Firebase Remote Config

In Firebase Console:

1. Go to **Remote Config**
2. Add parameter:
   - Key: `hf_model_url`
   - Type: String
   - Value: `https://huggingface.co/facebook/demo-model`
3. Publish changes

### Step 7: Handle Result Callbacks

To get results back to Android from Flutter:

```dart
// In Flutter module (lib/main.dart)
import 'package:flutter/services.dart';

class AndroidChannel {
  static const platform = MethodChannel('com.yourcompany.ai_sdk/result');

  static void sendResult(String result) {
    platform.invokeMethod('onResult', {'result': result});
  }
}
```

```kotlin
// In Android Activity
flutterEngine?.dartExecutor?.stringRegistry?.getController("com.yourcompany.ai_sdk/result")
    ?.setMessageHandler { message ->
        val result = message.arguments?.getString("result")
        // Handle result
    }
```

---

## Option 2: Platform Channels (Native Implementation)

If you want to call SDK functionality directly from native Android without Flutter UI:

### Step 1: Create Platform Channel Interface

```kotlin
// AiSdkBridge.kt
object AiSdkBridge {
    private const val CHANNEL = "com.yourcompany.ai_sdk/methods"

    fun downloadModel(onProgress: (progress: Float, status: String) -> Unit) {
        // This would call into Flutter or implement native logic
        // For now, this is a placeholder
    }

    fun runTask(taskType: String, input: Map<String, Any>, callback: (result: String) -> Unit) {
        // Call Flutter method channel
    }
}
```

### Step 2: Register Platform Channels in Flutter

```dart
// lib/main.dart
import 'package:flutter/services.dart';

class AiSdkPlugin {
  static const MethodChannel _channel = MethodChannel('com.yourcompany.ai_sdk/methods');

  static void register() {
    _channel.setMethodCallHandler((call, result) {
      switch (call.method) {
        case 'downloadModel':
          // Handle download
          break;
        case 'runTask':
          // Handle task
          break;
        default:
          result.notImplemented();
      }
    });
  }
}
```

---

## Firebase Remote Config on Android

When you need to fetch the HuggingFace URL from Firebase:

```kotlin
// FirebaseRemoteConfigHelper.kt
import com.google.firebase.remoteconfig.FirebaseRemoteConfig

object FirebaseRemoteConfigHelper {
    private val remoteConfig: FirebaseRemoteConfig by lazy {
        FirebaseRemoteConfig.getInstance()
    }

    fun getHuggingFaceUrl(): String {
        val url = remoteConfig.getString("hf_model_url")
        return if (url.isNotEmpty()) url else "https://huggingface.co/models"
    }

    fun fetchConfig() {
        remoteConfig.fetchAndActivate()
            .addOnSuccessListener { 
                // Config fetched successfully
            }
            .addOnFailureListener { e ->
                // Handle error
            }
    }
}
```

---

## Summary

| Component | Android Implementation |
|-----------|----------------------|
| AI SDK | Flutter module or platform channels |
| Firebase | google-services.json + Firebase BoM |
| Remote Config | FirebaseRemoteConfig.getInstance() |
| Model URL | Parameter: `hf_model_url` |
| Progress | Platform channels or Flutter UI |

---

## Troubleshooting

**Build fails with "Could not resolve" errors:**
- Check internet connection
- Run `flutter clean` and rebuild
- Verify google-services.json is in correct location

**Firebase not working:**
- Ensure google-services.json is in `android/app/`
- Verify plugin applied in build.gradle
- Check Firebase project is properly set up

**Flutter module not found:**
- Check `settings.gradle` includes the module
- Verify `projectDir` path is correct
