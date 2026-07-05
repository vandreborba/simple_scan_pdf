import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';

/// Leitor simples de PDF: abre um arquivo local, permite navegar pelas
/// páginas e exportar (compartilhar/fazer cópia) o documento.
class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({super.key, required this.path});

  final String path;

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  bool _ready = false;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 0;

  String get _fileName {
    final segment = widget.path.split('/').last;
    return segment.isEmpty ? 'PDF' : segment;
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
          : Stack(
              children: [
                PDFView(
                  filePath: widget.path,
                  fitPolicy: FitPolicy.WIDTH,
                  onRender: (pages) => setState(() {
                    _ready = true;
                    _totalPages = pages ?? 0;
                  }),
                  onError: (error) => setState(() => _error = '$error'),
                  onPageError: (page, error) =>
                      setState(() => _error = '$error'),
                  onPageChanged: (page, total) => setState(() {
                    _currentPage = page ?? 0;
                    _totalPages = total ?? _totalPages;
                  }),
                ),
                if (!_ready)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
      bottomNavigationBar: (_ready && _error == null && _totalPages > 0)
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  l.pdfPageOf(_currentPage + 1, _totalPages),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            )
          : null,
    );
  }
}
