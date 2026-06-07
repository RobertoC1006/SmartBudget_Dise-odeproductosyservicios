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
        child: RefreshIndicator(
          onRefresh: () => goalProvider.loadGoals(),
          color: AppColors.primaryGreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (with avatar image and notification bell)
                const AppHeader(),

                const SizedBox(height: AppSpacing.md),

                // Title and "+ Nueva meta" Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mis metas',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showCreateGoalDialog(context),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.plus,
                            color: AppColors.primaryGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Nueva meta',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animateEntrance(delay: 0.ms),

                const SizedBox(height: AppSpacing.lg),

                // Card 1: Meta sugerida para ti
                _buildSuggestedGoalCard().animateEntrance(delay: 50.ms),

                const SizedBox(height: AppSpacing.xl),

                // Segmented Tab Selector
                _buildTabSelector().animateEntrance(delay: 100.ms),

                const SizedBox(height: AppSpacing.lg),

                // Active List or Loading State
                _buildGoalsList(goalProvider).animateEntrance(delay: 150.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedGoalCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meta sugerida para ti 💡',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Crea una meta de emergencia para estar preparado ante imprevistos.',
                  style: AppTextStyles.bodySecondary.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _showCreateGoalDialog(
                    context,
                    defaultName: 'Fondo de emergencia 🛡️',
                    defaultAmount: 3000.00,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2F3DA), // Light green background matching mockup
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Crear meta',
                      style: AppTextStyles.captionBold.copyWith(
                        color: AppColors.primaryDark,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Image.asset(
              'assets/images/piggy_bank_3d.png',
              fit: BoxFit.contain,
              height: 95,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    LucideIcons.piggyBank,
                    color: AppColors.primaryGreen,
                    size: 40,
                  ),
                );
              },
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
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 0
                      ? const Color(0xFFE2F3DA)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Mis metas',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _activeTab == 0
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
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
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 1
                      ? const Color(0xFFE2F3DA)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Historial',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _activeTab == 1
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
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
      final isCompleted = goal.estado == EstadoMeta.completada ||
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
        return _buildGoalCard(filteredGoals[index]);
      },
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
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal.nombre,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              // Trash delete button if active tab is 0
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: 'S/ ${goal.saldoAcumulado.toStringAsFixed(2)} ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const TextSpan(text: 'de '),
                    TextSpan(
                      text: 'S/ ${goal.montoObjetivo.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$progressPercent%',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProgressBar(
            progress: progress,
            foregroundColor: const Color(0xFF8BC34A), // Lime green matching mockup
            height: 8.0,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Faltan: S/ ${remaining.clamp(0, double.infinity).toStringAsFixed(2)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fecha objetivo: $formattedDate',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
              if (_activeTab == 0 && remaining > 0)
                GestureDetector(
                  onTap: () => _showContributeDialog(context, goal),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2F3DA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Aportar',
                      style: AppTextStyles.captionBold.copyWith(
                        color: AppColors.primaryDark,
                        fontSize: 13,
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

  void _confirmDeleteGoal(BuildContext context, GoalModel goal) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final provider = context.read<GoalProvider>();
                await provider.deleteGoal(goal.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Meta eliminada con éxito')),
                  );
                }
              },
              child: Text(
                'Eliminar',
                style: GoogleFonts.inter(color: AppColors.expenseRed, fontWeight: FontWeight.bold),
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
    final nameController = TextEditingController(text: defaultName);
    final amountController = TextEditingController(
      text: defaultAmount != null ? defaultAmount.toStringAsFixed(2) : '',
    );
    DateTime? limitDate;
    final dateController = TextEditingController();

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
              child: SingleChildScrollView(
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
                            'Nueva meta',
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
                      const SizedBox(height: 16),
                      // Nombre
                      Text(
                        'Nombre de la meta',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameController,
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Ej. Vacaciones en Europa ✈️',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                          fillColor: const Color(0xFFF3FAF2),
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Ingresa un nombre'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      // Monto Objetivo
                      Text(
                        'Monto objetivo (S/)',
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
                          hintText: 'Ej. 6000.00',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                          fillColor: const Color(0xFFF3FAF2),
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
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
                      const SizedBox(height: 16),
                      // Fecha límite
                      Text(
                        'Fecha objetivo',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2035),
                            locale: const Locale('es', 'ES'),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppColors.primaryGreen,
                                    onPrimary: Colors.white,
                                    onSurface: AppColors.textPrimary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setDialogState(() {
                              limitDate = picked;
                              dateController.text =
                                  DateFormat("dd 'de' MMMM 'de' yyyy", 'es')
                                      .format(picked);
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: dateController,
                            style: AppTextStyles.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Selecciona una fecha',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                              fillColor: const Color(0xFFF3FAF2),
                              filled: true,
                              prefixIcon: const Icon(
                                LucideIcons.calendar,
                                color: AppColors.primaryGreen,
                                size: 18,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty
                                    ? 'Selecciona una fecha'
                                    : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Guardar Button
                      SizedBox(
                        width: double.infinity,
                        child: SBButton.primary(
                          label: 'Crear Meta',
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final provider = context.read<GoalProvider>();
                              final success = await provider.createGoal(
                                nombre: nameController.text.trim(),
                                montoObjetivo:
                                    double.parse(amountController.text.trim()),
                                fechaLimite: limitDate,
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
    final saldoDisponible = budgetProvider.currentBudget?.saldoDisponible ?? 0.0;

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
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                      fillColor: const Color(0xFFF3FAF2),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
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
                          final amount = double.parse(amountController.text.trim());
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
