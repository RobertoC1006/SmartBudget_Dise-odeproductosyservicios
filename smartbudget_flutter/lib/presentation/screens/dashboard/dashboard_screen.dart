import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/alert_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/budget_provider.dart';
import '../../../data/services/expense_service.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/sb_card.dart';
import '../../widgets/sb_button.dart';
import '../../widgets/app_header.dart';
import '../../widgets/sb_text_field.dart';
import '../../widgets/amount_display.dart';
import '../../widgets/smart_score_ring.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/sb_entrance_animation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final userName = authProvider.user?.nombre ?? 'Usuario';

    if (budgetProvider.isLoading && budgetProvider.currentBudget == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(
                title: '¡Hola, $userName! 👋',
                subtitle: 'Cargando tus finanzas...',
              ),
              Expanded(child: _buildLoadingState(context)),
            ],
          ),
        ),
      );
    }

    if (!budgetProvider.hasBudget) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(
                title: '¡Hola, $userName! 👋',
                subtitle: 'Configura tu mes',
              ),
              Expanded(child: _buildEmptyBudgetState(context, budgetProvider)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _buildDashboardContent(context, budgetProvider, userName),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      children: [
        const SizedBox(height: AppSpacing.sm),
        SBCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoadingShimmer.rect(width: 120, height: 14),
              const SizedBox(height: AppSpacing.md),
              LoadingShimmer.rect(width: 180, height: 32),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: SBCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingShimmer.circle(size: 24),
                    const SizedBox(height: AppSpacing.sm),
                    LoadingShimmer.rect(width: 80, height: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SBCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingShimmer.circle(size: 24),
                    const SizedBox(height: AppSpacing.sm),
                    LoadingShimmer.rect(width: 80, height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SBCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoadingShimmer.rect(width: 140, height: 14),
              const SizedBox(height: AppSpacing.md),
              LoadingShimmer.rect(width: double.infinity, height: 8),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SBCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const LoadingShimmer.circle(size: 80),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingShimmer.rect(width: 100, height: 16),
                    const SizedBox(height: 8),
                    LoadingShimmer.rect(width: 150, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyBudgetState(BuildContext context, BudgetProvider provider) {
    final TextEditingController amountController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.wallet,
                  color: AppColors.primaryGreen,
                  size: 48,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Comienza con tu presupuesto',
                style: AppTextStyles.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Define tu presupuesto base para este mes (por ejemplo, tus ingresos fijos o sueldo) para llevar un control inteligente.',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Form(
                key: formKey,
                child: SBTextField.currency(
                  controller: amountController,
                  labelText: 'Monto base del presupuesto',
                  hintText: 'Ej. 3000.00',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SBButton.primary(
                label: 'Establecer Presupuesto',
                isLoading: provider.isLoading,
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    final value = double.tryParse(amountController.text.trim());
                    if (value != null && value > 0) {
                      final success = await provider.initializeBudget(value);
                      if (success) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '¡Presupuesto inicial creado con éxito!',
                              ),
                            ),
                          );
                        }
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Por favor, ingresa un monto válido mayor a 0',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    BudgetProvider provider,
    String userName,
  ) {
    final budget = provider.currentBudget!;
    final totalBudget = budget.montoBase + budget.ingresosAdicionales;

    // Get the first active alert if any, for dynamic Análisis Inteligente
    final firstAlert = provider.activeAlerts.isNotEmpty
        ? provider.activeAlerts.first
        : null;
    final alertMessage =
        firstAlert?.mensaje ??
        'Gastaste 32% de tu presupuesto en Comida, que es más que el promedio. Intenta reducirlo un poco.';

    return RefreshIndicator(
      onRefresh: () => provider.loadDashboard(),
      color: AppColors.primaryGreen,
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        clipBehavior: Clip.none,
        children: [
          // Header (with avatar image and notification bell)
          const AppHeader(),

          const SizedBox(height: AppSpacing.sm),

          // 1. SALDO DISPONIBLE (Protagonist card, soft pastel green gradient with 3D Wallet)
          Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                        topRight: Radius.circular(
                          125,
                        ), // Asymmetric curve/deformity
                      ),
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppColors.accentGreenSoft, // Soft pastel green on the left
                          AppColors.accentGreenLight, // Almost white on the right
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.accentGreenBorder, // soft green border
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.only(
                      left: 24,
                      top: 24,
                      bottom: 24,
                      right: 120,
                    ), // Adjusted padding to reduce separation
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo disponible',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textGreenHighlight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AmountDisplay(
                          amount: budget.saldoDisponible,
                          size: AmountSize.large,
                          isMasked: !provider.showBalance,
                          color: const Color(0xFF1C2434),
                        ),
                        const SizedBox(height: 12),
                        // Ocultar Saldo button (pill-shaped)
                        GestureDetector(
                          onTap: provider.toggleShowBalance,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.accentGreenBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  provider.showBalance
                                      ? LucideIcons.eyeOff
                                      : LucideIcons.eye,
                                  size: 14,
                                  color: const Color(0xFF4C8C2B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  provider.showBalance
                                      ? 'Ocultar saldo'
                                      : 'Mostrar saldo',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4C8C2B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Overflowing 3D Wallet Image on the right (Adjusted size and right coordinate to reduce gap)
                  Positioned(
                    top: -24,
                    right: 0, // Brought in from -10 to 0
                    bottom: -10,
                    child: SizedBox(
                      width: 155, // Increased width from 145 to 155
                      child: Image.asset(
                        'assets/images/wallet_3d.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFC8E6C9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.wallet,
                                color: Color(0xFF4C8C2B),
                                size: 32,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              )
              .animateEntrance(slideOffset: 0.1),

          const SizedBox(height: AppSpacing.md),

          // 2. METRICS ROW (Ingresos, Gastos)
          Row(
                children: [
                  // Ingresos Card
                  Expanded(
                    child: SBCard(
                      borderRadius: 20,
                      backgroundColor: Colors.white,
                      border: const BorderSide(
                        color: Color(0xFFE5E7EB),
                        width: 1.0,
                      ),
                      padding: const EdgeInsets.all(12),
                      onTap: () {
                        // Action or navigate
                      },
                      child: Row(
                        children: [
                          // Icon Left
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3FAF0),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                LucideIcons.trendingUp,
                                color: Color(0xFF4C8C2B),
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Text center
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ingresos',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    provider.showBalance
                                        ? _formatNoDecimals(totalBudget)
                                        : 'S/ ••••',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1C2434),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Este mes',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Arrow Right
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3FAF0),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                LucideIcons.arrowRight,
                                color: Color(0xFF4C8C2B),
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Gastos Card
                  Expanded(
                    child: SBCard(
                      borderRadius: 20,
                      backgroundColor: Colors.white,
                      border: const BorderSide(
                        color: Color(0xFFE5E7EB),
                        width: 1.0,
                      ),
                      padding: const EdgeInsets.all(12),
                      onTap: () {
                        context.go('/expenses');
                      },
                      child: Row(
                        children: [
                          // Icon Left
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF5F4),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                LucideIcons.trendingDown,
                                color: Color(0xFFDC2626),
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Text center
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gastos',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    provider.showBalance
                                        ? _formatNoDecimals(budget.totalGastado)
                                        : 'S/ ••••',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1C2434),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Este mes',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Arrow Right
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF5F4),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                LucideIcons.arrowRight,
                                color: Color(0xFFDC2626),
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
              .animateEntrance(delay: 100.ms, slideOffset: 0.1),

          const SizedBox(height: AppSpacing.md),

          // 3. SMARTSCORE (Circular indicator & status info & Megaphone 3D inside card bounds)
          SBCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(16.0),
                border: const BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
                backgroundColor: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'SmartScore',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1C2434),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              LucideIcons.info,
                              color: Color(0xFF9CA3AF),
                              size: 16,
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            // Open details sheet or route
                          },
                          child: Row(
                            children: [
                              Text(
                                'Ver detalles',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                LucideIcons.chevronRight,
                                color: Color(0xFF3B82F6),
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        SmartScoreRing(
                          score: provider.currentScore,
                          size: 80,
                        ), // Compact ring size
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getScoreStatusText(provider.currentScore),
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1C2434),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getScoreStatusSubtitle(provider.currentScore),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF5C6470),
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildScoreTrendIndicator(
                                provider.scoreVariation,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 3D Megaphone Image inside the card bounds
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Soft peach circular backdrop
                              Container(
                                width: 72,
                                height: 72,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFFF0E5),
                                ),
                              ),
                              // Megaphone asset
                              SizedBox(
                                width: 72,
                                height: 72,
                                child: Image.asset(
                                  'assets/images/megaphone_3d.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFEF3C7),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          LucideIcons.megaphone,
                                          color: Color(0xFFD97706),
                                          size: 24,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
              .animateEntrance(delay: 200.ms, slideOffset: 0.1),

          const SizedBox(height: AppSpacing.md),

          // 4. ANÁLISIS INTELIGENTE (Lightbulb card with capsule button & Pie Chart 3D inside card bounds)
          SBCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(16.0),
                backgroundColor: Colors.white,
                border: const BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side: Lightbulb + Text Column
                    Expanded(
                      flex: 5,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEF9C3),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                LucideIcons.lightbulb,
                                color: Color(0xFFEAB308),
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Análisis inteligente',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1C2434),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  alertMessage,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF5C6470),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () => _showNotificationsBottomSheet(
                                    context,
                                    provider,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Ver consejos',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF16A34A),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          LucideIcons.arrowRight,
                                          color: Color(0xFF16A34A),
                                          size: 12,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Right side: 3D Pie Chart inside the card bounds
                    SizedBox(
                      width: 95,
                      height: 95,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Soft mint green/teal circular backdrop
                          Container(
                            width: 84,
                            height: 84,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFE8F5E9),
                            ),
                          ),
                          // Pie Chart asset
                          SizedBox(
                            width: 84,
                            height: 84,
                            child: Image.asset(
                              'assets/images/pie_chart_3d.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE0F2FE),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      LucideIcons.pieChart,
                                      color: Color(0xFF0284C7),
                                      size: 28,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .animateEntrance(delay: 300.ms, slideOffset: 0.1),

          const SizedBox(height: AppSpacing.md),

          // 5. ACTIVIDAD RECIENTE (Transaction list with clean empty state)
          Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Actividad reciente',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1C2434),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.go('/expenses');
                        },
                        child: Text(
                          'Ver todo',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5B9B1C),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (provider.recentExpenses.isEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFF3F4F6),
                          width: 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          // Grey rounded square with empty wallet icon
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F2F5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                'assets/images/wallet_empty_3d.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      LucideIcons.wallet,
                                      color: Color(0xFF9CA3AF),
                                      size: 28,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Text Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No has registrado gastos aún en este mes.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1C2434),
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '¡Comienza a registrar para tener un mejor control!',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: provider.recentExpenses.map((expense) {
                        return TransactionTile.fromExpense(
                          expense,
                          onTap: () =>
                              _showExpenseDetails(context, expense, provider),
                        );
                      }).toList(),
                    ),
                ],
              )
              .animateEntrance(delay: 400.ms, slideOffset: 0.1),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  String _formatNoDecimals(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/ ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _getScoreStatusText(int score) {
    if (score >= 71) {
      return 'Muy bien 💚';
    } else if (score >= 41) {
      return 'Regular 🟡';
    } else {
      return 'Alerta 🔴';
    }
  }

  String _getScoreStatusSubtitle(int score) {
    if (score >= 71) {
      return 'Estás haciendo un gran trabajo.';
    } else if (score >= 41) {
      return 'Buen camino, cuida tus gastos hormiga.';
    } else {
      return 'Alerta: estás gastando más de lo recomendado.';
    }
  }

  Widget _buildScoreTrendIndicator(int variation) {
    final Color color = variation >= 0
        ? const Color(0xFF4C8C2B)
        : const Color(0xFFDC2626);
    final String sign = variation > 0 ? '↑ ' : (variation < 0 ? '↓ ' : '');
    final String variationText = variation != 0
        ? '${variation.abs()} pts'
        : '0 pts';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$sign$variationText vs. el mes pasado',
          style: GoogleFonts.inter(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

  void _showExpenseDetails(
    BuildContext context,
    ExpenseModel expense,
    BudgetProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Detalle del Gasto', style: AppTextStyles.heading2),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SBCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      _buildDetailRow('Comercio', expense.comercio ?? 'Manual'),
                      const Divider(),
                      _buildDetailRow(
                        'Categoría',
                        expense.categoria.name.toUpperCase(),
                      ),
                      const Divider(),
                      _buildDetailRow(
                        'Descripción',
                        expense.descripcion ?? 'Sin descripción',
                      ),
                      const Divider(),
                      _buildDetailRow(
                        'Monto',
                        CurrencyFormatter.format(expense.monto),
                      ),
                      const Divider(),
                      _buildDetailRow(
                        'Fecha',
                        expense.fecha.toIso8601String().split('T')[0],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SBButton(
                  label: 'Eliminar Gasto',
                  customColor: AppColors.expenseRed,
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('¿Eliminar gasto?'),
                        content: const Text(
                          'Esta acción devolverá el dinero a tu saldo disponible.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Eliminar',
                              style: TextStyle(color: AppColors.expenseRed),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      navigator.pop();
                      try {
                        final expenseService = ExpenseService();
                        await expenseService.deleteExpense(expense.id);
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Gasto eliminado con éxito'),
                          ),
                        );
                        provider.loadDashboard();
                      } catch (e) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceAll('Exception: ', ''),
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
