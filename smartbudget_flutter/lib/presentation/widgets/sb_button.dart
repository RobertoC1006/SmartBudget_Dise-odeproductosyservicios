import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

enum SBButtonVariant {
  primary,
  secondary,
  text,
}

class SBButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final SBButtonVariant variant;
  final IconData? icon;
  final Color? customColor;
  final EdgeInsetsGeometry? padding;

  const SBButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.variant = SBButtonVariant.primary,
    this.icon,
    this.customColor,
    this.padding,
  });

  const SBButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.customColor,
    this.padding,
  }) : variant = SBButtonVariant.primary;

  const SBButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.customColor,
    this.padding,
  }) : variant = SBButtonVariant.secondary;

  const SBButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.customColor,
    this.padding,
  }) : variant = SBButtonVariant.text;

  @override
  Widget build(BuildContext context) {
    final buttonColor = customColor ?? AppColors.primaryGreen;

    Widget buttonChild;
    if (isLoading) {
      buttonChild = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == SBButtonVariant.primary ? AppColors.surfaceWhite : buttonColor,
          ),
        ),
      );
    } else {
      buttonChild = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: variant == SBButtonVariant.primary
                  ? AppColors.surfaceWhite
                  : buttonColor,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: variant == SBButtonVariant.primary
                  ? AppColors.surfaceWhite
                  : buttonColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    ButtonStyle style;
    final paddingValue = padding ?? const EdgeInsets.symmetric(vertical: AppSpacing.md);
    
    switch (variant) {
      case SBButtonVariant.primary:
        style = ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          disabledBackgroundColor: buttonColor.withValues(alpha: 0.6),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
          ),
          elevation: 0,
          padding: paddingValue,
        );
        break;
      case SBButtonVariant.secondary:
        style = OutlinedButton.styleFrom(
          side: BorderSide(color: buttonColor, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
          ),
          padding: paddingValue,
        );
        break;
      case SBButtonVariant.text:
        style = TextButton.styleFrom(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
          ),
          padding: paddingValue,
        );
        break;
    }

    Widget button;
    if (variant == SBButtonVariant.primary) {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: buttonChild,
      );
    } else if (variant == SBButtonVariant.secondary) {
      button = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: buttonChild,
      );
    } else {
      button = TextButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: buttonChild,
      );
    }

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}
