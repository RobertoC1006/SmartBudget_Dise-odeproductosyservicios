import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'widgets/goal_category_icon.dart';
import 'widgets/goal_format.dart';

/// ① del flujo de aporte a meta: ingresar monto, fecha y descripción.
/// Reemplaza el bottom sheet de aporte del detalle. "Continuar" lleva a la
/// pantalla de confirmación (② `/goals/:id/contribute/confirm`).
class GoalContributeScreen extends StatefulWidget {
  const GoalContributeScreen({super.key, required this.goalId});
  final int goalId;

  @override
  State<GoalContributeScreen> createState() => _GoalContributeScreenState();
}

class _GoalContributeScreenState extends State<GoalContributeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  static const List<int> _quickAmounts = [50, 100, 200, 500];

  late DateTime _fecha;
  bool _saldoError = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fecha = DateTime(now.year, now.month, now.day);
    _amountController.addListener(_onAmountChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final goalProvider = context.read<GoalProvider>();
      if (goalProvider.goalById(widget.goalId) == null) {
        goalProvider.loadGoals();
      }
      // El saldo disponible vive en el presupuesto del dashboard.
      final budgetProvider = context.read<BudgetProvider>();
      if (budgetProvider.currentBudget == null) {
        budgetProvider.loadDashboard();
      }
    });
  }

  void _onAmountChanged() {
    // Limpia el error de saldo al escribir y refresca el realce de los chips.
    setState(() => _saldoError = false);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0.0;

  void _setAmount(int value) {
    _amountController.text = value.toString();
    _amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: _amountController.text.length),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year, now.month, now.day),
      locale: const Locale('es'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryGreen,
            onPrimary: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _fecha = DateTime(picked.year, picked.month, picked.day));
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/goals/${widget.goalId}');
    }
  }

  void _continue(double saldoDisponible) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_amount > saldoDisponible) {
      setState(() => _saldoError = true);
      return;
    }
    final desc = _descController.text.trim();
    context.push('/goals/${widget.goalId}/contribute/confirm', extra: {
      'monto': _amount,
      'fecha': _fecha,
      'descripcion': desc.isEmpty ? null : desc,
    });
  }

  @override
  Widget build(BuildContext context) {
    final goal = context.watch<GoalProvider>().goalById(widget.goalId);
    final saldo = context.watch<BudgetProvider>().currentBudget?.saldoDisponible ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      body: SafeArea(
        child: goal == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppHeader(),
                      const SizedBox(height: AppSpacing.sm),
                      _buildTitleRow(),
                      const SizedBox(height: AppSpacing.md),

                      _GoalCard(goal: goal).animateEntrance(delay: 60.ms),
                      const SizedBox(height: AppSpacing.lg),

                      _label('¿Cuánto deseas aportar?'),
                      const SizedBox(height: 8),
                      _buildAmountField().animateEntrance(delay: 100.ms),
                      const SizedBox(height: 12),
                      _buildQuickChips().animateEntrance(delay: 140.ms),
                      const SizedBox(height: AppSpacing.lg),

                      _buildSaldoCard(saldo).animateEntrance(delay: 180.ms),
                      const SizedBox(height: AppSpacing.lg),

                      _label('Fecha'),
                      const SizedBox(height: 8),
                      _buildDateField().animateEntrance(delay: 220.ms),
                      const SizedBox(height: AppSpacing.lg),

                      _label('Descripción (opcional)'),
                      const SizedBox(height: 8),
                      _buildDescriptionField().animateEntrance(delay: 260.ms),
                      const SizedBox(height: AppSpacing.xl),

                      SizedBox(
                        width: double.infinity,
                        child: SBButton.primary(
                          label: 'Continuar',
                          onPressed: () => _continue(saldo),
                          customColor: AppColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ).animateEntrance(delay: 300.ms),
                    ],
                  ),
                ),
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
            'Aportar a la meta',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading2.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1C2434),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      autofocus: true,
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(
        prefixText: 'S/ ',
        prefixStyle: GoogleFonts.inter(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryGreen,
        ),
        hintText: '0.00',
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontWeight: FontWeight.w800,
          fontSize: 30,
        ),
        fillColor: AppColors.surfaceWhite,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      ),
      validator: (v) {
        final val = double.tryParse((v ?? '').trim());
        if (val == null || val <= 0) return 'Ingresa un monto válido';
        return null;
      },
    );
  }

  Widget _buildQuickChips() {
    return Row(
      children: [
        for (final amount in _quickAmounts) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => _setAmount(amount),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEAEAEA)),
                ),
                child: Text(
                  'S/ $amount',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          if (amount != _quickAmounts.last) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildSaldoCard(double saldo) {
    final exceeds = _saldoError || (_amount > 0 && _amount > saldo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: exceeds ? const Color(0xFFFEF2F2) : const Color(0xFFF3FAF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: exceeds ? AppColors.expenseRed.withValues(alpha: 0.4) : AppColors.accentGreenBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            exceeds ? LucideIcons.alertCircle : LucideIcons.wallet,
            size: 18,
            color: exceeds ? AppColors.expenseRed : AppColors.primaryDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              exceeds ? 'Supera tu saldo disponible' : 'Saldo disponible',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: exceeds ? AppColors.expenseRed : AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            GoalFormat.money(saldo),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: exceeds ? AppColors.expenseRed : AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    final now = DateTime.now();
    final isToday = _fecha.year == now.year && _fecha.month == now.month && _fecha.day == now.day;
    final formatted = DateFormat("dd 'de' MMMM 'de' yyyy", 'es').format(_fecha);
    final label = isToday ? 'Hoy, $formatted' : formatted;
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAEAEA)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.calendar, size: 18, color: Color(0xFF80C29E)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(LucideIcons.chevronDown, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descController,
      maxLength: 50,
      maxLines: 2,
      textCapitalization: TextCapitalization.sentences,
      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: 'Ej: Aporte de mi sueldo de junio',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
        counterStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
        fillColor: AppColors.surfaceWhite,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      ),
    );
  }
}

/// Tarjeta compacta de la meta (icono + nombre + saldo/objetivo + progreso).
class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});
  final GoalModel goal;

  @override
  Widget build(BuildContext context) {
    final cat = resolveCategoria(goal.categoria, goal.nombre);
    final pct = (goal.progreso * 100).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accentGreenBorder),
      ),
      child: Row(
        children: [
          GoalCategoryIcon(category: cat, size: 54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1C2434),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${GoalFormat.money(goal.saldoAcumulado)} de ${GoalFormat.money(goal.montoObjetivo)}',
                  style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: goal.progreso,
                          minHeight: 8,
                          backgroundColor: Colors.white,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primaryGreen),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$pct%',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
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
}
