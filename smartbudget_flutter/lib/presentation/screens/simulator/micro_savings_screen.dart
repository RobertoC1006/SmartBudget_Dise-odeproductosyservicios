import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/analysis_model.dart';
import '../../../data/providers/analysis_provider.dart';
import '../../../data/providers/budget_provider.dart';
import '../../widgets/header_background_painter.dart';
import '../../widgets/sb_button.dart';
import '../../widgets/sb_text_field.dart';
import '../../widgets/sb_entrance_animation.dart';

class MicroSavingsScreen extends StatefulWidget {
  const MicroSavingsScreen({super.key});

  @override
  State<MicroSavingsScreen> createState() => _MicroSavingsScreenState();
}

class _MicroSavingsScreenState extends State<MicroSavingsScreen> {
  int _simModule = 0; // 0 = Compras, 1 = Micro-ahorro
  String _selectedCategory = 'comida';
  double _gastoActual = 0.0;
  double _gastoObjetivo = 0.0;

  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  double _sliderValue = 0.0;

  @override
  void initState() {
    super.initState();
    _amountFocusNode.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AnalysisProvider>();
      if (provider.expensesByCategory == null) {
        provider.loadAnalysisData().then((_) {
          if (mounted) _prefillMicroSavings();
        });
      } else {
        _prefillMicroSavings();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Color _getCategoryColor(String key) {
    switch (key.toLowerCase()) {
      case 'comida':      return const Color(0xFFEF4444);
      case 'transporte':  return const Color(0xFF3B82F6);
      case 'ocio':        return const Color(0xFFA855F7);
      case 'salud':       return const Color(0xFF10B981);
      case 'educacion':   return const Color(0xFF6366F1);
      case 'ropa':        return const Color(0xFFEC4899);
      case 'hogar':       return const Color(0xFFF59E0B);
      case 'tecnologia':  return const Color(0xFF0EA5E9);
      case 'viajes':      return const Color(0xFF14B8A6);
      default:            return const Color(0xFF6B7280);
    }
  }

  String _translateCategory(String key) {
    switch (key.toLowerCase()) {
      case 'comida':      return 'Comida';
      case 'transporte':  return 'Transporte';
      case 'ocio':        return 'Ocio';
      case 'salud':       return 'Salud';
      case 'educacion':   return 'Educación';
      case 'ropa':        return 'Ropa';
      case 'hogar':       return 'Hogar';
      case 'tecnologia':  return 'Tecnología';
      case 'viajes':      return 'Viajes';
      default:            return 'Otros';
    }
  }

  IconData _getCategoryIcon(String key) {
    switch (key.toLowerCase()) {
      case 'comida':      return LucideIcons.utensils;
      case 'transporte':  return LucideIcons.car;
      case 'ocio':        return LucideIcons.gamepad2;
      case 'salud':       return LucideIcons.heart;
      case 'educacion':   return LucideIcons.bookOpen;
      case 'ropa':        return LucideIcons.shirt;
      case 'hogar':       return LucideIcons.home;
      case 'tecnologia':  return LucideIcons.laptop;
      case 'viajes':      return LucideIcons.plane;
      default:            return LucideIcons.moreHorizontal;
    }
  }

  void _prefillMicroSavings() {
    final expenses = context.read<AnalysisProvider>().expensesByCategory;
    if (expenses == null || expenses.isEmpty) return;
    final sorted = expenses.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.isEmpty) return;
    setState(() {
      _selectedCategory = sorted.first.key;
      _gastoActual = sorted.first.value;
      _gastoObjetivo = (_gastoActual * 0.7).roundToDouble();
    });
  }

  void _onCategorySelected(String cat, Map<String, double> expenses) {
    setState(() {
      _selectedCategory = cat;
      _gastoActual = expenses[cat] ?? 0.0;
      _gastoObjetivo = (_gastoActual * 0.7).roundToDouble();
      context.read<AnalysisProvider>().clearSavingsProjection();
    });
  }

  // ─── Glass card ─────────────────────────────────────────────────────────────

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
            border: Border.all(
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

  // ─── Module selector ────────────────────────────────────────────────────────

  Widget _buildSimModuleSelector() {
    final modules = [
      (icon: LucideIcons.shoppingCart, label: 'Compras'),
      (icon: LucideIcons.trendingDown, label: 'Micro-ahorro'),
    ];
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFE2ECD9),
        borderRadius: BorderRadius.circular(23),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(modules.length, (i) {
          final isSelected = _simModule == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _simModule = i;
                  if (i == 1) _prefillMicroSavings();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(19),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      modules[i].icon,
                      size: 14,
                      color: isSelected
                          ? AppColors.primaryGreen
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      modules[i].label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Purchase simulator ─────────────────────────────────────────────────────

  Widget _buildPurchaseSimulatorContent(
      AnalysisProvider provider, BudgetProvider budgetProvider) {
    final saldoDisponible =
        budgetProvider.currentBudget?.saldoDisponible ?? 0.0;
    final maxSlider = max(3000.0, saldoDisponible * 2);

    return Column(
      children: [
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0FDF4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.compass,
                        color: AppColors.primaryGreen, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Simulador de Compras',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa un monto para simular cómo afectará a tu presupuesto y metas activas.',
                style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildGlowInputWrapper(
                isFocused: _amountFocusNode.hasFocus,
                child: SBTextField.currency(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  labelText: 'Monto de la compra',
                  hintText: '0.00',
                  onChanged: (val) {
                    final cleanVal = val.replaceAll('S/ ', '').trim();
                    final parsed = double.tryParse(cleanVal);
                    if (parsed != null && parsed <= maxSlider) {
                      setState(() => _sliderValue = parsed);
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primaryGreen,
                  inactiveTrackColor: AppColors.dividerGray,
                  thumbColor: AppColors.primaryGreen,
                  overlayColor: AppColors.primaryGreen.withValues(alpha: 0.12),
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 10),
                ),
                child: Slider(
                  value: _sliderValue.clamp(0.0, maxSlider),
                  min: 0.0,
                  max: maxSlider,
                  onChanged: (val) {
                    setState(() {
                      _sliderValue = val;
                      _amountController.text = val.toStringAsFixed(2);
                    });
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('S/ 0.00',
                      style: AppTextStyles.caption.copyWith(fontSize: 10)),
                  Text('Max: ${CurrencyFormatter.format(maxSlider)}',
                      style: AppTextStyles.caption.copyWith(fontSize: 10)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SBButton.primary(
                label: 'Simular Compra',
                isLoading: provider.isLoading,
                onPressed: () {
                  final amt = double.tryParse(
                      _amountController.text.replaceAll('S/ ', '').trim());
                  if (amt != null && amt > 0) {
                    provider.runSimulation(amt);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Ingresa un monto válido mayor a 0.')),
                    );
                  }
                },
              ),
            ],
          ),
        ).animateEntrance(),
        const SizedBox(height: AppSpacing.md),
        if (provider.simulationResult != null)
          _buildSimulationResult(provider.simulationResult!)
        else if (provider.errorMessage != null)
          _buildSimulatorError(provider.errorMessage!),
      ],
    );
  }

  Widget _buildGlowInputWrapper({
    required Widget child,
    required bool isFocused,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.primaryGreen.withValues(alpha: 0.12),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: child,
    );
  }

  Widget _buildSimulationResult(SimulationResult res) {
    Color riskBg;
    Color riskBorder;
    Color riskText;
    IconData riskIcon;
    String riskTitle;

    switch (res.nivelRiesgo.toLowerCase()) {
      case 'critico':
        riskBg = const Color(0xFFFFF1F2);
        riskBorder = const Color(0xFFFECDD3);
        riskText = const Color(0xFFBE123C);
        riskIcon = LucideIcons.alertOctagon;
        riskTitle = 'Simulación de Riesgo Crítico';
        break;
      case 'medio':
        riskBg = const Color(0xFFFFFBEB);
        riskBorder = const Color(0xFFFEF3C7);
        riskText = const Color(0xFFD97706);
        riskIcon = LucideIcons.alertTriangle;
        riskTitle = 'Simulación de Riesgo Moderado';
        break;
      default:
        riskBg = const Color(0xFFECFDF5);
        riskBorder = const Color(0xFFA7F3D0);
        riskText = const Color(0xFF047857);
        riskIcon = LucideIcons.checkCircle2;
        riskTitle = 'Simulación Viable y Segura';
        break;
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: riskBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: riskBorder, width: 1.2),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(riskIcon, color: riskText, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    riskTitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: riskText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                res.mensajeAnalisis,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: riskText.withValues(alpha: 0.9),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ).animateEntrance(delay: 100.ms),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildGlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saldo Proyectado',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(res.saldoProyectado),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: res.saldoProyectado < 0
                            ? AppColors.expenseRed
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildGlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saldo Consumido',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      '${res.porcentajeSaldoConsumido.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: res.porcentajeSaldoConsumido > 75
                            ? AppColors.expenseRed
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).animateEntrance(delay: 200.ms),
        const SizedBox(height: AppSpacing.md),
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Impacto en Metas de Ahorro',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Dificultad de ahorro adicional por cada meta activa',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (res.impactoMetas.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  alignment: Alignment.center,
                  child: Text(
                    'No tienes metas de ahorro activas afectadas.',
                    style: AppTextStyles.caption,
                  ),
                )
              else
                Column(
                  children: res.impactoMetas.map((goal) {
                    final currentProgress = goal.montoObjetivo > 0
                        ? (goal.saldoAcumulado / goal.montoObjetivo)
                        : 0.0;
                    final compromisedProgress = goal.montoObjetivo > 0
                        ? (goal.porcentajeComprometido / 100) *
                            (1.0 - currentProgress)
                        : 0.0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                goal.nombre,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (goal.porcentajeComprometido > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF1F2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFFFECDD3)),
                                  ),
                                  child: Text(
                                    '-${goal.porcentajeComprometido.toStringAsFixed(0)}% recursos',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFE11D48),
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  'Sin impacto',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildDoubleProgressBar(
                            progress: currentProgress,
                            compromised: compromisedProgress,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(currentProgress * 100).toStringAsFixed(0)}% completado',
                                style: AppTextStyles.caption
                                    .copyWith(fontSize: 10.5, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Faltante: ${CurrencyFormatter.format(goal.faltanteActual)}',
                                style: AppTextStyles.caption
                                    .copyWith(fontSize: 10.5, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ).animateEntrance(delay: 300.ms),
      ],
    );
  }

  Widget _buildDoubleProgressBar({
    required double progress,
    required double compromised,
  }) {
    final double clampedProgress = progress.clamp(0.0, 1.0);
    final double clampedCompromised =
        compromised.clamp(0.0, 1.0 - clampedProgress);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final progressWidth = maxWidth * clampedProgress;
        final compromisedWidth = maxWidth * clampedCompromised;
        return Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.dividerGray,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                width: progressWidth,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              if (clampedCompromised > 0)
                Positioned(
                  left: progressWidth,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    width: compromisedWidth,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.expenseRed.withValues(alpha: 0.7),
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(5)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─── Micro-savings module ────────────────────────────────────────────────────

  Widget _buildMicroSavingsModule(AnalysisProvider provider) {
    final expenses = provider.expensesByCategory ?? {};
    final categories = [
      'comida', 'transporte', 'ocio', 'salud',
      'educacion', 'ropa', 'hogar', 'tecnologia', 'viajes', 'otros',
    ];

    return Column(
      children: [
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0FDF4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.trendingDown,
                        color: AppColors.primaryGreen, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Proyector de Micro-ahorro',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '¿Qué pasa si gasto menos en una categoría? Descubre cuánto acumulas.',
                style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Selecciona una categoría',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = categories[i];
                    final isSelected = _selectedCategory == cat;
                    final catColor = _getCategoryColor(cat);
                    return GestureDetector(
                      onTap: () => _onCategorySelected(cat, expenses),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? catColor.withValues(alpha: 0.12)
                              : const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? catColor : const Color(0xFFE4E7EB),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getCategoryIcon(cat),
                                size: 13,
                                color: isSelected
                                    ? catColor
                                    : AppColors.textSecondary),
                            const SizedBox(width: 5),
                            Text(
                              _translateCategory(cat),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? catColor
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE4E7EB)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Gasto actual en ${_translateCategory(_selectedCategory)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _gastoActual > 0
                          ? CurrencyFormatter.format(_gastoActual)
                          : 'Sin datos',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _gastoActual > 0
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nuevo objetivo mensual',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      CurrencyFormatter.format(_gastoObjetivo),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primaryGreen,
                  inactiveTrackColor: AppColors.dividerGray,
                  thumbColor: AppColors.primaryGreen,
                  overlayColor: AppColors.primaryGreen.withValues(alpha: 0.12),
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 10),
                ),
                child: Slider(
                  value: _gastoActual > 0
                      ? _gastoObjetivo.clamp(0.0, _gastoActual)
                      : 0.0,
                  min: 0.0,
                  max: _gastoActual > 0 ? _gastoActual : 1.0,
                  onChanged: _gastoActual > 0
                      ? (val) =>
                          setState(() => _gastoObjetivo = val.roundToDouble())
                      : null,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('S/ 0',
                      style: AppTextStyles.caption.copyWith(fontSize: 10)),
                  Text(
                    'Actual: ${CurrencyFormatter.format(_gastoActual)}',
                    style: AppTextStyles.caption.copyWith(fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SBButton.primary(
                label: 'Proyectar ahorro',
                isLoading: provider.isProjecting,
                onPressed: _gastoActual > 0 && _gastoObjetivo < _gastoActual
                    ? () => provider.runSavingsProjection(
                          categoria: _selectedCategory,
                          gastoActual: _gastoActual,
                          gastoObjetivo: _gastoObjetivo,
                        )
                    : null,
              ),
            ],
          ),
        ).animateEntrance(),
        const SizedBox(height: AppSpacing.md),
        if (provider.savingsProjection != null)
          _buildProjectionResults(provider.savingsProjection!)
        else if (provider.projectionError != null)
          _buildSimulatorError(provider.projectionError!),
      ],
    );
  }

  Widget _buildProjectionResults(SavingsProjectionResult res) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.lightbulb,
                  color: Color(0xFF047857), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  res.mensaje,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF047857),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ).animateEntrance(delay: 50.ms),
        const SizedBox(height: AppSpacing.md),
        _buildGlassCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ahorro mensual',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(res.ahorroMensual),
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  children: [
                    Text('Por semana',
                        style: AppTextStyles.caption.copyWith(fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(res.ahorroSemanal),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animateEntrance(delay: 100.ms),
        const SizedBox(height: AppSpacing.md),
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Proyección acumulada',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text('Si mantienes este hábito…',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              _buildTimelineBar('3 meses', res.proyeccion3m, res.proyeccion12m, 100.ms),
              const SizedBox(height: 14),
              _buildTimelineBar('6 meses', res.proyeccion6m, res.proyeccion12m, 180.ms),
              const SizedBox(height: 14),
              _buildTimelineBar('12 meses', res.proyeccion12m, res.proyeccion12m, 260.ms),
            ],
          ),
        ).animateEntrance(delay: 200.ms),
        if (res.metaImpacto.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.target,
                        size: 16, color: AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      'Aceleración de metas',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'En cuántos meses cubres cada meta con este ahorro',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                ...res.metaImpacto.asMap().entries
                    .map((e) => _buildGoalAccelCard(e.value, e.key)),
              ],
            ),
          ).animateEntrance(delay: 320.ms),
        ],
      ],
    );
  }

  Widget _buildTimelineBar(
      String label, double amount, double max12m, Duration delay) {
    final fraction = max12m > 0 ? (amount / max12m).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            Text(
              CurrencyFormatter.format(amount),
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(builder: (_, constraints) {
          return Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.dividerGray,
              borderRadius: BorderRadius.circular(5),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              width: constraints.maxWidth * fraction,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7CC827), Color(0xFF4C8C2B)],
                ),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          );
        }),
      ],
    ).animate().fade(delay: delay, duration: 400.ms).slideX(
        begin: -0.05, end: 0, delay: delay, duration: 400.ms);
  }

  Widget _buildGoalAccelCard(MetaImpactoProjection meta, int index) {
    final meses = meta.mesesParaCompletar;
    final pct = meta.porcentajeCubierto12m;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  meta.nombre,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (meses != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: meses <= 12
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: meses <= 12
                          ? const Color(0xFFA7F3D0)
                          : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Text(
                    '${meses.toStringAsFixed(0)} meses',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: meses <= 12
                          ? const Color(0xFF047857)
                          : const Color(0xFFD97706),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6,
              backgroundColor: AppColors.dividerGray,
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 100 ? AppColors.primaryGreen : const Color(0xFF7CC827),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${pct.toStringAsFixed(0)}% de la meta cubierta en 12 meses · Faltante: ${CurrencyFormatter.format(meta.faltante)}',
            style: AppTextStyles.caption.copyWith(fontSize: 10.5),
          ),
        ],
      ),
    ).animate().fade(
        delay: Duration(milliseconds: 340 + index * 60), duration: 400.ms);
  }

  Widget _buildSimulatorError(String error) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECDD3), width: 1.2),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.alertOctagon,
              color: AppColors.expenseRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error de simulación',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.expenseRed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.expenseRed.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    final budgetProvider = context.watch<BudgetProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: HeaderBackgroundPainter()),
            ),
            Column(
              children: [
                _buildScreenHeader(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    children: [
                      _buildSimModuleSelector(),
                      const SizedBox(height: AppSpacing.md),
                      if (_simModule == 0)
                        _buildPurchaseSimulatorContent(provider, budgetProvider)
                      else
                        _buildMicroSavingsModule(provider),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(LucideIcons.arrowLeft,
                  size: 20, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Micro-ahorro progresivo',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Simulador Financiero',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/images/piggy_bank_3d.png',
            height: 46,
            fit: BoxFit.contain,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
