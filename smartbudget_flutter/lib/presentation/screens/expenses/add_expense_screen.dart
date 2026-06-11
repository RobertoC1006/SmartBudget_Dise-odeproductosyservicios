import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/providers/budget_provider.dart';
import '../../../data/services/expense_service.dart';
import '../../widgets/sb_button.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/sb_entrance_animation.dart';
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

  void _showCategorySelector(BuildContext context) {
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
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selecciona una categoría',
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
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: CategoriaGasto.values.length,
                    itemBuilder: (context, index) {
                      final category = CategoriaGasto.values[index];
                      final isSelected = _selectedCategory == category;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryLight
                                : const Color(0xFFF9FBF9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryGreen.withValues(alpha: 0.3)
                                  : AppColors.dividerGray,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CategoryIcon(
                                category: category,
                                size: 44,
                                iconSize: 18,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _translateCategory(category),
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.primaryDark
                                      : AppColors.textPrimary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
      await _expenseService.createExpense(expense);
      await budgetProvider.loadDashboard();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Gasto registrado con éxito!')),
      );

      // Clean up the controllers/form state
      _amountController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedCategory = null;
        _comercio = null;
        _selectedDate = DateTime.now();
        _fuente = FuenteGasto.manual;
      });

      // Navigate back to Dashboard screen (route '/')
      context.go('/');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrowLeft,
            color: AppColors.textPrimary,
            size: 22,
          ),
          tooltip: 'Volver',
          onPressed: _goBack,
        ),
        title: Text(
          'Registro manual',
          style: AppTextStyles.heading2.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: const CustomPaint(
                painter: HeaderBackgroundPainter(),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildManualRegistrationFormCard(context)
                        .animateEntrance(),
                    const SizedBox(height: AppSpacing.xl),
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF3FAF2), // Pastel green background matching amount field
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
              DateFormat("dd 'de' MMMM 'de' yyyy", 'es').format(_selectedDate),
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(
              LucideIcons.edit2,
              color: Colors.grey.shade500,
              size: 16,
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
            padding: const EdgeInsets.only(right: 6.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _amountController.text = amount.toStringAsFixed(2);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
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
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
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

  Widget _buildManualRegistrationFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(
            0xFFE8F5E9,
          ), // Light green tint border to match Image 2
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9), // Light green background
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.add,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Registro Manual',
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Ingresa los detalles del gasto',
              style: AppTextStyles.bodySecondary.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // 1. Monto Label & Input
          Text(
            'Monto (S/)',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildGlowInputWrapper(
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
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.payments_outlined,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                hintText: '50.00',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
                fillColor: const Color(0xFFF3FAF2), // Pastel green background
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
          ),
          const SizedBox(height: 8),
          _buildQuickAmountChips(),

          const SizedBox(height: AppSpacing.lg),

          // 1b. Fecha del Gasto
          Text(
            'Fecha del Gasto',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildDateSelectorField(),

          const SizedBox(height: AppSpacing.lg),
          // 2. Categoría Label & Selector
          Text(
            'Categoría',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () => _showCategorySelector(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFF3FAF2,
                ), // Pastel green background matching home widgets
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedCategory != null
                      ? AppColors.primaryGreen.withValues(alpha: 0.3)
                      : const Color(0xFFE5E7EB),
                  width: 1.0,
                ),
              ),
              child: Row(
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
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 3. Descripción Label & Input
          Text(
            'Descripción (opcional)',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildGlowInputWrapper(
            isFocused: _descriptionFocusNode.hasFocus,
            child: TextFormField(
              controller: _descriptionController,
              focusNode: _descriptionFocusNode,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                hintText: 'Ej: Almuerzo en restaurante',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
                fillColor: const Color(0xFFF3FAF2), // Pastel green background
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
          ),
          const SizedBox(height: 8),
          _buildDescriptionSuggestionChips(),

          const SizedBox(height: AppSpacing.lg),

          // 4. Agregar Gasto Button
          SBButton.primary(
            label: _isSaving ? 'Guardando...' : 'Agregar Gasto',
            icon: LucideIcons.plus,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _saveExpense,
            customColor: AppColors.primaryGreen,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ],
      ),
    );
  }
}
