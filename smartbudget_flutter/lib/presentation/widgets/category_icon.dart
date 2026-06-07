import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/models/expense_model.dart';

class CategoryIcon extends StatelessWidget {
  final CategoriaGasto category;
  final double size;
  final double iconSize;
  final BoxShape shape;
  final double borderRadius;

  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 40.0,
    this.iconSize = 20.0,
    this.shape = BoxShape.circle,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final mapping = _getMapping();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: mapping.backgroundColor,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(borderRadius)
            : null,
      ),
      child: Center(
        child: Icon(
          mapping.icon,
          color: mapping.iconColor,
          size: iconSize,
        ),
      ),
    );
  }

  _CategoryConfig _getMapping() {
    switch (category) {
      case CategoriaGasto.comida:
        return const _CategoryConfig(
          icon: LucideIcons.utensils,
          backgroundColor: Color(0xFFFEE2E2), // Red light
          iconColor: Color(0xFFEF4444),
        );
      case CategoriaGasto.transporte:
        return const _CategoryConfig(
          icon: LucideIcons.car,
          backgroundColor: Color(0xFFDBEAFE), // Blue light
          iconColor: Color(0xFF3B82F6),
        );
      case CategoriaGasto.ocio:
        return const _CategoryConfig(
          icon: LucideIcons.gamepad2,
          backgroundColor: Color(0xFFF3E8FF), // Purple light
          iconColor: Color(0xFFA855F7),
        );
      case CategoriaGasto.salud:
        return const _CategoryConfig(
          icon: LucideIcons.heart,
          backgroundColor: Color(0xFFD1FAE5), // Green light (Emerald)
          iconColor: Color(0xFF10B981),
        );
      case CategoriaGasto.educacion:
        return const _CategoryConfig(
          icon: LucideIcons.bookOpen,
          backgroundColor: Color(0xFFE0E7FF), // Indigo light
          iconColor: Color(0xFF6366F1),
        );
      case CategoriaGasto.ropa:
        return const _CategoryConfig(
          icon: LucideIcons.shirt,
          backgroundColor: Color(0xFFFCE7F3), // Pink light
          iconColor: Color(0xFFEC4899),
        );
      case CategoriaGasto.hogar:
        return const _CategoryConfig(
          icon: LucideIcons.home,
          backgroundColor: Color(0xFFFEF3C7), // Amber light
          iconColor: Color(0xFFF59E0B),
        );
      case CategoriaGasto.tecnologia:
        return const _CategoryConfig(
          icon: LucideIcons.laptop,
          backgroundColor: Color(0xFFE0F2FE), // Sky light
          iconColor: Color(0xFF0EA5E9),
        );
      case CategoriaGasto.viajes:
        return const _CategoryConfig(
          icon: LucideIcons.plane,
          backgroundColor: Color(0xFFCCFBF1), // Teal light
          iconColor: Color(0xFF14B8A6),
        );
      case CategoriaGasto.otros:
        return const _CategoryConfig(
          icon: LucideIcons.moreHorizontal,
          backgroundColor: Color(0xFFF3F4F6), // Gray light
          iconColor: Color(0xFF6B7280),
        );
    }
  }
}

class _CategoryConfig {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const _CategoryConfig({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });
}
