import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/providers/budget_provider.dart';
import '../../../data/services/expense_service.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/header_background_painter.dart';
import '../../widgets/sb_entrance_animation.dart';

/// Pantalla 2B del flujo de gastos: éxito compartido por las ramas
/// manual y OCR. Muestra confetti, el resumen del gasto guardado y el
/// impacto inmediato (SmartScore + presupuesto).
class ExpenseSuccessScreen extends StatefulWidget {
  final ExpenseModel expense;
  final int? prevScore;
  final int? newScore;

  const ExpenseSuccessScreen({
    super.key,
    required this.expense,
    this.prevScore,
    this.newScore,
  });

  @override
  State<ExpenseSuccessScreen> createState() => _ExpenseSuccessScreenState();
}

class _ExpenseSuccessScreenState extends State<ExpenseSuccessScreen> {
  late final ConfettiController _leftCannon;
  late final ConfettiController _rightCannon;
  late final ConfettiController _topRain;

  bool _confettiLaunched = false;

  /// % del presupuesto total consumido por la categoría del gasto.
  /// Null mientras carga; si la carga falla se usa el % global.
  double? _categoryPercent;
  bool _categoryLoadFailed = false;

  static const List<Color> _confettiPalette = [
    AppColors.primaryGreen,
    AppColors.incomeGreen,
    AppColors.accentGreenSoft,
    Color(0xFFF59E0B), // dorado de las monedas
    Color(0xFFFBBF24),
  ];

