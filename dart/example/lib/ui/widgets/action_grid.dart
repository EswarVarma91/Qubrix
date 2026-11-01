import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import 'adaptive_button.dart';

/// Adaptive grid of action buttons that works on mobile and tablet
class ActionGrid extends StatelessWidget {
  final List<ActionItem> actions;

  const ActionGrid({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;

    if (isTablet) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: actions.map((action) {
          return SizedBox(
            width: 180,
            child: _buildActionCard(context, action),
          );
        }).toList(),
      );
    }

    return Column(
      children: actions.map((action) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: _buildActionCard(context, action),
        );
      }).toList(),
    );
  }

  Widget _buildActionCard(BuildContext context, ActionItem action) {
    return Card(
      child: InkWell(
        onTap: action.isLoading ? null : action.onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                action.icon,
                size: 32,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                action.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              if (action.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  action.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (action.isLoading) ...[
                const SizedBox(height: 12),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Action item for the grid
class ActionItem {
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final String? description;
  final bool isLoading;

  const ActionItem({
    required this.label,
    this.onPressed,
    required this.icon,
    this.description,
    this.isLoading = false,
  });
}
