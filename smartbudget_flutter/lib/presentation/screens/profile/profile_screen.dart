import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/user_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/header_background_painter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ────────────────────────────────────────
            _ProfileHeader(user: user),
            // ─── Content ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    _InfoSection(user: user)
                        .animate()
                        .fade(delay: 100.ms, duration: 400.ms)
                        .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
                    const SizedBox(height: AppSpacing.md),
                    _OcupacionSection(user: user)
                        .animate()
                        .fade(delay: 200.ms, duration: 400.ms)
                        .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
                    const SizedBox(height: AppSpacing.lg),
                    _LogoutButton()
                        .animate()
                        .fade(delay: 300.ms, duration: 400.ms),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header con avatar y nombre ───────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final nombre = user?.nombre ?? 'Usuario';
    final email = user?.email ?? '';
    final initials = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';

    return Stack(
      children: [
        SizedBox(
          height: 180,
          width: double.infinity,
          child: CustomPaint(painter: HeaderBackgroundPainter()),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mi perfil',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1C2434),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  // Avatar con iniciales
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7CC827), Color(0xFF4C8C2B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7CC827).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1C2434),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Sección de información básica ────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        children: [
          _InfoRow(
            icon: LucideIcons.user,
            label: 'Nombre',
            value: user?.nombre ?? '—',
          ),
          const Divider(height: 1, color: Color(0xFFE4E7EB), indent: 16, endIndent: 16),
          _InfoRow(
            icon: LucideIcons.mail,
            label: 'Correo',
            value: user?.email ?? '—',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF8A94A6)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8A94A6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1C2434),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Sección de ocupación editable ────────────────────────────────────────────

class _OcupacionSection extends StatelessWidget {
  const _OcupacionSection({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final ocupacion = user?.ocupacion as OcupacionUsuario?;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '¿A qué te dedicas?',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C2434),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showOcupacionSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7CC827).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'Editar',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5B9B1C),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (ocupacion != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7CC827).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: const Color(0xFF7CC827), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(ocupacion.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      ocupacion.label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4C8C2B),
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  const Icon(LucideIcons.helpCircle, size: 16, color: Color(0xFF8A94A6)),
                  const SizedBox(width: 8),
                  Text(
                    'No definida — toca Editar para personalizar tu simulador',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF8A94A6),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showOcupacionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _OcupacionBottomSheet(
        current: user?.ocupacion as OcupacionUsuario?,
      ),
    );
  }
}

// ─── Bottom sheet selector de ocupación ──────────────────────────────────────

class _OcupacionBottomSheet extends StatefulWidget {
  const _OcupacionBottomSheet({required this.current});
  final OcupacionUsuario? current;

  @override
  State<_OcupacionBottomSheet> createState() => _OcupacionBottomSheetState();
}

class _OcupacionBottomSheetState extends State<_OcupacionBottomSheet> {
  late OcupacionUsuario? _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  Future<void> _save() async {
    if (_selected == null) return;
    setState(() => _saving = true);
    final success = await context.read<AuthProvider>().updateOcupacion(_selected!);
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar. Intenta de nuevo.'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E7EB),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '¿A qué te dedicas?',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1C2434),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Esto personaliza los escenarios del simulador',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: OcupacionUsuario.values.map((ocu) {
                final isSelected = _selected == ocu;
                return GestureDetector(
                  onTap: () => setState(() => _selected = ocu),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF7CC827).withValues(alpha: 0.1)
                          : const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF7CC827)
                            : const Color(0xFFE4E7EB),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ocu.emoji, style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 7),
                        Text(
                          ocu.label,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? const Color(0xFF4C8C2B)
                                : const Color(0xFF5C6470),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_selected == null || _saving) ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111622),
                  disabledBackgroundColor: const Color(0xFFE4E7EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Guardar',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Botón de cerrar sesión ───────────────────────────────────────────────────

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
