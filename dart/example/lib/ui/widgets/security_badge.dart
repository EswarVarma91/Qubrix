import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

/// Small security status badge for app bar
class SecurityBadge extends StatelessWidget {
  final bool isSecure;
  final VoidCallback? onTap;
  final bool showDetails;

  const SecurityBadge({
    super.key,
    required this.isSecure,
    this.onTap,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSecure 
                ? AppColors.success.withValue(0.1) 
                : AppColors.error.withValue(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSecure 
                  ? AppColors.success.withValue(0.3) 
                  : AppColors.error.withValue(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSecure ? Icons.shield : Icons.shield_outlined,
                size: 16,
                color: isSecure ? AppColors.success : AppColors.error,
              ),
              if (showDetails) ...[
                const SizedBox(width: 6),
                Text(
                  isSecure ? 'Secure' : 'At Risk',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isSecure ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Security status card for detail view
class SecurityStatusCard extends StatelessWidget {
  final bool isSecure;
  final String? details;
  final VoidCallback? onRefresh;
  final VoidCallback? onViewDetails;

  const SecurityStatusCard({
    super.key,
    required this.isSecure,
    this.details,
    this.onRefresh,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSecure 
              ? AppColors.success.withValue(0.3) 
              : AppColors.error.withValue(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  isSecure ? Icons.shield_success : Icons.shield_alert,
                  color: isSecure ? AppColors.success : AppColors.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  isSecure ? 'Security Verified' : 'Security Warning',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSecure ? AppColors.success : AppColors.error,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: onRefresh,
                  tooltip: 'Check security status',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Status description
            Text(
              isSecure
                  ? 'Your SDK installation is protected and verified.'
                  : 'Potential security issues detected. Please investigate.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            
            if (details != null && details!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                details!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ],
            
            if (onViewDetails != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Details'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact security indicator for list items
class SecurityIndicator extends StatelessWidget {
  final bool isSecure;
  final bool showLabel;

  const SecurityIndicator({
    super.key,
    required this.isSecure,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isSecure ? Icons.check_circle : Icons.warning_amber,
          size: 16,
          color: isSecure ? AppColors.success : AppColors.warning,
        ),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            isSecure ? 'Verified' : 'Unverified',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSecure ? AppColors.success : AppColors.warning,
                ),
          ),
        ],
      ],
    );
  }
}
