import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/enum_labels.dart';
import '../models/scan_models.dart';
import '../services/document_channel.dart';
import '../services/document_detector.dart';
import '../services/image_processor.dart';
import '../services/settings_service.dart';
import '../session.dart';
import 'camera_screen.dart';
import 'crop_screen.dart';
import 'export_sheet.dart';
import 'page_edit_screen.dart';

/// Revisão do documento: reordenar, editar e remover páginas, e exportar.
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({
    super.key,
    required this.session,
    required this.settings,
  });

  final ScanSession session;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.reviewDocument),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l.discardAll,
            onPressed: () => _confirmDiscard(context, l),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          if (session.isEmpty) {
            return Center(child: Text(l.noPagesCaptured));
          }
          return Column(
            children: [
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  itemCount: session.pages.length,
                  onReorder: session.reorder,
                  itemBuilder: (context, index) {
                    final page = session.pages[index];
                    final path = page.processedPath ?? page.originalPath;
                    return ListTile(
                      key: ValueKey(page.originalPath),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(path),
                          key: ValueKey('${page.originalPath}_${page.version}'),
                          width: 56,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(l.pageNumber(index + 1)),
                      subtitle: Text(l.filterWithName(page.filter.label(l))),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.tune),
                            tooltip: l.editPage,
                            onPressed: () => _editPage(context, index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: l.removePage,
                            onPressed: () => session.removePage(index),
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle),
                          ),
                        ],
                      ),
                      onTap: () => _editPage(context, index),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final hasPages = !session.isEmpty;
          return Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: Text(l.addPage),
                        onPressed: () => _showAddPageOptions(context, l),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: Text(l.exportPdf),
                        onPressed: hasPages
                            ? () => showExportSheet(
                                context,
                                session: session,
                                settings: settings,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Mostra as opções de origem para uma nova página: câmera ou galeria.
  Future<void> _showAddPageOptions(
    BuildContext context,
    AppLocalizations l,
  ) async {
    final source = await showModalBottomSheet<_PageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l.addFromCamera),
              onTap: () => Navigator.of(context).pop(_PageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.addFromGallery),
              onTap: () => Navigator.of(context).pop(_PageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    switch (source) {
      case _PageSource.camera:
        _openCamera(context);
      case _PageSource.gallery:
        await _importFromGallery(context, l);
    }
  }

  void _openCamera(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CameraScreen(session: session, settings: settings),
      ),
    );
  }

  /// Importa uma imagem da galeria e a faz passar pelo mesmo fluxo da câmera:
  /// detecção de bordas (se ligada) → recorte → processamento → documento.
  Future<void> _importFromGallery(
    BuildContext context,
    AppLocalizations l,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    String? path;
    try {
      path = await pickImageFromDevice();
    } catch (_) {
      path = null;
    }
    if (path == null) return; // usuário cancelou

    final page = ScanPage(
      originalPath: path,
      corners: DocumentDetector.fullImageCorners(),
      filter: settings.defaultFilter,
    );
    if (settings.autoDetect) {
      page.corners = await DocumentDetector.detectFromFile(
        path,
        sensitivity: settings.detectionSensitivity,
      );
    }
    if (!context.mounted) return;

    final confirmed = await navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) => CropScreen(
          page: page,
          posicaoLupa: settings.posicaoLupa,
        ),
      ),
    );
    if (confirmed != true) return;

    try {
      page.processedPath = await ImageProcessor.process(page);
      page.version++;
      session.addPage(page);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.processError('$e'))));
    }
  }

  void _editPage(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PageEditScreen(
          session: session,
          pageIndex: index,
          posicaoLupa: settings.posicaoLupa,
        ),
      ),
    );
  }

  Future<void> _confirmDiscard(BuildContext context, AppLocalizations l) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.discardTitle),
        content: Text(l.discardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.discard),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      session.clear();
      Navigator.of(context).pop();
    }
  }
}

/// Origem de uma nova página adicionada na revisão.
enum _PageSource { camera, gallery }
