import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'category_visuals.dart';

/// Donut de distribución de gastos con el total al centro.
///
/// Reutilizable por el flujo de Análisis. Agrupa internamente a ≤6 segmentos
/// (top 5 + "Otros") con [CategoryVisuals.topCategories] y resalta el segmento
/// tocado. La leyenda/lista de categorías vive fuera (la maneja cada pantalla).
class CategoryDonut extends StatefulWidget {
  final Map<String, double> expenses;
  final double total;
  final double size;

  const CategoryDonut({
    super.key,
    required this.expenses,
    required this.total,
    this.size = 180,
  });

  @override
  State<CategoryDonut> createState() => _CategoryDonutState();
}

class _CategoryDonutState extends State<CategoryDonut> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final entries = CategoryVisuals.topCategories(widget.expenses).entries.toList();
    final centerRadius = widget.size * 0.31;
    final baseRadius = widget.size * 0.165;

    return SizedBox(
      width: widget.size,
      height: widget.size,
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
                      _touched = -1;
                      return;
                    }
                    _touched = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: centerRadius,
              sections: [
                for (var i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    color: CategoryVisuals.color(entries[i].key),
                    value: entries[i].value,
                    title: '',
                    radius: _touched == i ? baseRadius + 8 : baseRadius,
                    badgeWidget: _touched == i
                        ? _DonutBadge(categoryKey: entries[i].key)
                        : null,
                    badgePositionPercentageOffset: 1.0,
                  ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                CurrencyFormatter.formatCompact(widget.total),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: widget.size * 0.105,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Total',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: widget.size * 0.07,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutBadge extends StatelessWidget {
  final String categoryKey;

  const _DonutBadge({required this.categoryKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Image.asset(
        CategoryVisuals.illustration(categoryKey),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Text(CategoryVisuals.emoji(categoryKey), style: const TextStyle(fontSize: 13)),
        ),
      ),
    );
  }
}
