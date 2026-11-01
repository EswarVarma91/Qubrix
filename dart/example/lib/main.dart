import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qubrix/qubrix.dart';

import 'core/bindings/app_bindings.dart';
import 'core/utils/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for the SDK
  await initializeFirebase();

  // Set up dependencies
  await setupDependencies();

  runApp(const QubrixApp());
}

Future<void> initializeFirebase() async {
  try {
    await SdkFirebaseInitializer.initialize();
    SdkFirebaseOptions.printConfigStatus();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
}

class QubrixApp extends StatelessWidget {
  const QubrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Qubrix',
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
