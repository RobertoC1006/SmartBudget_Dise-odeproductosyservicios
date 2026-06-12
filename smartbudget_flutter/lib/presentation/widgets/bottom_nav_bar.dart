import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    if (currentIndex == index) return;
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/expenses');
        break;
      case 2:
        context.go('/goals');
        break;
      case 3:
        context.go('/analysis');
        break;
      case 4:
        context.go('/simulator');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavBarItem(icon: LucideIcons.home, label: 'Inicio'),
      _NavBarItem(icon: LucideIcons.creditCard, label: 'Gastos'),
      _NavBarItem(icon: LucideIcons.target, label: 'Metas'),
      _NavBarItem(icon: LucideIcons.barChart2, label: 'Análisis'),
      _NavBarItem(icon: LucideIcons.flaskConical, label: 'Simulador'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 12.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: AppColors.dividerGray.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = currentIndex == index;
              final item = items[index];

              return GestureDetector(
                onTap: () => _onTap(context, index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 20,
                        color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Text(
                                item.label,
                                style: AppTextStyles.captionBold.copyWith(
                                  color: AppColors.primaryDark,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem {
  final IconData icon;
  final String label;

  _NavBarItem({
    required this.icon,
    required this.label,
  });
}
