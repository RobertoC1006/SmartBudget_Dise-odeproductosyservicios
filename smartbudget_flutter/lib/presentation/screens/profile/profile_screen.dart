import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/profile_provider.dart';
import '../../../data/models/profile_summary_model.dart';
import '../../widgets/header_background_painter.dart';
import '../../widgets/smart_score_ring.dart';
import 'widgets/coming_soon.dart';

/// 1A · Perfil — Resumen (rediseño según mockup).
///
/// Vive dentro del Shell (la barra inferior la pone `AppScaffold`). Los datos
/// del "Resumen personal" y el SmartScore son reales (`ProfileProvider`); el
/// badge Premium es visual y "Días racha" es un placeholder (no hay tracking).
///
/// Toda la vista scrollea como una sola unidad (cabecera incluida).
///
/// Nav a 1B/1C/1D: las rutas `/profile/settings|security|preferences` se
/// registran en las Fases B/C/D (mismo patrón que el flujo de metas/análisis).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final user = auth.user;
    final summary = profile.summary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: () => context.read<ProfileProvider>().loadSummary(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileHeader(user: user),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SmartScoreCard(summary: summary)
                          .animate()
                          .fade(delay: 80.ms, duration: 360.ms)
                          .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
                      const SizedBox(height: AppSpacing.md),
                      _SectionTitle('Resumen personal')
                          .animate()
                          .fade(delay: 140.ms, duration: 360.ms),
                      const SizedBox(height: AppSpacing.sm),
                      _StatsGrid(summary: summary)
                          .animate()
                          .fade(delay: 180.ms, duration: 360.ms)
                          .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
                      const SizedBox(height: AppSpacing.md),
                      _PremiumCard()
                          .animate()
                          .fade(delay: 240.ms, duration: 360.ms)
                          .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
                      const SizedBox(height: AppSpacing.md),
                      _AccessRow(
                        icon: LucideIcons.settings,
                        label: 'Configuración',
                        onTap: () => comingSoon(context, 'Configuración'),
                      ).animate().fade(delay: 300.ms, duration: 320.ms),
                      const SizedBox(height: AppSpacing.sm),
                      _AccessRow(
                        icon: LucideIcons.shield,
                        label: 'Seguridad',
                        onTap: () => comingSoon(context, 'Seguridad'),
                      ).animate().fade(delay: 340.ms, duration: 320.ms),
                      const SizedBox(height: AppSpacing.sm),
                      _AccessRow(
                        icon: LucideIcons.slidersHorizontal,
                        label: 'Preferencias',
                        onTap: () => comingSoon(context, 'Preferencias'),
                      ).animate().fade(delay: 380.ms, duration: 320.ms),
                      const SizedBox(height: AppSpacing.md),
                      _LogoutButton()
                          .animate()
                          .fade(delay: 420.ms, duration: 320.ms),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header: avatar, nombre, badge y "miembro desde" ──────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final nombre = user?.nombre ?? 'Usuario';
    final email = user?.email ?? '';
    final initials = nombre.trim().isNotEmpty ? nombre.trim()[0].toUpperCase() : 'U';

    String miembroDesde = '';
    final createdAt = user?.createdAt as DateTime?;
    if (createdAt != null) {
      final mesAnio = DateFormat('MMMM yyyy', 'es').format(createdAt);
      final capitalizado =
          mesAnio.isNotEmpty ? mesAnio[0].toUpperCase() + mesAnio.substring(1) : mesAnio;
      miembroDesde = 'Miembro desde $capitalizado';
    }

    return Stack(
      children: [
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 150,
            child: CustomPaint(painter: HeaderBackgroundPainter()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 28, AppSpacing.md, 0),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7CC827), Color(0xFF4C8C2B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7CC827).withValues(alpha: 0.32),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Nombre + Editar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1C2434),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => comingSoon(context, 'La edición de perfil'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Editar',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4C8C2B),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.pencil, size: 12, color: Color(0xFF4C8C2B)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 10),
              // Badge SmartBudget+ (visual aspiracional)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SmartBudget+',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4C8C2B),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text('👑', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              if (miembroDesde.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  miembroDesde,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8A94A6),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Engrane → Configuración
        Positioned(
          top: 16,
          right: 8,
          child: IconButton(
            onPressed: () => comingSoon(context, 'Configuración'),
            icon: const Icon(LucideIcons.settings, size: 22),
            color: const Color(0xFF5C6470),
            tooltip: 'Configuración',
          ),
        ),
      ],
    );
  }
}

