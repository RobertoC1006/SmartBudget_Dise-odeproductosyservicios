import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/providers/budget_provider.dart';
import '../../../data/services/expense_service.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/sb_entrance_animation.dart';
import '../../widgets/app_header.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/header_background_painter.dart';

/// Pantalla 2A del flujo de gastos: registro manual fullscreen.
/// Recibe datos prellenados del OCR (`prefilledData`) o una categoría
/// inicial (`initialCategory`) vía query param.
class AddExpenseScreen extends StatefulWidget {
  final String? initialCategory;
  final Map<String, dynamic>? prefilledData;

  const AddExpenseScreen({super.key, this.initialCategory, this.prefilledData});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _expenseService = ExpenseService();

  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  late final FocusNode _amountFocusNode;
  late final FocusNode _descriptionFocusNode;

  CategoriaGasto? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  FuenteGasto _fuente = FuenteGasto.manual;
  String? _comercio;
  bool _isSaving = false;

  /// Controla el panel desplegable de categorías (overlay, no empuja
  /// el contenido de abajo).
  final MenuController _categoryMenuController = MenuController();

  final Map<CategoriaGasto, List<String>> _suggestionsByCategory = {
    CategoriaGasto.comida: [
      'Almuerzo',
      'Cena',
      'Supermercado',
      'Café',
      'Delivery',
    ],
    CategoriaGasto.transporte: [
      'Taxi / Uber',
      'Gasolina',
      'Metro / Autobús',
      'Estacionamiento',
    ],
    CategoriaGasto.ocio: [
      'Cine / Teatro',
      'Salida amigos',
      'Suscripción',
      'Videojuegos',
      'Bar / Club',
    ],
    CategoriaGasto.salud: [
      'Farmacia',
      'Consulta médica',
      'Seguro médico',
      'Dentista',
    ],
    CategoriaGasto.educacion: [
      'Libros',
      'Curso online',
      'Mensualidad',
      'Útiles',
    ],
    CategoriaGasto.ropa: ['Ropa', 'Zapatos', 'Lavandería', 'Accesorios'],
    CategoriaGasto.hogar: [
      'Alquiler',
      'Luz / Agua',
      'Mantenimiento',
      'Decoración',
      'Muebles',
    ],
    CategoriaGasto.tecnologia: [
      'Suscripción web',
      'Accesorios PC',
      'Gadget',
      'Reparación',
    ],
    CategoriaGasto.viajes: [
      'Vuelos',
      'Hotel',
      'Comida viaje',
      'Souvenirs',
      'Maleta',
    ],
    CategoriaGasto.otros: [
      'Regalo',
      'Imprevisto',
      'Préstamo',
      'Comisión bancaria',
    ],
  };

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();

    _amountFocusNode = FocusNode();
    _descriptionFocusNode = FocusNode();

    _amountFocusNode.addListener(_onFocusChange);
    _descriptionFocusNode.addListener(_onFocusChange);

