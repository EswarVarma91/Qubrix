import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SecurityStatusCard extends StatelessWidget {
  final bool isSecure;
  final VoidCallback? onRefresh;
  final VoidCallback? onViewDetails;
  
  const SecurityStatusCard({
    super.key,
    required this.isSecure,
    this.onRefresh,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      color: isSecure ? AppColors.successLight : AppColors.error.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSecure ? Icons.shield : Icons.warning_amber,
                  color: isSecure ? AppColors.success : AppColors.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Security Status',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: onRefresh,
                    tooltip: 'Refresh security check',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isSecure 
                        ? 'Security: Protected'
                        : 'Security: Compromised!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSecure ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (onViewDetails != null)
                  TextButton(
                    onPressed: onViewDetails,
                    child: Text(
                      'View Details',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isSecure ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
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
