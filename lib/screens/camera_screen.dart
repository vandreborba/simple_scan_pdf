import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/scan_models.dart';
import '../services/document_detector.dart';
import '../services/image_processor.dart';
import '../services/live_detector.dart';
import '../services/settings_service.dart';
import '../session.dart';
import '../widgets/quad_painter.dart';
import 'crop_screen.dart';
import 'review_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
    required this.session,
    required this.settings,
  });

  final ScanSession session;
  final AppSettings settings;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  final _liveDetector = LiveDetector();
  List<Offset>? _liveCorners;
  bool _capturing = false;
  bool _flashOn = false;
  bool _inicializando = false;
  String? _error;

  // Suavização (EMA) do contorno ao vivo: menor = mais suave e menos tremido.
  static const _smoothingFactor = 0.35;
  // Disparo automático: dispara quando o documento fica estável por alguns
  // ciclos de análise (a detecção ao vivo roda ~a cada 250 ms).
  static const _autoStableThreshold = 0.045; // movimento tolerado por canto (0..1)
  static const _autoStableFrames = 4; // ciclos estáveis exigidos (~1 s)
  List<Offset>? _prevCorners;
  int _stableCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      // Evita callbacks do stream após dispose do State.
      final future = controller.value.isStreamingImages
          ? controller.stopImageStream().whenComplete(controller.dispose)
          : controller.dispose();
      future.ignore();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_inicializando || _capturing) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller = null;
      controller.dispose();
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_inicializando) return;
    _inicializando = true;
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _controller = controller;

      final wantsStream =
          widget.settings.autoDetect || widget.settings.autoCapture;
      if (wantsStream && controller.supportsImageStreaming()) {
        await controller.startImageStream(_onFrame);
      }
      setState(() {});
    } on CameraException catch (e) {
      if (mounted) setState(() => _error = e.description ?? e.code);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      _inicializando = false;
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    final result = await _liveDetector.analyze(
      image,
      controller.description.sensorOrientation,
      sensitivity: widget.settings.detectionSensitivity,
    );
    if (!mounted || _capturing) return;

    // null = frame descartado (throttle/ocupado): mantém o overlay como está,
    // evitando o piscar. Lista vazia = analisou e não achou documento.
    if (result == null) return;
    final raw = result.isEmpty ? null : result;

    final smoothed = _smoothCorners(raw);
    if (smoothed != null || _liveCorners != null) {
      setState(() => _liveCorners = smoothed);
    }
    if (widget.settings.autoCapture) {
      _evaluateAutoCapture(smoothed);
    }
  }

  /// Suaviza o contorno com média exponencial (EMA) em relação ao anterior,
  /// para o overlay deslizar em vez de pular a cada detecção.
  List<Offset>? _smoothCorners(List<Offset>? target) {
    if (target == null) return null;
    final prev = _liveCorners;
    if (prev == null || prev.length != target.length) return target;
    return [
      for (var i = 0; i < target.length; i++)
        Offset.lerp(prev[i], target[i], _smoothingFactor)!,
    ];
  }

  /// Acompanha a estabilidade do documento detectado e dispara a captura
  /// automática quando ele fica parado por [_autoStableFrames] frames.
  void _evaluateAutoCapture(List<Offset>? corners) {
    if (corners == null) {
      _prevCorners = null;
      if (_stableCount != 0) setState(() => _stableCount = 0);
      return;
    }
    final prev = _prevCorners;
    _prevCorners = corners;
    final moved = prev == null ? double.infinity : _maxCornerDelta(prev, corners);
    // Parado acumula; mexeu recua devagar (não zera), tolerando tremidos.
    final next = moved < _autoStableThreshold
        ? _stableCount + 1
        : math.max(0, _stableCount - 1);
    if (next != _stableCount) setState(() => _stableCount = next);

    if (next >= _autoStableFrames) {
      _stableCount = 0;
      _prevCorners = null;
      // Clique discreto do sistema para sinalizar o disparo automático.
      SystemSound.play(SystemSoundType.click);
      _capture();
    }
  }

  /// Maior deslocamento entre cantos correspondentes (espaço normalizado).
  double _maxCornerDelta(List<Offset> a, List<Offset> b) {
    var max = 0.0;
    final n = math.min(a.length, b.length);
    for (var i = 0; i < n; i++) {
      max = math.max(max, (a[i] - b[i]).distance);
    }
    return max;
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    final l = AppLocalizations.of(context);
    _stableCount = 0;
    _prevCorners = null;
    setState(() => _capturing = true);

    final estavaEmStream = controller.value.isStreamingImages;
    try {
      // takePicture + ImageAnalysis juntos no CameraX costuma abandonar
      // buffers; para o stream antes de capturar.
      if (estavaEmStream) {
        await controller.stopImageStream();
      }

      final photo = await controller.takePicture();

      // Detecta o papel na foto em alta resolução.
      List<Offset> corners = DocumentDetector.fullImageCorners();
      if (widget.settings.autoDetect) {
        corners = await DocumentDetector.detectFromFile(
          photo.path,
          sensitivity: widget.settings.detectionSensitivity,
        );
      }
      if (!mounted) return;

      final page = ScanPage(
        originalPath: photo.path,
        corners: corners,
        filter: widget.settings.defaultFilter,
      );

      // Confirmação/ajuste do recorte (com a detecção já aplicada).
      final confirmed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => CropScreen(page: page)),
      );
      if (confirmed != true) {
        await _retomarStreamSePreciso(controller, estavaEmStream);
        return;
      }

      page.processedPath = await ImageProcessor.process(page);
      page.version++;
      widget.session.addPage(page);

      // Por padrão, após confirmar vai para a revisão do documento.
      // A captura contínua (permanecer na câmera) é opcional.
      if (mounted && widget.settings.reviewAfterEachPage) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ReviewScreen(
              session: widget.session,
              settings: widget.settings,
            ),
          ),
        );
        return;
      }

      await _retomarStreamSePreciso(controller, estavaEmStream);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.captureError('$e'))),
        );
        await _retomarStreamSePreciso(controller, estavaEmStream);
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _retomarStreamSePreciso(
    CameraController controller,
    bool estavaEmStream,
  ) async {
    if (!mounted || _controller != controller) return;
    if (!estavaEmStream || controller.value.isStreamingImages) return;
    try {
      await controller.startImageStream(_onFrame);
    } catch (_) {}
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null) return;
    _flashOn = !_flashOn;
    await controller.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    if (mounted) setState(() {});
  }

  void _finish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReviewScreen(
          session: widget.session,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l.scan),
        actions: [
          IconButton(
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
            tooltip: l.flashlight,
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l.cameraError(_error!),
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : controller == null || !controller.value.isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1 / controller.value.aspectRatio,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CameraPreview(controller),
                              CustomPaint(
                                painter: QuadPainter(
                                  corners: _liveCorners,
                                  color: Colors.greenAccent,
                                ),
                              ),
                              if (widget.settings.autoCapture &&
                                  _liveCorners != null &&
                                  _stableCount > 0 &&
                                  !_capturing)
                                Positioned(
                                  top: 16,
                                  left: 0,
                                  right: 0,
                                  child: Center(child: _autoCaptureHint(l)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildControls(l),
                    const SizedBox(height: 32),
                  ],
                ),
    );
  }

  Widget _autoCaptureHint(AppLocalizations l) {
    final progress = (_stableCount / _autoStableFrames).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              color: Colors.greenAccent,
              backgroundColor: Colors.white24,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            l.autoCaptureHint,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(AppLocalizations l) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: ListenableBuilder(
        listenable: widget.session,
        builder: (context, _) {
          final count = widget.session.pages.length;
          return Row(
            children: [
              SizedBox(
                width: 88,
                child: count > 0
                    ? TextButton(
                        onPressed: _finish,
                        child: Text(
                          l.finishWithCount(count),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _capture,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: _capturing
                          ? const Padding(
                              padding: EdgeInsets.all(18),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Container(
                              margin: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 88),
            ],
          );
        },
      ),
    );
  }
}
