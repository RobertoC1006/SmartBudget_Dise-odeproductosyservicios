import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get amountDisplay => GoogleFonts.inter(
        fontSize: 32.0,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle get heading1 => GoogleFonts.inter(
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle get heading2 => GoogleFonts.inter(
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get heading3 => GoogleFonts.inter(
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16.0,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySecondary => GoogleFonts.inter(
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 16.0,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12.0,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  static TextStyle get captionBold => GoogleFonts.inter(
        fontSize: 12.0,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );
}
