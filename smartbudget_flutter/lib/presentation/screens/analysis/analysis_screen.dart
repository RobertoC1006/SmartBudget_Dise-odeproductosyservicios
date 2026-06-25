import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/analysis_model.dart';
import '../../../data/providers/analysis_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/header_background_painter.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/sb_entrance_animation.dart';
import '../../widgets/smart_score_ring.dart';
import 'widgets/category_visuals.dart';

/// 1A · Análisis — Resumen.
/// Portada de la pestaña Análisis: gasto total con comparativa, ingresos/ahorro,
/// SmartScore, distribución de gastos y acceso al detalle por categorías.
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int _touchedPieIndex = -1;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  void _fetchData() {
    final provider = context.read<AnalysisProvider>();
    provider.loadOverview(mes: _selectedMonth, anio: _selectedYear);
    provider.loadAnalysisData(mes: _selectedMonth, anio: _selectedYear);
  }

  // ─── Helpers de categoría ──────────────────────────────────────────────────

  // Color/ícono/rótulo de categoría: fuente única en CategoryVisuals (compartida
  // con 1B/1D). Se conservan como métodos privados por los múltiples call sites.
  Color _getCategoryColor(String key) => CategoryVisuals.color(key);

  String _translateCategory(String key) => CategoryVisuals.label(key);

  IconData _getCategoryIcon(String key) => CategoryVisuals.icon(key);

  String _getMonthName(int month) {
    const list = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return (month >= 1 && month <= 12) ? list[month - 1] : '';
  }

  String _getMonthNameShort(int month) {
    const list = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return (month >= 1 && month <= 12) ? list[month - 1] : '';
  }

  // Agrupa la distribución a un máximo de 6 segmentos (top 5 + "Otros") para
  // el donut. Delegado a CategoryVisuals (compartido con 1B/1D).
  Map<String, double> _topCategories(Map<String, double> expenses) =>
      CategoryVisuals.topCategories(expenses);

  TextStyle _amountStyle(double size, Color color, {FontWeight weight = FontWeight.w800}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: HeaderBackgroundPainter())),
            RefreshIndicator(
              onRefresh: () async => _fetchData(),
              color: AppColors.primaryGreen,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const AppHeader(),
                  const SizedBox(height: AppSpacing.md),
                  _buildTitleAndPeriod(),
                  const SizedBox(height: AppSpacing.md),
                  _buildBody(provider),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AnalysisProvider provider) {
    // Primer cargado: esqueleto mientras no hay datos del resumen.
    if (provider.overview == null && provider.isOverviewLoading) {
      return _buildSkeleton();
    }
    if (provider.overview == null && provider.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: EmptyState(
          icon: LucideIcons.alertCircle,
          title: 'Ocurrió un problema',
          subtitle: provider.errorMessage ?? 'Error de red al consultar datos.',
          actionLabel: 'Reintentar',
          onAction: _fetchData,
        ),
      );
    }

    final overview = provider.overview;
    final expenses = provider.expensesByCategory ?? {};
    final totalSpent = expenses.values.fold<double>(0, (sum, v) => sum + v);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (overview != null) ...[
          _buildGastoTotalCard(overview),
          const SizedBox(height: AppSpacing.md),
          _buildIncomeSavingsRow(overview),
          const SizedBox(height: AppSpacing.md),
        ],
        _buildSmartScoreCard(provider),
        const SizedBox(height: AppSpacing.md),
        _buildDistribucionCard(expenses, totalSpent),
        const SizedBox(height: AppSpacing.md),
        _buildVerDetalleButton(),
      ],
    );
  }

  // ─── Título + selector de período ──────────────────────────────────────────

  Widget _buildTitleAndPeriod() {
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth == now.month && _selectedYear == now.year;
    final label = isCurrentMonth
        ? 'Este mes'
        : '${_getMonthName(_selectedMonth)} $_selectedYear';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análisis',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _showMonthPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentGreenBorder, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.calendar, size: 14, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.chevronDown, size: 15, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    ).animateEntrance(delay: 0.ms);
  }

  // ─── Card: Gasto total (hero) ──────────────────────────────────────────────

  Widget _buildGastoTotalCard(AnalysisOverview o) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accentGreenSoft, AppColors.accentGreenLight],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accentGreenBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gasto total',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textGreenHighlight,
            ),
          ),
          const SizedBox(height: 6),
          Text(CurrencyFormatter.format(o.gastoTotal), style: _amountStyle(32, AppColors.textPrimary)),
          const SizedBox(height: 8),
          _buildDeltaRow(o.gastoDeltaPct, lowerIsBetter: true),
        ],
      ),
    ).animateEntrance(delay: 50.ms);
  }

  /// Variación vs. mes anterior con flecha + signo + texto (nunca solo color).
  /// En gasto, una baja es buena (verde); en ingreso/ahorro, una subida es buena.
  Widget _buildDeltaRow(double? pct, {required bool lowerIsBetter}) {
    if (pct == null) {
      return Text(
        'Sin dato del mes pasado',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      );
    }
    final isZero = pct.abs() < 0.5;
    final goesDown = pct < 0;
    final isGood = isZero ? true : (lowerIsBetter ? goesDown : !goesDown);
    final color = isZero
        ? AppColors.textSecondary
        : (isGood ? AppColors.incomeGreen : AppColors.expenseRed);
    final arrow = isZero ? '' : (goesDown ? '↓ ' : '↑ ');

    return Row(
      children: [
        Text(
          '$arrow${pct.abs().toStringAsFixed(0)}%',
          style: _amountStyle(13, color, weight: FontWeight.w700),
        ),
        const SizedBox(width: 6),
        Text(
          'vs. el mes pasado',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ─── Cards: Ingresos + Ahorro ──────────────────────────────────────────────

  Widget _buildIncomeSavingsRow(AnalysisOverview o) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Expanded(
          child: _buildMetricCard(
            label: 'Ingresos',
            amount: o.ingresos,
            deltaPct: o.ingresosDeltaPct,
            imagePath: 'assets/images/wallet_3d.png',
            fallbackIcon: LucideIcons.wallet,
            fallbackColor: AppColors.incomeGreen,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildMetricCard(
            label: 'Ahorro',
            amount: o.ahorro,
            deltaPct: o.ahorroDeltaPct,
            imagePath: 'assets/images/piggy_bank_3d.png',
            fallbackIcon: LucideIcons.piggyBank,
            fallbackColor: AppColors.primaryGreen,
            floatDelay: 600.ms,
          ),
        ),
        ],
      ),
    ).animateEntrance(delay: 100.ms);
  }

  Widget _buildMetricCard({
    required String label,
    required double amount,
    required double? deltaPct,
    required String imagePath,
    required IconData fallbackIcon,
    required Color fallbackColor,
    Duration floatDelay = Duration.zero,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Imagen 3D flotante (billetera / chanchito) anclada a la derecha.
          Positioned(
            right: -4,
            top: 0,
            bottom: 0,
            child: Center(
              child: SizedBox(
                width: 54,
                height: 54,
                child:
                    Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(fallbackIcon, color: fallbackColor, size: 30),
                          ),
                        )
                        .animate(
                          delay: floatDelay,
                          onPlay: (controller) => controller.repeat(reverse: true),
                        )
                        .slideY(
                          begin: 0,
                          end: -0.07,
                          duration: 1800.ms,
                          curve: Curves.easeInOut,
                        ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(CurrencyFormatter.format(amount), style: _amountStyle(17, AppColors.textPrimary)),
                ),
                const SizedBox(height: 6),
                _buildCompactDelta(deltaPct, lowerIsBetter: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Delta compacto (solo flecha + %) para las cards de Ingresos/Ahorro.
  Widget _buildCompactDelta(double? pct, {required bool lowerIsBetter}) {
    if (pct == null) {
      return Text(
        '—',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      );
    }
    final isZero = pct.abs() < 0.5;
    final goesDown = pct < 0;
    final isGood = isZero ? true : (lowerIsBetter ? goesDown : !goesDown);
    final color = isZero
        ? AppColors.textSecondary
        : (isGood ? AppColors.incomeGreen : AppColors.expenseRed);
    final arrow = isZero ? '' : (goesDown ? '↓ ' : '↑ ');
    return Text(
      '$arrow${pct.abs().toStringAsFixed(0)}%',
      style: _amountStyle(12, color, weight: FontWeight.w700),
    );
  }

  // ─── Card: SmartScore ──────────────────────────────────────────────────────

  Widget _buildSmartScoreCard(AnalysisProvider provider) {
    final score = provider.currentScore;
    final variation = provider.scoreVariation;
    final varColor = variation >= 0 ? AppColors.incomeGreen : AppColors.expenseRed;
    final varSign = variation > 0 ? '+' : '';

    return _buildGlassCard(
      child: Row(
        children: [
          SmartScoreRing(score: score, size: 72),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'SmartScore',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(LucideIcons.star, size: 15, color: Color(0xFFF59E0B)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _scoreStatus(score),
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$varSign$variation pts vs. el mes pasado',
                  style: _amountStyle(12, varColor, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animateEntrance(delay: 150.ms);
  }

  String _scoreStatus(int score) {
    if (score >= 71) return '¡Vas por buen camino!';
    if (score >= 41) return 'Buen camino, cuida tus gastos.';
    return 'Cuida tus gastos este mes.';
  }

  // ─── Card: Distribución de gastos (donut) ──────────────────────────────────

  Widget _buildDistribucionCard(Map<String, double> rawExpenses, double totalSpent) {
    if (rawExpenses.isEmpty) {
      return _buildGlassCard(
        child: Container(
          height: 120,
          alignment: Alignment.center,
          child: Text(
            'No hay gastos registrados en esta fecha.',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ),
      ).animateEntrance(delay: 200.ms);
    }

    final expenses = _topCategories(rawExpenses);

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribución de gastos',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedPieIndex = -1;
                                return;
                              }
                              _touchedPieIndex =
                                  pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 3,
                        centerSpaceRadius: 42,
                        sections: _buildPieSections(expenses),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          CurrencyFormatter.formatCompact(totalSpent),
                          style: _amountStyle(14, AppColors.textPrimary),
                        ),
                        Text(
                          'Total',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: _buildLegend(expenses, totalSpent)),
            ],
          ),
        ],
      ),
    ).animateEntrance(delay: 200.ms);
  }

  Widget _buildLegend(Map<String, double> expenses, double totalSpent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: expenses.entries.toList().asMap().entries.map((item) {
        final index = item.key;
        final category = item.value.key;
        final amount = item.value.value;
        final percentage = totalSpent > 0 ? (amount / totalSpent) * 100 : 0.0;
        final color = _getCategoryColor(category);
        final isSelected = _touchedPieIndex == index;

        return GestureDetector(
          onTap: () => setState(() => _touchedPieIndex = isSelected ? -1 : index),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _translateCategory(category),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: _amountStyle(10, AppColors.textSecondary, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> expenses) {
    return expenses.entries.toList().asMap().entries.map((item) {
      final index = item.key;
      final entry = item.value;
      final isSelected = _touchedPieIndex == index;
      final color = _getCategoryColor(entry.key);

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '',
        radius: isSelected ? 22 : 14,
        badgeWidget: isSelected
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Icon(_getCategoryIcon(entry.key), size: 12, color: color),
              )
            : null,
        badgePositionPercentageOffset: 0.9,
      );
    }).toList();
  }

  // ─── CTA: Ver análisis detallado ───────────────────────────────────────────

  Widget _buildVerDetalleButton() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(
            '/analysis/categories',
            extra: {'mes': _selectedMonth, 'anio': _selectedYear},
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Ver análisis detallado',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.arrowRight, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    ).animateEntrance(delay: 250.ms);
  }

  // ─── Skeleton de carga ─────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LoadingShimmer.rect(width: double.infinity, height: 120),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: LoadingShimmer.rect(width: double.infinity, height: 92)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: LoadingShimmer.rect(width: double.infinity, height: 92)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        LoadingShimmer.rect(width: double.infinity, height: 110),
        const SizedBox(height: AppSpacing.md),
        LoadingShimmer.rect(width: double.infinity, height: 180),
      ],
    );
  }

  // ─── Selector de mes (diálogo) ─────────────────────────────────────────────

  void _showMonthPicker(BuildContext context) {
    final now = DateTime.now();
    int tempYear = _selectedYear;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Selecciona el mes',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 18),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.chevronLeft, size: 16),
                          onPressed: () => setDialogState(() => tempYear--),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          tempYear.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(LucideIcons.chevronRight, size: 16),
                          onPressed: tempYear >= now.year + 2
                              ? null
                              : () => setDialogState(() => tempYear++),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.dividerGray),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.8,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, idx) {
                        final monthIdx = idx + 1;
                        final isSelected =
                            _selectedMonth == monthIdx && _selectedYear == tempYear;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedMonth = monthIdx;
                              _selectedYear = tempYear;
                            });
                            _fetchData();
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryLight
                                  : const Color(0xFFF9FBF9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryGreen
                                    : AppColors.dividerGray,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _getMonthNameShort(monthIdx),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primaryDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
