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

  bool get ocrEnabled => _prefs.getBool('ocrEnabled') ?? true;
  set ocrEnabled(bool v) => _prefs.setBool('ocrEnabled', v);

  ScanFilter get defaultFilter {
    final name = _prefs.getString('defaultFilter');
    return ScanFilter.values.firstWhere(
      (f) => f.name == name,
      orElse: () => ScanFilter.document,
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
