import 'package:flutter/material.dart';
import 'package:ai_sdk/ai_sdk.dart';
import '../../core/constants/app_strings.dart';

/// Reusable widget to show model download/loading progress
class ModelProgressIndicator extends StatelessWidget {
  final ModelProgress? progress;
  final bool isLoading;

  const ModelProgressIndicator({
    super.key,
    required this.progress,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && progress == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: progress != null ? progress!.percent : null,
          backgroundColor: _getProgressColor().withValue(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            _getProgressColor(),
          ),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),

        // Status text
        Text(
          _getStatusText(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _getProgressColor(),
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Color _getProgressColor() {
    if (progress == null) return AppColors.primary;

    switch (progress!.operation) {
      case ModelOperationType.downloading:
        return AppColors.downloadingColor;
      case ModelOperationType.verifying:
        return AppColors.primary;
      case ModelOperationType.loading:
        return AppColors.loadingColor;
      case ModelOperationType.initializing:
        return AppColors.success;
    }
  }

  String _getStatusText() {
    if (progress == null) return '';

    final operationName = progress!.operation.name.toUpperCase();
    final percent = (progress!.percent * 100).toStringAsFixed(0);
    final detail = progress!.detail ?? '';

    return '$operationName: $percent%${detail.isNotEmpty ? ' - $detail' : ''}';
  }
}

extension on Color {
  Color withValue(double opacity) {
    return withOpacity(opacity);
  }
}
