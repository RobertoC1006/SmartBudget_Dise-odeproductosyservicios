import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/budget_provider.dart';
import '../../data/models/alert_model.dart';
import 'sb_card.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final userName = authProvider.user?.nombre ?? 'Usuario';

    return Padding(
      padding: const EdgeInsets.only(
        left: 8,
        right: 16,
        top: 12,
        bottom: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular 3D Avatar — tap to open profile
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE8F5E9),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Image.asset(
                  'assets/images/avatar.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.35), // Shifts the face downwards slightly
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        LucideIcons.user,
                        color: AppColors.primaryGreen,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '¡Hola, $userName! 👋',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1C2434),
                  ),
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  LucideIcons.bell,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
                onPressed: () => _showNotificationsBottomSheet(context, budgetProvider),
              ),
              if (budgetProvider.activeAlerts.any((a) => !a.leida))
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.expenseRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNotificationsBottomSheet(
    BuildContext context,
    BudgetProvider budgetProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return AnimatedBuilder(
              animation: budgetProvider,
              builder: (context, _) {
                final alerts = budgetProvider.activeAlerts;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.dividerGray,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusRound,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Notificaciones', style: AppTextStyles.heading2),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: alerts.isEmpty
                            ? const Center(
                                child: Text(
                                  'No tienes notificaciones por el momento',
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: alerts.length,
                                itemBuilder: (context, index) {
                                  final alert = alerts[index];
                                  IconData icon;
                                  Color color;
                                  switch (alert.tipo) {
                                    case TipoAlerta.critica:
                                      icon = LucideIcons.alertOctagon;
                                      color = AppColors.expenseRed;
                                      break;
                                    case TipoAlerta.advertencia:
                                      icon = LucideIcons.alertTriangle;
                                      color = AppColors.warningAmber;
                                      break;
                                    case TipoAlerta.informativa:
                                      icon = LucideIcons.info;
                                      color = Colors.blue;
                                      break;
                                    case TipoAlerta.motivacional:
                                      icon = LucideIcons.sparkles;
                                      color = AppColors.incomeGreen;
                                      break;
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: SBCard(
                                      backgroundColor: alert.leida
                                          ? AppColors.surfaceWhite
                                          : AppColors.primaryLight.withValues(
                                              alpha: 0.4,
                                            ),
                                      padding: const EdgeInsets.all(
                                        AppSpacing.md,
                                      ),
                                      border: alert.leida
                                          ? null
                                          : BorderSide(
                                              color: color.withValues(
                                                alpha: 0.3,
                                              ),
                                              width: 1.0,
                                            ),
                                      onTap: () {
                                        if (!alert.leida) {
                                          budgetProvider.markAlertAsRead(
                                            alert.id,
                                          );
                                        }
                                      },
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(icon, color: color, size: 24),
                                          const SizedBox(width: AppSpacing.md),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        alert.titulo,
                                                        style: AppTextStyles
                                                            .bodyMedium
                                                            .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                    ),
                                                    if (!alert.leida)
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration:
                                                            const BoxDecoration(
                                                          color: AppColors
                                                              .expenseRed,
                                                          shape: BoxShape
                                                              .circle,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  alert.mensaje,
                                                  style: AppTextStyles.caption
                                                      .copyWith(
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                ),
                                              ],
                                            ),
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
                );
              },
            );
          },
        );
      },
    );
  }
}
