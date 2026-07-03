import 'dart:io';

import 'package:flutter/foundation.dart';

import 'models/scan_models.dart';

/// Documento em andamento: as páginas capturadas antes da exportação.
class ScanSession extends ChangeNotifier {
  final List<ScanPage> pages = [];

  bool get isEmpty => pages.isEmpty;

  void addPage(ScanPage page) {
    pages.add(page);
    notifyListeners();
  }

  void removePage(int index) {
    final page = pages.removeAt(index);
    _deleteFiles(page);
    notifyListeners();
  }

  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final page = pages.removeAt(oldIndex);
    pages.insert(newIndex, page);
    notifyListeners();
  }

  void pageUpdated() => notifyListeners();

  void clear() {
    for (final page in pages) {
      _deleteFiles(page);
    }
    pages.clear();
    notifyListeners();
  }

  void _deleteFiles(ScanPage page) {
    for (final path in [page.originalPath, page.processedPath]) {
      if (path == null) continue;
      final f = File(path);
      f.exists().then((ok) {
        if (ok) f.delete();
      });
    }
  }
}
