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
import '../../../data/providers/goal_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/sb_button.dart';
import '../../widgets/sb_entrance_animation.dart';
import 'widgets/goal_category_icon.dart';
import 'widgets/goal_format.dart';

/// Pantalla 1C del flujo de metas: crear una nueva meta a pantalla completa.
/// Reemplaza el diálogo modal anterior. Sigue el mockup: nombre → cuánto
/// necesitas → en cuánto tiempo (chips) → fecha objetivo → aporte sugerido →
/// recordatorio → crear.
class GoalCreateScreen extends StatefulWidget {
  const GoalCreateScreen({super.key});

  @override
  State<GoalCreateScreen> createState() => _GoalCreateScreenState();
}

class _GoalCreateScreenState extends State<GoalCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  static const List<int> _monthOptions = [3, 6, 12, 18, 24];
  int _selectedMonths = 6;
  late DateTime _targetDate;
  bool _recordatorio = true;
  bool _isSaving = false;

  // Categoría (logo) de la meta: se autosugiere desde el nombre hasta que el
  // usuario la elige manualmente en el selector.
  MetaCategoria _categoria = MetaCategoria.otros;
  bool _categoriaManual = false;

  @override
  void initState() {
    super.initState();
    _targetDate = _dateFromMonths(_selectedMonths);
    _amountController.addListener(() => setState(() {})); // refresca el aporte
    _nameController.addListener(_autoSuggestCategoria);
  }

  /// Mientras el usuario no toque el selector, la categoría se sugiere sola
  /// a partir del nombre que va escribiendo.
  void _autoSuggestCategoria() {
    if (_categoriaManual) return;
    final detected = detectMetaCategoria(_nameController.text);
    if (detected != _categoria) {
      setState(() => _categoria = detected);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  DateTime _dateFromMonths(int months) {
    final now = DateTime.now();
    return DateTime(now.year, now.month + months, now.day);
  }

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0.0;

  /// Meses entre hoy y la fecha objetivo (mínimo 1) para el aporte sugerido.
  int get _effectiveMonths {
    final m = GoalFormat.monthsRemaining(_targetDate) ?? _selectedMonths;
    return m < 1 ? 1 : m;
  }

  double get _suggestedMonthly => _amount > 0 ? _amount / _effectiveMonths : 0.0;

  void _selectMonths(int months) {
    setState(() {
      _selectedMonths = months;
      _targetDate = _dateFromMonths(months);
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10),
      locale: const Locale('es'),
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
      setState(() {
        _targetDate = picked;
        _selectedMonths = -1; // fecha manual: deselecciona los chips
      });
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final provider = context.read<GoalProvider>();
    final success = await provider.createGoal(
      nombre: _nameController.text.trim(),
      montoObjetivo: _amount,
      fechaLimite: _targetDate,
      categoria: _categoria.value,
      recordatorio: _recordatorio,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      context.go('/goals');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Meta creada con éxito!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'No se pudo crear la meta'),
        ),
      );
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
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppHeader(),
                const SizedBox(height: AppSpacing.sm),
                _buildTitleRow(),
                const SizedBox(height: AppSpacing.md),

                // Mochila verde fija con flotación suave. La categoría real
                // (isla, auto, etc.) se asigna al logo de la meta, no aquí.
                Center(
                  child:
                      Image.asset(
                            'assets/images/crear_meta.png',
                            width: 150,
                            height: 150,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  LucideIcons.target,
                                  size: 64,
                                  color: AppColors.primaryGreen,
                                ),
                          )
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .slideY(
                            begin: 0,
                            end: -0.06,
                            duration: 1800.ms,
                            curve: Curves.easeInOut,
                          ),
                ),
                const SizedBox(height: AppSpacing.lg),

                _label('Nombre de la meta'),
                const SizedBox(height: 8),
                _buildNameField().animateEntrance(delay: 80.ms),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  children: [
                    _label('Categoría'),
                    const SizedBox(width: 6),
                    Text(
                      _categoriaManual ? '' : '(sugerida)',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildCategorySelector().animateEntrance(delay: 100.ms),
                const SizedBox(height: AppSpacing.lg),

                _label('¿Cuánto necesitas?'),
                const SizedBox(height: 8),
                _buildAmountField().animateEntrance(delay: 120.ms),
                const SizedBox(height: AppSpacing.lg),

                _label('¿En cuánto tiempo?'),
                const SizedBox(height: 10),
                _buildMonthChips().animateEntrance(delay: 160.ms),
                const SizedBox(height: AppSpacing.lg),

                _label('Fecha objetivo'),
                const SizedBox(height: 8),
                _buildDateField().animateEntrance(delay: 200.ms),
                const SizedBox(height: AppSpacing.lg),

                _label('Aporte mensual sugerido'),
                const SizedBox(height: 8),
                _buildSuggestedAmount().animateEntrance(delay: 240.ms),
                const SizedBox(height: AppSpacing.lg),

                _buildReminderToggle().animateEntrance(delay: 280.ms),
                const SizedBox(height: AppSpacing.xl),

                SizedBox(
                  width: double.infinity,
                  child: SBButton.primary(
                    label: 'Crear meta',
                    onPressed: _isSaving ? null : _save,
                    isLoading: _isSaving,
                    customColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ).animateEntrance(delay: 320.ms),
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
            'Crear nueva meta',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading2.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 40), // equilibra el back para centrar el título
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

  InputDecoration _fieldDecoration({String? hint, Widget? prefix}) {
    return InputDecoration(
      prefixIcon: prefix,
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildCategorySelector() {
    // La categoría seleccionada/sugerida va primero para que el usuario la vea
    // sin necesidad de desplazar la lista.
    final ordered = [
      _categoria,
      ...MetaCategoria.values.where((c) => c != _categoria),
    ];
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: ordered.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = ordered[index];
          final selected = _categoria == cat;
          return GestureDetector(
            onTap: () {
              setState(() {
                _categoria = cat;
                _categoriaManual = true;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 78,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFE2F3DA) : AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFEAEAEA),
                  width: selected ? 1.6 : 1.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GoalCategoryIcon(category: cat, size: 40, bare: true),
                  const SizedBox(height: 4),
                  Text(
                    cat.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? const Color(0xFF1B5E20)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      textCapitalization: TextCapitalization.sentences,
      decoration: _fieldDecoration(
        hint: 'Ej: Viaje a Cusco',
        prefix: const Icon(LucideIcons.tag, color: Color(0xFF80C29E), size: 18),
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      style: GoogleFonts.inter(
        fontSize: 26,
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
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryGreen,
        ),
        hintText: '0.00',
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontWeight: FontWeight.w800,
          fontSize: 26,
        ),
        fillColor: AppColors.surfaceWhite,
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  Widget _buildMonthChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _monthOptions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final months = _monthOptions[index];
          final selected = _selectedMonths == months;
          return GestureDetector(
            onTap: () => _selectMonths(months),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFE2F3DA) : AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFEAEAEA),
                  width: selected ? 1.6 : 1.0,
                ),
              ),
              child: Text(
                '$months meses',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? const Color(0xFF1B5E20)
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateField() {
    final formatted =
        DateFormat("dd 'de' MMMM 'de' yyyy", 'es').format(_targetDate);
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
                formatted,
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
    );
  }

  Widget _buildSuggestedAmount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FAF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentGreenBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFE2F3DA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.trendingUp,
              size: 18,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Para alcanzar tu meta a tiempo',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            GoalFormat.money(_suggestedMonthly),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recordarme este objetivo',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Te enviaremos recordatorios para que no pierdas el foco.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: _recordatorio,
            activeTrackColor: AppColors.primaryGreen,
            onChanged: (v) => setState(() => _recordatorio = v),
          ),
        ],
      ),
    );
  }
}
