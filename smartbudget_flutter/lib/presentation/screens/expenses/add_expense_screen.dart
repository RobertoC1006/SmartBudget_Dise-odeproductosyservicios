import 'package:flutter/material.dart';
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

class AddExpenseScreen extends StatefulWidget {
  final String? initialCategory;
  final Map<String, dynamic>? prefilledData;

  const AddExpenseScreen({
    super.key,
    this.initialCategory,
    this.prefilledData,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _expenseService = ExpenseService();

  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _merchantController;

  CategoriaGasto _selectedCategory = CategoriaGasto.comida;
  DateTime _selectedDate = DateTime.now();
  FuenteGasto _fuente = FuenteGasto.manual;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _amountController = TextEditingController(text: '0.00');
    _descriptionController = TextEditingController();
    _merchantController = TextEditingController();

    // Check prefilled data from OCR first
    if (widget.prefilledData != null) {
      final data = widget.prefilledData!;
      if (data['monto'] != null) {
        _amountController.text = (data['monto'] as double).toStringAsFixed(2);
      }
      if (data['descripcion'] != null) {
        _descriptionController.text = data['descripcion'] as String;
      }
      if (data['comercio'] != null) {
        _merchantController.text = data['comercio'] as String;
      }
      if (data['fecha'] != null) {
        try {
          _selectedDate = DateTime.parse(data['fecha'] as String);
        } catch (_) {}
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
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  CategoriaGasto _parseCategoryString(String cat) {
    return CategoriaGasto.values.firstWhere(
      (e) => e.name == cat.toLowerCase(),
      orElse: () => CategoriaGasto.otros,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (_amountController.text == '0.00' || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa un monto válido mayor a 0')),
      );
      return;
    }

    final double? monto = double.tryParse(_amountController.text);
    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Monto inválido')),
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
        categoria: _selectedCategory,
        monto: monto,
        descripcion: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        comercio: _merchantController.text.trim().isEmpty 
            ? null 
            : _merchantController.text.trim(),
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
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: ${e.toString().replaceAll('Exception: ', '')}')),
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

  @override
  Widget build(BuildContext context) {
    final categories = [
      _CategoryItem(name: 'Comida', key: CategoriaGasto.comida, icon: LucideIcons.utensils),
      _CategoryItem(name: 'Transporte', key: CategoriaGasto.transporte, icon: LucideIcons.car),
      _CategoryItem(name: 'Ocio', key: CategoriaGasto.ocio, icon: LucideIcons.gamepad2),
      _CategoryItem(name: 'Salud', key: CategoriaGasto.salud, icon: LucideIcons.heart),
      _CategoryItem(name: 'Educación', key: CategoriaGasto.educacion, icon: LucideIcons.bookOpen),
      _CategoryItem(name: 'Ropa', key: CategoriaGasto.ropa, icon: LucideIcons.shirt),
      _CategoryItem(name: 'Hogar', key: CategoriaGasto.hogar, icon: LucideIcons.home),
      _CategoryItem(name: 'Tecnología', key: CategoriaGasto.tecnologia, icon: LucideIcons.laptop),
      _CategoryItem(name: 'Viajes', key: CategoriaGasto.viajes, icon: LucideIcons.plane),
      _CategoryItem(name: 'Otros', key: CategoriaGasto.otros, icon: LucideIcons.moreHorizontal),
    ];

    final activeCategoryItem = categories.firstWhere(
      (c) => c.key == _selectedCategory,
      orElse: () => categories.last,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.prefilledData != null ? 'Verificar Gasto' : 'Registrar gasto',
          style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      
                      // 1. MONTO TITLE & INPUT (Mockup style S/ 0.00)
                      Text(
                        'Monto',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'S/ ',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary.withValues(alpha: 0.5),
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1F2937),
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                hintText: '0.00',
                              ),
                              onChanged: (val) {
                                // Sanitization of input format if necessary
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppSpacing.sm),
                      Divider(color: AppColors.dividerGray.withValues(alpha: 0.6), thickness: 1.2),
                      const SizedBox(height: AppSpacing.lg),
                      
                      // 2. CATEGORÍA TITLE
                      Text(
                        'Categoría',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      // Dropdown select box displaying active category
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: AppColors.dividerGray, width: 1.0),
                        ),
                        child: Row(
                          children: [
                            CategoryIcon(
                              category: _selectedCategory,
                              size: 26,
                              iconSize: 14,
                              shape: BoxShape.rectangle,
                              borderRadius: 6.0,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              activeCategoryItem.name,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              LucideIcons.chevronDown,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Grid of 10 category options (Active highlighted in light green/lime)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected = cat.key == _selectedCategory;
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = cat.key;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? const Color(0xFFD4E157).withValues(alpha: 0.35) 
                                    : AppColors.surfaceWhite.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(16.0),
                                border: Border.all(
                                  color: isSelected 
                                      ? const Color(0xFF9E9D24) 
                                      : AppColors.dividerGray.withValues(alpha: 0.4),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    cat.icon,
                                    color: isSelected 
                                        ? const Color(0xFF827717) 
                                        : AppColors.textPrimary.withValues(alpha: 0.7),
                                    size: 18,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    cat.name,
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected 
                                          ? const Color(0xFF827717) 
                                          : AppColors.textSecondary,
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
                      
                      const SizedBox(height: AppSpacing.xl),
                      Divider(color: AppColors.dividerGray.withValues(alpha: 0.6), thickness: 1.0),
                      const SizedBox(height: AppSpacing.lg),
                      
                      // 3. DESCRIPCIÓN INPUT (Optional)
                      Text(
                        'Descripción (opcional)',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _descriptionController,
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          hintText: '¿Qué fue este gasto?',
                          fillColor: AppColors.surfaceWhite,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            borderSide: const BorderSide(color: AppColors.dividerGray),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            borderSide: const BorderSide(color: AppColors.dividerGray),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.lg),
                      
                      // 3b. COMERCIO/NEGOCIO INPUT (Optional, useful for OCR)
                      Text(
                        'Establecimiento / Comercio (opcional)',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _merchantController,
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Ej. Supermercado Plaza Vea',
                          fillColor: AppColors.surfaceWhite,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            borderSide: const BorderSide(color: AppColors.dividerGray),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            borderSide: const BorderSide(color: AppColors.dividerGray),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.lg),
                      
                      // 4. FECHA INPUT
                      Text(
                        'Fecha',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: AppColors.dividerGray, width: 1.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat("dd 'de' MMMM 'de' yyyy", "es").format(_selectedDate),
                                style: AppTextStyles.bodyMedium,
                              ),
                              const Icon(
                                LucideIcons.calendar,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
            
            // 5. GUARDAR GASTO BUTTON (Black pill shaped)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: SBButton.primary(
                  label: _isSaving ? 'Guardando...' : 'Guardar gasto',
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _saveExpense,
                  customColor: const Color(0xFF111827), // Black button
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String name;
  final CategoriaGasto key;
  final IconData icon;

  _CategoryItem({
    required this.name,
    required this.key,
    required this.icon,
  });
}
