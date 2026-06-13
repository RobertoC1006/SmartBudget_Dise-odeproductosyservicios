import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/providers/goal_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/sb_entrance_animation.dart';
import '../../widgets/header_background_painter.dart';
import 'widgets/goal_category_icon.dart';
import 'widgets/goal_format.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  int _activeTab = 0; // 0 = Mis metas, 1 = Historial

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoalProvider>().loadGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final goalProvider = context.watch<GoalProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Stack(
          children: [
            // Curva superior suave (mismo fondo que el flujo de gastos)
            const Positioned.fill(
              child: CustomPaint(painter: HeaderBackgroundPainter()),
            ),
            RefreshIndicator(
              onRefresh: () => goalProvider.loadGoals(),
              color: AppColors.primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header (with avatar image and notification bell)
                    const AppHeader(),

                    const SizedBox(height: AppSpacing.md),

                    Text(
                      'Mis metas',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ).animateEntrance(delay: 0.ms),

                    const SizedBox(height: AppSpacing.lg),

                    // Card 1: Meta sugerida para ti (se conserva tal cual; su
                    // botón navega ahora a la pantalla de crear meta 1C)
                    _buildSuggestedGoalCard().animateEntrance(delay: 50.ms),

                    const SizedBox(height: AppSpacing.xl),

                    // Segmented Tab Selector
                    _buildTabSelector().animateEntrance(delay: 100.ms),

                    const SizedBox(height: AppSpacing.lg),

                    // Active List or Loading State
                    _buildGoalsList(goalProvider).animateEntrance(delay: 150.ms),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedGoalCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accentGreenSoft, AppColors.accentGreenLight],
        ),
        border: Border.all(color: AppColors.accentGreenBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Organic shape and plants background image behind piggy bank
          Positioned(
            right: 0,
            top: 5,
            bottom: 5,
            child: SizedBox(
              width: 140,
              height: 140,
              child: Image.asset(
                'assets/images/fondochanchito.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox();
                },
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge and Text
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F5E9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.lightbulb,
                              color: Color(0xFF2E7D32),
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Planifica tu futuro',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Define tus metas de ahorro',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Crea una meta de ahorro para alcanzar tus objetivos.',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => context.push('/goals/create'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF2E7D32,
                                ).withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            'Crear meta',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
          // Large floating piggy bank filling the space
          Positioned(
            right: -10,
            top: -12,
            bottom: -12,
            child: SizedBox(
              width: 155,
              child:
                  Image.asset(
                        'assets/images/piggy_bank_3d.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              LucideIcons.piggyBank,
                              color: AppColors.primaryGreen,
                              size: 40,
                            ),
                          );
                        },
                      )
                      .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                      )
                      .slideY(
                        begin: 0,
                        end: -0.05,
                        duration: 1800.ms,
                        curve: Curves.easeInOut,
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        children: [
          _buildTab(index: 0, label: 'Mis metas', icon: LucideIcons.target),
          _buildTab(index: 1, label: 'Historial', icon: LucideIcons.clock),
        ],
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final bool selected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE2F3DA) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? const Color(0xFF1B5E20)
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? const Color(0xFF1B5E20)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsList(GoalProvider goalProvider) {
    if (goalProvider.isLoading && goalProvider.goals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    final filteredGoals = goalProvider.goals.where((goal) {
      return _activeTab == 0 ? !goal.completada : goal.completada;
    }).toList();

    if (filteredGoals.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredGoals.length,
      itemBuilder: (context, index) {
        return _buildGoalCard(filteredGoals[index])
            .animate()
            .fade(duration: 350.ms, delay: (index * 60).ms)
            .slideY(
              begin: 0.08,
              end: 0.0,
              duration: 350.ms,
              curve: Curves.easeOutQuad,
            );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              _activeTab == 0 ? LucideIcons.target : LucideIcons.trophy,
              color: const Color(0xFF9CA3AF),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _activeTab == 0
                  ? 'No tienes metas activas registradas'
                  : 'Aún no has completado ninguna meta',
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(GoalModel goal) {
    final int progressPercent = (goal.progreso * 100).round().clamp(0, 100);
    final bool completed = goal.completada;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/goals/${goal.id}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: colorful 3D category icon
                GoalCategoryIcon(
                  category: resolveCategoria(goal.categoria, goal.nombre),
                  size: 58,
                ),
                const SizedBox(width: 12),
                // Right: content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + overflow menu
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.nombre,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildGoalMenu(goal),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Amount + percent
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        '${GoalFormat.money(goal.saldoAcumulado)} ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const TextSpan(text: 'de '),
                                  TextSpan(
                                    text: GoalFormat.money(goal.montoObjetivo),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$progressPercent%',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: completed
                                  ? AppColors.primaryGreen
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress bar (lime green from mockup)
                      ProgressBar(
                        progress: goal.progreso,
                        foregroundColor: const Color(0xFF8BC34A),
                        height: 6.0,
                      ),
                      const SizedBox(height: 10),
                      // Footer: faltante + meses restantes (or completed) + chevron
                      Row(
                        children: [
                          Expanded(
                            child: completed
                                ? Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.checkCircle,
                                        size: 13,
                                        color: AppColors.primaryGreen,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Meta completada',
                                        style: GoogleFonts.inter(
                                          color: AppColors.primaryGreen,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Faltan: ${GoalFormat.money(goal.faltante)}  •  ${GoalFormat.remainingLabel(goal.fechaLimite)}',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 18,
                            color: Color(0xFFB0B7C3),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalMenu(GoalModel goal) {
    return SizedBox(
      width: 28,
      height: 28,
      child: PopupMenuButton<String>(
        icon: const Icon(
          LucideIcons.moreVertical,
          size: 18,
          color: Color(0xFF9CA3AF),
        ),
        padding: EdgeInsets.zero,
        tooltip: 'Opciones',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: AppColors.surfaceWhite,
        onSelected: (value) {
          if (value == 'edit') {
            context.push('/goals/${goal.id}');
          } else if (value == 'delete') {
            _confirmDeleteGoal(context, goal);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const Icon(
                  LucideIcons.pencil,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Editar',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  LucideIcons.trash2,
                  size: 16,
                  color: AppColors.expenseRed.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 10),
                Text(
                  'Eliminar',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.expenseRed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGoal(BuildContext context, GoalModel goal) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '¿Eliminar meta?',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar la meta "${goal.nombre}"? El ahorro acumulado se devolverá a tu presupuesto.',
            style: AppTextStyles.bodySecondary,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final provider = context.read<GoalProvider>();
                final bool success = await provider.deleteGoal(goal.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Meta eliminada con éxito'
                            : provider.errorMessage ??
                                  'Error al eliminar la meta',
                      ),
                    ),
                  );
                }
              },
              child: Text(
                'Eliminar',
                style: GoogleFonts.inter(
                  color: AppColors.expenseRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
