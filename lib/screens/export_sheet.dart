import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/scan_models.dart';
import '../services/ocr_service.dart';
import '../services/pdf_service.dart';
import '../services/settings_service.dart';
import '../session.dart';
import 'ocr_text_screen.dart';

/// Abre a folha de exportação: nome do arquivo, qualidade e OCR,
/// tudo já preenchido com os padrões do usuário.
Future<void> showExportSheet(
  BuildContext context, {
  required ScanSession session,
  required AppSettings settings,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ExportSheet(session: session, settings: settings),
  );
}

class _ExportSheet extends StatefulWidget {
  const _ExportSheet({required this.session, required this.settings});

  final ScanSession session;
  final AppSettings settings;

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  late final TextEditingController _nameController;
  late PdfQuality _quality;
  late bool _ocr;

  bool _working = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.settings.defaultFileName());
    _quality = widget.settings.pdfQuality;
    _ocr = widget.settings.ocrEnabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    setState(() {
      _working = true;
      _status = 'Preparando…';
    });

    try {
      final pages = widget.session.pages;
      final ocrResults = <int, OcrPageResult>{};

      if (_ocr) {
        for (var i = 0; i < pages.length; i++) {
          setState(
              () => _status = 'OCR da página ${i + 1} de ${pages.length}…');
          final path = pages[i].processedPath ?? pages[i].originalPath;
          ocrResults[i] = await OcrService.recognizeFile(path);
        }
      }

      setState(() => _status = 'Gerando PDF…');
      final dir = await getApplicationDocumentsDirectory();
      final name = _nameController.text.trim().isEmpty
          ? widget.settings.defaultFileName()
          : _nameController.text.trim();
      final safeName = name.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
      final file = await PdfService.build(
        outputPath: '${dir.path}/$safeName.pdf',
        pages: pages,
        ocrResults: ocrResults,
        quality: _quality,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      await _showResult(file.path, safeName, ocrResults);
    } catch (e) {
      if (mounted) {
        setState(() {
          _working = false;
          _status = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar: $e')),
        );
      }
    }
  }

  Future<void> _showResult(
    String pdfPath,
    String name,
    Map<int, OcrPageResult> ocrResults,
  ) async {
    final fullText = ocrResults.entries
        .map((e) => e.value.fullText.trim())
        .where((t) => t.isNotEmpty)
        .join('\n\n');

    final navigator = Navigator.of(context, rootNavigator: true);
    await showModalBottomSheet(
      context: navigator.context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'PDF gerado: $name.pdf',
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Compartilhar'),
                onPressed: () => SharePlus.instance.share(
                  ShareParams(files: [XFile(pdfPath)]),
                ),
              ),
              if (fullText.isNotEmpty) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.text_snippet_outlined),
                  label: const Text('Ver texto reconhecido (OCR)'),
                  onPressed: () => Navigator.of(sheetContext).push(
                    MaterialPageRoute(
                      builder: (_) => OcrTextScreen(text: fullText),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Exportar PDF',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            enabled: !_working,
            decoration: const InputDecoration(
              labelText: 'Nome do arquivo',
              suffixText: '.pdf',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<PdfQuality>(
            initialValue: _quality,
            decoration: const InputDecoration(
              labelText: 'Qualidade',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final q in PdfQuality.values)
                DropdownMenuItem(value: q, child: Text(q.label)),
            ],
            onChanged: _working
                ? null
                : (q) => setState(() => _quality = q ?? _quality),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('OCR (texto pesquisável)'),
            subtitle: const Text('Reconhecimento local, no aparelho'),
            value: _ocr,
            onChanged: _working ? null : (v) => setState(() => _ocr = v),
          ),
          const SizedBox(height: 8),
          if (_working) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 8),
          ] else
            FilledButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Gerar PDF'),
              onPressed: _export,
            ),
        ],
      ),
    );
  }
}
