import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Card showing summary of installed models with quick stats
class ModelSummaryCard extends StatelessWidget {
  final int modelCount;
  final int totalSizeMb;
  final int? largestModelSizeMb;
  final String? largestModelName;
  final bool isModelLoaded;
  final VoidCallback? onViewModels;
  final VoidCallback? onFreeMemory;

  const ModelSummaryCard({
    super.key,
    required this.modelCount,
    required this.totalSizeMb,
    this.largestModelSizeMb,
    this.largestModelName,
    this.isModelLoaded = false,
    this.onViewModels,
    this.onFreeMemory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Icon(
                  Icons.storage,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Models Installed',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (isModelLoaded)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Memory Active',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            
            // Stats row
            Row(
              children: [
                _StatItem(
                  label: 'Count',
                  value: '${modelCount}',
                  icon: Icons.layers,
                ),
                const SizedBox(width: 24),
                _StatItem(
                  label: 'Total Size',
                  value: _formatSize(totalSizeMb),
                  icon: Icons.data_usage,
                ),
                if (largestModelSizeMb != null) ...[
                  const SizedBox(width: 24),
                  _StatItem(
                    label: 'Largest',
                    value: _formatSize(largestModelSizeMb!),
                    icon: Icons.flash_on,
                  ),
                ],
              ],
            ),
            
            if (largestModelName != null && largestModelName!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Largest: $largestModelName',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Actions
            if (onViewModels != null || onFreeMemory != null)
              Row(
                children: [
                  if (onViewModels != null)
                    TextButton(
                      onPressed: onViewModels,
                      child: const Text('View Models'),
                    ),
                  if (onFreeMemory != null && isModelLoaded) ...[
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: onFreeMemory,
                      icon: const Icon(Icons.memory, size: 16),
                      label: const Text('Free Memory'),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatSize(int mb) {
    if (mb < 1024) {
      return '$mb MB';
    }
    return '${(mb / 1024).toStringAsFixed(1)} GB';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Individual model info card
class ModelInfoCard extends StatelessWidget {
  final String modelName;
  final String modelId;
  final int sizeMb;
  final int memoryUsageMb;
  final bool isLoaded;
  final String? version;
  final VoidCallback? onUnload;

  const ModelInfoCard({
    super.key,
    required this.modelName,
    required this.modelId,
    required this.sizeMb,
    required this.memoryUsageMb,
    required this.isLoaded,
    this.version,
    this.onUnload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isLoaded 
                ? AppColors.successLight 
                : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isLoaded ? Icons.memory : Icons.storage,
            color: isLoaded ? AppColors.success : AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          modelName,
         style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: $modelId'),
            if (version != null)
              Text(
                'v$version',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Chip(label: _formatSize(sizeMb), icon: Icons.data_usage),
            const SizedBox(width: 8),
            _Chip(label: '${memoryUsageMb}MB', icon: Icons.memory),
            if (isLoaded && onUnload != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.unload, size: 18),
                onPressed: onUnload,
                tooltip: 'Unload from memory',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _Chip({required String label, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.onSurface.withValue(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  String _formatSize(int mb) {
    if (mb < 1024) return '$mb MB';
    return '${(mb / 1024).toStringAsFixed(1)} GB';
  }
}
