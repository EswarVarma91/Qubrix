# iOS Native Integration Guide

This guide shows how to integrate the AI SDK into a native iOS (Swift/Objective-C) application.

## Overview

The AI SDK is a Flutter/Dart package. For native iOS integration, you have two options:

1. **Flutter Module** - Embed the Flutter example app as a module in your iOS app
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
- `ios/` - iOS wrapper (the `.podspec` file)

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

### Step 3: Add Flutter Module to iOS Project

**Using CocoaPods:**

In your iOS app's `Podfile`:

```ruby
# ios/Podfile
platform :ios, '12.0'

target 'YourApp' do
  use_frameworks!
  
  # Add Flutter module
  flutter_module_path = '../ai_sdk_module'
  pod 'ai_sdk_module', :path => flutter_module_path
end
```

Then run:

```bash
cd ios
pod install
```

**Using Gradle-style import (alternative):**

In Xcode, drag `ai_sdk_module/ios` into your project, or use Swift Package Manager if applicable.

### Step 4: Initialize Flutter Engine

In your iOS AppDelegate:

```swift
// AppDelegate.swift
import UIKit
import Flutter
import ai_sdk_module

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var flutterEngine: FlutterEngine?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Create Flutter engine once
        flutterEngine = FlutterEngine(name: "AI SDK Engine", project: nil)
        flutterEngine?.run()
        
        // Optionally push initial route
        let controller = FlutterViewController(
            engine: flutterEngine!,
            nibName: nil,
            bundle: nil
        )
        controller.router = FlutterNavigationRouter(rootRoute: "/home")
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = controller
        window?.makeKeyAndVisible()
        
        return true
    }
}
```

**Alternative: Using FlutterViewController in a specific view:**

```swift
// In your view controller
import Flutter

class HomeViewController: UIViewController {
    var flutterEngine: FlutterEngine?
    var flutterViewController: FlutterViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if flutterEngine == nil {
            flutterEngine = FlutterEngine(name: "AI_SDK", project: nil)
            flutterEngine?.run()
        }
        
        flutterViewController = FlutterViewController(
            engine: flutterEngine!,
            nibName: nil,
            bundle: nil
        )
        
        // Add as child view controller
        addChild(flutterViewController!)
        view.addSubview(flutterViewController!.view)
        flutterViewController!.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            flutterViewController!.view.topAnchor.constraint(equalTo: view.topAnchor),
            flutterViewController!.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            flutterViewController!.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            flutterViewController!.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        flutterViewController!.didMove(toParent: self)
    }
}
```

### Step 5: Add Firebase to iOS

1. **Download GoogleService-Info.plist** from Firebase Console
2. **Add to Xcode project:**
   - Drag into `ios/Runner/` (or your app's main folder)
   - Make sure "Copy items if needed" is checked
   - Add to your app target

3. **Add Firebase via CocoaPods:**

```ruby
# ios/Podfile
target 'YourApp' do
  use_frameworks!
  
  # Firebase
  pod 'FirebaseCore'
  pod 'FirebaseRemoteConfig'
end
```

```bash
cd ios
pod install
```

4. **Initialize Firebase in AppDelegate:**

```swift
// AppDelegate.swift
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Initialize Firebase FIRST
        FirebaseApp.configure()
        
        // Then initialize Flutter
        flutterEngine = FlutterEngine(name: "AI_SDK", project: nil)
        flutterEngine?.run()
        
        return true
    }
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

To get results back to iOS from Flutter:

```dart
// In Flutter module (lib/main.dart)
import 'package:flutter/services.dart';

class iOSChannel {
  static const platform = MethodChannel('com.yourcompany.ai_sdk/result');

  static void sendResult(String result) {
    platform.invokeMethod('onResult', {'result': result});
  }
}
```

```swift
// In iOS AppDelegate or view controller
import Flutter

class FlutterResultHandler: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.yourcompany.ai_sdk/result",
            binaryMessenger: registrar.messenger()
        )
        
        let instance = FlutterResultHandler()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "onResult":
            if let args = call.arguments as? [String: Any],
               let resultValue = args["result"] as? String {
                // Handle result from Flutter
                print("Received result: \(resultValue)")
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
```

---

## Option 2: Platform Channels (Native Implementation)

If you want to call SDK functionality directly from native iOS without Flutter UI:

### Step 1: Create Platform Channel Interface

```swift
// AiSdkBridge.swift
import Flutter

class AiSdkBridge {
    private let channel = FlutterMethodChannel(
        name: "com.yourcompany.ai_sdk/methods",
        binaryMessenger: FlutterNativePlugin.messenger()
    )
    
    func downloadModel(onProgress: @escaping (Float, String) -> Void) {
        // This would call into Flutter or implement native logic
    }
    
    func runTask(taskType: String, input: [String: Any], callback: @escaping (String) -> Void) {
        // Call Flutter method channel
        channel.invokeMethod("runTask", arguments: [
            "taskType": taskType,
            "input": input
        ], result: { result in
            if let resultDict = result as? [String: Any],
               let output = resultDict["output"] as? String {
                callback(output)
            }
        })
    }
}
```

---

## Firebase Remote Config on iOS

When you need to fetch the HuggingFace URL from Firebase:

```swift
// FirebaseRemoteConfigHelper.swift
import FirebaseRemoteConfig

class FirebaseRemoteConfigHelper {
    static let shared = FirebaseRemoteConfigHelper()
    
    private let remoteConfig: FirebaseRemoteConfig
    
    init() {
        remoteConfig = FirebaseRemoteConfig.app()
        remoteConfig.setDefaults([
            "hf_model_url": ""
        ])
    }
    
    func getHuggingFaceUrl() -> String {
        let url = remoteConfig.string("hf_model_url")
        return url.isEmpty ? "https://huggingface.co/models" : url
    }
    
    func fetchConfig() {
        remoteConfig.fetchAndActivate { status, error in
            if status == .successFetchedFromServer ||
               status == .successUsingPreFetchedData {
                // Config fetched successfully
            } else {
                // Handle error
            }
        }
    }
}
```

---

## Summary

| Component | iOS Implementation |
|-----------|-------------------|
| AI SDK | Flutter module or platform channels |
| Firebase | GoogleService-Info.plist + Firebase pods |
| Remote Config | FirebaseRemoteConfig.app() |
| Model URL | Parameter: `hf_model_url` |
| Progress | Platform channels or Flutter UI |

---

## Troubleshooting

**"GoogleService-Info.plist not found":**
- Ensure file is in your app target's main bundle
- Check Build Phases → Copy Bundle Resources includes the file

**Firebase not initializing:**
- Call `FirebaseApp.configure()` before any Firebase usage
- Verify GoogleService-Info.plist is correct

**Flutter module not loading:**
- Run `pod install` after adding the module
- Check that the pod is in your Podfile
- Clean build folder and rebuild

**Method channel not working:**
- Ensure channel names match on both sides
- Check Flutter engine is properly initialized before calling channels
