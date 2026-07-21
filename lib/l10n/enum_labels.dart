import '../models/scan_models.dart';
import '../services/pdf_service.dart';
import 'app_localizations.dart';

/// Rótulos localizados dos filtros.
extension ScanFilterL10n on ScanFilter {
  String label(AppLocalizations l) => switch (this) {
        ScanFilter.original => l.filterOriginal,
        ScanFilter.document => l.filterDocument,
        ScanFilter.grayscale => l.filterGrayscale,
        ScanFilter.blackWhite => l.filterBlackWhite,
        ScanFilter.highContrast => l.filterHighContrast,
      };
}

/// Rótulos localizados da sensibilidade de detecção.
extension DetectionSensitivityL10n on DetectionSensitivity {
  String label(AppLocalizations l) => switch (this) {
        DetectionSensitivity.conservative => l.sensitivityConservative,
        DetectionSensitivity.balanced => l.sensitivityBalanced,
        DetectionSensitivity.sensitive => l.sensitivitySensitive,
      };
}

/// Rótulos localizados da posição da lupa.
extension PosicaoLupaL10n on PosicaoLupa {
  String label(AppLocalizations l) => switch (this) {
        PosicaoLupa.proximoAoDedo => l.loupeNearFinger,
        PosicaoLupa.cantoOposto => l.loupeOppositeCorner,
      };
}

/// Rótulos localizados das qualidades de PDF.
extension PdfQualityL10n on PdfQuality {
  String label(AppLocalizations l) => switch (this) {
        PdfQuality.economy => l.qualityEconomy,
        PdfQuality.balanced => l.qualityBalanced,
        PdfQuality.high => l.qualityHigh,
      };
}
