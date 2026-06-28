import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/providers/goal_provider.dart';
import '../../../data/providers/budget_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/sb_button.dart';
import '../../widgets/sb_entrance_animation.dart';
import 'widgets/goal_format.dart';
import 'widgets/goal_progress_card.dart';

/// ② del flujo de aporte a meta: confirmar. Muestra los detalles, el resumen
/// proyectado (calculado en el cliente) y el impacto REAL en el SmartScore
/// (endpoint preview). Al confirmar aporta y va a 1D (si completa) o a ③.
class GoalContributeConfirmScreen extends StatefulWidget {
  const GoalContributeConfirmScreen({
    super.key,
    required this.goalId,
    required this.monto,
    required this.fecha,
    this.descripcion,
  });

  final int goalId;
  final double monto;
  final DateTime fecha;
  final String? descripcion;

  @override
  State<GoalContributeConfirmScreen> createState() =>
      _GoalContributeConfirmScreenState();
}

class _GoalContributeConfirmScreenState
    extends State<GoalContributeConfirmScreen> {
  ContributePreview? _preview;
  bool _loadingPreview = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gp = context.read<GoalProvider>();
      if (gp.goalById(widget.goalId) == null) gp.loadGoals();
      _loadPreview();
    });
  }

  Future<void> _loadPreview() async {
    final preview = await context.read<GoalProvider>().previewContribution(
          goalId: widget.goalId,
          amount: widget.monto,
        );
    if (!mounted) return;
    setState(() {
      _preview = preview;
      _loadingPreview = false;
    });
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/goals/${widget.goalId}/contribute');
    }
  }

  Future<void> _confirm(GoalModel goal) async {
    setState(() => _submitting = true);
    final gp = context.read<GoalProvider>();
    final bp = context.read<BudgetProvider>();

    final ok = await gp.contribute(
      goalId: widget.goalId,
      amount: widget.monto,
      fecha: widget.fecha,
      descripcion: widget.descripcion,
    );
    if (!mounted) return;

    if (!ok) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(gp.errorMessage ?? 'No se pudo realizar el aporte'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      return;
    }

    // Refresca presupuesto (saldo) y aportes para que el detalle quede al día.
    await bp.loadDashboard();
    await gp.loadContributions(widget.goalId);
    if (!mounted) return;

    final result = gp.lastContributeResult;
    final updated = gp.goalById(widget.goalId) ?? goal;
    final completed = result?.completada ?? false;

    if (completed) {
      // 1D: celebración de meta alcanzada (pantalla existente).
      context.go('/goals/success', extra: {
        'goal': updated,
        'scoreDelta': result?.scoreDelta ?? 0,
      });
    } else {
      // ③: ¡Aporte realizado!
      context.go('/goals/contribute/success', extra: {
        'goal': updated,
        'monto': widget.monto,
        'fecha': widget.fecha,
        'scoreDelta': result?.scoreDelta ?? 0,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = context.watch<GoalProvider>().goalById(widget.goalId);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      body: SafeArea(
        child: goal == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen))
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppHeader(),
                    const SizedBox(height: AppSpacing.sm),
                    _buildTitleRow(),
                    const SizedBox(height: AppSpacing.md),

                    GoalProgressCard(goal: goal).animateEntrance(delay: 60.ms),
                    const SizedBox(height: AppSpacing.lg),

                    _buildDetailsCard().animateEntrance(delay: 100.ms),
                    const SizedBox(height: AppSpacing.md),

                    _buildSummaryCard(goal).animateEntrance(delay: 160.ms),
                    const SizedBox(height: AppSpacing.md),

                    _buildScoreCard().animateEntrance(delay: 220.ms),
                    const SizedBox(height: AppSpacing.xl),

                    SizedBox(
                      width: double.infinity,
                      child: SBButton.primary(
                        label: 'Confirmar aporte',
                        onPressed: _submitting ? null : () => _confirm(goal),
                        isLoading: _submitting,
                        customColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ).animateEntrance(delay: 280.ms),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(LucideIcons.arrowLeft,
              color: AppColors.textPrimary, size: 22),
          tooltip: 'Volver',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          onPressed: _submitting ? null : _goBack,
        ),
        Expanded(
          child: Text(
            'Confirmar aporte',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading2
                .copyWith(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  // ─── Detalles del aporte ────────────────────────────────────────────────
  Widget _buildDetailsCard() {
    final desc = widget.descripcion?.trim();
    final hasDesc = desc != null && desc.isNotEmpty;
    final fechaStr =
        DateFormat("dd 'de' MMMM 'de' yyyy", 'es').format(widget.fecha);
    return _card(
      title: 'Detalles del aporte',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monto a aportar',
            style: GoogleFonts.inter(
                fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            GoalFormat.money(widget.monto),
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 14),
          _detailRow(LucideIcons.calendar, 'Fecha', fechaStr),
          if (hasDesc) ...[
            const SizedBox(height: 12),
            _detailRow(LucideIcons.alignLeft, 'Descripción', desc),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF80C29E)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                    fontSize: 11.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Resumen después del aporte (calculado en el cliente) ────────────────
  Widget _buildSummaryCard(GoalModel goal) {
    final nuevoSaldo = goal.saldoAcumulado + widget.monto;
    final progreso = goal.montoObjetivo > 0
        ? (nuevoSaldo / goal.montoObjetivo).clamp(0.0, 1.0)
        : 0.0;
    final faltara =
        (goal.montoObjetivo - nuevoSaldo).clamp(0.0, double.infinity);
    final meses = GoalFormat.monthsRemaining(goal.fechaLimite);
    final tiempo = meses == null
        ? 'Sin fecha'
        : (meses <= 0 ? '< 1 mes' : '$meses ${meses == 1 ? 'mes' : 'meses'}');

    return _card(
      title: 'Resumen después del aporte',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  'Nuevo ahorro',
                  Text(
                    GoalFormat.money(nuevoSaldo),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _summaryItem(
                  'Progreso',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(progreso * 100).round()}%',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progreso,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: const AlwaysStoppedAnimation(
                              AppColors.primaryGreen),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  'Faltará',
                  Text(
                    GoalFormat.money(faltara),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _summaryItem(
                  'Tiempo restante',
                  Text(
                    tiempo,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, Widget value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        value,
      ],
    );
  }

  // ─── Impacto en el SmartScore (preview real) ─────────────────────────────
  Widget _buildScoreCard() {
    final Widget content;
    if (_loadingPreview) {
      content = Column(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primaryGreen),
          ),
          const SizedBox(height: 8),
          Text(
            'Calculando el impacto…',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      );
    } else if (_preview != null) {
      final delta = _preview!.scoreDelta;
      final String deltaText;
      final Color deltaColor;
      if (delta > 0) {
        deltaText = '+$delta pts';
        deltaColor = AppColors.incomeGreen;
      } else if (delta < 0) {
        deltaText = '$delta pts';
        deltaColor = AppColors.expenseRed;
      } else {
        deltaText = 'Sin cambios';
        deltaColor = AppColors.textSecondary;
      }
      content = Column(
        children: [
          Text(
            deltaText,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: deltaColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _scoreCopy(_preview!.scoreNuevo),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ],
      );
    } else {
      // El preview falló: copy cualitativo, sin número inventado.
      content = Text(
        'Sumarás puntos a tu SmartScore',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );
    }

    return _card(
      title: 'Impacto en tu SmartScore',
      center: true,
      child: content,
    );
  }

  String _scoreCopy(int score) {
    if (score >= 80) return '¡Vas increíble! 🌟';
    if (score >= 70) return '¡Vas por buen camino! 🚀';
    if (score >= 50) return 'Vas mejorando 💪';
    return 'Sigue sumando 🐷';
  }

  Widget _card({
    required String title,
    required Widget child,
    bool center = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Column(
        crossAxisAlignment:
            center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1C2434),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
