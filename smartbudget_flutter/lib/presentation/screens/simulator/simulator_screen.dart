import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../widgets/app_header.dart';
import '../../widgets/header_background_painter.dart';

class SimulatorScreen extends StatelessWidget {
  const SimulatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: HeaderBackgroundPainter()),
            ),
            ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              children: [
                const AppHeader(),
                const SizedBox(height: AppSpacing.xs),
                _buildHeroSection(),
                const SizedBox(height: 14),
                ..._buildModuleCards(context),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 55,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Simulador',
                style: GoogleFonts.inter(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A1A2E),
                  height: 1.05,
                ),
              ),
              Text(
                'Financiero',
                style: GoogleFonts.inter(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textGreenHighlight,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Prueba escenarios antes de tomar decisiones inteligentes.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.04, end: 0, duration: 400.ms, curve: Curves.easeOut),
        ),
        const SizedBox(width: 4),
        Expanded(
          flex: 45,
          child: Image.asset(
            'assets/images/simulador.png',
            height: 125,
            fit: BoxFit.contain,
          )
              .animate()
              .fadeIn(delay: 120.ms, duration: 500.ms)
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1, 1),
                delay: 120.ms,
                duration: 500.ms,
                curve: Curves.easeOutBack,
              ),
        ),
      ],
    );
  }

  List<Widget> _buildModuleCards(BuildContext context) {
    final modules = [
      _SimModule(
        title: 'Micro-ahorro progresivo',
        description:
            'Reduce pequeños gastos y descubre cuánto podrías ahorrar.',
        imagePath: 'assets/images/piggy_bank_3d.png',
        buttonLabel: 'Simular',
        onTap: () => context.push('/simulator/micro-ahorro'),
      ),
      _SimModule(
        title: 'Comparador de decisiones',
        description:
            '¿Delivery o cocinar? Compara hábitos y descubre cuánto dinero pierdes.',
        imagePath: 'assets/images/comparador_decisiones.png',
        buttonLabel: 'Comparar',
        onTap: () => _showComingSoon(
            context, 'Comparador de decisiones', LucideIcons.scale),
      ),
      _SimModule(
        title: 'Eventos de vida',
        description:
            '¿Puedes costear una laptop, un viaje o un auto? Analiza tu viabilidad.',
        imagePath: 'assets/images/eventos_vida.png',
        buttonLabel: 'Explorar',
        onTap: () =>
            _showComingSoon(context, 'Eventos de vida', LucideIcons.calendar),
      ),
      _SimModule(
        title: 'Escenario personalizado (IA)',
        description:
            'Crea cualquier escenario financiero y obtén un análisis con IA.',
        imagePath: 'assets/images/escenario_ia.png',
        buttonLabel: 'Analizar',
        onTap: () => _showComingSoon(
            context, 'Escenario personalizado', LucideIcons.sparkles),
      ),
      _SimModule(
        title: 'Analizador de ahorro (IA)',
        description: 'Descubre oportunidades de ahorro ocultas con IA.',
        imagePath: 'assets/images/analizador_ahorro.png',
        buttonLabel: 'Analizar gastos',
        onTap: () => _showComingSoon(
            context, 'Analizador de ahorro', LucideIcons.brain),
      ),
    ];

    return modules.asMap().entries.map((entry) {
      final i = entry.key;
      final module = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildModuleCard(context, module)
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: 100 + i * 80),
              duration: 360.ms,
            )
            .slideY(
              begin: 0.07,
              end: 0,
              delay: Duration(milliseconds: 100 + i * 80),
              duration: 360.ms,
              curve: Curves.easeOut,
            ),
      );
    }).toList();
  }

  Widget _buildModuleCard(BuildContext context, _SimModule module) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.dividerGray.withValues(alpha: 0.55),
          width: 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    module.title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    module.description,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 9),
                  GestureDetector(
                    onTap: module.onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFADD8A4),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        module.buttonLabel,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2A6B25),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2),
            // Imagen con animación flotante en loop
            Image.asset(
              module.imagePath,
              height: 125,
              width: 125,
              fit: BoxFit.contain,
            )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .moveY(
                  begin: 0,
                  end: -6,
                  duration: 1900.ms,
                  curve: Curves.easeInOut,
                ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(
      BuildContext context, String moduleName, IconData icon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.primaryGreen),
            ),
            const SizedBox(height: 16),
            Text(
              moduleName,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Este módulo estará disponible muy pronto.\nEstamos trabajando para ofrecerte la mejor experiencia.',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Entendido',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
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

class _SimModule {
  final String title;
  final String description;
  final String imagePath;
  final String buttonLabel;
  final VoidCallback onTap;

  const _SimModule({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.buttonLabel,
    required this.onTap,
  });
}
