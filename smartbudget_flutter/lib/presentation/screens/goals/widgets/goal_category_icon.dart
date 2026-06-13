import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Categoría visual de una meta. Solo determina la ilustración 3D (logo).
/// El `name` de cada valor coincide con lo que persiste el backend
/// (ej. `MetaCategoria.viaje.name == 'viaje'`).
enum MetaCategoria {
  playa,
  viaje,
  hogar,
  transporte,
  tecnologia,
  educacion,
  salud,
  otros,
}

extension MetaCategoriaInfo on MetaCategoria {
  /// Valor que viaja al backend.
  String get value => name;

  String get asset {
    switch (this) {
      case MetaCategoria.playa:
        return 'assets/images/playa.png';
      case MetaCategoria.viaje:
        return 'assets/images/viajes.png';
      case MetaCategoria.hogar:
        return 'assets/images/hogar.png';
      case MetaCategoria.transporte:
        return 'assets/images/transporte.png';
      case MetaCategoria.tecnologia:
        return 'assets/images/tecnologia.png';
      case MetaCategoria.educacion:
        return 'assets/images/educacion.png';
      case MetaCategoria.salud:
        return 'assets/images/salud.png';
      case MetaCategoria.otros:
        return 'assets/images/crear_meta.png';
    }
  }

  /// Fondo pastel del recuadro.
  Color get tile {
    switch (this) {
      case MetaCategoria.playa:
        return const Color(0xFFFFF3E0);
      case MetaCategoria.viaje:
        return const Color(0xFFE0F2FE);
      case MetaCategoria.hogar:
        return const Color(0xFFFEF3C7);
      case MetaCategoria.transporte:
        return const Color(0xFFFFF7CD);
      case MetaCategoria.tecnologia:
        return const Color(0xFFEDE9FE);
      case MetaCategoria.educacion:
        return const Color(0xFFDBEAFE);
      case MetaCategoria.salud:
        return const Color(0xFFFFE4E6);
      case MetaCategoria.otros:
        return const Color(0xFFE8F5E9);
    }
  }

  String get label {
    switch (this) {
      case MetaCategoria.playa:
        return 'Playa';
      case MetaCategoria.viaje:
        return 'Viaje';
      case MetaCategoria.hogar:
        return 'Casa';
      case MetaCategoria.transporte:
        return 'Auto';
      case MetaCategoria.tecnologia:
        return 'Tecnología';
      case MetaCategoria.educacion:
        return 'Educación';
      case MetaCategoria.salud:
        return 'Salud';
      case MetaCategoria.otros:
        return 'Otros';
    }
  }
}

/// Convierte el valor guardado del backend a [MetaCategoria] (otros por defecto).
MetaCategoria metaCategoriaFromValue(String? value) {
  return MetaCategoria.values.firstWhere(
    (c) => c.name == value,
    orElse: () => MetaCategoria.otros,
  );
}

/// Categoría efectiva de una meta para mostrar su logo:
/// usa la categoría guardada si es específica; si es `otros` (p. ej. metas
/// creadas antes del selector), cae a la detección por el nombre.
MetaCategoria resolveCategoria(String? stored, String nombre) {
  final c = metaCategoriaFromValue(stored);
  if (c != MetaCategoria.otros) return c;
  return detectMetaCategoria(nombre);
}

/// Sugiere una categoría a partir del nombre de la meta (palabras clave).
///
/// El texto se normaliza (minúsculas + sin acentos). El orden importa:
/// **playa se evalúa antes que viaje** para que "Viaje a Cancún" use la isla
/// y "Viaje a Cusco" use el ícono de viaje general.
MetaCategoria detectMetaCategoria(String name) {
  final n = _normalize(name);
  bool has(List<String> keys) => keys.any((k) => n.contains(k));

  if (name.contains('🏖️') ||
      name.contains('🏝️') ||
      has([
        'playa',
        'cancun',
        'mancora',
        'colan',
        'punta sal',
        'paracas',
        'caribe',
        'beach',
        'isla',
        'tortugas',
        'zorritos',
      ])) {
    return MetaCategoria.playa;
  }
  if (name.contains('✈️') ||
      name.contains('🌍') ||
      name.contains('🧳') ||
      has([
        'viaje',
        'vacacion',
        'cusco',
        'europa',
        'turismo',
        'crucero',
        'tour',
        'mochiler',
        'aventura',
        'montana',
        'ciudad',
        'machu',
        'paris',
        'roma',
        'extranjero',
        'mundial',
      ])) {
    return MetaCategoria.viaje;
  }
  if (name.contains('🏠') ||
      has([
        'casa',
        'hogar',
        'depa',
        'departamento',
        'mueble',
        'cocina',
        'remodel',
        'pieza',
        'habitacion',
        'agua',
        'cable',
        'comedor',
        'luz',
      ])) {
    return MetaCategoria.hogar;
  }
  if (name.contains('🚗') ||
      has(['auto', 'carro', 'vehiculo', 'moto', 'llanta'])) {
    return MetaCategoria.transporte;
  }
  if (name.contains('💻') ||
      has([
        'laptop',
        'celular',
        'tecnolog',
        'tablet',
        'computad',
        'pc',
        'telefono',
        'consola',
        'audifono',
        'camara',
        'tv',
        'juegos',
      ])) {
    return MetaCategoria.tecnologia;
  }
  if (name.contains('🎓') ||
      has([
        'universi',
        'estudi',
        'curso',
        'matricula',
        'educa',
        'colegio',
        'maestria',
        'diplomado',
        'libro',
      ])) {
    return MetaCategoria.educacion;
  }
  if (name.contains('❤️') ||
      has([
        'salud',
        'emergencia',
        'medic',
        'dental',
        'dentista',
        'gimnasio',
        'gym',
      ])) {
    return MetaCategoria.salud;
  }
  return MetaCategoria.otros;
}

String _normalize(String s) {
  var out = s.toLowerCase();
  const accents = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  accents.forEach((from, to) => out = out.replaceAll(from, to));
  return out;
}

/// Muestra la ilustración 3D de una categoría, opcionalmente sobre un recuadro
/// pastel. Se reutiliza en la lista (1A), el detalle (1B) y el detalle de logo.
class GoalCategoryIcon extends StatelessWidget {
  final MetaCategoria category;
  final double size;

  /// Si es true, muestra solo la ilustración sin el recuadro pastel.
  final bool bare;

  const GoalCategoryIcon({
    super.key,
    required this.category,
    this.size = 56,
    this.bare = false,
  });

  @override
  Widget build(BuildContext context) {
    final image = Padding(
      padding: EdgeInsets.all(size * 0.14),
      child: Image.asset(
        category.asset,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          LucideIcons.target,
          color: const Color(0xFF2E7D32),
          size: size * 0.5,
        ),
      ),
    );

    if (bare) {
      return SizedBox(width: size, height: size, child: image);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: category.tile,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: image,
    );
  }
}
