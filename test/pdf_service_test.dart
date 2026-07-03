import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:simple_scan_pdf/models/scan_models.dart';
import 'package:simple_scan_pdf/services/document_detector.dart';
import 'package:simple_scan_pdf/services/pdf_service.dart';

void main() {
  test('gera PDF com múltiplas páginas e camada de texto OCR', () async {
    final dir = await Directory.systemTemp.createTemp('simple_scan_test');

    // Cria duas "páginas" JPEG sintéticas.
    final paths = <String>[];
    for (var i = 0; i < 2; i++) {
      final image = img.Image(width: 400, height: 600);
      img.fill(image, color: img.ColorRgb8(240, 240, 235));
      final path = '${dir.path}/page$i.jpg';
      await File(path).writeAsBytes(img.encodeJpg(image, quality: 80));
      paths.add(path);
    }

    final pages = [
      for (final p in paths)
        ScanPage(
          originalPath: p,
          corners: DocumentDetector.fullImageCorners(),
        )..processedPath = p,
    ];

    final ocr = {
      0: OcrPageResult(
        fullText: 'Olá mundo',
        lines: [
          OcrLine(
            text: 'Olá mundo',
            box: const Rect.fromLTWH(50, 100, 200, 30),
          ),
        ],
      ),
    };

    final file = await PdfService.build(
      outputPath: '${dir.path}/out.pdf',
      pages: pages,
      ocrResults: ocr,
      quality: PdfQuality.balanced,
    );

    expect(await file.exists(), isTrue);
    final bytes = await file.readAsBytes();
    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');

    await dir.delete(recursive: true);
  });
}
