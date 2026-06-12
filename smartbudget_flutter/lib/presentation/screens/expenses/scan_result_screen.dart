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
import '../../../data/models/expense_model.dart';
import '../../../data/providers/budget_provider.dart';
import '../../../data/services/expense_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/header_background_painter.dart';
import '../../widgets/sb_entrance_animation.dart';

/// Pantalla 1D del flujo de gastos: resultado del análisis OCR.
/// Recibe el Map extraído por la API (monto, fecha, categoria,
/// descripcion, comercio); todos los campos son editables. Guardar crea
/// el gasto con fuente OCR y navega a la pantalla de éxito 2B.
class ScanResultScreen extends StatefulWidget {
  final Map<String, dynamic> scanData;

  const ScanResultScreen({super.key, required this.scanData});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  final _expenseService = ExpenseService();

  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final FocusNode _amountFocusNode;

  CategoriaGasto _selectedCategory = CategoriaGasto.otros;
  DateTime _selectedDate = DateTime.now();
  String? _comercio;

  bool _editingAmount = false;
  bool _isSaving = false;

  final MenuController _categoryMenuController = MenuController();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _amountFocusNode = FocusNode();

    // El monto vuelve al modo display al perder el foco.
    _amountFocusNode.addListener(() {
      if (!_amountFocusNode.hasFocus && _editingAmount) {
        setState(() => _editingAmount = false);
      }
    });

