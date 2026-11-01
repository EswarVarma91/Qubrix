import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';

/// Reusable adaptive button that works on mobile and tablet
class AdaptiveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final double? width;
  final IconData? icon;
  final Color? color;

  const AdaptiveButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.width,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;

    return SizedBox(
      width: width ?? (isTablet ? 200 : double.infinity),
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              child: _buildChild(),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              child: _buildChild(),
            ),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isOutlined ? (color ?? AppColors.primary) : AppColors.onPrimary,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    }

    return Text(label);
  }
}
