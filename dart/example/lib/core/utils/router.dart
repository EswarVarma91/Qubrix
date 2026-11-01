import 'package:get/get.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';

/// GetX route definitions
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String settings = '/settings';
}

/// GetX route configuration
class AppPages {
  AppPages._();

  static final pages = [
    GetPage(
      name: AppRoutes.home,
      page: () => const AdaptiveHomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      binding: SettingsBinding(),
    ),
  ];

  /// Get binding for a route
  static Bindings? bindingForRoute(String route) {
    switch (route) {
      case AppRoutes.home:
        return HomeBinding();
      case AppRoutes.settings:
        return SettingsBinding();
      default:
        return null;
    }
  }
}
