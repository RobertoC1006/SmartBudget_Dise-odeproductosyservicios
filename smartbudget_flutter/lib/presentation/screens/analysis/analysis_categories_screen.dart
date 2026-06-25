import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/providers/analysis_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/header_background_painter.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/sb_entrance_animation.dart';
import 'widgets/category_donut.dart';
import 'widgets/category_visuals.dart';

/// 1B · Análisis — Categorías.
/// Drill-down de la distribución de gastos: donut grande con el total y la
/// lista completa de categorías del mes, ordenada de mayor a menor. Cada fila
/// abre el detalle de la categoría (1D).
class AnalysisCategoriesScreen extends StatefulWidget {
  final int? mes;
  final int? anio;

  const AnalysisCategoriesScreen({super.key, this.mes, this.anio});

  @override
  State<AnalysisCategoriesScreen> createState() => _AnalysisCategoriesScreenState();
}

class _AnalysisCategoriesScreenState extends State<AnalysisCategoriesScreen> {
  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = widget.mes ?? now.month;
    _selectedYear = widget.anio ?? now.year;
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  void _fetchData() {
    context.read<AnalysisProvider>().loadAnalysisData(
          mes: _selectedMonth,
          anio: _selectedYear,
        );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/analysis');
    }
  }

  void _openCategory(String key) {
    // 1D Detalle de categoría; el mes seleccionado se propaga por `extra`.
    context.push(
      '/analysis/category/$key',
      extra: {'mes': _selectedMonth, 'anio': _selectedYear},
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
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
                  const SizedBox(height: AppSpacing.sm),
                  _buildTitleRow(),
                  const SizedBox(height: AppSpacing.md),
                  _buildPeriodPill(),
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

  // ─── Cabecera: título + back ───────────────────────────────────────────────

  Widget _buildTitleRow() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 22),
          tooltip: 'Volver',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          onPressed: _goBack,
        ),
        Expanded(
          child: Text(
            'Categorías',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 40), // balancea la flecha para centrar el título
      ],
    );
  }

  Widget _buildPeriodPill() {
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth == now.month && _selectedYear == now.year;
    final label =
        isCurrentMonth ? 'Este mes' : '${_monthName(_selectedMonth)} $_selectedYear';

    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: _showMonthPicker,
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
    );
  }

  // ─── Cuerpo ────────────────────────────────────────────────────────────────

  Widget _buildBody(AnalysisProvider provider) {
    if (provider.expensesByCategory == null && provider.isLoading) {
      return _buildSkeleton();
    }
    if (provider.expensesByCategory == null && provider.errorMessage != null) {
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

    final expenses = provider.expensesByCategory ?? {};
    if (expenses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: EmptyState(
          icon: LucideIcons.pieChart,
          title: 'Sin gastos este mes',
          subtitle: 'No hay gastos registrados en esta fecha. Registra uno para ver tu distribución por categoría.',
        ),
      );
    }

    final total = expenses.values.fold<double>(0, (sum, v) => sum + v);
    final sorted = expenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDonutCard(expenses, total),
        const SizedBox(height: AppSpacing.md),
        ...sorted.asMap().entries.map(
              (e) => _buildCategoryRow(e.value.key, e.value.value, total, e.key),
            ),
      ],
    );
  }

  Widget _buildDonutCard(Map<String, double> expenses, double total) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEEFF2), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: CategoryDonut(expenses: expenses, total: total, size: 212),
      ),
    ).animateEntrance(delay: 50.ms);
  }

  Widget _buildCategoryRow(String key, double amount, double total, int index) {
    final color = CategoryVisuals.color(key);
    final fraction = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;
    final pct = total > 0 ? (amount / total) * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openCategory(key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEEEFF2), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CategoryAvatar(categoryKey: key, size: 46),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CategoryVisuals.label(key),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        CurrencyFormatter.format(amount),
                        style: _amountStyle(13.5, AppColors.textSecondary, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFF0F1F4),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: _amountStyle(16, AppColors.textSecondary, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animateEntrance(delay: (100 + index * 50).ms);
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LoadingShimmer.rect(width: double.infinity, height: 240),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < 4; i++) ...[
          LoadingShimmer.rect(width: double.infinity, height: 76),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  TextStyle _amountStyle(double size, Color color, {FontWeight weight = FontWeight.w800}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  // ─── Selector de mes ───────────────────────────────────────────────────────

  String _monthName(int month) {
    const list = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return (month >= 1 && month <= 12) ? list[month - 1] : '';
  }

  String _monthNameShort(int month) {
    const list = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return (month >= 1 && month <= 12) ? list[month - 1] : '';
  }

  void _showMonthPicker() {
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
                              _monthNameShort(monthIdx),
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
