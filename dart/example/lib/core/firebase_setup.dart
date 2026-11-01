/// Firebase setup helper
/// 
/// This file documents how to configure Firebase for the app.
/// When you have your google-services.json (Android) and GoogleService-Info.plist (iOS),
/// place them in the respective platform folders.
/// 
/// ## Android Setup
/// 1. Place `google-services.json` in `android/app/`
/// 2. Add to android/app/build.gradle:
///    ```
///    apply plugin: 'com.google.gms.google-services'
///    ```
/// 3. Add to android/build.gradle (project level):
///    ```
///    classpath 'com.google.gms:google-services:4.4.0'
///    ```
/// 
/// ## iOS Setup
/// 1. Place `GoogleService-Info.plist` in `ios/Runner/`
/// 2. Add to ios/Runner.xcodeproj/project.pbxproj
/// 
/// ## Firebase Dependencies (pubspec.yaml)
/// Add these to example/pubspec.yaml dependencies:
/// ```yaml
/// dependencies:
///   firebase_core: ^2.24.0
///   firebase_remote_config: ^4.3.0
/// ```
/// 
/// ## Initialization (in main.dart)
/// ```dart
/// import 'package:firebase_core/firebase_core.dart';
/// 
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp();
///   // Then proceed with app initialization
/// }
/// ```

class FirebaseSetupConfig {
  // Firebase project configuration
  // These would come from Firebase console when you create a project
  
  /// Firebase project ID (set in Firebase console)
  static const String projectId = 'YOUR_FIREBASE_PROJECT_ID';
  
  /// Firebase API key (auto-configured via google-services.json / GoogleService-Info.plist)
  // static const String apiKey = 'YOUR_API_KEY'; // Not needed with proper config files
  
  /// Firebase Remote Config parameter keys
  static const String modelsParamKey = 'available_models';
  static const String enableCustomModelsKey = 'enable_custom_models';
  static const String defaultModelRepoKey = 'default_model_repo';
  
  /// Remote config parameter names
  static const String paramAvailableModels = 'available_models';
  static const String paramEnableCustomModels = 'enable_custom_models';
  static const String paramDefaultModelRepo = 'default_model_repo';
  
  /// Default remote config values
  static const List<Map<String, dynamic>> defaultModels = [
    {
      'repo_id': 'distilbert-base-uncased-finetuned-sst-2-english',
      'display_name': 'Sentiment Analysis',
      'description': 'DistilBERT fine-tuned for sentiment analysis',
      'license': 'Apache 2.0',
      'task_type': 'text_classification',
      'min_quality': 0.85,
      'enabled': true,
      'variants': [
        {'quantization': 'float32', 'download_size_mb': 250, 'memory_requirement_mb': 500, 'estimated_latency_ms': 50},
        {'quantization': 'int8', 'download_size_mb': 68, 'memory_requirement_mb': 200, 'estimated_latency_ms': 30},
        {'quantization': 'int4', 'download_size_mb': 36, 'memory_requirement_mb': 120, 'estimated_latency_ms': 25},
      ],
    },
    {
      'repo_id': 'gpt2',
      'display_name': 'GPT-2 Small',
      'description': '117M parameter text generation model',
      'license': 'MIT',
      'task_type': 'text_generation',
      'min_quality': 0.7,
      'enabled': true,
      'variants': [
        {'quantization': 'float32', 'download_size_mb': 500, 'memory_requirement_mb': 1000, 'estimated_latency_ms': 100},
        {'quantization': 'float16', 'download_size_mb': 250, 'memory_requirement_mb': 600, 'estimated_latency_ms': 80},
        {'quantization': 'int8', 'download_size_mb': 128, 'memory_requirement_mb': 350, 'estimated_latency_ms': 60},
        {'quantization': 'int4', 'download_size_mb': 65, 'memory_requirement_mb': 200, 'estimated_latency_ms': 45},
      ],
    },
  ];
  
  /// How to structure the available_models parameter in Firebase Remote Config
  /// 
  /// In Firebase Console → Remote Config → Parameters:
  /// - Key: `available_models`
  /// - Type: String
  /// - Value: JSON array of model configurations
  /// 
  /// Example JSON value:
  /// ```json
  /// [
  ///   {
  ///     "repo_id": "distilbert-base-uncased-finetuned-sst-2-english",
  ///     "display_name": "Sentiment Analysis",
  ///     "description": "DistilBERT for sentiment",
  ///     "license": "Apache 2.0",
  ///     "task_type": "text_classification",
  ///     "min_quality": 0.85,
  ///     "enabled": true,
  ///     "variants": [
  ///       {"quantization": "float32", "download_size_mb": 250, "memory_requirement_mb": 500, "estimated_latency_ms": 50},
  ///       {"quantization": "int8", "download_size_mb": 68, "memory_requirement_mb": 200, "estimated_latency_ms": 30}
  ///     ]
  ///   }
  /// ]
  /// ```
}

/// Helper to validate Firebase config files exist
class FirebaseConfigValidator {
  /// Check if google-services.json exists (Android)
  static bool hasAndroidConfig() {
    // In production, check file system
    // Return true if google-services.json is in android/app/
    return false; // Placeholder - implement based on your file check logic
  }
  
  /// Check if GoogleService-Info.plist exists (iOS)
  static bool hasIosConfig() {
    // In production, check file system
    // Return true if GoogleService-Info.plist is in ios/Runner/
    return false; // Placeholder - implement based on your file check logic
  }
  
  /// Get setup status
  static String getSetupStatus() {
    final hasAndroid = hasAndroidConfig();
    final hasIos = hasIosConfig();
    
    if (hasAndroid && hasIos) {
      return 'Firebase configured for Android and iOS';
    } else if (hasAndroid) {
      return 'Firebase configured for Android only';
    } else if (hasIos) {
      return 'Firebase configured for iOS only';
    } else {
      return 'Firebase not configured - add google-services.json and GoogleService-Info.plist';
    }
  }
}
