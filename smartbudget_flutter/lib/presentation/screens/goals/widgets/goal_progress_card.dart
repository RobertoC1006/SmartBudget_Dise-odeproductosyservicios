import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/goal_model.dart';
import 'goal_category_icon.dart';
import 'goal_format.dart';

/// Tarjeta compacta de una meta (icono 3D + nombre + saldo/objetivo + barra + %).
/// Encabeza las pantallas del flujo de aporte (① ingresar monto, ② confirmar).
class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({super.key, required this.goal});
  final GoalModel goal;

  @override
  Widget build(BuildContext context) {
    final cat = resolveCategoria(goal.categoria, goal.nombre);
    final pct = (goal.progreso * 100).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accentGreenBorder),
      ),
      child: Row(
        children: [
          GoalCategoryIcon(category: cat, size: 54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1C2434),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${GoalFormat.money(goal.saldoAcumulado)} de ${GoalFormat.money(goal.montoObjetivo)}',
                  style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: goal.progreso,
                          minHeight: 8,
                          backgroundColor: Colors.white,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primaryGreen),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$pct%',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
