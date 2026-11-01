import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ModelSummaryCard extends StatelessWidget {
  final int modelCount;
  final double totalSizeMb;
  final bool isModelLoaded;
  final VoidCallback? onFreeMemory;
  
  const ModelSummaryCard({
    super.key,
    required this.modelCount,
    required this.totalSizeMb,
    required this.isModelLoaded,
    this.onFreeMemory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.memory,
                  color: isModelLoaded ? AppColors.readyColor : AppColors.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Model Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isModelLoaded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Loaded',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Installed Models',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$modelCount model(s)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onFreeMemory != null)
                  OutlinedButton.icon(
                    onPressed: onFreeMemory,
                    icon: const Icon(Icons.eject, size: 18),
                    label: const Text('Unload'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.outlineVariant),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.storage,
                  color: AppColors.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Total Size: ${(totalSizeMb / 1024).toStringAsFixed(1)} GB',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
