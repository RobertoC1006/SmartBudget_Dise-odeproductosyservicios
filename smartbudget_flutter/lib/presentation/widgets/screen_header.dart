import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class ScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (actions != null) ...[
            const SizedBox(width: AppSpacing.md),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80.0);
}
