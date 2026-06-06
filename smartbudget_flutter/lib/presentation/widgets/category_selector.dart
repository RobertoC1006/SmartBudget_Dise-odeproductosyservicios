import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/expense_model.dart';
import 'category_icon.dart';

class CategorySelector extends StatelessWidget {
  final CategoriaGasto? selectedCategory;
  final ValueChanged<CategoriaGasto> onCategorySelected;

  const CategorySelector({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.9,
      ),
      itemCount: CategoriaGasto.values.length,
      itemBuilder: (context, index) {
        final category = CategoriaGasto.values[index];
        final isSelected = selectedCategory == category;

        return InkWell(
          onTap: () => onCategorySelected(category),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryLight : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isSelected ? AppColors.primaryGreen : AppColors.dividerGray,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CategoryIcon(
                      category: category,
                      size: 38.0,
                      iconSize: 18.0,
                    ),
                    if (isSelected)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _translate(category),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _translate(CategoriaGasto category) {
    switch (category) {
      case CategoriaGasto.comida:
        return 'Comida';
      case CategoriaGasto.transporte:
        return 'Transp.';
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
        return 'Tecno.';
      case CategoriaGasto.viajes:
        return 'Viajes';
      case CategoriaGasto.otros:
        return 'Otros';
    }
  }
}
