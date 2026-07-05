import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../l10n/enum_labels.dart';
import '../models/scan_models.dart';
import '../services/ocr_service.dart';
import '../services/pdf_service.dart';
import '../services/settings_service.dart';
import '../session.dart';

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
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _working = true;
      _status = l.preparing;
    });

    try {
      final pages = widget.session.pages;
      final ocrResults = <int, OcrPageResult>{};

      if (_ocr) {
        for (var i = 0; i < pages.length; i++) {
          setState(() => _status = l.ocrProgress(i + 1, pages.length));
          final path = pages[i].processedPath ?? pages[i].originalPath;
          ocrResults[i] = await OcrService.recognizeFile(path);
        }
      }

      setState(() => _status = l.generatingPdf);
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
      // Fecha a folha de opções e abre o compartilhamento do sistema direto,
      // sem folha intermediária.
      Navigator.of(context).pop();
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)]),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _working = false;
          _status = '';
        });
        messenger.showSnackBar(
          SnackBar(content: Text(l.exportError('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
            l.exportPdf,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            enabled: !_working,
            decoration: InputDecoration(
              labelText: l.fileName,
              suffixText: '.pdf',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<PdfQuality>(
            initialValue: _quality,
            decoration: InputDecoration(
              labelText: l.quality,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final q in PdfQuality.values)
                DropdownMenuItem(value: q, child: Text(q.label(l))),
            ],
            onChanged: _working
                ? null
                : (q) => setState(() => _quality = q ?? _quality),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.ocrSwitchTitle),
            subtitle: Text(l.ocrSwitchSubtitle),
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
              label: Text(l.generatePdf),
              onPressed: _export,
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
