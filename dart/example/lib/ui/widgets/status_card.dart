import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StatusCard extends StatelessWidget {
  final String title;
  final String status;
  final IconData icon;
  final String? subtitle;
  final bool isLoading;
  
  const StatusCard({
    super.key,
    required this.title,
    required this.status,
    required this.icon,
    this.subtitle,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
