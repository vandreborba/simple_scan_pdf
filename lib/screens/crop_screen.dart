import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/scan_models.dart';
import '../services/document_detector.dart';
import '../widgets/corner_editor.dart';

/// Ajuste do recorte: mostra a detecção automática e permite arrastar
/// os quatro cantos. Retorna true (pop) quando o usuário confirma.
class CropScreen extends StatefulWidget {
  const CropScreen({super.key, required this.page});

  final ScanPage page;

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  double? _aspectRatio;
  bool _detecting = false;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    final bytes = await File(widget.page.originalPath).readAsBytes();
    final ui.Image image = await decodeImageFromList(bytes);
    if (mounted) {
      setState(() => _aspectRatio = image.width / image.height);
    }
    image.dispose();
  }

  Future<void> _redetect() async {
    setState(() => _detecting = true);
    final corners =
        await DocumentDetector.detectFromFile(widget.page.originalPath);
    if (mounted) {
      setState(() {
        widget.page.corners = corners;
        _detecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Ajustar recorte'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _aspectRatio == null
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: AspectRatio(
                        aspectRatio: _aspectRatio!,
                        child: CornerEditor(
                          corners: widget.page.corners,
                          onChanged: (corners) =>
                              setState(() => widget.page.corners = corners),
                          child: Image.file(
                            File(widget.page.originalPath),
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: _detecting ? null : _redetect,
                  icon: const Icon(Icons.center_focus_strong,
                      color: Colors.white),
                  label: const Text(
                    'Detectar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => widget.page.corners =
                      DocumentDetector.fullImageCorners()),
                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                  label: const Text(
                    'Tudo',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.check),
                  label: const Text('Usar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
