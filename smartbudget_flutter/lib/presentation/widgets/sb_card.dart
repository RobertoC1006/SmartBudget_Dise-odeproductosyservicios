import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class SBCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderSide? border;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? leftHighlightColor;
  final VoidCallback? onTap;

  const SBCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.border,
    this.width,
    this.height,
    this.borderRadius = AppSpacing.radiusXl,
    this.leftHighlightColor,
    this.onTap,
  });

  factory SBCard.outlined({
    required Widget child,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    Color borderColor = AppColors.dividerGray,
    double borderWidth = 1.0,
    double borderRadius = AppSpacing.radiusXl,
    VoidCallback? onTap,
  }) {
    return SBCard(
      padding: padding,
      backgroundColor: backgroundColor,
      border: BorderSide(color: borderColor, width: borderWidth),
      borderRadius: borderRadius,
      onTap: onTap,
      child: child,
    );
  }

  factory SBCard.highlighted({
    required Widget child,
    required Color highlightColor,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    double borderRadius = AppSpacing.radiusXl,
    VoidCallback? onTap,
  }) {
    return SBCard(
      padding: padding,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      leftHighlightColor: highlightColor,
      onTap: onTap,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget cardChild = child;
    if (padding != null) {
      cardChild = Padding(padding: padding!, child: cardChild);
    }

    final decoration = BoxDecoration(
      color: backgroundColor ?? AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(borderRadius),
      border: leftHighlightColor == null
          ? Border.fromBorderSide(
              border ?? const BorderSide(color: AppColors.dividerGray, width: 1.0),
            )
          : null,
    );

    Widget mainWidget = leftHighlightColor != null
        ? Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: leftHighlightColor!, width: 4.0),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.dividerGray, width: 1.0),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(borderRadius),
                  bottomRight: Radius.circular(borderRadius),
                ),
              ),
              child: cardChild,
            ),
          )
        : Container(
            decoration: decoration,
            child: cardChild,
          );

    if (onTap != null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: mainWidget,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: mainWidget,
    );
  }
}
