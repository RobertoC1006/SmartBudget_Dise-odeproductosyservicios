import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/app_header.dart';
import '../../widgets/sb_entrance_animation.dart';
import '../../widgets/header_background_painter.dart';

/// Pantalla 1A del flujo de gastos: hub de decisión
/// "¿Cómo quieres agregar tu gasto?" con dos caminos:
/// escanear boleta con OCR o registro manual.
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  void _goToScan() => context.push('/expenses/scan');

  void _goToManual() => context.push('/expenses/add');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: const CustomPaint(
                painter: HeaderBackgroundPainter(),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppHeader(),

                  const SizedBox(height: AppSpacing.md),

                  Text(
                    '¿Cómo quieres\nagregar tu gasto?',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ).animateEntrance(),

                  const SizedBox(height: AppSpacing.lg),

                  _buildOcrCard(context).animateEntrance(delay: 100.ms),

                  const SizedBox(height: AppSpacing.lg),

                  _buildManualCard(context).animateEntrance(delay: 200.ms),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Tarjeta 1: Escanear boleta con OCR
  // ---------------------------------------------------------------------
  Widget _buildOcrCard(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Escanear boleta con OCR. Extrae monto, fecha, categoría y '
          'descripción automáticamente.',
      child: _PressableCard(
        onTap: _goToScan,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.accentGreenSoft, AppColors.accentGreenLight],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.accentGreenBorder, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Escanear boleta\ncon OCR',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Extrae automáticamente:',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _CheckItem(label: 'Monto'),
                        const SizedBox(height: 10),
                        const _CheckItem(label: 'Fecha'),
                        const SizedBox(height: 10),
                        const _CheckItem(label: 'Categoría'),
                        const SizedBox(height: 10),
                        const _CheckItem(label: 'Descripción'),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Image.asset(
                    'assets/images/ocr.png',
                    width: 148,
                    height: 168,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(
                        width: 148,
                        height: 168,
                        child: Icon(
                          LucideIcons.scanLine,
                          color: AppColors.primaryGreen,
                          size: 48,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _PillButton.primary(
                label: 'Escanear ahora',
                icon: LucideIcons.camera,
                onTap: _goToScan,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Tarjeta 2: Registro manual
  // ---------------------------------------------------------------------
  Widget _buildManualCard(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Registro manual. Agrega tu gasto manualmente en menos de '
          '10 segundos.',
      child: _PressableCard(
        onTap: _goToManual,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.primaryLight, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registro manual',
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Agrega tu gasto manualmente en menos de 10 segundos.',
                      style: AppTextStyles.bodySecondary.copyWith(
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Image.asset(
                    'assets/images/wallet_3d.png',
                    width: 112,
                    height: 104,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(
                        width: 112,
                        height: 104,
                        child: Icon(
                          LucideIcons.wallet,
                          color: AppColors.primaryGreen,
                          size: 44,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _PillButton.outline(
                label: 'Registrar manualmente',
                trailingIcon: LucideIcons.chevronRight,
                onTap: _goToManual,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de beneficio con check verde (checklist de la tarjeta OCR).
class _CheckItem extends StatelessWidget {
  final String label;

  const _CheckItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          LucideIcons.check,
          color: AppColors.primaryGreen,
          size: 16,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Envoltorio tocable con feedback de presión (scale 0.98) que no
/// desplaza el layout circundante.
class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableCard({required this.child, required this.onTap});

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Botón pill (radio completo) del mockup 1A. Variante primaria (verde
/// sólido) y outline (blanco con borde).
class _PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _PillButton.primary({
    required this.label,
    required this.onTap,
    this.icon,
  })  : trailingIcon = null,
        isPrimary = true;

  const _PillButton.outline({
    required this.label,
    required this.onTap,
    this.trailingIcon,
  })  : icon = null,
        isPrimary = false;

  @override
  Widget build(BuildContext context) {
    final Color foreground =
        isPrimary ? AppColors.surfaceWhite : AppColors.textPrimary;

    return Material(
      color: isPrimary ? AppColors.primaryGreen : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
            border: isPrimary
                ? null
                : Border.all(color: AppColors.dividerGray, width: 1.2),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: foreground, size: 18),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(trailingIcon, color: foreground, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
