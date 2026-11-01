import 'package:flutter/material.dart';
import 'package:qubrix/qubrix.dart';
import '../../core/constants/app_colors.dart';

class ModelProgressIndicator extends StatelessWidget {
  final ModelProgress? progress;
  final bool isLoading;
  
  const ModelProgressIndicator({
    super.key,
    required this.progress,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading || progress == null) {
      return const SizedBox.shrink();
    }
    
    final current = progress!;
    final percent = current.percent.clamp(0.0, 1.0);
    final operation = current.operation.name;
    final status = current.status ?? '';
    final detail = current.detail ?? '';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.download,
                  color: AppColors.downloadingColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Model Download',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Text(
                  '${(percent * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percent,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getOperationColor(operation),
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              operation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getOperationColor(operation),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (status.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                status,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (detail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                detail,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getOperationColor(String operation) {
    switch (operation.toLowerCase()) {
      case 'downloading':
        return AppColors.downloadingColor;
      case 'verifying':
        return AppColors.warning;
      case 'loading':
        return AppColors.loadingColor;
      case 'initializing':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }
}
