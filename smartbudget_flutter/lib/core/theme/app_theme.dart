import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryGreen,
      scaffoldBackgroundColor: AppColors.backgroundWhite,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryGreen,
        secondary: AppColors.primaryGreen,
        surface: AppColors.surfaceWhite,
        error: AppColors.expenseRed,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusLg)),
          side: BorderSide(color: AppColors.dividerGray, width: 1.0),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerGray,
        thickness: 1.0,
        space: 1.0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.surfaceWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
          ),
          textStyle: AppTextStyles.label.copyWith(color: AppColors.surfaceWhite),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
          borderSide: BorderSide(color: AppColors.dividerGray, width: 1.0),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
          borderSide: BorderSide(color: AppColors.dividerGray, width: 1.0),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
          borderSide: BorderSide(color: AppColors.expenseRed, width: 1.0),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
          borderSide: BorderSide(color: AppColors.expenseRed, width: 1.5),
        ),
        hintStyle: AppTextStyles.bodySecondary,
        labelStyle: AppTextStyles.bodySecondary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceWhite,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
