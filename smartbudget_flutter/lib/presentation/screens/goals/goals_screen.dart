import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/providers/goal_provider.dart';
import '../../../data/providers/budget_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/sb_button.dart';
import '../../widgets/sb_entrance_animation.dart';

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
            // Soft waving curves background matching login style
            Positioned.fill(
              child: CustomPaint(painter: _GoalsBackgroundPainter()),
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

                    // Card 1: Meta sugerida para ti (premium gradients + geometries + floating animation)
                    _buildSuggestedGoalCard().animateEntrance(delay: 50.ms),

                    const SizedBox(height: AppSpacing.xl),

                    // Segmented Tab Selector
                    _buildTabSelector().animateEntrance(delay: 100.ms),

                    const SizedBox(height: AppSpacing.lg),

                    // Active List or Loading State
                    _buildGoalsList(
                      goalProvider,
                    ).animateEntrance(delay: 150.ms),

                    const SizedBox(height: AppSpacing.xl),

                    // Summary Section
                    _buildGoalsSummary(
                      goalProvider,
                    ).animateEntrance(delay: 200.ms),

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
                        onTap: () => _showCreateGoalDialog(context),
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
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeTab = 0;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 0
                      ? const Color(0xFFE2F3DA)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _activeTab == 0
                      ? [
                          BoxShadow(
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.06,
                            ),
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
                      LucideIcons.target,
                      size: 16,
                      color: _activeTab == 0
                          ? const Color(0xFF1B5E20)
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Mis metas',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _activeTab == 0
                            ? const Color(0xFF1B5E20)
                            : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeTab = 1;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 1
                      ? const Color(0xFFE2F3DA)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _activeTab == 1
                      ? [
                          BoxShadow(
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.06,
                            ),
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
                      LucideIcons.clock,
                      size: 16,
                      color: _activeTab == 1
                          ? const Color(0xFF1B5E20)
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Historial',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _activeTab == 1
                            ? const Color(0xFF1B5E20)
                            : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
      final isCompleted =
          goal.estado == EstadoMeta.completada ||
          goal.saldoAcumulado >= goal.montoObjetivo;
      return _activeTab == 0 ? !isCompleted : isCompleted;
    }).toList();

    if (filteredGoals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              const Icon(
                LucideIcons.piggyBank,
                color: Color(0xFF9CA3AF),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _activeTab == 0
                    ? 'No tienes metas activas registradas'
                    : 'No tienes metas completadas en tu historial',
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

  Widget _buildGoalsSummary(GoalProvider goalProvider) {
    final activeGoalsCount = goalProvider.goals.where((goal) {
      final isCompleted =
          goal.estado == EstadoMeta.completada ||
          goal.saldoAcumulado >= goal.montoObjetivo;
      return !isCompleted;
    }).length;

    final double totalAhorrado = goalProvider.goals.fold(
      0.0,
      (sum, goal) => sum + goal.saldoAcumulado,
    );

    double averageProgress = 0.0;
    final activeGoalsList = goalProvider.goals.where((goal) {
      final isCompleted =
          goal.estado == EstadoMeta.completada ||
          goal.saldoAcumulado >= goal.montoObjetivo;
      return !isCompleted;
    }).toList();

    if (activeGoalsList.isNotEmpty) {
      double totalProgress = 0.0;
      for (var goal in activeGoalsList) {
        if (goal.montoObjetivo > 0) {
          totalProgress += (goal.saldoAcumulado / goal.montoObjetivo);
        }
      }
      averageProgress = totalProgress / activeGoalsList.length;
    }
    final int averageProgressPercent = (averageProgress * 100).toInt().clamp(
      0,
      100,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Resumen de tus metas',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    'Este mes',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    LucideIcons.chevronDown,
                    size: 14,
                    color: Color(0xFF2E7D32),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Stat 1: Metas Activas
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.target,
                        color: Color(0xFF2E7D32),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$activeGoalsCount',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Metas activas',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Stat 2: Total Ahorrado
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF3E0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.wallet,
                        color: Color(0xFFE65100),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'S/ ${totalAhorrado.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Total ahorrado',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Stat 3: Progreso Promedio
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE3F2FD),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.trendingUp,
                        color: Color(0xFF0D47A1),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$averageProgressPercent%',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Progreso prom.',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBadge(String name) {
    final nameLower = name.toLowerCase();
    String emoji = '✨';
    Color bgColor = const Color(0xFFF0FDFA); // soft teal
    if (name.contains('✈️') ||
        nameLower.contains('viaje') ||
        nameLower.contains('vacaciones') ||
        nameLower.contains('cancún')) {
      emoji = '🏝️';
      bgColor = const Color(0xFFE0F2FE); // soft blue
    } else if (name.contains('🏠') ||
        nameLower.contains('casa') ||
        nameLower.contains('hogar') ||
        nameLower.contains('depa')) {
      emoji = '🏠';
      bgColor = const Color(0xFFFFEDD5); // soft orange
    } else if (name.contains('🚗') ||
        nameLower.contains('auto') ||
        nameLower.contains('carro') ||
        nameLower.contains('vehículo')) {
      emoji = '🚗';
      bgColor = const Color(0xFFF1F5F9); // soft slate
    } else if (name.contains('🎓') ||
        nameLower.contains('estudi') ||
        nameLower.contains('universi') ||
        nameLower.contains('curso')) {
      emoji = '🎓';
      bgColor = const Color(0xFFF3E8FF); // soft purple
    } else if (name.contains('❤️') ||
        nameLower.contains('salud') ||
        nameLower.contains('emergencia') ||
        nameLower.contains('médic')) {
      emoji = '🏥';
      bgColor = const Color(0xFFFFE4E6); // soft rose
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 30))),
    );
  }

  Widget _buildGoalCard(GoalModel goal) {
    final double progress = goal.montoObjetivo > 0
        ? (goal.saldoAcumulado / goal.montoObjetivo)
        : 0.0;
    final int progressPercent = (progress * 100).toInt().clamp(0, 100);
    final double remaining = goal.montoObjetivo - goal.saldoAcumulado;

    final String formattedDate = goal.fechaLimite != null
        ? DateFormat("dd MMM yyyy", 'es').format(goal.fechaLimite!)
        : 'Sin fecha';

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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: category badge
            _buildCategoryBadge(goal.nombre),
            const SizedBox(width: 12),
            // Right: content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Trash
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      const SizedBox(width: 8),
                      if (_activeTab == 0)
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 16),
                          color: AppColors.expenseRed.withValues(alpha: 0.7),
                          onPressed: () => _confirmDeleteGoal(context, goal),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Progress text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  'S/ ${goal.saldoAcumulado.toStringAsFixed(2)} ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const TextSpan(text: 'de '),
                            TextSpan(
                              text:
                                  'S/ ${goal.montoObjetivo.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$progressPercent%',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Progress Bar
                  ProgressBar(
                    progress: progress,
                    foregroundColor: const Color(
                      0xFF8BC34A,
                    ), // Lime green from mockup
                    height: 6.0,
                  ),
                  const SizedBox(height: 12),
                  // Footer info + Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Faltan: S/ ${remaining.clamp(0, double.infinity).toStringAsFixed(2)}  •  Fecha objetivo: $formattedDate',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_activeTab == 0 && remaining > 0)
                        GestureDetector(
                          onTap: () => _showContributeDialog(context, goal),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2F3DA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Aportar',
                              style: GoogleFonts.inter(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
            '¿Estás seguro de que deseas eliminar la meta "${goal.nombre}"? Esta acción no se puede deshacer.',
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

  void _showCreateGoalDialog(
    BuildContext context, {
    String? defaultName,
    double? defaultAmount,
  }) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final amountController = TextEditingController(
      text: defaultAmount != null ? defaultAmount.toStringAsFixed(2) : '',
    );

    int selectedIconIndex = 0;

    // Detect category and pre-select based on defaultName if available
    if (defaultName != null) {
      final nameLower = defaultName.toLowerCase();
      if (nameLower.contains('viaje') ||
          nameLower.contains('vacaciones') ||
          nameLower.contains('playa')) {
        selectedIconIndex = 0;
      } else if (nameLower.contains('casa') ||
          nameLower.contains('hogar') ||
          nameLower.contains('mueble') ||
          nameLower.contains('depa')) {
        selectedIconIndex = 1;
      } else if (nameLower.contains('auto') ||
          nameLower.contains('carro') ||
          nameLower.contains('vehículo') ||
          nameLower.contains('llanta')) {
        selectedIconIndex = 2;
      } else if (nameLower.contains('estudi') ||
          nameLower.contains('universi') ||
          nameLower.contains('curso') ||
          nameLower.contains('educa') ||
          nameLower.contains('laptop') ||
          nameLower.contains('matrícula')) {
        selectedIconIndex = 3;
      } else if (nameLower.contains('salud') ||
          nameLower.contains('emergencia') ||
          nameLower.contains('médic') ||
          nameLower.contains('dental') ||
          nameLower.contains('dentista')) {
        selectedIconIndex = 4;
      } else {
        selectedIconIndex = 5;
      }
      // Clean up special emojis and characters to show clean text
      nameController.text = defaultName
          .replaceAll(RegExp(r'[^\w\s\dáéíóúÁÉÍÓÚñÑ]'), '')
          .trim();
    }

    final List<_IconItem> iconItems = const [
      _IconItem(name: 'Viaje', icon: LucideIcons.plane, emoji: '✈️'),
      _IconItem(name: 'Casa', icon: LucideIcons.home, emoji: '🏠'),
      _IconItem(name: 'Auto', icon: LucideIcons.car, emoji: '🚗'),
      _IconItem(
        name: 'Educación',
        icon: LucideIcons.graduationCap,
        emoji: '🎓',
      ),
      _IconItem(name: 'Salud', icon: LucideIcons.heart, emoji: '❤️'),
      _IconItem(name: 'Otro', icon: LucideIcons.sparkles, emoji: '✨'),
    ];

    // Smart recommendations map for each category index
    final Map<int, List<String>> recommendations = {
      0: [
        'Vacaciones en Cancún',
        'Eurotrip de aventura',
        'Fin de semana de playa',
        'Viaje familiar',
      ],
      1: [
        'Inicial para mi depa',
        'Remodelación de cocina',
        'Juego de comedor',
        'Pintar el departamento',
      ],
      2: [
        'Cuota inicial del auto',
        'Mantenimiento anual',
        'Seguro vehicular',
        'Llantas nuevas',
      ],
      3: [
        'Ciclo de universidad',
        'Curso de especialización',
        'Libros y matrícula',
        'Nueva Laptop',
      ],
      4: [
        'Fondo de emergencias',
        'Seguro médico anual',
        'Tratamiento dental',
        'Gimnasio y salud',
      ],
      5: [
        'Regalos navideños',
        'Entradas para concierto',
        'Nueva tecnología',
        'Ahorro imprevistos',
      ],
    };

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppColors.surfaceWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          // Decorative target icon
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEAF5E6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.target,
                                color: Color(0xFF1B5E20),
                                size: 28,
                              ),
                            ),
                          ).animate().fadeIn(duration: 300.ms, delay: 100.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                          const SizedBox(height: 14),

                          // Centered Title and Subtitle
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'Nueva Meta',
                                  style: GoogleFonts.inter(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(
                                      0xFF1B5E20,
                                    ), // Dark green title color
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Crea una meta de ahorro para alcanzar tus objetivos',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 300.ms, delay: 150.ms).slideY(begin: 0.1, end: 0.0, curve: Curves.easeOutQuad),
                          const SizedBox(height: 24),

                          // 1. Nombre de la meta
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nombre de la meta',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1C2434),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: nameController,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                    LucideIcons.tag,
                                    color: Color(0xFF80C29E),
                                    size: 18,
                                  ),
                                  hintText: 'Ej: Viaje a Europa',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  fillColor: const Color(0xFFFAFAFA),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFEAEAEA),
                                      width: 1.0,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFEAEAEA),
                                      width: 1.0,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: AppColors.primaryGreen,
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Ingresa un nombre'
                                    : null,
                              ),
                            ],
                          ).animate().fadeIn(duration: 350.ms, delay: 200.ms).slideY(begin: 0.08, end: 0.0, curve: Curves.easeOutQuad),
                          const SizedBox(height: 10),

                          // Dynamic Name Recommendations
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    LucideIcons.sparkles,
                                    size: 13,
                                    color: Color(0xFF80C29E),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Sugerencias:',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1B5E20),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 34,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount:
                                      recommendations[selectedIconIndex]!.length,
                                  itemBuilder: (context, chipIndex) {
                                    final chipText =
                                        recommendations[selectedIconIndex]![chipIndex];
                                    final isSelected =
                                        nameController.text.trim() == chipText;
                                    return GestureDetector(
                                      onTap: () {
                                        setDialogState(() {
                                          nameController.text = chipText;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFEAF5E6)
                                              : const Color(0xFFFAFAFA),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF80C29E)
                                                : const Color(0xFFEEEEEE),
                                            width: isSelected ? 1.5 : 1.0,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(0xFF80C29E)
                                                        .withValues(alpha: 0.15),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Text(
                                          chipText,
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? const Color(0xFF1B5E20)
                                                : const Color(0xFF6C757D),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ).animate().fadeIn(duration: 350.ms, delay: 250.ms).slideY(begin: 0.08, end: 0.0, curve: Curves.easeOutQuad),
                          const SizedBox(height: 18),

                          // 2. Monto objetivo (S/)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Monto objetivo (S/)',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1C2434),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: amountController,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                    LucideIcons.coins,
                                    color: Color(0xFF80C29E),
                                    size: 18,
                                  ),
                                  hintText: '5000.00',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  fillColor: const Color(0xFFFAFAFA),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFEAEAEA),
                                      width: 1.0,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFEAEAEA),
                                      width: 1.0,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: AppColors.primaryGreen,
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ingresa un monto';
                                  }
                                  final val = double.tryParse(value);
                                  if (val == null || val <= 0) {
                                    return 'Monto inválido';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ).animate().fadeIn(duration: 350.ms, delay: 300.ms).slideY(begin: 0.08, end: 0.0, curve: Curves.easeOutQuad),
                          const SizedBox(height: 18),

                          // 3. Ícono selection
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ícono',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1C2434),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // 3-column Grid for Icons
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      childAspectRatio: 1.15,
                                    ),
                                itemCount: iconItems.length,
                                itemBuilder: (context, index) {
                                  final item = iconItems[index];
                                  final isSelected = selectedIconIndex == index;

                                  return GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        selectedIconIndex = index;
                                      });
                                    },
                                    child: AnimatedScale(
                                      scale: isSelected ? 1.05 : 1.0,
                                      duration: const Duration(milliseconds: 150),
                                      curve: Curves.easeOutBack,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFEAF5E6)
                                              : const Color(0xFFFAFAFA),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF4CAF50)
                                                : const Color(0xFFEEEEEE),
                                            width: isSelected ? 2.0 : 1.0,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(0xFF4CAF50)
                                                        .withValues(alpha: 0.15),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              item.icon,
                                              color: isSelected
                                                  ? const Color(0xFF1B5E20)
                                                  : const Color(0xFF6C757D),
                                              size: 22,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              item.name,
                                              style: GoogleFonts.inter(
                                                fontSize: 11.5,
                                                fontWeight: isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: isSelected
                                                    ? const Color(0xFF1B5E20)
                                                    : const Color(0xFF6C757D),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ).animate().fadeIn(duration: 350.ms, delay: 350.ms).slideY(begin: 0.08, end: 0.0, curve: Curves.easeOutQuad),

                          const SizedBox(height: 24),
                          // Guardar Button
                          SizedBox(
                            width: double.infinity,
                            child: SBButton.primary(
                              label: 'Crear Meta',
                              onPressed: () async {
                                if (formKey.currentState?.validate() ?? false) {
                                  final provider = context.read<GoalProvider>();

                                  // Append the selected emoji to the name to persist it
                                  final String finalName =
                                      '${nameController.text.trim()} ${iconItems[selectedIconIndex].emoji}';

                                  // Calculate a default date in background (e.g. 1 year from now) as date is optional in DB
                                  final DateTime defaultLimitDate =
                                      DateTime.now().add(
                                        const Duration(days: 365),
                                      );

                                  final success = await provider.createGoal(
                                    nombre: finalName,
                                    montoObjetivo: double.parse(
                                      amountController.text.trim(),
                                    ),
                                    fechaLimite: defaultLimitDate,
                                  );
                                  if (success && context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Meta creada con éxito!'),
                                      ),
                                    );
                                  }
                                }
                              },
                              customColor: AppColors.primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ).animate().fadeIn(duration: 350.ms, delay: 420.ms).slideY(begin: 0.08, end: 0.0, curve: Curves.easeOutQuad),
                        ],
                      ),
                    ),
                  ),
                  // Close button (positioned absolutely in top right)
                  Positioned(
                    right: 16,
                    top: 16,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 250.ms, delay: 150.ms),
                ],
              ),
            ).animate().scale(
              duration: 350.ms,
              curve: Curves.easeOutBack,
              begin: const Offset(0.9, 0.9),
            ).fadeIn(
              duration: 250.ms,
            );
          },
        );
      },
    );
  }

  void _showContributeDialog(BuildContext context, GoalModel goal) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final budgetProvider = context.read<BudgetProvider>();
    final saldoDisponible =
        budgetProvider.currentBudget?.saldoDisponible ?? 0.0;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Aportar a meta',
                        style: AppTextStyles.heading2.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.pop(context),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    goal.nombre,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Monto a aportar (S/)',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: amountController,
                    style: AppTextStyles.bodyMedium,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ej. 100.00',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                      fillColor: const Color(0xFFF3FAF2),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primaryGreen,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa un monto';
                      }
                      final val = double.tryParse(value);
                      if (val == null || val <= 0) {
                        return 'Monto inválido';
                      }
                      if (val > saldoDisponible) {
                        return 'Saldo disponible insuficiente (S/ ${saldoDisponible.toStringAsFixed(2)})';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Saldo disponible: S/ ${saldoDisponible.toStringAsFixed(2)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Guardar Button
                  SizedBox(
                    width: double.infinity,
                    child: SBButton.primary(
                      label: 'Confirmar Aportación',
                      onPressed: () async {
                        if (formKey.currentState?.validate() ?? false) {
                          final amount = double.parse(
                            amountController.text.trim(),
                          );
                          final provider = context.read<GoalProvider>();
                          final success = await provider.contribute(
                            goalId: goal.id,
                            amount: amount,
                          );
                          if (success && context.mounted) {
                            await budgetProvider.loadDashboard();
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '¡Aportación de S/ ${amount.toStringAsFixed(2)} realizada con éxito!',
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      },
                      customColor: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IconItem {
  final String name;
  final IconData icon;
  final String emoji;

  const _IconItem({
    required this.name,
    required this.icon,
    required this.emoji,
  });
}

class _GoalsBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Top-left waving curve
    final paint1 = Paint()
      ..color = const Color(0xFFE2F3DA).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, 0);
    path1.lineTo(size.width, 0);
    path1.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.12,
      size.width * 0.45,
      size.height * 0.08,
    );
    path1.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.05,
      0,
      size.height * 0.14,
    );
    path1.close();
    canvas.drawPath(path1, paint1);

    // Bottom waving hills
    final paint2 = Paint()
      ..color = const Color(0xFFE2F3DA).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.85);
    path2.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.80,
      size.width * 0.5,
      size.height * 0.88,
    );
    path2.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.95,
      size.width,
      size.height * 0.90,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);

    final paint3 = Paint()
      ..color = const Color(0xFFE8F5E9).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final path3 = Path();
    path3.moveTo(0, size.height * 0.90);
    path3.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.94,
      size.width * 0.65,
      size.height * 0.89,
    );
    path3.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.85,
      size.width,
      size.height * 0.93,
    );
    path3.lineTo(size.width, size.height);
    path3.lineTo(0, size.height);
    path3.close();
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
