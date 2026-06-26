/// Métricas reales del "Resumen personal" de la pantalla de Perfil (1A).
///
/// Las alimenta el endpoint `GET /profile/summary`. "Días racha" NO viene de
/// aquí: no hay tracking en el backend, así que en la UI es un placeholder.
class ProfileSummary {
  final int metasActivas;
  final int gastosRegistrados;
  final double dineroAhorrado;

  /// SmartScore actual; `null` si el usuario aún no tiene presupuesto activo.
  final int? smartScore;

  /// Variación vs. el mes anterior (puede ser negativa o 0).
  final int smartScoreDelta;

  const ProfileSummary({
    required this.metasActivas,
    required this.gastosRegistrados,
    required this.dineroAhorrado,
    this.smartScore,
    this.smartScoreDelta = 0,
  });

  factory ProfileSummary.fromJson(Map<String, dynamic> json) {
    return ProfileSummary(
      metasActivas: json['metas_activas'] as int? ?? 0,
      gastosRegistrados: json['gastos_registrados'] as int? ?? 0,
      dineroAhorrado: (json['dinero_ahorrado'] as num?)?.toDouble() ?? 0.0,
      smartScore: json['smartscore'] as int?,
      smartScoreDelta: json['smartscore_delta'] as int? ?? 0,
    );
  }
}
