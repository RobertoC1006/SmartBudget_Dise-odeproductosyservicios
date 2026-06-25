import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/analysis_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/providers/analysis_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/header_background_painter.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/sb_entrance_animation.dart';
import '../../widgets/transaction_tile.dart';
import 'widgets/category_visuals.dart';

/// 1D · Análisis — Detalle de categoría.
/// Total del mes con comparativa, desglose por comercio, recomendación con
/// simulación de ahorro y las transacciones de la categoría.
class AnalysisCategoryDetailScreen extends StatefulWidget {
  final String categoryKey;
  final int? mes;
  final int? anio;

  const AnalysisCategoryDetailScreen({
    super.key,
    required this.categoryKey,
    this.mes,
    this.anio,
  });

  @override
  State<AnalysisCategoryDetailScreen> createState() =>
      _AnalysisCategoryDetailScreenState();
}

class _AnalysisCategoryDetailScreenState extends State<AnalysisCategoryDetailScreen> {
  static const int _maxRecent = 4;
  static const Widget _itemDivider =
      Divider(height: 1, thickness: 1, color: Color(0xFFEDEEF1));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  void _fetchData() {
    context.read<AnalysisProvider>().loadCategoryDetail(
          categoria: widget.categoryKey,
          mes: widget.mes,
          anio: widget.anio,
        );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/analysis/categories');
    }
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
            CategoryVisuals.label(widget.categoryKey),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildBody(AnalysisProvider provider) {
    if (provider.categoryDetail == null && provider.isCategoryLoading) {
      return _buildSkeleton();
    }
    if (provider.categoryDetail == null && provider.categoryError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: EmptyState(
          icon: LucideIcons.alertCircle,
          title: 'Ocurrió un problema',
          subtitle: provider.categoryError ?? 'Error de red al consultar datos.',
          actionLabel: 'Reintentar',
          onAction: _fetchData,
        ),
      );
    }

    final detail = provider.categoryDetail;
    if (detail == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderCard(detail),
        const SizedBox(height: AppSpacing.md),
        _buildMerchantSection(detail),
        const SizedBox(height: AppSpacing.md),
        _buildRecommendationCard(detail),
        const SizedBox(height: AppSpacing.md),
        _buildTransactionsSection(provider),
      ],
    );
  }

  // ─── Card cabecera ─────────────────────────────────────────────────────────

  Widget _buildHeaderCard(CategoryDetail detail) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryAvatar(categoryKey: widget.categoryKey, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CategoryVisuals.label(widget.categoryKey),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${detail.porcentajeDelTotal.toStringAsFixed(0)}% de tus gastos del mes',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            CurrencyFormatter.format(detail.total),
            style: _amountStyle(32, AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          _buildDelta(detail),
        ],
      ),
    ).animateEntrance(delay: 0.ms);
  }

  /// Comparativa vs mes pasado. En gasto, bajar es bueno → verde.
  Widget _buildDelta(CategoryDetail detail) {
    final pct = detail.deltaPct;
    if (pct == null) {
      return Text(
        'Sin datos del mes pasado',
        style: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      );
    }

    final diff = detail.total - detail.totalPrev;
    final goesDown = diff < 0;
    final isZero = diff.abs() < 0.005;
    final color = isZero
        ? AppColors.textSecondary
        : (goesDown ? AppColors.incomeGreen : AppColors.expenseRed);
    final arrow = isZero ? '' : (goesDown ? '↓ ' : '↑ ');
    final suffix = goesDown ? 'menos que el mes pasado' : 'más que el mes pasado';

    return Row(
      children: [
        Text(
          '$arrow${pct.abs().toStringAsFixed(0)}%',
          style: _amountStyle(13, color, weight: FontWeight.w700),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            isZero
                ? 'igual que el mes pasado'
                : '· ${CurrencyFormatter.format(diff.abs())} $suffix',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─── Desglose por comercio ─────────────────────────────────────────────────

  Widget _buildMerchantSection(CategoryDetail detail) {
    final color = CategoryVisuals.color(widget.categoryKey);
    final merchants = detail.desgloseComercio;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Desglose de ${CategoryVisuals.label(widget.categoryKey).toLowerCase()}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (merchants.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Aún no hay comercios registrados en esta categoría.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            for (int i = 0; i < merchants.length; i++) ...[
              if (i > 0) _itemDivider,
              _buildMerchantRow(merchants[i], detail.total, color),
            ],
        ],
      ),
    ).animateEntrance(delay: 80.ms);
  }

  Widget _buildMerchantRow(MerchantBreakdown m, double categoryTotal, Color color) {
    final fraction = categoryTotal > 0 ? (m.total / categoryTotal).clamp(0.0, 1.0) : 0.0;
    final pct = categoryTotal > 0 ? (m.total / categoryTotal) * 100 : 0.0;
    final txLabel = m.nTransacciones == 1 ? '1 movimiento' : '${m.nTransacciones} movimientos';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.comercio,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      txLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(m.total),
                    style: _amountStyle(14, AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pct.toStringAsFixed(0)}%',
                    style: _amountStyle(11, AppColors.textSecondary, weight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 7,
              backgroundColor: const Color(0xFFF0F1F4),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Recomendación + Simular ahorro ────────────────────────────────────────

  Widget _buildRecommendationCard(CategoryDetail detail) {
    // Sugerencia simple, data-driven: reducir un 20% libera este monto al mes.
    final ahorro20 = detail.total * 0.20;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentGreenBorder, width: 1.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      'Recomendación',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Podrías liberar ${CurrencyFormatter.format(ahorro20)} al mes '
                  'reduciendo un 20% en ${CategoryVisuals.label(widget.categoryKey).toLowerCase()}.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            height: 92,
            child:
                Image.asset(
                      'assets/images/disciplina.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .slideY(begin: 0, end: -0.06, duration: 1800.ms, curve: Curves.easeInOut),
          ),
        ],
      ),
    ).animateEntrance(delay: 160.ms);
  }

  // ─── Transacciones de la categoría ─────────────────────────────────────────

  Widget _buildTransactionsSection(AnalysisProvider provider) {
    final txs = provider.categoryTransactions;
    if (txs.isEmpty) return const SizedBox.shrink();

    final recent = txs.take(_maxRecent).toList();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Transacciones recientes',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (txs.length > _maxRecent)
                GestureDetector(
                  onTap: () => _showAllTransactions(txs),
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'Ver todas',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (int i = 0; i < recent.length; i++) ...[
            if (i > 0) _itemDivider,
            TransactionTile.fromExpense(recent[i], leading: _txLeading(recent[i])),
          ],
        ],
      ),
    ).animateEntrance(delay: 240.ms);
  }

  Widget _txLeading(ExpenseModel e) =>
      CategoryAvatar(categoryKey: e.categoria.name, size: 48);

  void _showAllTransactions(List<ExpenseModel> txs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.dividerGray,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Movimientos de ${CategoryVisuals.label(widget.categoryKey).toLowerCase()}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        for (int i = 0; i < txs.length; i++) ...[
                          if (i > 0) _itemDivider,
                          TransactionTile.fromExpense(txs[i], leading: _txLeading(txs[i])),
                        ],
                      ],
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

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _card({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(18)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: child,
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

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LoadingShimmer.rect(width: double.infinity, height: 150),
        const SizedBox(height: AppSpacing.md),
        LoadingShimmer.rect(width: double.infinity, height: 160),
        const SizedBox(height: AppSpacing.md),
        LoadingShimmer.rect(width: double.infinity, height: 120),
      ],
    );
  }
}