    _initializeFromScanData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _initializeFromScanData() {
    final data = widget.scanData;
    if (data['monto'] != null) {
      // El OCR puede devolver int o double.
      _amountController.text = (data['monto'] as num).toStringAsFixed(2);
    }
    if (data['descripcion'] != null) {
      _descriptionController.text = data['descripcion'] as String;
    }
    if (data['comercio'] != null) {
      _comercio = data['comercio'] as String;
      // Si el OCR no trajo descripción, el comercio sirve de base.
      if (_descriptionController.text.isEmpty) {
        _descriptionController.text = _comercio!;
      }
    }
    if (data['fecha'] != null) {
      _selectedDate = _parseOcrDate(data['fecha'] as String) ?? _selectedDate;
    }
    if (data['categoria'] != null) {
      _selectedCategory = _parseCategoryString(data['categoria'] as String);
    }
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

  double get _currentAmount =>
      double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0;

  /// Back de 1D: reintentar el escaneo (regla de navegación del plan).
  void _rescan() {
    context.pushReplacement('/expenses/scan');
  }

  Future<void> _saveExpense() async {
    final double monto = _currentAmount;
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Monto inválido. Debe ser mayor a 0')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final expense = ExpenseModel(
        id: 0,
        userId: 0,
        categoria: _selectedCategory,
        monto: monto,
        descripcion: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        comercio: _comercio?.trim().isEmpty == true ? null : _comercio?.trim(),
        fecha: _selectedDate,
        fuente: FuenteGasto.ocrImagen,
        createdAt: DateTime.now(),
      );

      final budgetProvider = context.read<BudgetProvider>();
      // Score previo para mostrar el delta real en la pantalla de éxito.
      final int prevScore = budgetProvider.currentScore;

      final created = await _expenseService.createExpense(expense);
      await budgetProvider.loadDashboard();

      if (!mounted) return;
      final int newScore = budgetProvider.currentScore;

      // 2B: éxito compartido (reemplaza en el stack: back nunca regresa
      // a un resultado ya guardado).
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
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Regla del plan: back desde 1D vuelve a 1B para reintentar.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _rescan();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        bottomNavigationBar: const BottomNavBar(currentIndex: 1),
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: HeaderBackgroundPainter()),
              ),
              // Patrón anclado del flujo (2B/1C): la columna llena el
              // alto y el Spacer fija los CTA a 20px del bottom nav.
              LayoutBuilder(
                builder: (context, viewport) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: viewport.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const AppHeader(),

                              const SizedBox(height: AppSpacing.md),

                              _buildTitleRow(),

                              const SizedBox(height: AppSpacing.xl),

                              _buildSuccessBanner()
                                  .animateEntrance(delay: 50.ms),

                              const SizedBox(height: AppSpacing.md),

                              _buildConfirmationCard()
                                  .animateEntrance(delay: 100.ms),

                              const SizedBox(height: AppSpacing.xl),

                              _buildSaveButton()
                                  .animateEntrance(delay: 200.ms),

                              const SizedBox(height: 12),

                              _buildRescanButton()
                                  .animateEntrance(delay: 250.ms),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
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
          tooltip: 'Volver a escanear',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          onPressed: _rescan,
        ),
        Expanded(
          child: Text(
            'Resultado del análisis',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading2.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // Equilibra el back para que el título quede centrado.
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentGreenBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.check, color: Colors.white, size: 18),
          ).animate().scale(
                begin: const Offset(0.4, 0.4),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Datos extraídos con éxito!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Revisa y confirma la información.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta de confirmación: monto protagonista editable + categoría,
  /// fecha y descripción (sin método de pago, decisión cerrada).
  Widget _buildConfirmationCard() {
    return Container(
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
          const SizedBox(height: 6),
          Center(child: _buildAmountSection()),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: Color(0xFFE5E7EB), height: 1),
          const SizedBox(height: AppSpacing.md),
          _buildFieldLabel('Categoría'),
          const SizedBox(height: 8),
          _buildCategoryField(context),
          const SizedBox(height: AppSpacing.md),
          _buildFieldLabel('Fecha'),
          const SizedBox(height: 8),
          _buildDateField(context),
          const SizedBox(height: AppSpacing.md),
          _buildFieldLabel('Descripción'),
          const SizedBox(height: 8),
          _buildDescriptionField(),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.bodyMedium.copyWith(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  /// Monto protagonista: "S/ 58.90" en 32 bold con lápiz; al tocar se
  /// vuelve TextField inline con teclado numérico (mismos formatters
  /// estabilizados del formulario 2A).
  Widget _buildAmountSection() {
    if (_editingAmount) {
      return SizedBox(
        width: 220,
        child: TextFormField(
          controller: _amountController,
          focusNode: _amountFocusNode,
          autofocus: true,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            TextInputFormatter.withFunction((oldValue, newValue) {
              if (newValue.text.isEmpty) return newValue;
              final isValid =
                  RegExp(r'^\d{0,7}([.,]\d{0,2})?$').hasMatch(newValue.text);
              return isValid ? newValue : oldValue;
            }),
          ],
          onFieldSubmitted: (_) => _amountFocusNode.unfocus(),
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            prefixText: 'S/ ',
            prefixStyle: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primaryGreen,
                width: 1.5,
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: 'Editar monto',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _editingAmount = true),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'S/ ${_currentAmount.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.pencil,
                color: AppColors.primaryGreen,
                size: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Selector de categoría: panel desplegable superpuesto (mismo estilo
  /// que 2A/micro-ahorro, no empuja el contenido).
  Widget _buildCategoryField(BuildContext context) {
    final double panelWidth =
        MediaQuery.of(context).size.width - AppSpacing.lg * 2;

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
                    setState(() => _selectedCategory = category);
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                CategoryIcon(
                  category: _selectedCategory,
                  size: 24,
                  iconSize: 12,
                ),
                const SizedBox(width: 8),
                Text(
                  _translateCategory(_selectedCategory),
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
      },
    );
  }

  Widget _buildDateField(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectCustomDate(context),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
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
    // Clamp: una fecha mal leída por el OCR fuera de rango haría que
    // showDatePicker lance una excepción y el calendario nunca se abra.
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

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 2,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
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
    );
  }

  // ---------------------------------------------------------------------
  // CTAs (52dp, radio 16 — mismo sistema que 2A/2B)
  // ---------------------------------------------------------------------

  Widget _buildSaveButton() {
    return SizedBox(
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Guardar gasto',
                style: AppTextStyles.label.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildRescanButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _isSaving ? null : _rescan,
        icon: const Icon(
          LucideIcons.camera,
          size: 18,
          color: AppColors.textPrimary,
        ),
        label: Text(
          'Escanear otra boleta',
          style: AppTextStyles.label.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surfaceWhite,
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
