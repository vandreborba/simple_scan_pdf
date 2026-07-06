// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Simple Scan PDF';

  @override
  String get homeTagline =>
      'Escaneie documentos e gere PDFs\ncom texto pesquisável';

  @override
  String get homeSubtitle =>
      'Tudo é processado no seu aparelho.\nSem conta, sem nuvem, sem propaganda.';

  @override
  String get scan => 'Escanear';

  @override
  String get openDocument => 'Abrir documento';

  @override
  String openDocError(String error) {
    return 'Não foi possível abrir o documento.\n$error';
  }

  @override
  String get emptyDocument => 'Este documento não tem texto legível.';

  @override
  String pdfPageOf(int current, int total) {
    return 'Página $current de $total';
  }

  @override
  String get settings => 'Configurações';

  @override
  String continueDocument(int count) {
    return 'Continuar documento ($count pág.)';
  }

  @override
  String get flashlight => 'Lanterna';

  @override
  String cameraError(String error) {
    return 'Não foi possível abrir a câmera.\n$error';
  }

  @override
  String captureError(String error) {
    return 'Erro ao capturar: $error';
  }

  @override
  String finishWithCount(int count) {
    return 'Concluir\n($count pág.)';
  }

  @override
  String get adjustCrop => 'Ajustar recorte';

  @override
  String get detect => 'Detectar';

  @override
  String get all => 'Tudo';

  @override
  String get use => 'Usar';

  @override
  String get reviewDocument => 'Revisar documento';

  @override
  String get addPage => 'Adicionar página';

  @override
  String get discardAll => 'Descartar tudo';

  @override
  String get noPagesCaptured => 'Nenhuma página capturada.';

  @override
  String pageNumber(int number) {
    return 'Página $number';
  }

  @override
  String filterWithName(String name) {
    return 'Filtro: $name';
  }

  @override
  String get addFromCamera => 'Tirar foto';

  @override
  String get addFromGallery => 'Escolher da galeria';

  @override
  String get addPhoto => 'Adicionar foto';

  @override
  String get editPage => 'Editar página';

  @override
  String get removePage => 'Remover página';

  @override
  String get exportPdf => 'Exportar PDF';

  @override
  String get discardTitle => 'Descartar documento?';

  @override
  String get discardMessage => 'Todas as páginas capturadas serão removidas.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get discard => 'Descartar';

  @override
  String get rotate => 'Girar';

  @override
  String processError(String error) {
    return 'Erro ao processar: $error';
  }

  @override
  String get preparing => 'Preparando…';

  @override
  String ocrProgress(int current, int total) {
    return 'OCR da página $current de $total…';
  }

  @override
  String get generatingPdf => 'Gerando PDF…';

  @override
  String exportError(String error) {
    return 'Erro ao exportar: $error';
  }

  @override
  String pdfGenerated(String name) {
    return 'PDF gerado: $name.pdf';
  }

  @override
  String get share => 'Compartilhar';

  @override
  String get viewOcrText => 'Ver texto reconhecido (OCR)';

  @override
  String get fileName => 'Nome do arquivo';

  @override
  String get quality => 'Qualidade';

  @override
  String get ocrSwitchTitle => 'OCR (texto pesquisável)';

  @override
  String get ocrSwitchSubtitle => 'Reconhecimento local, no aparelho';

  @override
  String get generatePdf => 'Gerar PDF';

  @override
  String get recognizedText => 'Texto reconhecido';

  @override
  String get copyAll => 'Copiar tudo';

  @override
  String get textCopied => 'Texto copiado';

  @override
  String get autoDetectTitle => 'Detecção automática de documento';

  @override
  String get autoDetectSubtitle =>
      'Sugere o recorte automaticamente; o ajuste manual continua disponível';

  @override
  String get detectionSensitivity => 'Sensibilidade da detecção';

  @override
  String get sensitivityConservative => 'Conservadora';

  @override
  String get sensitivityBalanced => 'Equilibrada';

  @override
  String get sensitivitySensitive => 'Sensível';

  @override
  String get autoCaptureTitle => 'Disparo automático';

  @override
  String get autoCaptureSubtitle =>
      'Tira a foto sozinho quando o documento estiver estável (precisa da detecção automática)';

  @override
  String get autoCaptureHint => 'Segure firme…';

  @override
  String get ocrOnExportTitle => 'OCR ao exportar';

  @override
  String get ocrOnExportSubtitle =>
      'Reconhecimento de texto local para PDF pesquisável';

  @override
  String get reviewAfterCaptureTitle => 'Revisar após cada página';

  @override
  String get reviewAfterCaptureSubtitle =>
      'Ao confirmar, vai para a revisão do documento. Desligado, continua na câmera para capturar várias páginas seguidas.';

  @override
  String get defaultFilter => 'Filtro padrão';

  @override
  String get defaultPdfQuality => 'Qualidade padrão do PDF';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Padrão do sistema';

  @override
  String get privacy => 'Privacidade';

  @override
  String get privacyDetail =>
      'Todo o processamento (detecção, filtros, OCR e PDF) acontece no seu aparelho. Nada é enviado para a internet.';

  @override
  String get sourceCode => 'Código-fonte';

  @override
  String get sourceCodeSubtitle => 'Veja o projeto open source no GitHub';

  @override
  String get moreApps => 'Mais apps';

  @override
  String get moreAppsSubtitle => 'Conheça outros apps do mesmo desenvolvedor';

  @override
  String get contactDev => 'Contato com o desenvolvedor';

  @override
  String get contactDevSubtitle =>
      'Dúvidas, sugestões ou problemas? Me escreva';

  @override
  String get couldNotOpenLink => 'Não foi possível abrir o link';

  @override
  String get filterOriginal => 'Original';

  @override
  String get filterDocument => 'Documento';

  @override
  String get filterGrayscale => 'Cinza';

  @override
  String get filterBlackWhite => 'P&B';

  @override
  String get filterHighContrast => 'Contraste';

  @override
  String get qualityEconomy => 'Econômico';

  @override
  String get qualityBalanced => 'Equilibrado';

  @override
  String get qualityHigh => 'Alta';
}
