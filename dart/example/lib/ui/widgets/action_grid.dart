import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ActionItem {
  final String label;
  final IconData icon;
  final String description;
  final VoidCallback? onPressed;
  final bool isLoading;
  
  const ActionItem({
    required this.label,
    required this.icon,
    required this.description,
    this.onPressed,
    this.isLoading = false,
  });
}

class ActionGrid extends StatelessWidget {
  final List<ActionItem> actions;
  
  const ActionGrid({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _ActionTile(action: action);
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final ActionItem action;
  
  const _ActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final isDisabled = action.isLoading || action.onPressed == null;
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: action.onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  action.icon,
                  color: isDisabled 
                      ? AppColors.onSurfaceVariant 
                      : AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                action.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDisabled 
                      ? AppColors.onSurfaceVariant 
                      : AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                action.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
