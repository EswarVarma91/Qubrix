import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../controllers/home_controller.dart';
import '../widgets/security_badge.dart';
import '../widgets/model_summary_card.dart';

/// Comprehensive settings screen
class SettingsScreen extends GetView<HomeController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
        actions: [
          // Security badge in app bar
          Obx(() => SecurityBadge(
                isSecure: !controller.tamperWarning,
                onTap: controller.navigateToSecurity,
              )),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Security status card
            Obx(() => SecurityStatusCard(
                  isSecure: !controller.tamperWarning,
                  onRefresh: controller.refreshSecurityStatus,
                  onViewDetails: controller.navigateToSecurity,
                )),
            
            const SizedBox(height: 24),
            
            // Model summary
            Obx(() => ModelSummaryCard(
                  modelCount: controller.installedModelsCount,
                  totalSizeMb: 0, // Would be calculated
                  isModelLoaded: controller.isModelLoaded,
                  onFreeMemory: controller.unloadModel,
                )),
            
            const SizedBox(height: 24),
            
            // Settings sections
            _buildSectionHeader(context, 'General'),
            _buildSettingsList(
              context,
              [
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: AppStrings.about,
                  subtitle: 'Version ${AppStrings.appVersion}',
                  onTap: controller.showAbout,
                ),
                _SettingsTile(
                  icon: Icons.code_off,
                  title: AppStrings.clearPersonalizationData,
                  subtitle: 'Reset all learned preferences',
                  iconColor: AppColors.warning,
                  onTap: controller.clearPersonalizationData,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            _buildSectionHeader(context, 'Security'),
            _buildSettingsList(
              context,
              [
                _SettingsTile(
                  icon: Icons.shield,
                  title: 'Security Status',
                  subtitle: controller.securityStatus,
                  iconColor: controller.tamperWarning 
                      ? AppColors.error 
                      : AppColors.success,
                  onTap: controller.navigateToSecurity,
                ),
                _SettingsTile(
                  icon: Icons.integration_instructions,
                  title: 'Model Verification',
                  subtitle: 'Verify downloaded models',
                  onTap: () => _showModelVerificationInfo(context),
                ),
                _SettingsTile(
                  icon: Icons.delete_forever,
                  title: 'Clear Model Cache',
                  subtitle: 'Remove all downloaded models',
                  iconColor: AppColors.error,
                  onTap: controller.clearModelCache,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            _buildSectionHeader(context, 'Models'),
            _buildSettingsList(
              context,
              [
                _SettingsTile(
                  icon: Icons.download_done,
                  title: 'Downloaded Models',
                  subtitle: '${controller.installedModelsCount} installed',
                  onTap: controller.navigateToModels,
                ),
                _SettingsTile(
                  icon: Icons.recommend,
                  title: 'Model Recommendations',
                  subtitle: 'Find best model for your tasks',
                  onTap: controller.getRecommendation,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            _buildSectionHeader(context, 'Data'),
            _buildSettingsList(
              context,
              [
                _SettingsTile(
                  icon: Icons.privacy_tip,
                  title: 'Privacy Mode',
                  subtitle: 'Local processing only',
                  iconColor: AppColors.primary,
                  onTap: () => _showPrivacyInfo(context),
                ),
                _SettingsTile(
                  icon: Icons.storage,
                  title: 'Storage Used',
                  subtitle: 'Model cache and data',
                  onTap: controller.showStorageInfo,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // App version footer
            Center(
              child: Text(
                'AI SDK v${AppStrings.appVersion}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  Widget _buildSettingsList(
    BuildContext context,
    List<_SettingsTile> tiles,
  ) {
    return Card(
      child: Column(
        children: tiles.map((tile) => 
          Column(
            children: [
              tile,
              if (tile != tiles.last)
                const Divider(height: 1, indent: 72, endIndent: 16),
            ],
          )
        ).toList(),
      ),
    );
  }

  void _showModelVerificationInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Model Verification'),
        content: const Text(
          'All downloaded models are verified using cryptographic hashes.\n\n'
          'This ensures models haven\'t been tampered with and are the '
          'authentic versions from the source.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Mode'),
        content: const Text(
          'When enabled, all AI processing happens on-device.\n\n'
          '• No data sent to external servers\n'
          '• Full privacy for sensitive tasks\n'
          '• May use more battery and storage\n'
          '• Models run locally on your device',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = iconColor ?? theme.colorScheme.primary;
    
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
