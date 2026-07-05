import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/scan_models.dart';
import 'pdf_service.dart';

/// Preferências do usuário. Tudo tem padrão sensato: quem não quiser
/// configurar nada usa o app direto.
class AppSettings {
  AppSettings._(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppSettings> load() async =>
      AppSettings._(await SharedPreferences.getInstance());

  bool get autoDetect => _prefs.getBool('autoDetect') ?? true;
  set autoDetect(bool v) => _prefs.setBool('autoDetect', v);

  /// Sensibilidade da detecção automática de bordas.
  DetectionSensitivity get detectionSensitivity {
    final name = _prefs.getString('detectionSensitivity');
    return DetectionSensitivity.values.firstWhere(
      (s) => s.name == name,
      orElse: () => DetectionSensitivity.balanced,
    );
  }

  set detectionSensitivity(DetectionSensitivity s) =>
      _prefs.setString('detectionSensitivity', s.name);

  /// Se true, dispara a foto sozinho quando o documento fica estável no
  /// preview. Depende da detecção automática estar ligada.
  bool get autoCapture => _prefs.getBool('autoCapture') ?? true;
  set autoCapture(bool v) => _prefs.setBool('autoCapture', v);

  bool get ocrEnabled => _prefs.getBool('ocrEnabled') ?? true;
  set ocrEnabled(bool v) => _prefs.setBool('ocrEnabled', v);

  /// Se true (padrão), ao confirmar uma página vai direto para a revisão do
  /// documento. Se false, continua na câmera para capturar várias em sequência.
  bool get reviewAfterEachPage => _prefs.getBool('reviewAfterEachPage') ?? true;
  set reviewAfterEachPage(bool v) => _prefs.setBool('reviewAfterEachPage', v);

  /// Locale escolhido pelo usuário, ou null para seguir o sistema.
  Locale? get locale {
    final code = _prefs.getString('locale');
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  set locale(Locale? value) {
    if (value == null) {
      _prefs.remove('locale');
    } else {
      _prefs.setString('locale', value.languageCode);
    }
  }

  ScanFilter get defaultFilter {
    final name = _prefs.getString('defaultFilter');
    return ScanFilter.values.firstWhere(
      (f) => f.name == name,
      orElse: () => ScanFilter.original,
    );
  }

  set defaultFilter(ScanFilter f) => _prefs.setString('defaultFilter', f.name);

  PdfQuality get pdfQuality {
    final name = _prefs.getString('pdfQuality');
    return PdfQuality.values.firstWhere(
      (q) => q.name == name,
      orElse: () => PdfQuality.balanced,
    );
  }

  set pdfQuality(PdfQuality q) => _prefs.setString('pdfQuality', q.name);

  /// Nome padrão do arquivo baseado em data/hora.
  String defaultFileName() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'Scan_${now.year}-${two(now.month)}-${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }
}
