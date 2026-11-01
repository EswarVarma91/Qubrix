import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/bindings/app_bindings.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies (includes engine initialization)
  await initializeDependencies();

  runApp(const AiSdkApp());
}

/// Main application widget
class AiSdkApp extends StatelessWidget {
  const AiSdkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialBinding: HomeBinding(),
      home: const AdaptiveHomePage(),
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

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallMobile ? 12 : (isTablet ? 32 : 20),
            ),
            child: isTablet
                ? _buildTabletLayout(context)
                : const _buildMobileLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    // Tablet layout with two columns
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side - Status card (larger)
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildTabletStatusCard(context),
                const SizedBox(height: 32),
                _buildModelStatusCard(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        // Right side - Actions (narrower)
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                _buildActionPanel(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletStatusCard(BuildContext context) {
    return Obx(() => StatusCard(
          title: AppStrings.appName,
          status: Get.find<HomeController>().status,
          isLoading: Get.find<HomeController>().isLoading,
          icon: Icons.ai_large,
          subtitle: _getSubtitle(context),
        ));
  }

  Widget _buildModelStatusCard(BuildContext context) {
    return Obx(() {
      final controller = Get.find<HomeController>();
      if (controller.installedModelsCount == 0) {
        return const SizedBox.shrink();
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  controller.isModelLoaded
                      ? Icons.memory
                      : Icons.storage,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Model Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${controller.installedModelsCount} model(s) installed',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (controller.isModelLoaded) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'In Memory • Ready for inference',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: controller.unloadModel,
                icon: const Icon(Icons.memory, size: 18),
                label: const Text('Free Memory'),
              ),
            ],
          ),
        ),
      );
    });
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
              label: AppStrings.checkHealth,
              icon: Icons.health_and_safety,
              onPressed: controller.checkHealth,
              isOutlined: true,
              width: double.infinity,
            ),
          ],
        ));
  }

  Widget _buildMobileLayout() {
    // Mobile layout - single column
    return const HomeScreen();
  }

  String? _getSubtitle(BuildContext context) {
    final controller = Get.find<HomeController>();
    if (controller.installedModelsCount > 0) {
      return '${controller.installedModelsCount} model(s) installed';
    }
    if (controller.isModelLoaded) {
      return AppStrings.modelLoaded;
    }
    return null;
  }
}