// ─── Tarjeta SmartScore (datos reales) ────────────────────────────────────────

class _SmartScoreCard extends StatelessWidget {
  const _SmartScoreCard({required this.summary});
  final ProfileSummary? summary;

  String _copy(int score) {
    if (score >= 80) return '¡Vas increíble! 🌟';
    if (score >= 70) return '¡Vas por buen camino! 🚀';
    if (score >= 50) return 'Vas mejorando 💪';
    if (score >= 30) return 'Cuidado con tus gastos ⚠️';
    return 'Es hora de ahorrar 🐷';
  }

  @override
  Widget build(BuildContext context) {
    final score = summary?.smartScore;
    final delta = summary?.smartScoreDelta ?? 0;

    return GestureDetector(
      onTap: () => context.push('/analysis'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accentGreenBorder),
        ),
        child: score == null
            ? Row(
                children: [
                  const Icon(LucideIcons.activity, size: 36, color: Color(0xFF8A94A6)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Crea tu presupuesto para ver tu SmartScore.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5C6470),
                      ),
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, size: 20, color: Color(0xFF8A94A6)),
                ],
              )
            : Row(
                children: [
                  SmartScoreRing(score: score, size: 66),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SmartScore',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4C8C2B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _copy(score),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1C2434),
                          ),
                        ),
                        const SizedBox(height: 5),
                        _DeltaPill(delta: delta),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, size: 20, color: Color(0xFF8A94A6)),
                ],
              ),
      ),
    );
  }
}

class _DeltaPill extends StatelessWidget {
  const _DeltaPill({required this.delta});
  final int delta;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    final String text;
    if (delta > 0) {
      icon = LucideIcons.trendingUp;
      color = AppColors.incomeGreen;
      text = '+$delta pts vs. el mes pasado';
    } else if (delta < 0) {
      icon = LucideIcons.trendingDown;
      color = AppColors.expenseRed;
      text = '$delta pts vs. el mes pasado';
    } else {
      icon = LucideIcons.minus;
      color = const Color(0xFF8A94A6);
      text = 'Sin cambios vs. el mes pasado';
    }
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Grid 2×2 del Resumen personal ────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.summary});
  final ProfileSummary? summary;

  @override
  Widget build(BuildContext context) {
    final metas = summary?.metasActivas;
    final gastos = summary?.gastosRegistrados;
    final ahorro = summary?.dineroAhorrado;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: LucideIcons.target,
                iconColor: AppColors.primaryGreen,
                value: metas?.toString() ?? '—',
                label: 'Metas activas',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              // Placeholder visual: no hay tracking de racha (ver Fase E).
              child: _StatCard(
                icon: LucideIcons.flame,
                iconColor: AppColors.warningAmber,
                value: '23',
                label: 'Días racha',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: LucideIcons.receipt,
                iconColor: const Color(0xFF3B82F6),
                value: gastos?.toString() ?? '—',
                label: 'Gastos registrados',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                icon: LucideIcons.piggyBank,
                iconColor: const Color(0xFFEC4899),
                value: ahorro != null ? CurrencyFormatter.format(ahorro) : '—',
                label: 'Dinero ahorrado',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1C2434),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8A94A6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta Plan Premium (visual aspiracional) ───────────────────────────────

class _PremiumCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFAFEF9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFF3E2B3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('👑', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      'Plan Premium',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1C2434),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Desbloquea todas las funciones',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => comingSoon(context, 'El plan Premium'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'Ver beneficios',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text('👑', style: TextStyle(fontSize: 52)),
        ],
      ),
    );
  }
}

// ─── Fila de acceso (Configuración / Seguridad / Preferencias) ────────────────

class _AccessRow extends StatelessWidget {
  const _AccessRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF4C8C2B)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1C2434),
                  ),
                ),
              ),
              const Icon(LucideIcons.chevronRight, size: 20, color: Color(0xFF8A94A6)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Botón Cerrar sesión ──────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () async {
          await context.read<AuthProvider>().logout();
          if (context.mounted) context.go('/login');
        },
        icon: const Icon(LucideIcons.logOut, size: 18, color: AppColors.expenseRed),
        label: Text(
          'Cerrar sesión',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.expenseRed,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.expenseRed, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ─── Título de sección ────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1C2434),
      ),
    );
  }
}
