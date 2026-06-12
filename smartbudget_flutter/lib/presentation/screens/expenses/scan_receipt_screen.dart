import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/expense_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/header_background_painter.dart';
import '../../widgets/sb_entrance_animation.dart';

/// Pantallas 1B y 1C del flujo de gastos. 1B: cámara con preview EN
/// VIVO dentro del marco de esquinas verdes (paquete `camera`); el
/// obturador captura directamente y, si la plataforma no soporta
/// preview (web, escritorio) o el permiso se deniega, degrada a la
/// cámara nativa vía image_picker. 1C (estado `_isProcessing`):
/// checklist de 5 pasos sincronizado con la llamada real al OCR,
/// barra de progreso y nota de seguridad anclada sobre la nav.
class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen>
    with WidgetsBindingObserver {
  static const Color _scanDark = Color(0xFF1A1A2E);

  final _picker = ImagePicker();
  final _expenseService = ExpenseService();

  CameraController? _cameraController;
  bool _cameraInitializing = true;

  bool _isProcessing = false;
  String? _errorMessage;

  /// Pasos del checklist de 1C: los primeros 4 avanzan con timers y el
  /// quinto se completa cuando la API responde.
  static const List<String> _processingSteps = [
    'Detectando monto',
    'Detectando fecha',
    'Detectando comercio',
    'Detectando categoría',
    'Finalizando análisis',
  ];

  /// Progreso mostrado según pasos completados (75% con 3 checks, como
  /// el mockup).
  static const List<double> _progressByStep = [
    0.0,
    0.25,
    0.5,
    0.75,
    0.85,
    1.0,
  ];

  int _completedSteps = 0;

  /// Token de sesión: cancelar o reiniciar el proceso invalida los
  /// timers y la respuesta en vuelo de la sesión anterior.
  int _processSession = 0;

  double get _progress => _progressByStep[_completedSteps.clamp(0, 5)];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  /// Libera la cámara cuando la app pasa a segundo plano (p. ej. al
  /// abrir la galería) y la re-inicializa al volver.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (state == AppLifecycleState.inactive) {
      if (controller != null) {
        _cameraController = null;
        controller.dispose();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_cameraController == null && !_isProcessing) {
        _initCamera();
      }
    }
  }

  /// Inicializa la cámara trasera para el preview en vivo. Si la
  /// plataforma no la soporta o el permiso se deniega, la pantalla
  /// degrada al marco ilustrado y el obturador usa la cámara nativa.
  Future<void> _initCamera() async {
    setState(() => _cameraInitializing = true);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('noCamera', 'Sin cámaras disponibles');
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _cameraInitializing = false;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraController = null;
        _cameraInitializing = false;
        if (e.code == 'CameraAccessDenied' ||
            e.code == 'CameraAccessDeniedWithoutPrompt') {
          _errorMessage =
              'Permiso de cámara denegado. Actívalo en los ajustes del '
              'teléfono o usa la galería.';
        }
      });
    } catch (_) {
      // Plataforma sin soporte de preview (web/escritorio): respaldo
      // silencioso, el obturador abre la cámara nativa.
      if (!mounted) return;
      setState(() {
        _cameraController = null;
        _cameraInitializing = false;
      });
    }
  }

  /// Obturador: captura desde el preview en vivo; sin preview activo
  /// recurre a la cámara nativa del sistema.
  Future<void> _capturePhoto() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      await _pickImage(ImageSource.camera);
      return;
    }
    if (controller.value.isTakingPicture) return;
    setState(() => _errorMessage = null);
    try {
      final XFile photo = await controller.takePicture();
      await _processReceipt(photo);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'No se pudo capturar la foto: ${e.description ?? e.code}';
      });
    }
  }

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
        _errorMessage =
            'Error al acceder a la cámara o galería: ${e.toString()}';
      });
    }
  }

  Future<void> _processReceipt(XFile file) async {
    final int session = ++_processSession;
    setState(() {
      _isProcessing = true;
      _completedSteps = 0;
      _errorMessage = null;
    });
    _advanceStepsWithTimers(session);

    try {
      // En web no existe acceso al filesystem, así que se envían los bytes.
      final bytes = await file.readAsBytes();

      // Call API (UNA sola llamada; el checklist avanza con timers)
      final Map<String, dynamic> result = await _expenseService.scanReceipt(
        bytes,
        filename: file.name,
        mimeType: file.mimeType,
      );

      if (!mounted || session != _processSession) return;

      await _completeRemainingSteps(session);
      if (!mounted || session != _processSession) return;

      // 1D: resultado del análisis con los campos extraídos editables.
      context.replace('/expenses/scan/result', extra: result);
    } catch (e) {
      if (!mounted || session != _processSession) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isProcessing = false;
      });
    }
  }

  /// Los primeros 4 pasos del checklist avanzan con timers (~850 ms
  /// c/u, progreso hasta 85%); el quinto queda girando hasta que la
  /// API responda.
  Future<void> _advanceStepsWithTimers(int session) async {
    for (var step = 1; step <= 4; step++) {
      await Future.delayed(const Duration(milliseconds: 850));
      if (!mounted || session != _processSession || !_isProcessing) return;
      if (_completedSteps < step) {
        setState(() => _completedSteps = step);
      }
    }
  }

  /// Si la API responde antes que los timers, completa los pasos
  /// restantes en cascada rápida y deja ver el 100% un instante antes
  /// de navegar.
  Future<void> _completeRemainingSteps(int session) async {
    while (_completedSteps < _processingSteps.length) {
      if (!mounted || session != _processSession) return;
      setState(() => _completedSteps++);
      await Future.delayed(const Duration(milliseconds: 140));
    }
    await Future.delayed(const Duration(milliseconds: 350));
  }

  /// Back/cancelar durante el proceso: invalida la sesión (la
  /// respuesta en vuelo se ignora) y regresa al vestíbulo 1B.
  void _cancelProcessing() {
    _processSession++;
    setState(() {
      _isProcessing = false;
      _completedSteps = 0;
    });
  }

  // Helper method to simulate a mock OCR scan (extremely useful for simulator/desktop tests)
  Future<void> _simulateMockScan() async {
    final int session = ++_processSession;
    setState(() {
      _errorMessage = null;
      _isProcessing = true;
      _completedSteps = 0;
    });
    _advanceStepsWithTimers(session);

    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted || session != _processSession) return;
    await _completeRemainingSteps(session);
    if (!mounted || session != _processSession) return;

    final mockResult = {
      'monto': 145.90,
      'fecha': DateTime.now().toIso8601String().split('T')[0],
      'categoria': 'comida',
      'descripcion': 'Consumo de restaurante (Parrillada Familiar)',
      'comercio': 'El Hornero',
    };

    context.replace('/expenses/scan/result', extra: mockResult);
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/expenses');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return _buildProcessingView();
    }
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return _buildVestibule(context, reduceMotion);
  }

  // ---------------------------------------------------------------------
  // 1B · Vestíbulo de cámara
  // ---------------------------------------------------------------------

  Widget _buildVestibule(BuildContext context, bool reduceMotion) {
    return Scaffold(
      backgroundColor: _scanDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          tooltip: 'Volver',
          onPressed: _goBack,
        ),
        // Long-press en el título: acceso discreto al escaneo simulado
        // (vital para demos sin backend de visión).
        title: GestureDetector(
          onLongPress: _simulateMockScan,
          child: Text(
            'Escanear boleta',
            style: AppTextStyles.heading3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              LucideIcons.helpCircle,
              color: Colors.white.withValues(alpha: 0.7),
              size: 22,
            ),
            tooltip: 'Tips de escaneo',
            onPressed: () => _showScanTips(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_errorMessage != null) _buildErrorBanner(),

            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 320,
                    maxHeight: 430,
                  ),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: _buildScanFrame(reduceMotion),
                  ),
                ),
              ).animate().fade(duration: 350.ms).scale(
                    begin: const Offset(0.94, 0.94),
                    end: const Offset(1, 1),
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),

            Text(
              (_cameraController?.value.isInitialized ?? false)
                  ? 'Centra la boleta dentro del marco'
                  : 'Toca el obturador para abrir la cámara',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13.5,
              ),
            ).animate().fade(delay: 150.ms, duration: 300.ms),

            const SizedBox(height: AppSpacing.lg),

            _buildControlsRow()
                .animate()
                .fade(delay: 200.ms, duration: 300.ms)
                .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  /// Marco de escaneo: preview de cámara en vivo recortado al marco,
  /// barrido láser y esquinas verdes con pulso suave (animaciones
  /// omitidas con reduced motion).
  Widget _buildScanFrame(bool reduceMotion) {
    Widget corners = const Positioned.fill(
      child: CustomPaint(
        painter: _ScanFramePainter(color: AppColors.primaryGreen),
      ),
    );
    if (!reduceMotion) {
      corners = Positioned.fill(
        child: const CustomPaint(
          painter: _ScanFramePainter(color: AppColors.primaryGreen),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .fade(
              begin: 0.55,
              end: 1.0,
              duration: 1500.ms,
              curve: Curves.easeInOut,
            ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: _buildFrameBackground(),
        ),
        if (!reduceMotion)
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: _buildLaserSweep(),
          ),
        corners,
      ],
    );
  }

  /// Interior del marco: preview en vivo si la cámara está lista,
  /// spinner mientras inicializa, o boleta de respaldo si no hay
  /// preview disponible (el obturador abre la cámara nativa).
  Widget _buildFrameBackground() {
    final controller = _cameraController;
    if (controller != null && controller.value.isInitialized) {
      final previewSize = controller.value.previewSize;
      if (previewSize == null) {
        return CameraPreview(controller);
      }
      // El sensor reporta el tamaño apaisado; se intercambia para
      // retrato y se recorta al marco 3:4 (efecto cover).
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(controller),
          ),
        ),
      );
    }
    if (_cameraInitializing) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primaryGreen,
          ),
        ),
      );
    }
    return Center(
      child: Icon(
        LucideIcons.receipt,
        color: Colors.white.withValues(alpha: 0.24),
        size: 90,
      ),
    );
  }

  Widget _buildLaserSweep() {
    return Container(
          height: 3,
          margin: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryGreen.withValues(alpha: 0),
                AppColors.primaryGreen,
                AppColors.primaryGreen.withValues(alpha: 0),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: 0.55),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .custom(
          duration: 2400.ms,
          curve: Curves.easeInOut,
          builder: (context, value, child) => Align(
            alignment: Alignment(0, -0.82 + 1.64 * value),
            child: child,
          ),
        );
  }

  /// Fila inferior: mock discreto · obturador 72dp · galería.
  Widget _buildControlsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Tooltip(
                message: 'Simular escaneo (demo)',
                child: _buildRoundAction(
                  icon: LucideIcons.cpu,
                  label: 'Simular escaneo de prueba',
                  size: 48,
                  backgroundAlpha: 0.06,
                  borderAlpha: 0.14,
                  iconColor: Colors.white.withValues(alpha: 0.55),
                  onTap: _simulateMockScan,
                ),
              ),
            ),
          ),
          _buildShutter(),
          Expanded(
            child: Center(
              child: _buildRoundAction(
                icon: LucideIcons.image,
                label: 'Seleccionar desde galería',
                size: 52,
                backgroundAlpha: 0.10,
                borderAlpha: 0.25,
                iconColor: Colors.white,
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShutter() {
    return Semantics(
      button: true,
      label: 'Tomar foto de la boleta',
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3.5),
        ),
        padding: const EdgeInsets.all(5),
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _capturePhoto,
            child: const Icon(
              LucideIcons.camera,
              color: _scanDark,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundAction({
    required IconData icon,
    required String label,
    required double size,
    required double backgroundAlpha,
    required double borderAlpha,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.white.withValues(alpha: backgroundAlpha),
        shape: CircleBorder(
          side: BorderSide(
            color: Colors.white.withValues(alpha: borderAlpha),
          ),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ),
      ),
    );
  }

  /// Banner inline de error de cámara/permiso con recuperación visible.
  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 4, AppSpacing.lg, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.expenseRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.expenseRed.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.alertCircle,
            color: AppColors.expenseRed,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTextStyles.bodySecondary.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            // Sin preview activo el reintento vuelve a inicializar la
            // cámara; con preview vivo reintenta la captura.
            onPressed: () {
              setState(() => _errorMessage = null);
              if (_cameraController == null) {
                _initCamera();
              } else {
                _capturePhoto();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text(
              'Reintentar',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 250.ms).slideY(begin: -0.2, end: 0);
  }

  void _showScanTips(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tips de escaneo',
                      style: AppTextStyles.heading2.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(context),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _ScanTip(
                  icon: LucideIcons.sun,
                  text:
                      'Busca buena iluminación y evita sombras o reflejos '
                      'sobre la boleta.',
                ),
                const SizedBox(height: 12),
                const _ScanTip(
                  icon: LucideIcons.maximize,
                  text: 'Encuadra la boleta completa dentro del marco verde.',
                ),
                const SizedBox(height: 12),
                const _ScanTip(
                  icon: LucideIcons.smartphone,
                  text:
                      'Mantén el teléfono firme para que el texto salga '
                      'nítido.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // 1C · Procesando boleta (mockup: ilustración + progreso + checklist
  // de 5 pasos + nota de seguridad anclada sobre la nav inferior)
  // ---------------------------------------------------------------------

  Widget _buildProcessingView() {
    return PopScope(
      canPop: false,
      // Back físico durante el proceso = cancelar y volver a 1B.
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _cancelProcessing();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: AppColors.backgroundWhite,
          bottomNavigationBar: const BottomNavBar(currentIndex: 1),
          body: SafeArea(
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: HeaderBackgroundPainter()),
                ),
                // Igual que 2B: la columna ocupa todo el alto disponible
                // y el Spacer ancla la nota de seguridad a 20px del nav.
                LayoutBuilder(
                  builder: (context, viewport) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: viewport.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.xl,
                              AppSpacing.lg,
                              20,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildProcessingTitleRow(),

                                const SizedBox(height: AppSpacing.xl),

                                Center(
                                  child:
                                      Image.asset(
                                            'assets/images/procesando_ia.png',
                                            width: 220,
                                            height: 175,
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const SizedBox(
                                                width: 220,
                                                height: 175,
                                                child: Icon(
                                                  LucideIcons.scanLine,
                                                  color:
                                                      AppColors.primaryGreen,
                                                  size: 72,
                                                ),
                                              );
                                            },
                                          )
                                          .animate()
                                          .scale(
                                            begin: const Offset(0.5, 0.5),
                                            end: const Offset(1, 1),
                                            duration: 700.ms,
                                            curve: Curves.elasticOut,
                                          )
                                          .fade(duration: 250.ms)
                                          .animate(
                                            onPlay: (controller) =>
                                                controller.repeat(reverse: true),
                                          )
                                          .moveY(
                                            begin: 0,
                                            end: -10,
                                            duration: 2000.ms,
                                            curve: Curves.easeInOut,
                                          ),
                                ),

                                const SizedBox(height: AppSpacing.md),

                                Text(
                                  'Analizando boleta...',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.heading2.copyWith(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ).animateEntrance(delay: 100.ms),

                                const SizedBox(height: AppSpacing.md),

                                _buildProgressBar()
                                    .animateEntrance(delay: 150.ms),

                                const SizedBox(height: AppSpacing.lg),

                                _buildStepsCard()
                                    .animateEntrance(delay: 200.ms),

                                const SizedBox(height: AppSpacing.lg),
                                const Spacer(),

                                _buildSecurityNote()
                                    .animateEntrance(delay: 250.ms),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingTitleRow() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            LucideIcons.chevronLeft,
            color: AppColors.textPrimary,
            size: 24,
          ),
          tooltip: 'Cancelar',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          onPressed: _cancelProcessing,
        ),
        Expanded(
          child: Text(
            'Procesando boleta',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading2.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // Equilibra el chevron para que el título quede centrado.
        const SizedBox(width: 40),
      ],
    );
  }

  /// Barra de progreso con porcentaje a la derecha; barra y número se
  /// animan juntos hacia el nuevo valor.
  Widget _buildProgressBar() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: _progress),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Row(
          children: [
            Expanded(
              child: Container(
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.dividerGray,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusRound),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusRound),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 40,
              child: Text(
                '${(value * 100).round()}%',
                textAlign: TextAlign.right,
                style: AppTextStyles.captionBold.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Tarjeta blanca con el checklist de 5 pasos (3 estados por fila).
  Widget _buildStepsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerGray, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < _processingSteps.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            _ProcessingStepTile(
              label: _processingSteps[i],
              state: i < _completedSteps
                  ? _StepState.done
                  : (i == _completedSteps
                      ? _StepState.active
                      : _StepState.pending),
            ),
          ],
        ],
      ),
    );
  }

  /// Nota de seguridad al pie (tarjeta primaryLight con candado).
  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentGreenBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.lock, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tus datos están seguros',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Solo tú puedes ver esta información.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Estados visuales de cada paso del checklist de procesamiento.
enum _StepState { done, active, pending }

/// Fila del checklist 1C: check verde con pop elástico, spinner en
/// curso o círculo gris pendiente.
class _ProcessingStepTile extends StatelessWidget {
  final String label;
  final _StepState state;

  const _ProcessingStepTile({required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final Widget indicator;
    switch (state) {
      case _StepState.done:
        indicator = Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.check, color: Colors.white, size: 14),
        ).animate(key: ValueKey('done-$label')).scale(
              begin: const Offset(0.4, 0.4),
              end: const Offset(1, 1),
              duration: 450.ms,
              curve: Curves.elasticOut,
            );
      case _StepState.active:
        indicator = const Padding(
          padding: EdgeInsets.all(2.5),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primaryGreen,
          ),
        );
      case _StepState.pending:
        indicator = Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.dividerGray, width: 2),
          ),
        );
    }

    final bool isPending = state == _StepState.pending;
    return Row(
      children: [
        SizedBox(width: 24, height: 24, child: Center(child: indicator)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: isPending ? FontWeight.w500 : FontWeight.w600,
              color: isPending
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Fila de tip del diálogo de ayuda (ícono en burbuja verde + texto).
class _ScanTip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ScanTip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryGreen, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              text,
              style: AppTextStyles.bodySecondary.copyWith(height: 1.35),
            ),
          ),
        ),
      ],
    );
  }
}

