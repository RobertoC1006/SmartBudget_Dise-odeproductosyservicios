import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Verde principal (botones, acentos, navbar activo)
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFFE8F5E9);   // Fondos suaves, badges
  static const Color primaryDark = Color(0xFF1B5E20);    // Textos verdes destacados

  // Neutros
  static const Color backgroundWhite = Color(0xFFF7FCF6);   // Fondo general soft green de la app
  static const Color surfaceWhite = Color(0xFFFFFFFF);      // Cards
  static const Color textPrimary = Color(0xFF1A1A2E);       // Texto principal
  static const Color textSecondary = Color(0xFF6B7280);     // Texto secundario
  static const Color dividerGray = Color(0xFFE5E7EB);       // Separadores

  // Semánticos
  static const Color expenseRed = Color(0xFFDC2626);        // Gastos
  static const Color incomeGreen = Color(0xFF16A34A);       // Ingresos (diferente al primary)
  static const Color warningAmber = Color(0xFFF59E0B);      // Alertas

  // Reutilizables del rediseño minimalista
  static const Color accentGreenSoft = Color(0xFFE2F3DA);   // Verde pastel suave (izquierda del degradado)
  static const Color accentGreenLight = Color(0xFFFAFEF9);  // Casi blanco verde (derecha del degradado)
  static const Color accentGreenBorder = Color(0xFFD8ECD0); // Borde verde oliva suave
  static const Color textGreenHighlight = Color(0xFF4C8C2B); // Texto verde destacado de la cabecera
}