  @override
  void initState() {
    super.initState();
    _leftCannon =
        ConfettiController(duration: const Duration(milliseconds: 1800));
    _rightCannon =
        ConfettiController(duration: const Duration(milliseconds: 1800));
    _topRain =
        ConfettiController(duration: const Duration(milliseconds: 1600));
    _loadCategoryImpact();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Un solo disparo, omitido por completo si el sistema pide
    // animaciones reducidas.
    if (!_confettiLaunched) {
      _confettiLaunched = true;
      final reduceMotion = MediaQuery.of(context).disableAnimations;
      if (!reduceMotion) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _leftCannon.play();
          _rightCannon.play();
          _topRain.play();
        });
      }
    }
  }

  @override
  void dispose() {
    _leftCannon.dispose();
    _rightCannon.dispose();
    _topRain.dispose();
    super.dispose();
  }

  Future<void> _loadCategoryImpact() async {
    try {
      final expenses = await ExpenseService().getExpenses();
      if (!mounted) return;
      final budget = context.read<BudgetProvider>().currentBudget;
      final total =
          (budget?.montoBase ?? 0) + (budget?.ingresosAdicionales ?? 0);
      if (total <= 0) {
        setState(() => _categoryLoadFailed = true);
        return;
      }
      final catTotal = expenses
          .where((e) => e.categoria == widget.expense.categoria)
          .fold<double>(0, (sum, e) => sum + e.monto);
      setState(() => _categoryPercent = (catTotal / total * 100).clamp(0, 100));
    } catch (_) {
      if (mounted) setState(() => _categoryLoadFailed = true);
    }
  }

  String _translateCategory(CategoriaGasto category) {
    switch (category) {
      case CategoriaGasto.comida:
        return 'Comida';
      case CategoriaGasto.transporte:
        return 'Transporte';
      case CategoriaGasto.ocio:
        return 'Ocio';
      case CategoriaGasto.salud:
        return 'Salud';
      case CategoriaGasto.educacion:
        return 'Educación';
      case CategoriaGasto.ropa:
        return 'Ropa';
      case CategoriaGasto.hogar:
        return 'Hogar';
      case CategoriaGasto.tecnologia:
        return 'Tecnología';
      case CategoriaGasto.viajes:
        return 'Viajes';
      case CategoriaGasto.otros:
        return 'Otros';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // El gasto ya se guardó: back nunca regresa al formulario.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/expenses');
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        bottomNavigationBar: const BottomNavBar(currentIndex: 1),
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: HeaderBackgroundPainter()),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child:
                          Image.asset(
                                'assets/images/gasto_registrado.png',
                                width: 170,
                                height: 160,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox(
                                    width: 170,
                                    height: 160,
                                    child: Icon(
                                      LucideIcons.checkCircle2,
                                      color: AppColors.primaryGreen,
                                      size: 72,
                                    ),
                                  );
                                },
                              )
                              .animate()
                              .scale(
                                begin: const Offset(0.5, 0.5),
                                end: const Offset(1, 1),
                                duration: 700.ms,
                                curve: Curves.elasticOut,
                              )
                              .fade(duration: 250.ms),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Text(
                      '¡Gasto registrado!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ).animateEntrance(delay: 100.ms),

                    const SizedBox(height: 6),

                    Text(
                      'Tu gasto ha sido agregado correctamente.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySecondary.copyWith(
                        fontSize: 13.5,
                      ),
                    ).animateEntrance(delay: 150.ms),

                    const SizedBox(height: AppSpacing.lg),

                    _buildSummaryCard().animateEntrance(delay: 200.ms),

                    const SizedBox(height: AppSpacing.lg),

                    Text(
                      'Impacto inmediato',
                      style: AppTextStyles.heading3.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ).animateEntrance(delay: 250.ms),

                    const SizedBox(height: AppSpacing.sm + 4),

                    _buildSmartScoreCard().animateEntrance(delay: 300.ms),

                    const SizedBox(height: 12),

                    _buildBudgetCard().animateEntrance(delay: 350.ms),

                    const SizedBox(height: AppSpacing.lg),

                    _buildPrimaryButton(
                      label: 'Agregar otro gasto',
                      onTap: () => context.go('/expenses'),
                    ).animateEntrance(delay: 400.ms),

                    const SizedBox(height: 12),

                    _buildOutlineButton(
                      label: 'Ir al Dashboard',
                      onTap: () => context.go('/'),
                    ).animateEntrance(delay: 450.ms),
                  ],
                ),
              ),

              // Emisores de confetti: dos cañones en las esquinas
              // superiores y una lluvia suave desde arriba.
              Align(
                alignment: Alignment.topLeft,
                child: ConfettiWidget(
                  confettiController: _leftCannon,
                  blastDirection: math.pi / 3, // hacia abajo-derecha
                  blastDirectionality: BlastDirectionality.directional,
                  emissionFrequency: 0.05,
                  numberOfParticles: 12,
                  maxBlastForce: 22,
                  minBlastForce: 9,
                  gravity: 0.25,
                  shouldLoop: false,
                  colors: _confettiPalette,
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: ConfettiWidget(
                  confettiController: _rightCannon,
                  blastDirection: 2 * math.pi / 3, // hacia abajo-izquierda
                  blastDirectionality: BlastDirectionality.directional,
                  emissionFrequency: 0.05,
                  numberOfParticles: 12,
                  maxBlastForce: 22,
                  minBlastForce: 9,
                  gravity: 0.25,
                  shouldLoop: false,
                  colors: _confettiPalette,
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _topRain,
                  blastDirection: math.pi / 2, // recto hacia abajo
                  blastDirectionality: BlastDirectionality.directional,
                  emissionFrequency: 0.04,
                  numberOfParticles: 6,
                  maxBlastForce: 10,
                  minBlastForce: 4,
                  gravity: 0.18,
                  shouldLoop: false,
                  colors: _confettiPalette,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Tarjetas
  // ---------------------------------------------------------------------

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  Widget _buildSummaryCard() {
    final expense = widget.expense;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Row(
        children: [
          CategoryIcon(category: expense.categoria, size: 40, iconSize: 17),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _translateCategory(expense.categoria),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (expense.descripcion != null &&
                    expense.descripcion!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    expense.descripcion!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'S/ ${expense.monto.toStringAsFixed(2)}',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartScoreCard() {
    final int score =
        widget.newScore ?? context.watch<BudgetProvider>().currentScore;
    final int? delta = (widget.newScore != null && widget.prevScore != null)
        ? widget.newScore! - widget.prevScore!
        : null;

    final String headline;
    final String subtitle;
    final Color deltaColor;
    if (delta != null && delta > 0) {
      headline = '+$delta pts';
      subtitle = '¡Buen trabajo! Vas por buen camino.';
      deltaColor = AppColors.incomeGreen;
    } else if (delta != null && delta < 0) {
      headline = '$delta pts';
      subtitle = 'Sigue registrando para mejorar tu score.';
      deltaColor = AppColors.warningAmber;
    } else {
      headline = '$score pts';
      subtitle = 'Vas por buen camino.';
      deltaColor = AppColors.primaryGreen;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Row(
        children: [
          _PercentRing(
            percent: score.toDouble(),
            label: '$score',
            color: AppColors.primaryGreen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SmartScore',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            headline,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: deltaColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard() {
    final budget = context.watch<BudgetProvider>().currentBudget;
    final double saldo = budget?.saldoDisponible ?? 0;
    final double total =
        (budget?.montoBase ?? 0) + (budget?.ingresosAdicionales ?? 0);
    final double globalPercent =
        total > 0 ? ((budget?.totalGastado ?? 0) / total * 100).clamp(0, 100) : 0;

    final bool useCategory = _categoryPercent != null;
    final double percent =
        useCategory ? _categoryPercent! : globalPercent;
    final String title = useCategory
        ? 'Presupuesto · ${_translateCategory(widget.expense.categoria)}'
        : 'Presupuesto mensual';

    final Color ringColor = percent > 85
        ? AppColors.expenseRed
        : percent > 60
            ? AppColors.warningAmber
            : AppColors.primaryGreen;

    final bool stillLoading = !useCategory && !_categoryLoadFailed;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Row(
        children: [
          stillLoading
              ? const SizedBox(
                  width: 48,
                  height: 48,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                )
              : _PercentRing(
                  percent: percent,
                  label: '${percent.round()}%',
                  color: ringColor,
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stillLoading
                      ? 'Calculando impacto...'
                      : '${percent.round()}% utilizado · Te quedan '
                          'S/ ${saldo.toStringAsFixed(2)} de tu '
                          'presupuesto mensual.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Botones (52dp, radio 16 — mismo sistema que el formulario 2A)
  // ---------------------------------------------------------------------

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surfaceWhite,
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Anillo pequeño de porcentaje para las tarjetas de impacto.
class _PercentRing extends StatelessWidget {
  final double percent; // 0..100
  final String label;
  final Color color;

  const _PercentRing({
    required this.percent,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(48, 48),
            painter: _PercentRingPainter(
              percent: percent,
              color: color,
              backgroundColor: AppColors.dividerGray.withValues(alpha: 0.5),
            ),
          ),
          Text(
            label,
            style: AppTextStyles.captionBold.copyWith(
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PercentRingPainter extends CustomPainter {
  final double percent;
  final Color color;
  final Color backgroundColor;

  _PercentRingPainter({
    required this.percent,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 4.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        math.min(size.width / 2, size.height / 2) - strokeWidth / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (percent / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PercentRingPainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