    _initializeFromPrefilledData();
  }

  void _onFocusChange() {
    setState(() {}); // Rebuild to update focused glow effects
  }

  void _initializeFromPrefilledData() {
    // Check prefilled data from OCR first
    if (widget.prefilledData != null) {
      final data = widget.prefilledData!;
      if (data['monto'] != null) {
        // El OCR puede devolver int o double.
        _amountController.text = (data['monto'] as num).toStringAsFixed(2);
      }
      if (data['descripcion'] != null) {
        _descriptionController.text = data['descripcion'] as String;
      }
      if (data['comercio'] != null) {
        _comercio = data['comercio'] as String;
      }
      if (data['fecha'] != null) {
        _selectedDate = _parseOcrDate(data['fecha'] as String) ?? _selectedDate;
      }
      if (data['categoria'] != null) {
        _selectedCategory = _parseCategoryString(data['categoria'] as String);
      }
      _fuente = FuenteGasto.ocrImagen; // Marked as OCR if prefilled
    } else if (widget.initialCategory != null) {
      _selectedCategory = _parseCategoryString(widget.initialCategory!);
    }
  }

  @override
  void didUpdateWidget(covariant AddExpenseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.prefilledData != oldWidget.prefilledData ||
        widget.initialCategory != oldWidget.initialCategory) {
      _initializeFromPrefilledData();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _amountFocusNode.removeListener(_onFocusChange);
    _descriptionFocusNode.removeListener(_onFocusChange);
    _amountFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  /// El OCR debería devolver YYYY-MM-DD, pero puede venir en formato local.
  DateTime? _parseOcrDate(String raw) {
    try {
      return DateTime.parse(raw);
    } catch (_) {}
    for (final pattern in ['dd/MM/yyyy', 'dd-MM-yyyy']) {
      try {
        return DateFormat(pattern).parseStrict(raw);
      } catch (_) {}
    }
    return null;
  }

  CategoriaGasto _parseCategoryString(String cat) {
    return CategoriaGasto.values.firstWhere(
      (e) => e.name == cat.toLowerCase(),
      orElse: () => CategoriaGasto.otros,
    );
  }

  String _translateCategory(CategoriaGasto category) {
    switch (category) {
      case CategoriaGasto.comida:
        return 'Comida';
      case CategoriaGasto.transporte:
        return 'Transporte';
      case CategoriaGasto.ocio:
        return 'Ocio';
      case CategoriaGasto.salud:
        return 'Salud';
      case CategoriaGasto.educacion:
        return 'Educación';
      case CategoriaGasto.ropa:
        return 'Ropa';
      case CategoriaGasto.hogar:
        return 'Hogar';
      case CategoriaGasto.tecnologia:
        return 'Tecnología';
      case CategoriaGasto.viajes:
        return 'Viajes';
      case CategoriaGasto.otros:
        return 'Otros';
    }
  }

  Future<void> _saveExpense() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una categoría')),
      );
      return;
    }

    final String amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa un monto válido')),
      );
      return;
    }

    final double? monto = double.tryParse(amountText.replaceAll(',', '.'));
    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Monto inválido. Debe ser mayor a 0')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final expense = ExpenseModel(
        id: 0,
        userId: 0,
        categoria: _selectedCategory!,
        monto: monto,
        descripcion: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        comercio: _comercio?.trim().isEmpty == true ? null : _comercio?.trim(),
        fecha: _selectedDate,
        fuente: _fuente,
        createdAt: DateTime.now(),
      );

      final budgetProvider = context.read<BudgetProvider>();
      // Score previo para mostrar el delta real en la pantalla de éxito.
      final int prevScore = budgetProvider.currentScore;

      final created = await _expenseService.createExpense(expense);
      await budgetProvider.loadDashboard();

      if (!mounted) return;
      final int newScore = budgetProvider.currentScore;

      // 2B: pantalla de éxito compartida (reemplaza al formulario en el
      // stack para que back nunca regrese a un form ya enviado).
      context.pushReplacement('/expenses/success', extra: {
        'expense': created,
        'prevScore': prevScore,
        'newScore': newScore,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al guardar: ${e.toString().replaceAll('Exception: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/expenses');
    }
  }

  /// Fila de título dentro del cuerpo (la pantalla no usa AppBar para
  /// poder mostrar el AppHeader reutilizable encima, como micro-ahorro).
  Widget _buildTitleRow(BuildContext context) {
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
            'Registro manual',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading2.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(
            LucideIcons.helpCircle,
            color: AppColors.textSecondary,
            size: 22,
          ),
          tooltip: 'Ayuda',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          onPressed: () => _showHelpDialog(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: HeaderBackgroundPainter()),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                20,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppHeader(),

                    const SizedBox(height: AppSpacing.sm + 2),

                    _buildTitleRow(context),

                    const SizedBox(height: AppSpacing.sm + 2),

                    Text(
                      'Ingresa los detalles del gasto',
                      style: AppTextStyles.bodySecondary.copyWith(
                        fontSize: 14,
                      ),
                    ).animateEntrance(),

                    const SizedBox(height: AppSpacing.md + 4),

                    // 1. Categoría (primero, según mockup 2A)
                    _buildSection(
                      label: 'Categoría',
                      child: _buildCategoryField(context),
                    ).animateEntrance(delay: 50.ms),

                    const SizedBox(height: AppSpacing.md),

                    // 2. Monto + chips rápidos
                    _buildSection(
                      label: 'Monto (S/)',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAmountField(),
                          const SizedBox(height: 10),
                          _buildQuickAmountChips(),
                        ],
                      ),
                    ).animateEntrance(delay: 100.ms),

                    const SizedBox(height: AppSpacing.md),

                    // 3. Fecha
                    _buildSection(
                      label: 'Fecha',
                      child: _buildDateSelectorField(),
                    ).animateEntrance(delay: 150.ms),

                    const SizedBox(height: AppSpacing.md),

                    // 4. Descripción + sugerencias
                    _buildSection(
                      label: 'Descripción (opcional)',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDescriptionField(),
                          const SizedBox(height: 10),
                          _buildDescriptionSuggestionChips(),
                        ],
                      ),
                    ).animateEntrance(delay: 200.ms),

                    const SizedBox(height: AppSpacing.md),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveExpense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          disabledBackgroundColor:
                              AppColors.primaryGreen.withValues(alpha: 0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.plus,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Agregar gasto',
                                    style: AppTextStyles.label.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ).animateEntrance(delay: 250.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
        // La sombra base ahora la lleva la tarjeta de sección; aquí solo
        // queda el glow de enfoque.
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

  Widget _buildDateSelectorField() {
    return GestureDetector(
      onTap: () => _selectCustomDate(context),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.calendar,
              color: AppColors.primaryGreen,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              _formatFecha(_selectedDate),
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(
              LucideIcons.chevronDown,
              color: Colors.grey.shade500,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectCustomDate(BuildContext context) async {
    final DateTime firstDate = DateTime(2020);
    final DateTime lastDate = DateTime(2030);
    // Si initialDate queda fuera del rango (p. ej. una fecha mal leída por el
    // OCR), showDatePicker lanza una excepción y el calendario nunca se abre.
    DateTime initialDate = _selectedDate;
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
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
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Widget _buildQuickAmountChips() {
    final List<double> quickAmounts = [10.0, 20.0, 50.0, 100.0];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: quickAmounts.map((amount) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _amountController.text = amount.toStringAsFixed(2);
                });
              },
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  'S/ ${amount.toInt()}',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                    fontSize: 11.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDescriptionSuggestionChips() {
    final CategoriaGasto category = _selectedCategory ?? CategoriaGasto.otros;
    final List<String> suggestions =
        _suggestionsByCategory[category] ??
        _suggestionsByCategory[CategoriaGasto.otros]!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: suggestions.map((suggestion) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _descriptionController.text = suggestion;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  suggestion,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary.withValues(alpha: 0.8),
                    fontSize: 11.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Fecha con prefijo relativo del mockup: "Hoy, 05 de junio de 2026".
  String _formatFecha(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(date.year, date.month, date.day);
    final String formatted =
        DateFormat("dd 'de' MMMM 'de' yyyy", 'es').format(date);
    if (day == today) return 'Hoy, $formatted';
    if (day == today.subtract(const Duration(days: 1))) {
      return 'Ayer, $formatted';
    }
    return formatted;
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cómo registrar tu gasto',
                      style: AppTextStyles.heading2.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(context),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _HelpTip(
                  icon: LucideIcons.tag,
                  text: 'Elige la categoría que mejor describa tu gasto.',
                ),
                const SizedBox(height: 12),
                const _HelpTip(
                  icon: LucideIcons.zap,
                  text: 'Usa los montos rápidos para registrar en segundos.',
                ),
                const SizedBox(height: 12),
                const _HelpTip(
                  icon: LucideIcons.edit3,
                  text:
                      'La descripción es opcional, pero te ayuda a recordar '
                      'en qué gastaste.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Tarjeta blanca de sección del mockup 2A: label + campo dentro de
  /// un contenedor elevado; el campo interior solo lleva borde.
  Widget _buildSection({required String label, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildCategoryField(BuildContext context) {
    final double panelWidth =
        MediaQuery.of(context).size.width - AppSpacing.md * 2;

    return MenuAnchor(
      controller: _categoryMenuController,
      alignmentOffset: const Offset(0, 6),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(12),
        shadowColor: WidgetStatePropertyAll(
          Colors.black.withValues(alpha: 0.18),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
      menuChildren: [
        // Lista de categorías (mismo estilo que el selector del
        // simulador de micro-ahorro).
        SizedBox(
          width: panelWidth,
          height: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: CategoriaGasto.values.map((category) {
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                    _categoryMenuController.close();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryGreen.withValues(alpha: 0.10)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        CategoryIcon(
                          category: category,
                          size: 28,
                          iconSize: 13,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _translateCategory(category),
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 14,
                          child: isSelected
                              ? const Icon(
                                  LucideIcons.check,
                                  size: 13,
                                  color: AppColors.primaryGreen,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
      builder: (context, controller, child) {
        return GestureDetector(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedCategory != null
                    ? AppColors.primaryGreen.withValues(alpha: 0.3)
                    : const Color(0xFFE5E7EB),
                width: 1.0,
              ),
            ),
            child: _buildCategoryFieldContent(),
          ),
        );
      },
    );
  }

  Widget _buildCategoryFieldContent() {
    return Row(
          children: [
            if (_selectedCategory != null) ...[
              CategoryIcon(
                category: _selectedCategory!,
                size: 24,
                iconSize: 12,
              ),
              const SizedBox(width: 8),
              Text(
                _translateCategory(_selectedCategory!),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ] else ...[
              const Icon(
                LucideIcons.tag,
                color: AppColors.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Selecciona una categoría',
                style: AppTextStyles.bodySecondary.copyWith(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const Spacer(),
            Icon(
              LucideIcons.chevronDown,
              color: Colors.grey.shade500,
              size: 18,
            ),
          ],
    );
  }

  Widget _buildAmountField() {
    return _buildGlowInputWrapper(
      isFocused: _amountFocusNode.hasFocus,
      child: TextFormField(
        controller: _amountController,
        focusNode: _amountFocusNode,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
        ),
        // En web/escritorio keyboardType no restringe el teclado,
        // así que el formatter es la validación real.
        inputFormatters: [
          TextInputFormatter.withFunction((oldValue, newValue) {
            if (newValue.text.isEmpty) return newValue;
            final isValid =
                RegExp(r'^\d{0,7}([.,]\d{0,2})?$').hasMatch(newValue.text);
            return isValid ? newValue : oldValue;
          }),
        ],
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          // Mockup 2A: monto protagonista "S/ 50.00", sin ícono.
          prefixText: 'S/ ',
          prefixStyle: AppTextStyles.bodyMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          hintText: '50.00',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          fillColor: Colors.white,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
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
            borderSide: const BorderSide(
              color: AppColors.primaryGreen,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return _buildGlowInputWrapper(
      isFocused: _descriptionFocusNode.hasFocus,
      child: TextFormField(
        controller: _descriptionController,
        focusNode: _descriptionFocusNode,
        maxLines: 3,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Ej: Almuerzo en restaurante',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w500,
          ),
          fillColor: Colors.white,
          filled: true,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
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
            borderSide: const BorderSide(
              color: AppColors.primaryGreen,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila de consejo del diálogo de ayuda.
class _HelpTip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HelpTip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryGreen, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySecondary.copyWith(
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
