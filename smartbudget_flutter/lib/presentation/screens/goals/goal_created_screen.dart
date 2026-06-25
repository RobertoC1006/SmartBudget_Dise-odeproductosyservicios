import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/header_background_painter.dart';
import '../../widgets/sb_button.dart';
import '../../widgets/sb_entrance_animation.dart';
import 'widgets/goal_category_icon.dart';
import 'widgets/goal_format.dart';

/// Pantalla 1C-success del flujo de metas: celebración al **crear** una meta.
/// Comparte el lenguaje visual de 1D (`GoalSuccessScreen`): confetti, hero con
/// "pop" elástico, tarjeta de la meta, tarjetas de plan (aporte sugerido +
/// plazo) y CTAs para empezar a ahorrar o volver a la lista.
class GoalCreatedScreen extends StatefulWidget {
  final GoalModel goal;

  const GoalCreatedScreen({super.key, required this.goal});

  @override
  State<GoalCreatedScreen> createState() => _GoalCreatedScreenState();
}

class _GoalCreatedScreenState extends State<GoalCreatedScreen> {
  late final ConfettiController _leftCannon;
  late final ConfettiController _rightCannon;
  late final ConfettiController _topRain;

  bool _confettiLaunched = false;

  static const List<Color> _confettiPalette = [
    AppColors.primaryGreen,
    AppColors.incomeGreen,
    AppColors.accentGreenSoft,
    Color(0xFFF59E0B), // dorado de las monedas
    Color(0xFFFBBF24),
    Color(0xFF38BDF8), // celeste de acento del confeti
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
    // Un solo disparo, omitido por completo si el sistema pide
    // animaciones reducidas (accesibilidad).
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

  /// Nombre de pila del usuario para el saludo ("¡Buen comienzo, Roberto!").
  String get _firstName {
    final full = context.read<AuthProvider>().user?.nombre.trim() ?? '';
    if (full.isEmpty) return '';
    return full.split(RegExp(r'\s+')).first;
  }

  /// Plan de la meta recién creada: aporte mensual sugerido + plazo.
  /// `suggested` es null cuando no hay fecha objetivo válida.
  ({double? suggested, int? months}) get _plan {
    final months = GoalFormat.monthsRemaining(widget.goal.fechaLimite);
    final hasDate = months != null && months > 0;
    final suggested = hasDate ? widget.goal.montoObjetivo / months : null;
    return (suggested: suggested, months: hasDate ? months : null);
  }

  void _empezarAAhorrar() => context.go('/goals/${widget.goal.id}');
  void _verMisMetas() => context.go('/goals');

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final cat = resolveCategoria(goal.categoria, goal.nombre);
    final firstName = _firstName;
    final plan = _plan;

    return PopScope(
      // La meta ya quedó creada: el back regresa siempre a la lista.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/goals');
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
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppHeader(),

                    _buildTopBar(),

                    const SizedBox(height: AppSpacing.sm),

                    // Hero: la mochila con monedas de la pantalla de éxito 1D
                    // (a pedido de Roberto). Aparece con un "pop" elástico y
                    // luego flota suavemente, igual que en 1D.
                    Center(
                      child: Image.asset(
                            'assets/images/meta_alcanzada.png',
                            width: 190,
                            height: 170,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox(
                              width: 190,
                              height: 170,
                              child: Icon(
                                LucideIcons.target,
                                color: AppColors.primaryGreen,
                                size: 72,
                              ),
                            ),
                          )
                          .animate()
                          .scale(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1, 1),
                            duration: 700.ms,
                            curve: Curves.elasticOut,
                          )
                          .fade(duration: 250.ms)
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .slideY(
                            begin: 0,
                            end: -0.05,
                            duration: 2000.ms,
                            curve: Curves.easeInOut,
                          ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      firstName.isEmpty
                          ? '¡Buen comienzo!'
                          : '¡Buen comienzo, $firstName!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ).animateEntrance(delay: 100.ms),

                    const SizedBox(height: 6),

                    Text(
                      'Creaste una nueva meta de ahorro',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySecondary.copyWith(fontSize: 14),
                    ).animateEntrance(delay: 150.ms),

                    const SizedBox(height: AppSpacing.lg),

                    _buildGoalCard(goal, cat).animateEntrance(delay: 200.ms),

                    const SizedBox(height: AppSpacing.lg),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tu plan',
                        style: AppTextStyles.heading3
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ).animateEntrance(delay: 250.ms),

                    const SizedBox(height: AppSpacing.sm + 4),

                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              label: 'Aporte sugerido',
                              value: plan.suggested != null
                                  ? GoalFormat.money(plan.suggested!)
                                  : 'Tú decides',
                              caption: plan.suggested != null
                                  ? 'al mes para lograrla'
                                  : 'Define una fecha objetivo',
                              badge: const Icon(
                                LucideIcons.trendingUp,
                                size: 18,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              label: 'Plazo',
                              value: plan.months != null
                                  ? (plan.months == 1
                                      ? '1 mes'
                                      : '${plan.months} meses')
                                  : 'Sin fecha',
                              caption: _targetCaption(goal.fechaLimite),
                              badge: const Icon(
                                LucideIcons.calendarCheck,
                                size: 18,
                                color: AppColors.warningAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animateEntrance(delay: 300.ms),

                    const SizedBox(height: AppSpacing.md),

                    _buildQuoteCard().animateEntrance(delay: 350.ms),

                    const SizedBox(height: AppSpacing.lg),

                    SBButton.primary(
                      label: 'Empezar a ahorrar',
                      onPressed: _empezarAAhorrar,
                      customColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ).animateEntrance(delay: 400.ms),

                    const SizedBox(height: 12),

                    SBButton.secondary(
                      label: 'Ver mis metas',
                      onPressed: _verMisMetas,
                      customColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ).animateEntrance(delay: 450.ms),
                  ],
                ),
              ),

              // Emisores de confetti: dos cañones en las esquinas superiores y
              // una lluvia suave desde arriba (mismo patrón que 1D y el éxito
              // de gastos, para mantener coherencia entre flujos).
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

  // ---------------------------------------------------------------------
  // Secciones
  // ---------------------------------------------------------------------

  /// Subtítulo de la tarjeta de plazo: la fecha objetivo formateada ("Dic 2026").
  String _targetCaption(DateTime? fecha) {
    if (fecha == null) return 'Agrega una fecha';
    final label = DateFormat('MMM yyyy', 'es').format(fecha);
    // Mayúscula inicial del mes ("dic. 2026" → "Dic. 2026").
    return label.isEmpty
        ? 'Fecha objetivo'
        : '${label[0].toUpperCase()}${label.substring(1)}';
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            LucideIcons.arrowLeft,
            color: AppColors.textPrimary,
            size: 22,
          ),
          tooltip: 'Volver',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          onPressed: _verMisMetas,
        ),
        Expanded(
          child: Text(
            '¡Meta creada! 🎉',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading2.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // Espaciador simétrico (ancho del IconButton) para centrar el título.
        const SizedBox(width: 40),
      ],
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Row(
        children: [
          GoalCategoryIcon(category: cat, size: 60),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  goal.nombre,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  GoalFormat.money(goal.montoObjetivo),
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.target,
                      size: 14,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Nueva meta · ${cat.label}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String caption,
    Widget? badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, 8, AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentGreenBorder, width: 1.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Cada gran meta empieza con el primer paso. ¡Hoy diste el tuyo! 🌱',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Image.asset(
            'assets/images/disciplina.png',
            width: 76,
            height: 76,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              LucideIcons.sprout,
              size: 40,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}
