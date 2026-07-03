import 'dart:io';

import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../session.dart';
import 'camera_screen.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisar documento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined),
            tooltip: 'Adicionar página',
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => CameraScreen(
                  session: session,
                  settings: settings,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Descartar tudo',
            onPressed: () => _confirmDiscard(context),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          if (session.isEmpty) {
            return const Center(child: Text('Nenhuma página capturada.'));
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: session.pages.length,
            onReorder: session.reorder,
            itemBuilder: (context, index) {
              final page = session.pages[index];
              final path = page.processedPath ?? page.originalPath;
              return ListTile(
                key: ValueKey(page.originalPath),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                title: Text('Página ${index + 1}'),
                subtitle: Text('Filtro: ${page.filter.label}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.tune),
                      tooltip: 'Editar página',
                      onPressed: () => _editPage(context, index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Remover página',
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
          );
        },
      ),
      floatingActionButton: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          if (session.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Exportar PDF'),
            onPressed: () => showExportSheet(
              context,
              session: session,
              settings: settings,
            ),
          );
        },
      ),
    );
  }

  void _editPage(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PageEditScreen(session: session, pageIndex: index),
      ),
    );
  }

  Future<void> _confirmDiscard(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar documento?'),
        content: const Text('Todas as páginas capturadas serão removidas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Descartar'),
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
