import 'package:get/get.dart';
import '../../ui/screens/home_screen.dart';
import '../../ui/screens/settings_screen.dart';

/// GetX route definitions
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String settings = '/settings';
}

/// GetX route configuration
///
/// Dependencies are registered once in `setupDependencies()`; the controllers
/// are shared, so the pages do not need per-route bindings.
class AppPages {
  AppPages._();

  static final pages = [
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
    ),
  ];
}
