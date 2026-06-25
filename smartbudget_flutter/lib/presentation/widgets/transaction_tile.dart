import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/expense_model.dart';
import 'amount_display.dart';
import 'category_icon.dart';

class TransactionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final CategoriaGasto? category;
  final bool isIncome;
  final VoidCallback? onTap;

  /// Reemplaza el ícono de categoría por defecto (lo usa Análisis para mostrar
  /// la ilustración 3D en vez del ícono de línea).
  final Widget? leading;

  const TransactionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    this.category,
    this.isIncome = false,
    this.onTap,
    this.leading,
  });

  factory TransactionTile.fromExpense(
    ExpenseModel expense, {
    VoidCallback? onTap,
    Widget? leading,
  }) {
    return TransactionTile(
      title: expense.comercio ?? expense.descripcion ?? 'Gasto sin comercio',
      subtitle: expense.descripcion ?? _capitalize(expense.categoria.name),
      amount: -expense.monto,
      date: expense.fecha,
      category: expense.categoria,
      isIncome: false,
      onTap: onTap,
      leading: leading,
    );
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            child: Row(
              children: [
                leading ??
                    (category != null
                    ? CategoryIcon(
                        category: category!,
                        shape: BoxShape.rectangle,
                        borderRadius: 12.0,
                        size: 48.0,
                        iconSize: 22.0,
                      )
                    : Container(
                        width: 48.0,
                        height: 48.0,
                        decoration: BoxDecoration(
                          color: isIncome ? AppColors.primaryLight : AppColors.dividerGray.withValues(alpha: 0.5),
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Icon(
                          isIncome ? LucideIcons.banknote : LucideIcons.moreHorizontal,
                          color: isIncome ? AppColors.incomeGreen : AppColors.textSecondary,
                          size: 22.0,
                        ),
                      )),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormatter.formatRelative(date)} • $subtitle',
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                AmountDisplay(
                  amount: amount,
                  size: AmountSize.small,
                  color: amount > 0 ? AppColors.incomeGreen : AppColors.expenseRed,
                  showSign: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
