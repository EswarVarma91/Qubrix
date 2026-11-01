import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:ai_sdk/ai_sdk.dart';

import 'core/firebase_remote_config.dart';
import 'core/bindings/app_bindings.dart';
import 'core/utils/router.dart';
import 'data/repositories/ai_repository.dart';
import 'ui/controllers/home_controller.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for the SDK
  await initializeFirebase();

  // Set up dependencies
  await setupDependencies();

  runApp(const AiSdkExampleApp());
}

Future<void> initializeFirebase() async {
  try {
    await SdkFirebaseInitializer.initialize();
    SdkFirebaseOptions.printConfigStatus();
    final remoteConfigService = FirebaseRemoteConfigService();
    await remoteConfigService.initialize();
  } catch (e) {
    print('Firebase initialization error: $e');
  }
}

class AiSdkExampleApp extends StatelessWidget {
  const AiSdkExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AI SDK Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1976D2)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      initialRoute: AppRoutes.home,
      getPages: AppPages.pages,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
