import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';

import '../models/scan_models.dart';

/// Qualidade de exportação do PDF (largura da página em pontos).
/// Os rótulos ficam em [PdfQualityL10n].
enum PdfQuality {
  economy(420),
  balanced(595),
  high(842);

  const PdfQuality(this.pageWidth);
  final double pageWidth;
}

/// Gera o PDF final com as imagens processadas e, quando disponível,
/// uma camada de texto OCR invisível para busca e cópia.
class PdfService {
  static Future<File> build({
    required String outputPath,
    required List<ScanPage> pages,
    required Map<int, OcrPageResult> ocrResults,
    PdfQuality quality = PdfQuality.balanced,
  }) async {
    final doc = PdfDocument();
    PdfInfo(doc, title: 'Simple Scan PDF', creator: 'Simple Scan PDF');
    final font = PdfFont.helvetica(doc);

    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      final path = page.processedPath ?? page.originalPath;
      final jpegBytes = Uint8List.fromList(await File(path).readAsBytes());

      final image = PdfImage.jpeg(doc, image: jpegBytes);
      final imgW = image.width.toDouble();
      final imgH = image.height.toDouble();

      final pageW = quality.pageWidth;
      final pageH = pageW * imgH / imgW;
      final pdfPage = PdfPage(doc, pageFormat: PdfPageFormat(pageW, pageH));
      final g = pdfPage.getGraphics();

      g.drawImage(image, 0, 0, pageW, pageH);

      final ocr = ocrResults[i];
      if (ocr != null) {
        _drawInvisibleText(g, font, ocr, imgW, imgH, pageW, pageH);
      }
    }

    final bytes = await doc.save();
    final file = File(outputPath);
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Desenha o texto OCR em modo invisível, alinhado às posições da imagem,
  /// tornando o PDF pesquisável e com texto copiável.
  static void _drawInvisibleText(
    PdfGraphics g,
    PdfFont font,
    OcrPageResult ocr,
    double imgW,
    double imgH,
    double pageW,
    double pageH,
  ) {
    final sx = pageW / imgW;
    final sy = pageH / imgH;

    for (final line in ocr.lines) {
      // A fonte Type1 usa latin1; troca caracteres fora dela para não
      // quebrar a camada invisível.
      final text = line.text
          .trim()
          .replaceAll(RegExp(r'[^\x00-\xFF]'), '?');
      if (text.isEmpty) continue;

      final boxH = line.box.height * sy;
      final boxW = line.box.width * sx;
      if (boxH <= 1 || boxW <= 1) continue;

      final fontSize = boxH * 0.9;
      final metrics = font.stringMetrics(text);
      final naturalW = metrics.advanceWidth * fontSize;
      // Estica/encolhe horizontalmente para casar com a largura real da linha.
      final hScale = naturalW > 0 ? (boxW / naturalW).clamp(0.2, 5.0) : 1.0;

      final x = line.box.left * sx;
      // PDF usa origem no canto inferior esquerdo.
      final y = pageH - (line.box.bottom * sy) + boxH * 0.18;

      g.drawString(
        font,
        fontSize,
        text,
        x,
        y,
        scale: hScale.toDouble(),
        mode: PdfTextRenderingMode.invisible,
      );
    }
  }
}
