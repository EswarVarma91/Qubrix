import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../core/model_catalog.dart';
import '../../core/theme/app_theme.dart';
import '../controllers/home_controller.dart';
import '../widgets/action_grid.dart';
import '../widgets/model_progress_indicator.dart';
import '../widgets/status_card.dart';
import '../widgets/adaptive_button.dart';

/// Home screen with reactive GetX state management
class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.find<HomeController>().navigateToSettings(),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          // Loading overlay
          if (controller.isLoading) {
            return const FullScreenLoading();
          }

          return RefreshIndicator(
            onRefresh: () async => controller.checkModelStatus(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // Status card
                  StatusCard(
                    title: AppStrings.home,
                    status: controller.status,
                    isLoading: controller.isLoading,
                    icon: Icons.ai,
                    subtitle: _getStatusSubtitle(),
                  ),

                  const SizedBox(height: 24),

                  // Security status card
                  Obx(() {
                    if (controller.tamperWarning) {
                      return Card(
                        color: AppColors.error.withValue(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.security,
                                color: AppColors.error,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Security Alert',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: AppColors.error,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'SDK integrity may be compromised!',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppColors.error,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, color: AppColors.error),
                                onPressed: controller.refreshSecurityStatus,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Card(
                      color: AppColors.success.withValue(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.security,
                              color: AppColors.success,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Security Status',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    controller.securityStatus,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 20),
                              onPressed: controller.refreshSecurityStatus,
                              tooltip: 'Refresh security check',
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Model progress (if downloading/loading)
                  Obx(() {
                    if (controller.isDownloading || controller.progress != null) {
                      return ModelProgressIndicator(
                        progress: controller.progress,
                        isLoading: controller.isDownloading,
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  const SizedBox(height: 24),

                  // Action grid
                  Text(
                    'Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ActionGrid(
                    actions: [
                      Obx(() => ActionItem(
                        label: AppStrings.downloadModel,
                        icon: Icons.download,
                        description: controller.availableModels.isEmpty
                            ? 'Loading models...'
                            : '${controller.availableModels.length} model(s) from Firebase',
                        onPressed: controller.availableModels.isNotEmpty
                            ? controller.showModelPickerDialog
                            : null,
                        isLoading: controller.isDownloading,
                      )),
                      ActionItem(
                        label: AppStrings.runTask,
                        icon: Icons.play_arrow,
                        description: 'Run AI task with model',
                        onPressed: controller.runTask,
                      ),
                      ActionItem(
                        label: AppStrings.getRecommendation,
                        icon: Icons.recommend,
                        description: 'Get personalized suggestion',
                        onPressed: controller.getRecommendation,
                      ),
                      ActionItem(
                        label: AppStrings.checkHealth,
                        icon: Icons.health_and_safety,
                        description: 'Check system health status',
                        onPressed: controller.checkHealth,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Model status section
                  Obx(() {
                    if (controller.installedModelsCount > 0) {
                      return _buildModelStatusSection(context);
                    }
                    return const SizedBox.shrink();
                  }),

                  const SizedBox(height: 24),

                  // Clear data button
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.delete_sweep),
                      title: const Text('Clear Personalization Data'),
                      subtitle: const Text('Reset all learned preferences'),
                      onTap: controller.clearPersonalizationData,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Model picker overlay
          _buildModelPickerOverlay(context),
        }),
      ),
    );
  }

  Widget _buildModelStatusSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Model Status',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  controller.isModelLoaded
                      ? Icons.memory
                      : Icons.storage,
                  color: controller.isModelLoaded
                      ? AppColors.readyColor
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Installed Models',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${controller.installedModelsCount} model(s)',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(width: 8),
                          if (controller.isModelLoaded)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.successLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Loaded',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: controller.unloadModel,
                  icon: const Icon(Icons.unload, size: 18),
                  label: const Text('Unload'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String? _getStatusSubtitle() {
    if (controller.installedModelsCount > 0) {
      return '${controller.installedModelsCount} model(s) installed';
    }
    if (controller.isModelLoaded) {
      return AppStrings.modelLoaded;
    }
    return null;
  }

  /// Build model picker dialog overlay when showModelPicker is true
  Widget _buildModelPickerOverlay(BuildContext context) {
    if (!controller.showModelPicker) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        ModalBarrier(
          color: Colors.black.withValue(0.4),
          dismissible: true,
          onDismiss: () => controller.setShowModelPicker(false),
        ),
        Center(
          child: _buildModelPickerDialog(context),
        ),
      ],
    );
  }

  /// Model picker dialog - shows models from Firebase Remote Config
  Widget _buildModelPickerDialog(BuildContext context) {
    return Obx(() {
      final models = controller.availableModels;
      final selectedRepo = controller.selectedModelRepo;
      final usingFirebase = controller.usingFirebase;

      return AlertDialog(
        title: Text(usingFirebase ? 'Models from Firebase' : 'Select Model'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  usingFirebase
                      ? 'These models are configured in Firebase Remote Config.\n'
                        'Tap a model to download it from HuggingFace.'
                      : 'Select a HuggingFace model to download.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              if (selectedRepo.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Selected: $selectedRepo',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          controller.setSelectedModel('');
                        },
                        tooltip: 'Deselect',
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: models.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: models.length,
                        itemBuilder: (context, index) {
                          final model = models[index];
                          final isSelected = selectedRepo == model.repoId;

                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryLight
                                    : AppColors.surfaceVariant.withValue(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.account_tree,
                                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              model.displayName,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  model.repoId,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontFamily: 'monospace',
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                Text(
                                  model.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: AppColors.primary)
                                : null,
                            onTap: () => controller.selectModel(model),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.setShowModelPicker(false);
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: selectedRepo.isNotEmpty
                ? () {
                    controller.setShowModelPicker(false);
                    Navigator.of(context).pop();
                    controller.downloadModel();
                  }
                : null,
            child: Text(AppStrings.downloadModel),
          ),
        ],
      );
    });
  }
}

/// Full screen loading overlay
class FullScreenLoading extends StatelessWidget {
  const FullScreenLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  AppStrings.pleaseWait,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
