import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/analysis_model.dart';
import '../../../data/providers/analysis_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/header_background_painter.dart';

class MicroSavingsScreen extends StatefulWidget {
  const MicroSavingsScreen({super.key});

  @override
  State<MicroSavingsScreen> createState() => _MicroSavingsScreenState();
}

class _MicroSavingsScreenState extends State<MicroSavingsScreen> {
  String _selectedCategory = 'comida';
  double _gastoActual = 0.0;
  double _gastoObjetivo = 0.0;
  bool _accordionOpen = false;
  final _pillKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  late final ConfettiController _confettiController;
  bool _prevShowResults = false;

  @override
  void dispose() {
    _confettiController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 2200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AnalysisProvider>();
      if (provider.expensesByCategory == null) {
        provider.loadAnalysisData().then((_) {
          if (mounted) _prefillCategory();
        });
      } else {
        _prefillCategory();
      }
    });
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  void _prefillCategory() {
    final expenses = context.read<AnalysisProvider>().expensesByCategory;
    if (expenses == null || expenses.isEmpty) return;
    final sorted = expenses.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.isEmpty) return;
    setState(() {
      _selectedCategory = sorted.first.key;
      _gastoActual = sorted.first.value;
      _gastoObjetivo = (_gastoActual * 0.7).roundToDouble();
    });
  }

  void _selectCategory(String cat, Map<String, double> expenses) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _selectedCategory = cat;
      _gastoActual = expenses[cat] ?? 0.0;
      _gastoObjetivo = (_gastoActual * 0.7).roundToDouble();
      _accordionOpen = false;
      context.read<AnalysisProvider>().clearSavingsProjection();
    });
  }

  Color _catColor(String key) {
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

  String _catLabel(String key) {
    switch (key.toLowerCase()) {
      case 'comida':
        return 'Comida';
      case 'transporte':
        return 'Transporte';
      case 'ocio':
        return 'Ocio';
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

  String _catEmoji(String key) {
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
        return '💰';
    }
  }

  String _catImage(String key) {
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

  double get _ahorroEstimado =>
      (_gastoActual - _gastoObjetivo).clamp(0.0, double.infinity);

  void _showInfoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dividerGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '¿Cómo funciona?',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '1. Selecciona la categoría donde más gastas.\n'
              '2. Ajusta cuánto quieres gastar al mes con el slider.\n'
              '3. Proyecta cuánto ahorrarías en 3, 6 y 12 meses.\n\n'
              'Los datos se basan en tus últimos 3 meses de movimientos.',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Dropdown overlay ────────────────────────────────────────────────────────

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _accordionOpen = false);
  }

  void _openDropdown(BuildContext ctx, Map<String, double> expenses) {
    final renderBox = _pillKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenWidth = MediaQuery.of(ctx).size.width;

    _overlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.opaque,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          Positioned(
            top: offset.dy + size.height + 6,
            left: 20,
            width: screenWidth - 40,
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildCategoryOverlayItems(expenses),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(ctx).insert(_overlayEntry!);
    setState(() => _accordionOpen = true);
  }

  List<Widget> _buildCategoryOverlayItems(Map<String, double> expenses) {
    const cats = [
      'comida',
      'transporte',
      'ocio',
      'salud',
      'educacion',
      'ropa',
      'hogar',
      'tecnologia',
      'viajes',
      'otros',
    ];
    return cats.map((cat) {
      final amount = expenses[cat] ?? 0.0;
      final isSelected = _selectedCategory == cat;
      final color = _catColor(cat);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectCategory(cat, expenses),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Text(_catEmoji(cat), style: const TextStyle(fontSize: 17)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _catLabel(cat),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? color : AppColors.textPrimary,
                  ),
                ),
              ),
              if (amount > 0)
                Text(
                  CurrencyFormatter.format(amount),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? color : AppColors.textSecondary,
                  ),
                ),
              const SizedBox(width: 6),
              SizedBox(
                width: 14,
                child: isSelected
                    ? Icon(LucideIcons.check, size: 13, color: color)
                    : null,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ─── Root build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    final showResults = provider.savingsProjection != null;

    if (showResults && !_prevShowResults) {
      _prevShowResults = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _confettiController.play(),
      );
    } else if (!showResults) {
      _prevShowResults = false;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      bottomNavigationBar: BottomNavBar(currentIndex: 4),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: HeaderBackgroundPainter()),
            ),
            Column(
              children: [
            const AppHeader(),
            _buildHeader(context, showResults),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: showResults
                    ? _buildResultsScreen(
                        provider.savingsProjection!,
                        key: const ValueKey('results'),
                      )
                    : _buildConfigScreen(
                        provider,
                        key: const ValueKey('config'),
                      ),
              ),
            ),
          ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool showResults) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {
              final p = context.read<AnalysisProvider>();
              if (p.savingsProjection != null) {
                p.clearSavingsProjection();
              } else {
                context.pop();
              }
            },
            icon: const Icon(
              LucideIcons.arrowLeft,
              size: 22,
              color: AppColors.textPrimary,
            ),
            padding: const EdgeInsets.all(10),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: Text(
                showResults
                    ? 'Tu proyección de ahorro'
                    : 'Micro-ahorro progresivo',
                key: ValueKey(showResults),
                style: AppTextStyles.heading2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: showResults ? 0.0 : 1.0,
            child: IconButton(
              onPressed: showResults ? null : _showInfoSheet,
              icon: const Icon(
                LucideIcons.info,
                size: 20,
                color: AppColors.textSecondary,
              ),
              padding: const EdgeInsets.all(10),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ─── Config screen (1A) ──────────────────────────────────────────────────────

  Widget _buildConfigScreen(AnalysisProvider provider, {Key? key}) {
    final expenses = provider.expensesByCategory ?? {};
    final canProject =
        _gastoActual > 0 &&
        _gastoObjetivo < _gastoActual &&
        !provider.isProjecting;

    return LayoutBuilder(
      key: key,
      builder: (_, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── TOP: tarjetas + banner de ahorro ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Card 1: unified ──
                  Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8F6),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                14,
                                16,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selecciona una categoría',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Pill — tap opens floating dropdown overlay
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _accordionOpen
                                        ? _closeDropdown()
                                        : _openDropdown(context, expenses),
                                    child: Container(
                                      key: _pillKey,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 9,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFD4E8CE),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            _catEmoji(_selectedCategory),
                                            style: const TextStyle(
                                              fontSize: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _catLabel(_selectedCategory),
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          AnimatedRotation(
                                            turns: _accordionOpen ? 0.25 : 0.0,
                                            duration: const Duration(
                                              milliseconds: 260,
                                            ),
                                            curve: Curves.easeInOut,
                                            child: const Icon(
                                              LucideIcons.chevronRight,
                                              size: 17,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                10,
                                24,
                                10,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 320,
                                      ),
                                      transitionBuilder: (child, anim) =>
                                          FadeTransition(
                                            opacity: anim,
                                            child: SlideTransition(
                                              position: Tween<Offset>(
                                                begin: const Offset(0, 0.08),
                                                end: Offset.zero,
                                              ).animate(
                                                CurvedAnimation(
                                                  parent: anim,
                                                  curve: Curves.easeOut,
                                                ),
                                              ),
                                              child: child,
                                            ),
                                          ),
                                      child: Align(
                                        key: ValueKey(_selectedCategory),
                                        alignment: Alignment.centerLeft,
                                        child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Gasto promedio actual',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              _gastoActual > 0
                                                  ? CurrencyFormatter.format(
                                                      _gastoActual,
                                                    )
                                                  : 'Sin datos',
                                              style: GoogleFonts.inter(
                                                fontSize: 36,
                                                fontWeight: FontWeight.w900,
                                                color: const Color(0xFF1A1A2E),
                                                height: 1.1,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'por mes',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  AnimatedSwitcher(
                                    duration: const Duration(
                                      milliseconds: 350,
                                    ),
                                    transitionBuilder: (child, anim) =>
                                        FadeTransition(
                                          opacity: anim,
                                          child: ScaleTransition(
                                            scale: Tween<double>(
                                              begin: 0.80,
                                              end: 1.0,
                                            ).animate(
                                              CurvedAnimation(
                                                parent: anim,
                                                curve: Curves.easeOutBack,
                                              ),
                                            ),
                                            child: child,
                                          ),
                                        ),
                                    child: Image.asset(
                                          _catImage(_selectedCategory),
                                          key: ValueKey(_selectedCategory),
                                          height: 95,
                                          width: 95,
                                          fit: BoxFit.contain,
                                        )
                                        .animate(
                                          onPlay: (c) =>
                                              c.repeat(reverse: true),
                                        )
                                        .moveY(
                                          begin: 0,
                                          end: -6,
                                          duration: 2200.ms,
                                          curve: Curves.easeInOut,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.04, end: 0, duration: 350.ms),

                  const SizedBox(height: 8),

                  // ── Card 2: Objective slider ──
                  Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8F6),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¿Cuánto quieres gastar?',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Objetivo mensual',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _gastoActual > 0
                                    ? CurrencyFormatter.format(_gastoObjetivo)
                                    : 'S/ 0',
                                style: GoogleFonts.inter(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1A1A2E),
                                  height: 1.1,
                                ),
                              ),
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.primaryGreen,
                                inactiveTrackColor: const Color(0xFFDDE7D6),
                                thumbColor: AppColors.primaryGreen,
                                overlayColor: AppColors.primaryGreen.withValues(
                                  alpha: 0.1,
                                ),
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 10,
                                ),
                              ),
                              child: Slider(
                                value: _gastoActual > 0
                                    ? _gastoObjetivo.clamp(0.0, _gastoActual)
                                    : 0.0,
                                min: 0.0,
                                max: _gastoActual > 0 ? _gastoActual : 1.0,
                                onChanged: _gastoActual > 0
                                    ? (val) => setState(
                                        () => _gastoObjetivo = val
                                            .roundToDouble(),
                                      )
                                    : null,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'S/ 100',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(_gastoActual),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 60.ms, duration: 350.ms)
                      .slideY(
                        begin: 0.04,
                        end: 0,
                        delay: 60.ms,
                        duration: 350.ms,
                      ),

                  if (_ahorroEstimado > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF7EA),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD1EEC9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.trendingDown,
                              size: 20,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Ahorrarías ${CurrencyFormatter.format(_ahorroEstimado)} al mes '
                              'reduciendo tu gasto en ${_catLabel(_selectedCategory)}.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1F5C16),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 110.ms, duration: 300.ms),
                  ],
                ],
              ),

              // ── BOTTOM: error + botón + footer ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (provider.projectionError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.alertCircle,
                            size: 17,
                            color: Color(0xFFE11D48),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              provider.projectionError!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFFE11D48),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: canProject
                        ? () => provider.runSavingsProjection(
                            categoria: _selectedCategory,
                            gastoActual: _gastoActual,
                            gastoObjetivo: _gastoObjetivo,
                          )
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: canProject
                            ? AppColors.primaryGreen
                            : const Color(0xFFCDD5C9),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: canProject
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryGreen.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: provider.isProjecting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Proyectar ahorro',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 160.ms, duration: 350.ms),
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: 260,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              LucideIcons.info,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'Tus datos están basados en tus últimos 3 meses de movimientos.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Results screen (1B) ─────────────────────────────────────────────────────

  Widget _buildResultsScreen(SavingsProjectionResult res, {Key? key}) {
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      children: [
        _buildResultsHero(res),
        const SizedBox(height: 12),
        _buildWeeklyCard(res),
        const SizedBox(height: 12),
        _buildAccumulatedChart(res),
        if (res.metaImpacto.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildGoalImpact(res),
        ],
        const SizedBox(height: 22),
        GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Función disponible próximamente')),
          ),
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Guardar como meta',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 380.ms, duration: 350.ms),
      ],
    );
  }

  Widget _buildResultsHero(SavingsProjectionResult res) {
    return Container(
          padding: const EdgeInsets.fromLTRB(12, 18, 8, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE8EDEA)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ahorrarías',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(res.ahorroMensual),
                        style: GoogleFonts.inter(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1A1A2E),
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'al mes',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    emissionFrequency: 0.06,
                    numberOfParticles: 18,
                    maxBlastForce: 22,
                    minBlastForce: 8,
                    gravity: 0.25,
                    colors: const [
                      Color(0xFF4CAF50),
                      Color(0xFF8BC34A),
                      Color(0xFFFFEB3B),
                      Color(0xFFFF9800),
                      Color(0xFF2196F3),
                      Color(0xFFE91E63),
                      Color(0xFFAB47BC),
                    ],
                  ),
                  Image.asset(
                        'assets/images/piggy_bank_3d.png',
                        height: 155,
                        width: 155,
                        fit: BoxFit.contain,
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(
                        begin: 0,
                        end: -8,
                        duration: 2000.ms,
                        curve: Curves.easeInOut,
                      ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildWeeklyCard(SavingsProjectionResult res) {
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.wallet,
                  size: 20,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CurrencyFormatter.format(res.ahorroSemanal),
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    'por semana',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 80.ms, duration: 350.ms)
        .slideY(begin: 0.05, end: 0, delay: 80.ms, duration: 350.ms);
  }

  Widget _buildAccumulatedChart(SavingsProjectionResult res) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDEA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Proyección acumulada',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildChartBar(
                '3 meses',
                res.proyeccion3m,
                res.proyeccion12m,
                80.ms,
              ),
              _buildChartBar(
                '6 meses',
                res.proyeccion6m,
                res.proyeccion12m,
                160.ms,
              ),
              _buildChartBar(
                '12 meses',
                res.proyeccion12m,
                res.proyeccion12m,
                240.ms,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 140.ms, duration: 350.ms);
  }

  Widget _buildChartBar(
    String label,
    double amount,
    double maxAmount,
    Duration delay,
  ) {
    const maxH = 100.0;
    final h = maxAmount > 0
        ? (maxH * (amount / maxAmount).clamp(0.08, 1.0))
        : maxH * 0.08;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          CurrencyFormatter.format(amount),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Container(
              width: 62,
              height: h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF86EFAC), Color(0xFF16A34A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            )
            .animate(delay: delay)
            .scale(
              begin: const Offset(1, 0),
              end: const Offset(1, 1),
              alignment: Alignment.bottomCenter,
              duration: 700.ms,
              curve: Curves.easeOutCubic,
            ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ).animate(delay: delay).fadeIn(duration: 300.ms);
  }

  Widget _buildGoalImpact(SavingsProjectionResult res) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDEA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impacto en tus metas',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          ...res.metaImpacto.asMap().entries.map(
            (e) => _buildGoalRingCard(e.value, e.key),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 240.ms, duration: 350.ms);
  }

  Widget _buildGoalRingCard(MetaImpactoProjection meta, int index) {
    final pct = (meta.porcentajeCubierto12m / 100).clamp(0.0, 1.0);
    final meses = meta.mesesParaCompletar;
    final desc = meses != null
        ? 'Cubres el ${meta.porcentajeCubierto12m.toStringAsFixed(0)}% de tu meta en ${meses.toStringAsFixed(0)} meses'
        : 'Cubres el ${meta.porcentajeCubierto12m.toStringAsFixed(0)}% en 12 meses';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.nombre,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: pct),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => CircularProgressIndicator(
                      value: v,
                      strokeWidth: 5.5,
                      backgroundColor: const Color(0xFFE4E7EB),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryGreen,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
                Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 260 + index * 60),
      duration: 350.ms,
    );
  }
}
