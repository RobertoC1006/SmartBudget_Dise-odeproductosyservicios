import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/smartscore_model.dart';
import '../../../data/providers/analysis_provider.dart';
import '../../../data/providers/budget_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/header_background_painter.dart';
import '../../widgets/sb_entrance_animation.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    context.read<AnalysisProvider>().loadAnalysisData(
          mes: _selectedMonth,
          anio: _selectedYear,
        );
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Helper mappings
  Color _getCategoryColor(String key) {
    switch (key.toLowerCase()) {
      case 'comida':
        return const Color(0xFFEF4444); // Red
      case 'transporte':
        return const Color(0xFF3B82F6); // Blue
      case 'ocio':
        return const Color(0xFFA855F7); // Purple
      case 'salud':
        return const Color(0xFF10B981); // Emerald
      case 'educacion':
        return const Color(0xFF6366F1); // Indigo
      case 'ropa':
        return const Color(0xFFEC4899); // Pink
      case 'hogar':
        return const Color(0xFFF59E0B); // Amber
      case 'tecnologia':
        return const Color(0xFF0EA5E9); // Sky
      case 'viajes':
        return const Color(0xFF14B8A6); // Teal
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  String _translateCategory(String key) {
    switch (key.toLowerCase()) {
      case 'comida':
        return 'Comida';
      case 'transporte':
        return 'Transporte';
      case 'ocio':
        return 'Ocio';
      case 'salud':
        return 'Salud';
      case 'educacion':
        return 'Educación';
      case 'ropa':
        return 'Ropa';
      case 'hogar':
        return 'Hogar';
      case 'tecnologia':
        return 'Tecnología';
      case 'viajes':
        return 'Viajes';
      default:
        return 'Otros';
    }
  }

  IconData _getCategoryIcon(String key) {
    switch (key.toLowerCase()) {
      case 'comida':
        return LucideIcons.utensils;
      case 'transporte':
        return LucideIcons.car;
      case 'ocio':
        return LucideIcons.gamepad2;
      case 'salud':
        return LucideIcons.heart;
      case 'educacion':
        return LucideIcons.bookOpen;
      case 'ropa':
        return LucideIcons.shirt;
      case 'hogar':
        return LucideIcons.home;
      case 'tecnologia':
        return LucideIcons.laptop;
      case 'viajes':
        return LucideIcons.plane;
      default:
        return LucideIcons.moreHorizontal;
    }
  }

  String _getMonthName(int month) {
    const list = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    if (month >= 1 && month <= 12) {
      return list[month - 1];
    }
    return '';
  }

  // Premium Glassmorphic Card builder
  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
    BoxBorder? border,
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
            border: border ??
                Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1.5,
                ),
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
    final analysisProvider = context.watch<AnalysisProvider>();
    final budgetProvider = context.watch<BudgetProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Stack(
          children: [
            // Wave background
            Positioned.fill(
              child: const CustomPaint(
                painter: HeaderBackgroundPainter(),
              ),
            ),
            RefreshIndicator(
              onRefresh: () async {
                _fetchData();
              },
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
                  if (analysisProvider.isLoading &&
                      analysisProvider.expensesByCategory == null)
                    _buildLoadingState()
                  else if (analysisProvider.errorMessage != null &&
                      analysisProvider.expensesByCategory == null)
                    _buildErrorState(analysisProvider)
                  else
                    _buildReportsTab(analysisProvider, budgetProvider),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Analizando tus finanzas...',
              style: AppTextStyles.bodySecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(AnalysisProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: EmptyState(
        icon: LucideIcons.alertCircle,
        title: 'Ocurrió un problema',
        subtitle: provider.errorMessage ?? 'Error de red al consultar datos.',
        actionLabel: 'Reintentar',
        onAction: () => _fetchData(),
      ),
    );
  }

  Widget _buildReportsTab(AnalysisProvider provider, BudgetProvider budgetProvider) {
    final expenses = provider.expensesByCategory ?? {};
    final totalSpent = expenses.values.fold(0.0, (sum, val) => sum + val);

    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth == now.month && _selectedYear == now.year;

    // Budget metrics setup
    double ingresosVal = 0.0;
    double disponibleVal = 0.0;
    double gastosVal = totalSpent;

    if (isCurrentMonth && budgetProvider.currentBudget != null) {
      final b = budgetProvider.currentBudget!;
      ingresosVal = b.montoBase + b.ingresosAdicionales;
      disponibleVal = b.saldoDisponible;
      gastosVal = b.totalGastado;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. DATE PICKER & FILTER HEADER
        _buildDateFilterRow(),

        const SizedBox(height: AppSpacing.md),

        // 2. HERO CARD WITH LEVITATING 3D PIE CHART
        _buildHeroIllustrationCard(),

        const SizedBox(height: AppSpacing.md),

        // 3. RESUMEN GENERAL CARD (Income, Available, Expenses Row)
        _buildResumenGeneralCard(ingresosVal, disponibleVal, gastosVal, isCurrentMonth),

        const SizedBox(height: AppSpacing.md),

        // 4. PIE CHART CARD (Donut Chart & Custom Legends)
        _buildExpensesByCategoryCard(expenses, totalSpent),

        const SizedBox(height: AppSpacing.md),

        // 5. SMARTSCORE HISTORY LINE CHART CARD (Evolución mensual)
        _buildSmartScoreHistoryCard(provider),
      ],
    );
  }

  Widget _buildDateFilterRow() {
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth == now.month && _selectedYear == now.year;
    final displayLabel = isCurrentMonth
        ? 'Este mes'
        : '${_getMonthName(_selectedMonth)} $_selectedYear';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Análisis Financiero',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        // Filter button
        GestureDetector(
          onTap: () => _showMonthPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentGreenBorder, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              children: [
                Text(
                  displayLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  LucideIcons.calendar,
                  size: 14,
                  color: AppColors.primaryGreen,
                ),
              ],
            ),
          ),
        ),
      ],
    ).animateEntrance(delay: 0.ms);
  }

  Widget _buildHeroIllustrationCard() {
    return _buildGlassCard(
      padding: EdgeInsets.zero,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F5E9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.sparkles,
                              color: Color(0xFF2E7D32),
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reporte del Mes',
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
                        'Distribución y Gastos',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Monitorea en qué categorías estás gastando tu dinero.',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
          // Levitating 3D Pie Chart Illustration
          Positioned(
            right: -10,
            top: -12,
            bottom: -12,
            child: SizedBox(
              width: 145,
              child: Image.asset(
                'assets/images/pie_chart_3d.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      LucideIcons.pieChart,
                      color: AppColors.primaryGreen,
                      size: 40,
                    ),
                  );
                },
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
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
    ).animateEntrance(delay: 50.ms);
  }

  Widget _buildResumenGeneralCard(
    double ingresos,
    double disponible,
    double gastos,
    bool isCurrentMonth,
  ) {
    return _buildGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resumen General',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (!isCurrentMonth)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade100),
                    ),
                    child: Text(
                      'Histórico',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // 1. Ingresos
              Expanded(
                child: Column(
                  children: [
                    Text(
                      isCurrentMonth
                          ? CurrencyFormatter.formatCompact(ingresos)
                          : 'S/ ---',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.incomeGreen,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ingresos',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 30,
                width: 1.2,
                color: AppColors.dividerGray,
              ),
              // 2. Disponible
              Expanded(
                child: Column(
                  children: [
                    Text(
                      isCurrentMonth
                          ? CurrencyFormatter.formatCompact(disponible)
                          : 'S/ ---',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Disponible',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 30,
                width: 1.2,
                color: AppColors.dividerGray,
              ),
              // 3. Gastos
              Expanded(
                child: Column(
                  children: [
                    Text(
                      CurrencyFormatter.formatCompact(gastos),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.expenseRed,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gastos',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animateEntrance(delay: 100.ms);
  }

  Widget _buildExpensesByCategoryCard(
      Map<String, double> expenses, double totalSpent) {
    if (expenses.isEmpty) {
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
      );
    }

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gastos por categoría',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Donut pie chart row
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
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedPieIndex = -1;
                                return;
                              }
                              _touchedPieIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 3,
                        centerSpaceRadius: 42,
                        sections: _buildPieSections(expenses),
                      ),
                    ),
                    // Center text showing total spent
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          CurrencyFormatter.formatCompact(totalSpent),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
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
              // Category legend list
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: expenses.entries.toList().asMap().entries.map((item) {
                    final index = item.key;
                    final entry = item.value;
                    final category = entry.key;
                    final amount = entry.value;
                    final percentage =
                        totalSpent > 0 ? (amount / totalSpent) * 100 : 0.0;
                    final color = _getCategoryColor(category);
                    final isSelected = _touchedPieIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _touchedPieIndex = isSelected ? -1 : index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 6,
                        ),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _translateCategory(category),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(0)}%',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.formatCompact(amount),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animateEntrance(delay: 150.ms);
  }

  Widget _buildSmartScoreHistoryCard(AnalysisProvider provider) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evolución de Salud Financiera',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Tu historial de SmartScore en los últimos 6 meses',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (provider.scoreHistory.isEmpty)
            Container(
              height: 120,
              alignment: Alignment.center,
              child: Text(
                'No hay historial de salud financiera disponible.',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            )
          else
            SizedBox(
              height: 160,
              child: LineChart(
                _buildLineChartData(provider.scoreHistory),
              ),
            ),
        ],
      ),
    ).animateEntrance(delay: 200.ms);
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
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Icon(
                  _getCategoryIcon(entry.key),
                  size: 12,
                  color: color,
                ),
              )
            : null,
        badgePositionPercentageOffset: 0.9,
      );
    }).toList();
  }

  LineChartData _buildLineChartData(List<SmartScoreSnapshotModel> history) {
    final maxSpots = history.length;
    final List<FlSpot> spots = [];
    for (int i = 0; i < maxSpots; i++) {
      spots.add(FlSpot(i.toDouble(), history[i].score.toDouble()));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 25,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade100,
            strokeWidth: 1.0,
            dashArray: [5, 5],
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 25,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < history.length) {
                final item = history[index];
                final monthName = _getMonthNameShort(item.mes);
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    monthName,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      minX: 0,
      maxX: maxSpots > 1 ? (maxSpots - 1).toDouble() : 1.0,
      minY: 0,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: const LinearGradient(
            colors: [
              AppColors.primaryGreen,
              AppColors.incomeGreen,
            ],
          ),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
              radius: 4.5,
              color: Colors.white,
              strokeWidth: 2.5,
              strokeColor: AppColors.primaryGreen,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryGreen.withValues(alpha: 0.16),
                AppColors.primaryGreen.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getMonthNameShort(int month) {
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
      'Dic'
    ];
    if (month >= 1 && month <= 12) {
      return list[month - 1];
    }
    return '';
  }

  // Custom month picker dialog
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
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
                    // Year selector arrows
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.chevronLeft, size: 16),
                          onPressed: () {
                            setDialogState(() {
                              tempYear--;
                            });
                          },
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
                              : () {
                                  setDialogState(() {
                                    tempYear++;
                                  });
                                },
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.dividerGray),
                    const SizedBox(height: 8),
                    // Month Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
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
