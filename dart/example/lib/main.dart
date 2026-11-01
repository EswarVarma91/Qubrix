import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:ai_sdk/ai_sdk.dart';

import 'core/firebase_remote_config.dart';
import 'core/model_catalog.dart';
import 'core/firebase_setup.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_theme.dart';
import 'core/bindings/app_bindings.dart';
import 'core/utils/router.dart';
import 'data/repositories/ai_repository.dart';
import 'ui/controllers/home_controller.dart';
import 'ui/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for the SDK
  // The SDK manages its own Firebase for Remote Config.
  // This initializes the SDK's Firebase with its own configuration.
  // The host app may have its own Firebase too, but the SDK's Firebase
  // is separate and handles the model URL fetching.
  await initializeFirebase();

  runApp(const AiSdkExampleApp());
}

Future<void> initializeFirebase() async {
  try {
    // Initialize the SDK's Firebase
    // This creates the SDK's own Firebase app for Remote Config
    await SdkFirebaseInitializer.initialize();

    // Print config status for debugging
    SdkFirebaseOptions.printConfigStatus();

    // Initialize the Remote Config service
    final remoteConfigService = FirebaseRemoteConfigService();
    await remoteConfigService.initialize();
  } catch (e) {
    print('Firebase initialization error: $e');
    // Continue without Firebase - the SDK can use defaults
  }
}

class AiSdkExampleApp extends StatelessWidget {
  const AiSdkExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set up dependency injection
    final getItInstance = setupDependencies();
    Get.put(getItInstance);

    return GetMaterialApp(
      title: 'AI SDK Example',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: AppRoutes.home,
      getPages: AppPages.pages,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      builder: (context, child) {
        return RareKeys(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class RareKeys extends StatelessWidget {
  final Widget child;

  const RareKeys({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Apply background color to the entire screen
    return ColoredBox(
      color: AppColors.background,
      child: child,
    );
  }
}
