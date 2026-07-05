import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/scan_models.dart';
import '../services/document_detector.dart';
import '../widgets/corner_editor.dart';

/// Ajuste do recorte: mostra a detecção automática, permite arrastar os
/// quatro cantos e girar a página. Retorna true (pop) ao confirmar.
class CropScreen extends StatefulWidget {
  const CropScreen({super.key, required this.page});

  final ScanPage page;

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  double? _aspectRatio;
  bool _detecting = false;

  int get _turns => widget.page.quarterTurns % 4;

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

  void _rotate() {
    setState(() =>
        widget.page.quarterTurns = (widget.page.quarterTurns + 1) % 4);
  }

  // Converte um ponto do espaço da imagem original para o espaço exibido
  // (imagem girada [_turns] quartos de volta no sentido horário).
  Offset _toDisplay(Offset p) {
    switch (_turns) {
      case 1:
        return Offset(1 - p.dy, p.dx);
      case 2:
        return Offset(1 - p.dx, 1 - p.dy);
      case 3:
        return Offset(p.dy, 1 - p.dx);
      default:
        return p;
    }
  }

  // Inverso de [_toDisplay]: do espaço exibido de volta para o original.
  Offset _toOriginal(Offset p) {
    switch (_turns) {
      case 1:
        return Offset(p.dy, 1 - p.dx);
      case 2:
        return Offset(1 - p.dx, 1 - p.dy);
      case 3:
        return Offset(1 - p.dy, p.dx);
      default:
        return p;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final baseAspect = _aspectRatio;
    final displayAspect = baseAspect == null
        ? null
        : (_turns.isOdd ? 1 / baseAspect : baseAspect);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l.adjustCrop),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
            tooltip: l.rotate,
            onPressed: _rotate,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: displayAspect == null
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: AspectRatio(
                        aspectRatio: displayAspect,
                        child: CornerEditor(
                          corners: widget.page.corners.map(_toDisplay).toList(),
                          onChanged: (corners) => setState(() => widget
                              .page.corners = corners.map(_toOriginal).toList()),
                          child: RotatedBox(
                            quarterTurns: _turns,
                            child: Image.file(
                              File(widget.page.originalPath),
                              fit: BoxFit.fill,
                            ),
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
                  label: Text(
                    l.detect,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => widget.page.corners =
                      DocumentDetector.fullImageCorners()),
                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                  label: Text(
                    l.all,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.check),
                  label: Text(l.use),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
