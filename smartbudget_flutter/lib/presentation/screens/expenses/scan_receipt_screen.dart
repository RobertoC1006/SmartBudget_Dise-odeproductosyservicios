import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/expense_service.dart';
import '../../widgets/sb_button.dart';
import '../../widgets/sb_card.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  final _picker = ImagePicker();
  final _expenseService = ExpenseService();
  
  bool _isProcessing = false;
  String _statusMessage = '';
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85, // Reduce size slightly for faster network uploads
      );

      if (file == null) return; // User cancelled

      await _processReceipt(file);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al acceder a la cámara o galería: ${e.toString()}';
      });
    }
  }

  Future<void> _processReceipt(XFile file) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Subiendo comprobante...';
    });

    try {
      // En web no existe acceso al filesystem, así que se envían los bytes.
      final bytes = await file.readAsBytes();

      // Simulate steps for better UX feel
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Analizando estructura del documento...';
      });

      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        _statusMessage = 'IA está extrayendo datos de compra...';
      });

      // Call API
      final Map<String, dynamic> result = await _expenseService.scanReceipt(
        bytes,
        filename: file.name,
        mimeType: file.mimeType,
      );

      if (!mounted) return;

      // Navigate to verify form (puente hasta la pantalla 1D de resultado)
      context.replace('/expenses/add', extra: result);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isProcessing = false;
      });
    }
  }

  // Helper method to simulate a mock OCR scan (extremely useful for simulator/desktop tests)
  Future<void> _simulateMockScan() async {
    setState(() {
      _errorMessage = null;
      _isProcessing = true;
      _statusMessage = 'Simulando subida de comprobante...';
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _statusMessage = 'Simulando extracción con GPT-4o Vision...';
    });

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final mockResult = {
      'monto': 145.90,
      'fecha': DateTime.now().toIso8601String().split('T')[0],
      'categoria': 'comida',
      'descripcion': 'Consumo de restaurante (Parrillada Familiar)',
      'comercio': 'El Hornero',
    };

    context.replace('/expenses/add', extra: mockResult);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Escanear comprobante',
          style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isProcessing) ...[
                // Banner Graphic showing Receipt Scanning
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.scanLine,
                    color: AppColors.primaryGreen,
                    size: 72,
                  ),
                )
                .animate()
                .fade(duration: 400.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.easeOutBack),
                
                const SizedBox(height: AppSpacing.xl),
                
                Text(
                  'Sube tu boleta o factura',
                  style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'El motor de IA extraerá automáticamente la fecha, comercio, categoría y el monto total en segundos.',
                  style: AppTextStyles.bodySecondary.copyWith(height: 1.4),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: SBCard(
                      backgroundColor: const Color(0xFFFEF2F2),
                      border: const BorderSide(color: Color(0xFFFCA5A5), width: 1),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.alertCircle, color: AppColors.expenseRed, size: 20),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTextStyles.bodySecondary.copyWith(
                                color: AppColors.expenseRed,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Button options
                SizedBox(
                  width: double.infinity,
                  child: SBButton.primary(
                    label: 'Tomar foto con Cámara',
                    icon: LucideIcons.camera,
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(LucideIcons.image, size: 18),
                    label: const Text(
                      'Seleccionar desde Galería',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Simulation button
                TextButton.icon(
                  icon: const Icon(LucideIcons.cpu, size: 16),
                  label: const Text(
                    'Simular escaneo de prueba (Sin Cámara)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  onPressed: _simulateMockScan,
                ),
              ] else ...[
                // Loading OCR processing state
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const SizedBox(
                          width: 90,
                          height: 90,
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGreen,
                            strokeWidth: 4,
                          ),
                        ),
                        Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.brainCircuit,
                            color: AppColors.primaryGreen,
                            size: 32,
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1000.ms, curve: Curves.easeInOut),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      _statusMessage,
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    )
                    .animate(key: ValueKey(_statusMessage))
                    .fade(duration: 300.ms)
                    .slideY(begin: 0.1, end: 0, duration: 300.ms),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Esto puede tardar unos segundos...',
                      style: AppTextStyles.bodySecondary,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