/// Cuatro esquinas redondeadas verdes del marco de escaneo.
class _ScanFramePainter extends CustomPainter {
  final Color color;

  const _ScanFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 4.0;
    const double inset = stroke / 2;
    const double corner = 34.0; // largo de cada brazo
    const double r = 22.0; // radio de la curva

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final double left = inset;
    final double top = inset;
    final double right = size.width - inset;
    final double bottom = size.height - inset;

    final topLeft = Path()
      ..moveTo(left, top + corner)
      ..lineTo(left, top + r)
      ..quadraticBezierTo(left, top, left + r, top)
      ..lineTo(left + corner, top);

    final topRight = Path()
      ..moveTo(right - corner, top)
      ..lineTo(right - r, top)
      ..quadraticBezierTo(right, top, right, top + r)
      ..lineTo(right, top + corner);

    final bottomRight = Path()
      ..moveTo(right, bottom - corner)
      ..lineTo(right, bottom - r)
      ..quadraticBezierTo(right, bottom, right - r, bottom)
      ..lineTo(right - corner, bottom);

    final bottomLeft = Path()
      ..moveTo(left + corner, bottom)
      ..lineTo(left + r, bottom)
      ..quadraticBezierTo(left, bottom, left, bottom - r)
      ..lineTo(left, bottom - corner);

    canvas.drawPath(topLeft, paint);
    canvas.drawPath(topRight, paint);
    canvas.drawPath(bottomRight, paint);
    canvas.drawPath(bottomLeft, paint);
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
