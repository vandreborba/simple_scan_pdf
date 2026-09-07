import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';

/// Leitor simples de PDF: abre um arquivo local, exibe as páginas em rolagem
/// contínua (empilhadas num único canvas, sem pular de página ao rolar) com
/// zoom nítido no rodapé e permite exportar (compartilhar/fazer cópia) o
/// documento.
class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({super.key, required this.path});

  final String path;

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  PdfDocument? _document;
  PdfControllerPinch? _controller;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 0;

  String get _fileName {
    final segment = widget.path.split('/').last;
    return segment.isEmpty ? 'PDF' : segment;
  }

  Future<void> _loadDocument() async {
    try {
      final document = await PdfDocument.openFile(widget.path);
      if (!mounted) return;
      setState(() {
        _document = document;
        _totalPages = document.pagesCount;
        _controller = PdfControllerPinch(document: Future.value(document));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _document?.close();
    super.dispose();
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(widget.path)]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_fileName, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: l.share,
            onPressed: _error == null ? _share : null,
          ),
        ],
      ),
      body: _error != null
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  l.openDocError(_error!),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _controller == null
              ? const Center(child: CircularProgressIndicator())
              : PdfViewPinch(
                  controller: _controller!,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                    options: const DefaultBuilderOptions(),
                    documentLoaderBuilder: (_) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
      bottomNavigationBar:
          (_controller != null && _error == null && _totalPages > 0)
              ? SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      l.pdfPageOf(_currentPage, _totalPages),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                )
              : null,
    );
  }
}
