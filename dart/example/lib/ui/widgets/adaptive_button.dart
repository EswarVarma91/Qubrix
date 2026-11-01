import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AdaptiveButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final double? width;
  final Widget? trailing;
  
  const AdaptiveButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.width,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = isLoading || onPressed == null;
    
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: isDisabled ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: isDisabled ? AppColors.onSurfaceVariant : AppColors.primary,
          side: BorderSide(
            color: isDisabled ? AppColors.outline : AppColors.primary,
          ),
          minimumSize: const Size(88, 40),
        ),
      );
    }
    
    return ElevatedButton.icon(
      onPressed: isDisabled ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled ? AppColors.surfaceVariant : AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size(88, 40),
      ),
    );
  }
}
