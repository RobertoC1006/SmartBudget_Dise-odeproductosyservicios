import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/providers/goal_provider.dart';
import '../../../data/providers/budget_provider.dart';
import '../../../data/services/smartscore_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/sb_button.dart';
import 'widgets/goal_category_icon.dart';
import 'widgets/goal_format.dart';

/// Pantalla 1B del flujo de metas: detalle de una meta.
/// Hero, gráfico de progreso real, aporte sugerido, impacto (SmartScore real),
/// aportar, historial y editar/eliminar.
class GoalDetailScreen extends StatefulWidget {
  final int goalId;
  const GoalDetailScreen({super.key, required this.goalId});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final _smartScoreService = SmartScoreService();

  /// Puntos reales que aportan las metas al SmartScore (criterio "metas" del
  /// desglose). Se usa en la tarjeta de impacto cuando no hay un aporte reciente.
  int? _metasPuntos;

  /// Resolución del gráfico de progreso: false = por mes, true = por día (mes actual).
  bool _dailyView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<GoalProvider>();
      if (provider.goals.isEmpty) await provider.loadGoals();
      await provider.loadContributions(widget.goalId);
      await _loadScore();
    });
  }

  Future<void> _loadScore() async {
    try {
      final score = await _smartScoreService.getScore();
      if (mounted) setState(() => _metasPuntos = score.metas);
    } catch (_) {
      // Sin presupuesto activo u otro error: la tarjeta cae a su estado neutro.
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/goals');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GoalProvider>();
    final goal = provider.goalById(widget.goalId);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      body: SafeArea(
        child: goal == null
            ? _buildLoadingOrMissing(provider)
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppHeader(),
                    const SizedBox(height: AppSpacing.sm),
                    _buildTitleRow(goal),
                    const SizedBox(height: AppSpacing.md),
                    _buildHeroCard(goal),
                    const SizedBox(height: AppSpacing.md),
                    _buildProgresoCard(goal, provider),
                    const SizedBox(height: AppSpacing.md),
                    _buildSuggestedCard(goal),
                    const SizedBox(height: AppSpacing.md),
                    _buildImpactCard(goal, provider),
                    const SizedBox(height: AppSpacing.lg),
                    if (!goal.completada)
                      SizedBox(
                        width: double.infinity,
                        child: SBButton.primary(
                          label: 'Aportar a esta meta',
                          icon: LucideIcons.plus,
                          onPressed: () => _showContributeSheet(goal),
                          customColor: AppColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: SBButton.secondary(
                        label: 'Ver historial de aportes',
                        icon: LucideIcons.history,
                        onPressed: () => _showHistorySheet(goal),
                        customColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingOrMissing(GoalProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }
    // No encontrada: regresar a la lista.
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.searchX, size: 48, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 12),
          Text('No encontramos esta meta', style: AppTextStyles.bodySecondary),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go('/goals'),
            child: const Text('Volver a mis metas'),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleRow(GoalModel goal) {
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
          onPressed: _goBack,
        ),
        Expanded(
          child: Text(
            'Detalle de meta',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading2.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _buildMenu(goal),
      ],
    );
  }

  Widget _buildMenu(GoalModel goal) {
    return PopupMenuButton<String>(
      icon: const Icon(
        LucideIcons.moreVertical,
        size: 20,
        color: AppColors.textPrimary,
      ),
      tooltip: 'Opciones',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: AppColors.surfaceWhite,
      onSelected: (value) {
        if (value == 'edit') {
          _showEditSheet(goal);
        } else if (value == 'delete') {
          _confirmDelete(goal);
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
                'Editar meta',
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
    );
  }

  Widget _buildHeroCard(GoalModel goal) {
    final int percent = (goal.progreso * 100).round().clamp(0, 100);
    final cat = resolveCategoria(goal.categoria, goal.nombre);
    final off = _heroOffset(cat);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF7E6), Color(0xFFFAFEF9)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.accentGreenBorder, width: 1.2),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ilustración grande a la derecha. Las escenas anchas (playa/viaje)
          // ya llenan; los íconos cuadrados se empujan a la derecha con un
          // offset por categoría para que también lleguen al borde.
          Positioned(
            right: off.right,
            top: off.top,
            child: IgnorePointer(
              child: SizedBox(
                width: 185,
                height: 185,
                child: Image.asset(
                  cat.asset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    LucideIcons.target,
                    color: AppColors.primaryGreen,
                    size: 80,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Texto limitado a ~58% del ancho para no chocar con la imagen
                FractionallySizedBox(
                  widthFactor: 0.58,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.nombre,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          GoalFormat.money(goal.saldoAcumulado),
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.05,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'de ${GoalFormat.money(goal.montoObjetivo)}',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ProgressBar(
                        progress: goal.progreso,
                        foregroundColor: const Color(0xFF8BC34A),
                        height: 8,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$percent%',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      goal.completada
                          ? '¡Meta completada!'
                          : 'Faltan: ${GoalFormat.money(goal.faltante)}',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      GoalFormat.remainingLabel(goal.fechaLimite),
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
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

  /// Posición de la ilustración del hero por categoría.
  /// - playa/viaje: escenas anchas que ya llenan el PNG → se dejan tal cual.
  /// - íconos cuadrados (con margen transparente): se empujan a la derecha
  ///   (right negativo) para que el objeto llegue al borde como la playa.
  ({double right, double top}) _heroOffset(MetaCategoria cat) {
    switch (cat) {
      case MetaCategoria.playa:
        return (right: 18, top: -16);
      case MetaCategoria.viaje:
        return (right: 18, top: -16);
      default:
        return (right: 8, top: -14);
    }
  }

  // ─── Tarjeta "Progreso" (gráfico real de aportes acumulados) ─────────────
  Widget _buildProgresoCard(GoalModel goal, GoalProvider provider) {
    final points = _dailyView
        ? _cumulativeByDay(provider.contributions)
        : _cumulativeByMonth(provider.contributions);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              _buildRangeToggle(),
            ],
          ),
          const SizedBox(height: 14),
          if (provider.isLoadingContributions && points.isEmpty)
            const SizedBox(
              height: 170,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              ),
            )
          else if (points.isEmpty)
            SizedBox(
              height: 150,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.lineChart,
                      size: 36,
                      color: Color(0xFFB0B7C3),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Aún no has hecho aportes a esta meta',
                      style: AppTextStyles.bodySecondary.copyWith(
                        fontSize: 12.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: LineChart(_buildChartData(points, goal.montoObjetivo)),
            ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(List<_CumPoint> points, double objetivo) {
    final maxCum = points.last.cum;
    final double maxY = (objetivo > maxCum ? objetivo : maxCum) * 1.1;
    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].cum),
    ];
    // Con muchos puntos (vista por día) mostramos ~6 etiquetas, no todas.
    final double labelInterval = points.length <= 7
        ? 1.0
        : (points.length / 6).ceilToDouble();

    // Verde pastel suave para la línea y el área.
    const pastelLine = Color(0xFF8BC34A);
    const pastelLineLight = Color(0xFFAED581);

    return LineChartData(
      minX: 0,
      maxX: (points.length > 1 ? points.length - 1 : 1).toDouble(),
      minY: 0,
      maxY: maxY <= 0 ? 1 : maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxY <= 0 ? 1 : maxY) / 2,
        getDrawingHorizontalLine: (value) =>
            const FlLine(color: Color(0xFFEEF2F6), strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 46,
            interval: (maxY <= 0 ? 1 : maxY) / 2,
            getTitlesWidget: (value, meta) => Text(
              'S/ ${_compact(value)}',
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: labelInterval,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= points.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  points[i].label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.primaryDark,
          getTooltipItems: (spots) => spots
              .map(
                (s) => LineTooltipItem(
                  GoalFormat.money(s.y),
                  GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              )
              .toList(),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          preventCurveOverShooting: true,
          gradient: const LinearGradient(colors: [pastelLine, pastelLineLight]),
          barWidth: 3.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: pastelLine,
                ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                pastelLine.withValues(alpha: 0.16),
                pastelLine.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Acumulado de aportes por mes, del primer aporte hasta el mes actual
  /// (máx. 8 meses visibles). Refleja el comportamiento real del usuario.
  List<_CumPoint> _cumulativeByMonth(List<GoalContributionModel> aportes) {
    if (aportes.isEmpty) return [];
    final sorted = [...aportes]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final first = sorted.first.createdAt;
    final now = DateTime.now();

    final months = <DateTime>[];
    var m = DateTime(first.year, first.month);
    final end = DateTime(now.year, now.month);
    while (!m.isAfter(end)) {
      months.add(m);
      m = DateTime(m.year, m.month + 1);
    }

    final points = <_CumPoint>[];
    for (final month in months) {
      final lastDay = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      final cum = sorted
          .where((a) => !a.createdAt.isAfter(lastDay))
          .fold<double>(0.0, (s, a) => s + a.monto);
      points.add(_CumPoint(_monthShort(month.month), cum));
    }

    if (points.length > 8) {
      return points.sublist(points.length - 8);
    }
    return points;
  }

  /// Acumulado de aportes por día del mes actual (día 1 → hoy). Permite ver el
  /// detalle de los aportes hechos dentro del mes cuando la vista mensual
  /// mostraría un solo punto.
  List<_CumPoint> _cumulativeByDay(List<GoalContributionModel> aportes) {
    if (aportes.isEmpty) return [];
    final now = DateTime.now();
    final sorted = [...aportes]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final points = <_CumPoint>[];
    for (var d = 1; d <= now.day; d++) {
      final dayEnd = DateTime(now.year, now.month, d, 23, 59, 59);
      final cum = sorted
          .where((a) => !a.createdAt.isAfter(dayEnd))
          .fold<double>(0.0, (s, a) => s + a.monto);
      points.add(_CumPoint('$d', cum));
    }
    return points;
  }

  String _compact(double value) {
    if (value >= 1000) {
      final k = value / 1000;
      return '${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}k';
    }
    return value.toInt().toString();
  }

  String _monthShort(int month) {
    const list = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return list[(month - 1).clamp(0, 11)];
  }

  /// Selector compacto Día / Mes para la resolución del gráfico.
  Widget _buildRangeToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _rangeChip(
            label: 'Día',
            selected: _dailyView,
            onTap: () {
              if (!_dailyView) setState(() => _dailyView = true);
            },
          ),
          _rangeChip(
            label: 'Mes',
            selected: !_dailyView,
            onTap: () {
              if (_dailyView) setState(() => _dailyView = false);
            },
          ),
        ],
      ),
    );
  }

  Widget _rangeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primaryDark : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedCard(GoalModel goal) {
    final months = GoalFormat.monthsRemaining(goal.fechaLimite);
    final hasDate = months != null && months > 0;
    final suggested = hasDate ? goal.faltante / months : 0.0;

    return _card(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFE2F3DA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.trendingUp,
              color: AppColors.primaryDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aporte mensual sugerido',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  goal.completada
                      ? 'Ya alcanzaste tu objetivo'
                      : hasDate
                      ? 'Para alcanzar tu meta a tiempo'
                      : 'Define una fecha objetivo para calcularlo',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!goal.completada && hasDate)
            Text(
              GoalFormat.money(suggested),
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImpactCard(GoalModel goal, GoalProvider provider) {
    // SmartScore real: si acabas de aportar, el delta del aporte; si no, los
    // puntos que tus metas aportan al score (criterio "metas" del desglose).
    final delta = provider.lastContributeResult?.scoreDelta;
    final bool showDelta = delta != null && delta > 0;

    String scoreValue;
    String scoreLabel;
    if (showDelta) {
      scoreValue = '+$delta pts';
      scoreLabel = '¡Buen trabajo!';
    } else if (_metasPuntos != null && _metasPuntos! > 0) {
      scoreValue = '+$_metasPuntos pts';
      scoreLabel = 'Por tu constancia';
    } else {
      scoreValue = 'SmartScore';
      scoreLabel = 'Por tu constancia';
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impacto en tus finanzas',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  bg: const Color(0xFFE8F5E9),
                  iconColor: AppColors.primaryGreen,
                  icon: LucideIcons.wallet,
                  value: GoalFormat.money(goal.saldoAcumulado),
                  label: 'Tus ahorros',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat(
                  bg: const Color(0xFFFFF8E1),
                  iconColor: AppColors.warningAmber,
                  icon: LucideIcons.star,
                  value: scoreValue,
                  label: scoreLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required Color bg,
    required Color iconColor,
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
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
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ─── Aportar ────────────────────────────────────────────────────────────
  void _showContributeSheet(GoalModel goal) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final budgetProvider = context.read<BudgetProvider>();
    final saldoDisponible =
        budgetProvider.currentBudget?.saldoDisponible ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.dividerGray,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Aportar a esta meta',
                  style: AppTextStyles.heading2.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  goal.nombre,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    prefixText: 'S/ ',
                    hintText: '0.00',
                    fillColor: const Color(0xFFF3FAF2),
                    filled: true,
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
                  validator: (v) {
                    final val = double.tryParse((v ?? '').trim());
                    if (val == null || val <= 0) {
                      return 'Ingresa un monto válido';
                    }
                    if (val > saldoDisponible) {
                      return 'Saldo disponible insuficiente (${GoalFormat.money(saldoDisponible)})';
                    }
                    if (val > goal.faltante) {
                      return 'Supera lo que falta (${GoalFormat.money(goal.faltante)})';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Disponible: ${GoalFormat.money(saldoDisponible)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: SBButton.primary(
                    label: 'Confirmar aporte',
                    customColor: AppColors.primaryGreen,
                    onPressed: () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      final amount = double.parse(amountController.text.trim());
                      Navigator.pop(sheetContext);
                      await _confirmContribution(goal, amount);
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmContribution(GoalModel goal, double amount) async {
    final provider = context.read<GoalProvider>();
    final budgetProvider = context.read<BudgetProvider>();

    final success = await provider.contribute(goalId: goal.id, amount: amount);
    if (!mounted) return;

    if (success) {
      await budgetProvider.loadDashboard();
      await provider.loadContributions(goal.id);
      if (!mounted) return;
      final completed = provider.lastContributeResult?.completada ?? false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            completed
                ? '¡Felicidades! Alcanzaste tu meta 🎉'
                : 'Aporte de ${GoalFormat.money(amount)} realizado',
          ),
        ),
      );
      // La pantalla de celebración 1D llega en la Fase D.
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'No se pudo realizar el aporte',
          ),
        ),
      );
    }
  }

  // ─── Historial ──────────────────────────────────────────────────────────
  void _showHistorySheet(GoalModel goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Consumer<GoalProvider>(
          builder: (context, provider, _) {
            final aportes = provider.contributions.reversed.toList();
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.dividerGray,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Historial de aportes',
                    style: AppTextStyles.heading2.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  if (provider.isLoadingContributions)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    )
                  else if (aportes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Text(
                          'Aún no has hecho aportes a esta meta',
                          style: AppTextStyles.bodySecondary,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: aportes.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final a = aportes[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE8F5E9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.arrowUp,
                                    size: 16,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    DateFormat(
                                      "dd MMM yyyy",
                                      'es',
                                    ).format(a.createdAt),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '+${GoalFormat.money(a.monto)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Editar ─────────────────────────────────────────────────────────────
  void _showEditSheet(GoalModel goal) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: goal.nombre);
    final amountController = TextEditingController(
      text: goal.montoObjetivo.toStringAsFixed(2),
    );
    DateTime? date = goal.fechaLimite;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.dividerGray,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Editar meta',
                      style: AppTextStyles.heading2.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: _sheetField('Nombre de la meta'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ingresa un nombre'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: _sheetField('Monto objetivo (S/)'),
                      validator: (v) {
                        final val = double.tryParse((v ?? '').trim());
                        if (val == null || val <= 0) return 'Monto inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: date ?? now,
                          firstDate: DateTime(now.year, now.month, now.day),
                          lastDate: DateTime(now.year + 10),
                          locale: const Locale('es'),
                        );
                        if (picked != null) setSheet(() => date = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3FAF2),
                          borderRadius: BorderRadius.circular(16),
                          border: const Border.fromBorderSide(
                            BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.calendar,
                              size: 18,
                              color: Color(0xFF80C29E),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                date != null
                                    ? DateFormat(
                                        "dd 'de' MMMM 'de' yyyy",
                                        'es',
                                      ).format(date!)
                                    : 'Sin fecha objetivo',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(
                              LucideIcons.chevronDown,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: SBButton.primary(
                        label: 'Guardar cambios',
                        customColor: AppColors.primaryGreen,
                        onPressed: () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          // Capturamos referencias estables antes del await
                          // (el context del sheet se desmonta tras el pop).
                          final provider = context.read<GoalProvider>();
                          final messenger = ScaffoldMessenger.of(context);
                          final newName = nameController.text.trim();
                          final newAmount = double.parse(
                            amountController.text.trim(),
                          );
                          final newDate = date;
                          Navigator.pop(sheetContext);
                          final ok = await provider.updateGoal(
                            goalId: goal.id,
                            nombre: newName,
                            montoObjetivo: newAmount,
                            fechaLimite: newDate,
                          );
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Meta actualizada'
                                    : provider.errorMessage ??
                                          'No se pudo actualizar',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _sheetField(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      fillColor: const Color(0xFFFAFAFA),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
      ),
    );
  }

  void _confirmDelete(GoalModel goal) {
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
            '¿Estás seguro de eliminar "${goal.nombre}"? El ahorro acumulado se devolverá a tu presupuesto.',
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
                final ok = await provider.deleteGoal(goal.id);
                if (!mounted) return;
                if (ok) {
                  context.go('/goals');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ?? 'No se pudo eliminar',
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

/// Punto del gráfico de progreso: etiqueta del eje X (mes o día) + acumulado.
class _CumPoint {
  final String label;
  final double cum;
  const _CumPoint(this.label, this.cum);
}
