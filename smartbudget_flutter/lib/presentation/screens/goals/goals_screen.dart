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
    final nameController = TextEditingController();
    final amountController = TextEditingController(
      text: defaultAmount != null ? defaultAmount.toStringAsFixed(2) : '',
    );
    
    int selectedIconIndex = 0;

    // Detect category and pre-select based on defaultName if available
    if (defaultName != null) {
      final nameLower = defaultName.toLowerCase();
      if (nameLower.contains('viaje') || nameLower.contains('vacaciones') || nameLower.contains('playa')) {
        selectedIconIndex = 0;
      } else if (nameLower.contains('casa') || nameLower.contains('hogar') || nameLower.contains('mueble') || nameLower.contains('depa')) {
        selectedIconIndex = 1;
      } else if (nameLower.contains('auto') || nameLower.contains('carro') || nameLower.contains('vehículo') || nameLower.contains('llanta')) {
        selectedIconIndex = 2;
      } else if (nameLower.contains('estudi') || nameLower.contains('universi') || nameLower.contains('curso') || nameLower.contains('educa') || nameLower.contains('laptop') || nameLower.contains('matrícula')) {
        selectedIconIndex = 3;
      } else if (nameLower.contains('salud') || nameLower.contains('emergencia') || nameLower.contains('médic') || nameLower.contains('dental') || nameLower.contains('dentista')) {
        selectedIconIndex = 4;
      } else {
        selectedIconIndex = 5;
      }
      // Clean up special emojis and characters to show clean text
      nameController.text = defaultName.replaceAll(RegExp(r'[^\w\s\dáéíóúÁÉÍÓÚñÑ]'), '').trim();
    }

    final List<_IconItem> iconItems = const [
      _IconItem(name: 'Viaje', icon: LucideIcons.plane, emoji: '✈️'),
      _IconItem(name: 'Casa', icon: LucideIcons.home, emoji: '🏠'),
      _IconItem(name: 'Auto', icon: LucideIcons.car, emoji: '🚗'),
      _IconItem(name: 'Educación', icon: LucideIcons.graduationCap, emoji: '🎓'),
      _IconItem(name: 'Salud', icon: LucideIcons.heart, emoji: '❤️'),
      _IconItem(name: 'Otro', icon: LucideIcons.sparkles, emoji: '✨'),
    ];

    // Smart recommendations map for each category index
    final Map<int, List<String>> recommendations = {
      0: [
        'Vacaciones en Cancún',
        'Eurotrip de aventura',
        'Fin de semana de playa',
        'Viaje familiar',
      ],
      1: [
        'Inicial para mi depa',
        'Remodelación de cocina',
        'Juego de comedor',
        'Pintar el departamento',
      ],
      2: [
        'Cuota inicial del auto',
        'Mantenimiento anual',
        'Seguro vehicular',
        'Llantas nuevas',
      ],
      3: [
        'Ciclo de universidad',
        'Curso de especialización',
        'Libros y matrícula',
        'Nueva Laptop',
      ],
      4: [
        'Fondo de emergencias',
        'Seguro médico anual',
        'Tratamiento dental',
        'Gimnasio y salud',
      ],
      5: [
        'Regalos navideños',
        'Entradas para concierto',
        'Nueva tecnología',
        'Ahorro imprevistos',
      ],
    };

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
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          // Decorative target icon
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE2F3DA),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.target,
                                color: Color(0xFF1B5E20),
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          
                          // Centered Title and Subtitle
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'Nueva Meta',
                                  style: GoogleFonts.inter(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1B5E20), // Dark green title color
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Crea una meta de ahorro para alcanzar tus objetivos',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
    
                          // 1. Nombre de la meta
                          Text(
                            'Nombre de la meta',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1C2434),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: nameController,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                LucideIcons.tag,
                                color: Color(0xFF80C29E),
                                size: 18,
                              ),
                              hintText: 'Ej: Viaje a Europa',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                              fillColor: const Color(0xFFF3FAF2),
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Color(0xFF80C29E), width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Color(0xFF80C29E), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2.0),
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Ingresa un nombre'
                                    : null,
                          ),
                          const SizedBox(height: 10),

                          // Dynamic Name Recommendations
                          Row(
                            children: [
                              const Icon(LucideIcons.sparkles, size: 13, color: Color(0xFF80C29E)),
                              const SizedBox(width: 4),
                              Text(
                                'Sugerencias:',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1B5E20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 34,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: recommendations[selectedIconIndex]!.length,
                              itemBuilder: (context, chipIndex) {
                                final chipText = recommendations[selectedIconIndex]![chipIndex];
                                final isSelected = nameController.text.trim() == chipText;
                                return GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      nameController.text = chipText;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFE2F3DA)
                                          : const Color(0xFFFAFEF9),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primaryGreen
                                            : const Color(0xFFE2F3DA),
                                        width: isSelected ? 1.5 : 1.0,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Text(
                                      chipText,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 18),
    
                          // 2. Monto objetivo (S/)
                          Text(
                            'Monto objetivo (S/)',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1C2434),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: amountController,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                LucideIcons.coins,
                                color: Color(0xFF80C29E),
                                size: 18,
                              ),
                              hintText: '5000.00',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                              fillColor: const Color(0xFFFAFEF9),
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Color(0xFFF3FAF2)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Color(0xFFF3FAF2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
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
                          const SizedBox(height: 18),
    
                          // 3. Ícono selection
                          Text(
                            'Ícono',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1C2434),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // 3-column Grid for Icons
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.15,
                            ),
                            itemCount: iconItems.length,
                            itemBuilder: (context, index) {
                              final item = iconItems[index];
                              final isSelected = selectedIconIndex == index;
    
                              return InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    selectedIconIndex = index;
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFE2F3DA) // Light green selected background
                                        : const Color(0xFFFAFEF9),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primaryGreen
                                          : const Color(0xFFE2F3DA),
                                      width: isSelected ? 2.0 : 1.0,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primaryGreen.withValues(alpha: 0.15),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        item.icon,
                                        color: isSelected
                                            ? AppColors.primaryDark
                                            : const Color(0xFF1C2434),
                                        size: 20,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? AppColors.primaryDark
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
                                  
                                  // Append the selected emoji to the name to persist it
                                  final String finalName =
                                      '${nameController.text.trim()} ${iconItems[selectedIconIndex].emoji}';
                                      
                                  // Calculate a default date in background (e.g. 1 year from now) as date is optional in DB
                                  final DateTime defaultLimitDate =
                                      DateTime.now().add(const Duration(days: 365));
    
                                  final success = await provider.createGoal(
                                    nombre: finalName,
                                    montoObjetivo:
                                        double.parse(amountController.text.trim()),
                                    fechaLimite: defaultLimitDate,
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
                              customColor: const Color(0xFF26A69A), // Teal green color from mockup
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Close button (positioned absolutely in top right)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.x,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
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

class _IconItem {
  final String name;
  final IconData icon;
  final String emoji;

  const _IconItem({
    required this.name,
    required this.icon,
    required this.emoji,
  });
}
