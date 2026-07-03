import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/scan_models.dart';

/// OCR local (on-device) usando ML Kit.
class OcrService {
  static Future<OcrPageResult> recognizeFile(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(imagePath);
      final recognized = await recognizer.processImage(input);
      final lines = <OcrLine>[
        for (final block in recognized.blocks)
          for (final line in block.lines)
            OcrLine(text: line.text, box: line.boundingBox),
      ];
      return OcrPageResult(lines: lines, fullText: recognized.text);
    } finally {
      await recognizer.close();
    }
  }
}
