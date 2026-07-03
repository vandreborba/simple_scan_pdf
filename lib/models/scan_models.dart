import 'dart:ui';

/// Filtros disponíveis por página.
enum ScanFilter {
  original('Original'),
  document('Documento'),
  grayscale('Cinza'),
  blackWhite('P&B'),
  highContrast('Contraste');

  const ScanFilter(this.label);
  final String label;
}

/// Uma página capturada dentro do documento em andamento.
class ScanPage {
  ScanPage({
    required this.originalPath,
    required this.corners,
    this.filter = ScanFilter.document,
    this.quarterTurns = 0,
  });

  /// Foto original tirada pela câmera.
  final String originalPath;

  /// Cantos normalizados (0..1) na ordem TL, TR, BR, BL.
  List<Offset> corners;

  ScanFilter filter;

  /// Rotações de 90° aplicadas após o recorte (0..3).
  int quarterTurns;

  /// Imagem processada (recortada + filtro), pronta para o PDF.
  String? processedPath;

  /// Incrementado a cada reprocessamento para invalidar cache de imagem.
  int version = 0;

  bool get isProcessed => processedPath != null;
}

/// Linha de texto reconhecida pelo OCR com posição na imagem processada.
class OcrLine {
  OcrLine({required this.text, required this.box});

  final String text;
  final Rect box;
}

/// Resultado do OCR de uma página.
class OcrPageResult {
  OcrPageResult({required this.lines, required this.fullText});

  final List<OcrLine> lines;
  final String fullText;
}
