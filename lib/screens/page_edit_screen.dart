import 'dart:io';

import 'package:flutter/material.dart';

import '../models/scan_models.dart';
import '../services/image_processor.dart';
import '../session.dart';
import 'crop_screen.dart';

/// Edição de uma página: filtro, rotação e novo recorte.
class PageEditScreen extends StatefulWidget {
  const PageEditScreen({
    super.key,
    required this.session,
    required this.pageIndex,
  });

  final ScanSession session;
  final int pageIndex;

  @override
  State<PageEditScreen> createState() => _PageEditScreenState();
}

class _PageEditScreenState extends State<PageEditScreen> {
  bool _processing = false;

  ScanPage get page => widget.session.pages[widget.pageIndex];

  Future<void> _reprocess() async {
    setState(() => _processing = true);
    try {
      final oldPath = page.processedPath;
      page.processedPath = await ImageProcessor.process(page);
      page.version++;
      if (oldPath != null) {
        final f = File(oldPath);
        if (await f.exists()) await f.delete();
      }
      widget.session.pageUpdated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _changeFilter(ScanFilter filter) async {
    if (page.filter == filter) return;
    page.filter = filter;
    await _reprocess();
  }

  Future<void> _rotate() async {
    page.quarterTurns = (page.quarterTurns + 1) % 4;
    await _reprocess();
  }

  Future<void> _recrop() async {
    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CropScreen(page: page)),
    );
    if (confirmed == true) {
      await _reprocess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = page.processedPath ?? page.originalPath;
    return Scaffold(
      appBar: AppBar(
        title: Text('Página ${widget.pageIndex + 1}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.crop),
            tooltip: 'Ajustar recorte',
            onPressed: _processing ? null : _recrop,
          ),
          IconButton(
            icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
            tooltip: 'Girar',
            onPressed: _processing ? null : _rotate,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _processing
                  ? const CircularProgressIndicator()
                  : InteractiveViewer(
                      maxScale: 5,
                      child: Image.file(
                        File(path),
                        key: ValueKey('${page.originalPath}_${page.version}'),
                      ),
                    ),
            ),
          ),
          SafeArea(
            child: SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final filter in ScanFilter.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      child: ChoiceChip(
                        label: Text(filter.label),
                        selected: page.filter == filter,
                        onSelected: _processing
                            ? null
                            : (_) => _changeFilter(filter),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
