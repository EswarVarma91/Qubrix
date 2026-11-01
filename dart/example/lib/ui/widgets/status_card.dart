import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';

/// Reusable status card widget showing current state
class StatusCard extends StatelessWidget {
  final String title;
  final String status;
  final bool isLoading;
  final String? subtitle;
  final IconData? icon;

  const StatusCard({
    super.key,
    required this.title,
    required this.status,
    this.isLoading = false,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;

    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
          vertical: isTablet ? 20 : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              status,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w500,
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (status.isEmpty || status == AppStrings.loading) {
      return AppColors.onSurfaceVariant;
    }
    if (status.contains('Error') || status.contains('failed')) {
      return AppColors.errorColor;
    }
    if (status.contains('ready') || status.contains('completed')) {
      return AppColors.readyColor;
    }
    return AppColors.onSurface;
  }
}
