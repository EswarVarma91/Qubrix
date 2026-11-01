import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SecurityBadge extends StatelessWidget {
  final bool isSecure;
  final VoidCallback? onTap;
  
  const SecurityBadge({
    super.key,
    required this.isSecure,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSecure ? AppColors.successLight : AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSecure ? Icons.security : Icons.warning,
              color: isSecure ? AppColors.success : AppColors.error,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              isSecure ? 'Secure' : 'Warning',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSecure ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
