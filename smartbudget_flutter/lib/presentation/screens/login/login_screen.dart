import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/sb_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success) {
        if (mounted) {
          context.go('/');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Error de inicio de sesión'),
              backgroundColor: AppColors.expenseRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Light soft pastel green background
      body: Stack(
        children: [
          // Bottom subtle chart graphic decoration
          Positioned.fill(
            child: CustomPaint(
              painter: _BottomChartPainter(),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      // Styled Squircle Logo matching image
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8CD83B),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8CD83B).withValues(alpha: 0.25),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'S',
                            style: GoogleFonts.outfit(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fade(duration: 600.ms)
                          .scale(begin: const Offset(0.7, 0.7), curve: Curves.elasticOut),
                      const SizedBox(height: AppSpacing.md),
                      // Title "SmartBudget" with colors
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1C2434),
                          ),
                          children: const [
                            TextSpan(text: 'Smart'),
                            TextSpan(
                              text: 'Budget',
                              style: TextStyle(color: Color(0xFF7CC827)),
                            ),
                          ],
                        ),
                      ).animate().fade(delay: 100.ms, duration: 500.ms),
                      const SizedBox(height: 6),
                      // Tagline
                      Text(
                        'Tu compañero inteligente\npara una vida financiera saludable',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF5C6470),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fade(delay: 200.ms, duration: 500.ms),
                      const SizedBox(height: 36),
                      // Credentials Card unspiled
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE4E7EB), width: 1.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Email Field Row
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.mail,
                                    color: Color(0xFF5C6470),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Correo electrónico',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFF8A94A6),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        TextFormField(
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: const Color(0xFF1C2434),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          decoration: const InputDecoration(
                                            isCollapsed: true,
                                            contentPadding: EdgeInsets.zero,
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            focusedErrorBorder: InputBorder.none,
                                            hintText: 'ejemplo@correo.com',
                                            hintStyle: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFFBAC2CB),
                                            ),
                                            filled: false,
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Ingresa tu correo';
                                            }
                                            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                                            if (!emailRegex.hasMatch(value)) {
                                              return 'Ingresa un correo válido';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: Color(0xFFE4E7EB), indent: 16, endIndent: 16),
                            // Password Field Row
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.lock,
                                    color: Color(0xFF5C6470),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Contraseña',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFF8A94A6),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: const Color(0xFF1C2434),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          decoration: const InputDecoration(
                                            isCollapsed: true,
                                            contentPadding: EdgeInsets.zero,
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            focusedErrorBorder: InputBorder.none,
                                            hintText: '••••••••••••',
                                            hintStyle: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFFBAC2CB),
                                            ),
                                            filled: false,
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Ingresa tu contraseña';
                                            }
                                            if (value.length < 8) {
                                              return 'Debe tener al menos 8 caracteres';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                                      color: const Color(0xFF5C6470),
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fade(delay: 300.ms, duration: 500.ms)
                          .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                      const SizedBox(height: AppSpacing.sm),
                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            '¿Olvidaste tu contraseña?',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF5B9B1C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ).animate().fade(delay: 400.ms, duration: 500.ms),
                      const SizedBox(height: AppSpacing.md),
                      // Login Button (Dark charcoal rounded)
                      SBButton.primary(
                        label: 'Iniciar sesión',
                        customColor: const Color(0xFF111622),
                        isLoading: authProvider.isLoading,
                        onPressed: _submit,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      )
                          .animate()
                          .fade(delay: 500.ms, duration: 500.ms)
                          .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                      const SizedBox(height: 36),
                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿No tienes cuenta? ',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF5C6470),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/register'),
                            child: Text(
                              'Regístrate',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF5B9B1C),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fade(delay: 550.ms, duration: 500.ms),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for the bottom green line chart decoration
class _BottomChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFF7CC827).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final paintFill = Paint()
      ..style = PaintingStyle.fill;

    final pathLine = Path();
    final pathFill = Path();

    // Define line chart points
    final points = [
      Offset(0, size.height * 0.95),
      Offset(size.width * 0.2, size.height * 0.92),
      Offset(size.width * 0.4, size.height * 0.86),
      Offset(size.width * 0.5, size.height * 0.90),
      Offset(size.width * 0.6, size.height * 0.84),
      Offset(size.width * 0.75, size.height * 0.85),
      Offset(size.width * 0.88, size.height * 0.72),
      Offset(size.width, size.height * 0.62),
    ];

    pathLine.moveTo(points[0].dx, points[0].dy);
    pathFill.moveTo(0, size.height);
    pathFill.lineTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      pathLine.lineTo(points[i].dx, points[i].dy);
      pathFill.lineTo(points[i].dx, points[i].dy);
    }

    pathFill.lineTo(size.width, size.height);
    pathFill.close();

    // Draw fill gradient matching image
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFE6F7D4).withValues(alpha: 0.4),
        AppColors.backgroundWhite.withValues(alpha: 0.0),
      ],
    );
    paintFill.shader = gradient.createShader(Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.5));
    canvas.drawPath(pathFill, paintFill);

    // Draw line
    canvas.drawPath(pathLine, paintLine);

    // Draw dots at vertices
    final paintDot = Paint()
      ..color = const Color(0xFF7CC827).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final paintDotInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (var point in points) {
      canvas.drawCircle(point, 4.5, paintDot);
      canvas.drawCircle(point, 2.0, paintDotInner);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
