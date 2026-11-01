import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/bindings/app_bindings.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/router.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/widgets/security_badge.dart';
import 'ui/widgets/model_summary_card.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDependencies();

  runApp(const AiSdkApp());
}

/// Main application widget with GetX routing
class AiSdkApp extends StatelessWidget {
  const AiSdkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.home,
      getPages: AppPages.pages,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
      builder: (context, child) {
        // Add security badge to all app bars
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
          ],
        );
      },
    );
  }
}

/// Adaptive home page that handles responsive layout
class AdaptiveHomePage extends StatelessWidget {
  const AdaptiveHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final isSmallMobile = MediaQuery.sizeOf(context).width < 360;
    final isLargeScreen = MediaQuery.sizeOf(context).width > 900;

    // Use adaptive container width
    final containerWidth = isSmallMobile 
        ? double.infinity 
        : (isLargeScreen ? 1000 : 800);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: containerWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallMobile ? 12 : (isTablet ? 32 : 20),
                vertical: isSmallMobile ? 8 : 16,
              ),
              child: isTablet && !isLargeScreen
                  ? _buildTabletLayout(context)
                  : const _buildMobileLayout(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    final isLargeScreen = MediaQuery.sizeOf(context).width > 900;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side - Main content
        Expanded(
          flex: isLargeScreen ? 3 : 2,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildStatusCard(context),
                const SizedBox(height: 24),
                _buildModelSummaryCard(context),
                const SizedBox(height: 24),
                _buildSecurityStatusCard(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        if (isLargeScreen) const SizedBox(width: 24),
        // Right side - Actions panel (only on medium tablets)
        if (!isLargeScreen)
          Container(
            width: 300,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildSectionHeader(context, 'Quick Actions'),
                  const SizedBox(height: 12),
                  _buildActionPanel(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return const StatusCard(
      title: AppStrings.appName,
      status: 'AI SDK Ready',
      icon: Icons.ai_large,
      subtitle: 'Tap download to get started',
    );
  }

  Widget _buildModelSummaryCard(BuildContext context) {
    return Obx(() => ModelSummaryCard(
          modelCount: Get.find<HomeController>().installedModelsCount,
          totalSizeMb: 0,
          isModelLoaded: Get.find<HomeController>().isModelLoaded,
          onFreeMemory: Get.find<HomeController>().unloadModel,
        ));
  }

  Widget _buildSecurityStatusCard(BuildContext context) {
    return Obx(() => SecurityStatusCard(
          isSecure: !Get.find<HomeController>().tamperWarning,
          onRefresh: Get.find<HomeController>().refreshSecurityStatus,
        ));
  }

  Widget _buildActionPanel(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Obx(() => Column(
          children: [
            AdaptiveButton(
              label: AppStrings.downloadModel,
              icon: Icons.download,
              onPressed: controller.downloadModel,
              isLoading: controller.isDownloading,
              width: double.infinity,
            ),
            const SizedBox(height: 12),
            AdaptiveButton(
              label: AppStrings.runTask,
              icon: Icons.play_arrow,
              onPressed: controller.runTask,
              width: double.infinity,
            ),
            const SizedBox(height: 12),
            AdaptiveButton(
              label: AppStrings.getRecommendation,
              icon: Icons.recommend,
              onPressed: controller.getRecommendation,
              isOutlined: true,
              width: double.infinity,
            ),
            const SizedBox(height: 12),
            AdaptiveButton(
              label: AppStrings.settings,
              icon: Icons.settings,
              onPressed: controller.navigateToSettings,
              isOutlined: true,
              width: double.infinity,
            ),
          ],
        ));
  }

  Widget _buildMobileLayout() {
    return const HomeScreen();
  }
}
