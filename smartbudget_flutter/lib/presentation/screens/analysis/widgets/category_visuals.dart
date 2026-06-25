import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Helpers visuales de las categorías de gasto, compartidos por el flujo de
/// Análisis (1A Resumen · 1B Categorías · 1D Detalle).
///
/// Fuente única de color, ícono y rótulo para que las tres pantallas pinten
/// cada categoría igual (lock de consistencia del plan). "ocio" se rotula
/// "Entretenimiento" en toda la sección.
class CategoryVisuals {
  CategoryVisuals._();

  static Color color(String key) {
    switch (key.toLowerCase()) {
      case 'comida':
        return const Color(0xFFEF4444);
      case 'transporte':
        return const Color(0xFF3B82F6);
      case 'ocio':
        return const Color(0xFFA855F7);
      case 'salud':
        return const Color(0xFF10B981);
      case 'educacion':
        return const Color(0xFF6366F1);
      case 'ropa':
        return const Color(0xFFEC4899);
      case 'hogar':
        return const Color(0xFFF59E0B);
      case 'tecnologia':
        return const Color(0xFF0EA5E9);
      case 'viajes':
        return const Color(0xFF14B8A6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  static String label(String key) {
    switch (key.toLowerCase()) {
      case 'comida':
        return 'Comida';
      case 'transporte':
        return 'Transporte';
      case 'ocio':
        return 'Entretenimiento';
      case 'salud':
        return 'Salud';
      case 'educacion':
        return 'Educación';
      case 'ropa':
        return 'Ropa';
      case 'hogar':
        return 'Hogar';
      case 'tecnologia':
        return 'Tecnología';
      case 'viajes':
        return 'Viajes';
      default:
        return 'Otros';
    }
  }

  /// Emoji 3D por categoría (estilo del mockup) para las listas de categorías
  /// y comercios. Más cálido que el ícono de línea; el `icon()` de Lucide se
  /// reserva para badges/affordances de UI.
  static String emoji(String key) {
    switch (key.toLowerCase()) {
      case 'comida':
        return '🍔';
      case 'transporte':
        return '🚗';
      case 'ocio':
        return '🎮';
      case 'salud':
        return '❤️';
      case 'educacion':
        return '📚';
      case 'ropa':
        return '👕';
      case 'hogar':
        return '🏠';
      case 'tecnologia':
        return '💻';
      case 'viajes':
        return '✈️';
      default:
        return '📦';
    }
  }

  /// Ilustración 3D por categoría (las mismas de assets que usan metas y el
  /// simulador). Es lo que se muestra en las listas de categorías del flujo.
  static String illustration(String key) {
    switch (key.toLowerCase()) {
      case 'comida':
        return 'assets/images/comida.webp';
      case 'transporte':
        return 'assets/images/transporte.png';
      case 'ocio':
        return 'assets/images/ocio.png';
      case 'salud':
        return 'assets/images/salud.png';
      case 'educacion':
        return 'assets/images/educacion.png';
      case 'ropa':
        return 'assets/images/ropa.png';
      case 'hogar':
        return 'assets/images/hogar.png';
      case 'tecnologia':
        return 'assets/images/tecnologia.png';
      case 'viajes':
        return 'assets/images/viajes.png';
      default:
        return 'assets/images/otros.png';
    }
  }

  static IconData icon(String key) {
    switch (key.toLowerCase()) {
      case 'comida':
        return LucideIcons.utensils;
      case 'transporte':
        return LucideIcons.car;
      case 'ocio':
        return LucideIcons.gamepad2;
      case 'salud':
        return LucideIcons.heart;
      case 'educacion':
        return LucideIcons.bookOpen;
      case 'ropa':
        return LucideIcons.shirt;
      case 'hogar':
        return LucideIcons.home;
      case 'tecnologia':
        return LucideIcons.laptop;
      case 'viajes':
        return LucideIcons.plane;
      default:
        return LucideIcons.moreHorizontal;
    }
  }

  /// Agrupa la distribución a un máximo de 6 segmentos (top 5 + "Otros") para
  /// mantener el donut legible (regla no-pie-overuse). La lista completa de 1B
  /// usa los datos sin agrupar; esto es solo para el chart.
  static Map<String, double> topCategories(Map<String, double> expenses) {
    final entries = expenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.length <= 6) {
      return {for (final e in entries) e.key: e.value};
    }
    final result = <String, double>{};
    double otros = 0;
    for (var i = 0; i < entries.length; i++) {
      if (i < 5 && entries[i].key.toLowerCase() != 'otros') {
        result[entries[i].key] = entries[i].value;
      } else {
        otros += entries[i].value;
      }
    }
    if (otros > 0) result['otros'] = otros;
    return result;
  }
}

/// Recuadro con la ilustración 3D de la categoría sobre un fondo con su tinte.
/// Reutilizable por las listas de Análisis (1B Categorías, 1D Detalle).
class CategoryAvatar extends StatelessWidget {
  final String categoryKey;
  final double size;

  const CategoryAvatar({super.key, required this.categoryKey, this.size = 46});

  @override
  Widget build(BuildContext context) {
    final color = CategoryVisuals.color(categoryKey);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.30),
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.15),
        child: Image.asset(
          CategoryVisuals.illustration(categoryKey),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Text(
              CategoryVisuals.emoji(categoryKey),
              style: TextStyle(fontSize: size * 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
