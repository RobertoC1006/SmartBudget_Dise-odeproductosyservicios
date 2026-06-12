import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class ProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color? foregroundColor;
  final bool useGoalColoring;

  const ProgressBar({
    super.key,
    required this.progress,
    this.height = 8.0,
    this.foregroundColor,
    this.useGoalColoring = false,
  });

  @override
  Widget build(BuildContext context) {
    final double clampedProgress = progress.clamp(0.0, 1.0);

    Color activeColor;
    if (foregroundColor != null) {
      activeColor = foregroundColor!;
    } else {
      if (useGoalColoring) {
        if (clampedProgress >= 0.7) {
          activeColor = AppColors.incomeGreen;
        } else if (clampedProgress >= 0.3) {
          activeColor = AppColors.warningAmber;
        } else {
          activeColor = AppColors.expenseRed;
        }
      } else {
        if (clampedProgress >= 0.8) {
          activeColor = AppColors.expenseRed;
        } else if (clampedProgress >= 0.5) {
          activeColor = AppColors.warningAmber;
        } else {
          activeColor = AppColors.primaryGreen;
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final targetWidth = maxWidth * clampedProgress;

        return Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.dividerGray,
            borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
          ),
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            width: targetWidth,
            height: height,
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
            ),
          ),
        );
      },
    );
  }
}
