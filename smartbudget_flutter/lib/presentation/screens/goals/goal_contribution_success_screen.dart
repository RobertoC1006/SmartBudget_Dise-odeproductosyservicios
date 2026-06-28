import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/goal_model.dart';
import '../../widgets/app_header.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/header_background_painter.dart';
import '../../widgets/sb_button.dart';
import '../../widgets/sb_entrance_animation.dart';
import 'widgets/goal_category_icon.dart';
import 'widgets/goal_format.dart';

/// ③ del flujo de aporte a meta: celebración de un aporte realizado (que NO
/// completó la meta; los que completan van a 1D "¡Meta alcanzada!"). Muestra
/// confetti, la meta actualizada, el aporte y el impacto real en el SmartScore.
class GoalContributionSuccessScreen extends StatefulWidget {
  const GoalContributionSuccessScreen({
    super.key,
    required this.goal,
    required this.monto,
    required this.fecha,
    this.scoreDelta = 0,
  });

  /// Meta ya actualizada (saldo/progreso al día).
  final GoalModel goal;
  final double monto;
  final DateTime fecha;

  /// Puntos reales que sumó este aporte al SmartScore.
  final int scoreDelta;

  @override
  State<GoalContributionSuccessScreen> createState() =>
      _GoalContributionSuccessScreenState();
}

class _GoalContributionSuccessScreenState
    extends State<GoalContributionSuccessScreen> {
  late final ConfettiController _leftCannon;
  late final ConfettiController _rightCannon;
  late final ConfettiController _topRain;

  bool _confettiLaunched = false;

  static const List<Color> _confettiPalette = [
    AppColors.primaryGreen,
    AppColors.incomeGreen,
    AppColors.accentGreenSoft,
    Color(0xFFF59E0B),
    Color(0xFFFBBF24),
    Color(0xFF38BDF8),
  ];

  @override
  void initState() {
    super.initState();
    _leftCannon =
        ConfettiController(duration: const Duration(milliseconds: 1800));
    _rightCannon =
        ConfettiController(duration: const Duration(milliseconds: 1800));
    _topRain = ConfettiController(duration: const Duration(milliseconds: 1600));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

  void _verDetalle() => context.go('/goals/${widget.goal.id}');
  void _irAlInicio() => context.go('/');

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final cat = resolveCategoria(goal.categoria, goal.nombre);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _verDetalle();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        bottomNavigationBar: const BottomNavBar(currentIndex: 2),
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: HeaderBackgroundPainter()),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppHeader(),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.arrowLeft,
                              color: AppColors.textPrimary, size: 22),
                          tooltip: 'Volver',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          onPressed: _verDetalle,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Hero: jar con check (reusa la ilustración de éxito de
                    // gastos; swap trivial a un asset propio de aporte).
                    Center(
                      child: Image.asset(
                        'assets/images/gasto_registrado.png',
                        width: 170,
                        height: 160,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          LucideIcons.checkCircle2,
                          color: AppColors.primaryGreen,
                          size: 72,
                        ),
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
                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      '¡Aporte realizado!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ).animateEntrance(delay: 100.ms),
                    const SizedBox(height: 6),
                    Text(
                      'Has sumado a tu meta',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySecondary.copyWith(fontSize: 14),
                    ).animateEntrance(delay: 150.ms),
                    const SizedBox(height: AppSpacing.lg),

                    _buildGoalCard(goal, cat).animateEntrance(delay: 200.ms),
                    const SizedBox(height: AppSpacing.md),

                    _buildAporteCard().animateEntrance(delay: 250.ms),
                    const SizedBox(height: AppSpacing.md),

                    _buildScoreCard().animateEntrance(delay: 300.ms),
                    const SizedBox(height: AppSpacing.lg),

                    SBButton.primary(
                      label: 'Ver detalle de la meta',
                      onPressed: _verDetalle,
                      customColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ).animateEntrance(delay: 360.ms),
                    const SizedBox(height: 12),
                    SBButton.secondary(
                      label: 'Ir al inicio',
                      onPressed: _irAlInicio,
                      customColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ).animateEntrance(delay: 410.ms),
                  ],
                ),
              ),

              // Confetti de un disparo (3 emisores, mismo patrón que 1D/2B).
              Align(
                alignment: Alignment.topLeft,
                child: ConfettiWidget(
                  confettiController: _leftCannon,
                  blastDirection: math.pi / 3,
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
                  blastDirection: 2 * math.pi / 3,
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
                  blastDirection: math.pi / 2,
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

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerGray, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  Widget _buildGoalCard(GoalModel goal, MetaCategoria cat) {
    final pct = (goal.progreso * 100).round();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              GoalCategoryIcon(category: cat, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      goal.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      GoalFormat.money(goal.saldoAcumulado),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$pct% completado',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: goal.progreso,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAporteCard() {
    final fechaStr =
        DateFormat("dd 'de' MMMM 'de' yyyy", 'es').format(widget.fecha);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu aporte',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            GoalFormat.money(widget.monto),
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            fechaStr,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    final delta = widget.scoreDelta;
    final String deltaText;
    final Color deltaColor;
    if (delta > 0) {
      deltaText = '+$delta pts';
      deltaColor = AppColors.incomeGreen;
    } else if (delta < 0) {
      deltaText = '$delta pts';
      deltaColor = AppColors.expenseRed;
    } else {
      deltaText = 'Aporte sumado';
      deltaColor = AppColors.textSecondary;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Impacto en tu SmartScore',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  deltaText,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: deltaColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '¡Sigue así!',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.warningAmber.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.star,
                size: 24, color: AppColors.warningAmber),
          ),
        ],
      ),
    );
  }
}
