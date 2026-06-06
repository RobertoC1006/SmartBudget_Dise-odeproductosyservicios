import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

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
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          top: BorderSide(color: AppColors.dividerGray, width: 1.0),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onTap(context, index),
        elevation: 0,
        backgroundColor: AppColors.surfaceWhite,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTextStyles.captionBold.copyWith(color: AppColors.primaryGreen, fontSize: 11),
        unselectedLabelStyle: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(LucideIcons.home, size: 22),
            ),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(LucideIcons.creditCard, size: 22),
            ),
            label: 'Gastos',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(LucideIcons.target, size: 22),
            ),
            label: 'Metas',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(LucideIcons.barChart2, size: 22),
            ),
            label: 'Análisis',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(LucideIcons.user, size: 22),
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
