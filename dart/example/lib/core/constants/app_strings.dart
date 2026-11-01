import 'package:flutter/material.dart';

/// App-wide string constants
class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'AI SDK Demo';
  static const String appVersion = '1.0.0';
  static const String loadingText = 'Loading...';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String done = 'Done';
  static const String ok = 'OK';

  // Pages
  static const String home = 'Home';
  static const String models = 'Models';
  static const String settings = 'Settings';
  static const String about = 'About';
  static const String clearPersonalizationData = 'Clear Personalization Data';

  // Actions
  static const String downloadModel = 'Download Model';
  static const String runTask = 'Run Task';
  static const String getRecommendation = 'Get Recommendation';
  static const String checkHealth = 'Check Health';
  static const String checkStatus = 'Check Status';
  static const String unloadModel = 'Unload Model';
  static const String clearData = 'Clear Data';

  // Status messages
  static const String engineInitialized = 'Engine initialized';
  static const String engineNotInitialized = 'Not initialized';
  static const String noRecommendation = 'No recommendations available';
  static const String noSuitableModel = 'No suitable model found';
  static const String modelReady = 'Model ready!';
  static const String taskCompleted = 'Task completed';
  static const String taskFailed = 'Task failed';

  // Model operations
  static const String downloading = 'Downloading';
  static const String verifying = 'Verifying';
  static const String loadingText2 = 'Loading';
  static const String loading = 'Loading';
  static const String initializing = 'Initializing';
  static const String modelInstalled = 'Model installed';
  static const String modelLoaded = 'Model loaded in memory';

  // Personalization
  static const String personalizationEnabled = 'Personalization enabled';
  static const String personalizationDisabled = 'Personalization disabled';
  static const String recommendationsDisabled = 'Recommendations disabled';

  // Errors
  static const String errorOccurred = 'Error occurred';
  static const String pleaseWait = 'Please wait...';
  static const String noModelsInstalled = 'No models installed';
}

/// App-wide color constants
class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF6750A4);
  static const Color primaryLight = Color(0xFFEADDFF);
  static const Color primaryContainer = Color(0xFF6750A4);

  // Secondary
  static const Color secondary = Color(0xFF625B71);
  static const Color secondaryContainer = Color(0xFFE8DEF8);

  // Background
  static const Color background = Color(0xFFFFFBFE);
  static const Color surface = Color(0xFFFFFBFE);
  static const Color surfaceVariant = Color(0xFFE7E0EC);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);

  // Success
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);

  // Warning
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFF8E1);

  // Neutral
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF1C1B1F);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color onSurfaceVariant = Color(0xFF49454F);
  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFCAC4D0);

  // Model status colors
  static const Color downloadingColor = Color(0xFF2196F3);
  static const Color loadingColor = Color(0xFFFF9800);
  static const Color readyColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
}


