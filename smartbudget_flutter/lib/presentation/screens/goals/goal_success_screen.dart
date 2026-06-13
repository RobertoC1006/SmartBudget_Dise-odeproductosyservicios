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
import '../../../data/models/goal_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/header_background_painter.dart';
import '../../widgets/sb_button.dart';
import '../../widgets/sb_entrance_animation.dart';
import 'widgets/goal_category_icon.dart';
import 'widgets/goal_format.dart';

/// Pantalla 1D del flujo de metas: celebración al completar una meta.
/// Llega desde el aporte que cierra la meta (1B) con el delta real del
/// SmartScore. Muestra confetti, el logro (tiempo + puntos) y CTAs para
/// volver a la lista o crear otra meta.
class GoalSuccessScreen extends StatefulWidget {
  final GoalModel goal;

  /// Puntos reales que sumó el aporte que completó la meta.
  final int scoreDelta;

  const GoalSuccessScreen({
    super.key,
    required this.goal,
    this.scoreDelta = 0,
  });

  @override
  State<GoalSuccessScreen> createState() => _GoalSuccessScreenState();
}

class _GoalSuccessScreenState extends State<GoalSuccessScreen> {
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

  /// Nombre de pila del usuario para el saludo ("¡Felicidades, Roberto!").
  String get _firstName {
    final full = context.read<AuthProvider>().user?.nombre.trim() ?? '';
    if (full.isEmpty) return '';
    return full.split(RegExp(r'\s+')).first;
  }

  /// Tiempo que tomó alcanzar la meta + un subtítulo contextual.
  /// `value` p. ej. "10 meses" / "8 días"; `caption` p. ej. "Antes de lo
  /// esperado" cuando se cumplió antes de la fecha objetivo.
  ({String value, String caption}) get _logro {
    final now = DateTime.now();
    final created = widget.goal.createdAt;

    var months = (now.year - created.year) * 12 + (now.month - created.month);
    if (now.day < created.day) months -= 1;

    final String value;
    if (months >= 1) {
      value = months == 1 ? '1 mes' : '$months meses';
    } else {
      final days = math.max(1, now.difference(created).inDays);
      value = days == 1 ? '1 día' : '$days días';
    }

    final limite = widget.goal.fechaLimite;
    final caption = (limite != null && now.isBefore(limite))
        ? 'Antes de lo esperado'
        : '¡Meta cumplida!';

    return (value: value, caption: caption);
  }

  void _verMisMetas() => context.go('/goals');
  void _crearNuevaMeta() => context.go('/goals/create');

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final cat = resolveCategoria(goal.categoria, goal.nombre);
    final firstName = _firstName;
    final logro = _logro;

    return PopScope(
      // La meta ya está completada: el back regresa siempre a la lista.
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

                    // Hero: mochila con monedas (la misma ilustración del
                    // catálogo de logros). Aparece con un "pop" elástico.
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
                                LucideIcons.partyPopper,
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
                          ? '¡Felicidades!'
                          : '¡Felicidades, $firstName!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ).animateEntrance(delay: 100.ms),

                    const SizedBox(height: 6),

                    Text(
                      'Alcanzaste tu meta',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySecondary.copyWith(fontSize: 14),
                    ).animateEntrance(delay: 150.ms),

                    const SizedBox(height: AppSpacing.lg),

                    _buildGoalCard(goal, cat).animateEntrance(delay: 200.ms),

                    const SizedBox(height: AppSpacing.lg),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tu logro',
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
                              label: 'Tiempo logrado',
                              value: logro.value,
                              caption: logro.caption,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              label: 'SmartScore',
                              value: widget.scoreDelta > 0
                                  ? '+${widget.scoreDelta} pts'
                                  : '¡Logrado!',
                              caption: '¡Excelente trabajo!',
                              badge: const Icon(
                                LucideIcons.star,
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
                      label: 'Ver mis metas',
                      onPressed: _verMisMetas,
                      customColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ).animateEntrance(delay: 400.ms),

                    const SizedBox(height: 12),

                    SBButton.secondary(
                      label: 'Crear una nueva meta',
                      onPressed: _crearNuevaMeta,
                      customColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ).animateEntrance(delay: 450.ms),
                  ],
                ),
              ),

              // Emisores de confetti: dos cañones en las esquinas superiores
              // y una lluvia suave desde arriba (mismo patrón que el éxito de
              // gastos para mantener coherencia entre flujos).
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
            '¡Meta alcanzada! 🎉',
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
                      LucideIcons.checkCircle2,
                      size: 14,
                      color: AppColors.incomeGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Meta completada',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.incomeGreen,
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
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, 8, AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentGreenBorder, width: 1.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'La disciplina de hoy construye el mañana que sueñas. 🌱',
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
