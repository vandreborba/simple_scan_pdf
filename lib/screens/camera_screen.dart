import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

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
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
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
        controller.dispose();
        return;
      }
      _controller = controller;

      if (widget.settings.autoDetect && controller.supportsImageStreaming()) {
        await controller.startImageStream(_onFrame);
      }
      setState(() {});
    } on CameraException catch (e) {
      setState(() => _error = e.description ?? e.code);
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    final corners = await _liveDetector.analyze(
      image,
      controller.description.sensorOrientation,
    );
    if (!mounted || _capturing) return;
    if (corners != null || _liveCorners != null) {
      setState(() => _liveCorners = corners);
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    setState(() => _capturing = true);

    try {
      final photo = await controller.takePicture();

      // Detecta o papel na foto em alta resolução.
      List<Offset> corners = DocumentDetector.fullImageCorners();
      if (widget.settings.autoDetect) {
        corners = await DocumentDetector.detectFromFile(photo.path);
      }
      if (!mounted) return;

      final page = ScanPage(
        originalPath: photo.path,
        corners: corners,
        filter: widget.settings.defaultFilter,
      );

      // Confirmação/ajuste do recorte.
      final confirmed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => CropScreen(page: page)),
      );
      if (confirmed != true) return;

      page.processedPath = await ImageProcessor.process(page);
      page.version++;
      widget.session.addPage(page);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao capturar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Escanear'),
        actions: [
          IconButton(
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
            tooltip: 'Lanterna',
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Não foi possível abrir a câmera.\n$_error',
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
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildControls(),
                  ],
                ),
    );
  }

  Widget _buildControls() {
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
                          'Concluir\n($count pág.)',
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
