// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Simple Scan PDF';

  @override
  String get homeTagline =>
      'Scan documents and create PDFs\nwith searchable text';

  @override
  String get homeSubtitle =>
      'Everything is processed on your device.\nNo account, no cloud, no ads.';

  @override
  String get scan => 'Scan';

  @override
  String get openDocument => 'Open document';

  @override
  String openDocError(String error) {
    return 'Could not open the document.\n$error';
  }

  @override
  String get emptyDocument => 'This document has no readable text.';

  @override
  String pdfPageOf(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get pdfSearch => 'Search';

  @override
  String get pdfSearchHint => 'Search in the document';

  @override
  String get pdfMoreOptions => 'More options';

  @override
  String pdfResultsCount(int current, int total) {
    return '$current of $total';
  }

  @override
  String get pdfNoResults => 'No results';

  @override
  String get pdfExitSearch => 'Close search';

  @override
  String get pdfPreviousResult => 'Previous result';

  @override
  String get pdfNextResult => 'Next result';

  @override
  String get pdfGoToPageTitle => 'Go to page';

  @override
  String get pdfGoToPageHint => 'Enter a page number';

  @override
  String get pdfGoToPageConfirm => 'Go';

  @override
  String get pdfPreviousPage => 'Previous page';

  @override
  String get pdfNextPage => 'Next page';

  @override
  String get pdfZoomIn => 'Zoom in';

  @override
  String get pdfZoomOut => 'Zoom out';

  @override
  String get pdfFitWidth => 'Fit to width';

  @override
  String get pdfOutline => 'Table of contents';

  @override
  String get pdfOutlineEmpty => 'This document has no table of contents';

  @override
  String get pdfReadMode => 'Reading mode';

  @override
  String get pdfModeOriginal => 'Original';

  @override
  String get pdfModeSepia => 'Sepia';

  @override
  String get pdfModeNight => 'Night';

  @override
  String get pdfPasswordTitle => 'Protected document';

  @override
  String get pdfPasswordMessage => 'Enter the password to open this document.';

  @override
  String get pdfPasswordOk => 'Open';

  @override
  String get settings => 'Settings';

  @override
  String continueDocument(int count) {
    return 'Continue document ($count pg.)';
  }

  @override
  String get flashlight => 'Flashlight';

  @override
  String cameraError(String error) {
    return 'Could not open the camera.\n$error';
  }

  @override
  String captureError(String error) {
    return 'Capture error: $error';
  }

  @override
  String finishWithCount(int count) {
    return 'Finish\n($count pg.)';
  }

  @override
  String get adjustCrop => 'Adjust crop';

  @override
  String get detect => 'Detect';

  @override
  String get all => 'All';

  @override
  String get use => 'Use';

  @override
  String get reviewDocument => 'Review document';

  @override
  String get addPage => 'Add page';

  @override
  String get discardAll => 'Discard all';

  @override
  String get noPagesCaptured => 'No pages captured.';

  @override
  String pageNumber(int number) {
    return 'Page $number';
  }

  @override
  String filterWithName(String name) {
    return 'Filter: $name';
  }

  @override
  String get addFromCamera => 'Take a photo';

  @override
  String get addFromGallery => 'Choose from gallery';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get editPage => 'Edit page';

  @override
  String get removePage => 'Remove page';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get discardTitle => 'Discard document?';

  @override
  String get discardMessage => 'All captured pages will be removed.';

  @override
  String get cancel => 'Cancel';

  @override
  String get discard => 'Discard';

  @override
  String get rotate => 'Rotate';

  @override
  String processError(String error) {
    return 'Processing error: $error';
  }

  @override
  String get preparing => 'Preparing…';

  @override
  String ocrProgress(int current, int total) {
    return 'OCR of page $current of $total…';
  }

  @override
  String get generatingPdf => 'Generating PDF…';

  @override
  String exportError(String error) {
    return 'Export error: $error';
  }

  @override
  String pdfGenerated(String name) {
    return 'PDF created: $name.pdf';
  }

  @override
  String get share => 'Share';

  @override
  String get viewOcrText => 'View recognized text (OCR)';

  @override
  String get fileName => 'File name';

  @override
  String get quality => 'Quality';

  @override
  String get ocrSwitchTitle => 'OCR (searchable text)';

  @override
  String get ocrSwitchSubtitle => 'Local, on-device recognition';

  @override
  String get generatePdf => 'Generate PDF';

  @override
  String get recognizedText => 'Recognized text';

  @override
  String get copyAll => 'Copy all';

  @override
  String get textCopied => 'Text copied';

  @override
  String get autoDetectTitle => 'Automatic document detection';

  @override
  String get autoDetectSubtitle =>
      'Suggests the crop automatically; manual adjustment stays available';

  @override
  String get detectionSensitivity => 'Detection sensitivity';

  @override
  String get sensitivityConservative => 'Conservative';

  @override
  String get sensitivityBalanced => 'Balanced';

  @override
  String get sensitivitySensitive => 'Sensitive';

  @override
  String get autoCaptureTitle => 'Auto capture';

  @override
  String get autoCaptureSubtitle =>
      'Takes the photo automatically when the document is steady (needs automatic detection)';

  @override
  String get autoCaptureHint => 'Hold steady…';

  @override
  String get ocrOnExportTitle => 'OCR on export';

  @override
  String get ocrOnExportSubtitle =>
      'Local text recognition for a searchable PDF';

  @override
  String get reviewAfterCaptureTitle => 'Review after each page';

  @override
  String get reviewAfterCaptureSubtitle =>
      'After confirming, go to the document review. When off, stay on the camera to capture several pages in a row.';

  @override
  String get defaultFilter => 'Default filter';

  @override
  String get defaultPdfQuality => 'Default PDF quality';

  @override
  String get loupePosition => 'Magnifier position';

  @override
  String get loupeNearFinger => 'Near finger';

  @override
  String get loupeOppositeCorner => 'Opposite corner';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyDetail =>
      'All processing (detection, filters, OCR and PDF) happens on your device. Nothing is sent to the internet.';

  @override
  String get sourceCode => 'Source code';

  @override
  String get sourceCodeSubtitle => 'View the open source project on GitHub';

  @override
  String get moreApps => 'More apps';

  @override
  String get moreAppsSubtitle => 'Discover other apps by the same developer';

  @override
  String get contactDev => 'Contact the developer';

  @override
  String get contactDevSubtitle =>
      'Questions, suggestions or issues? Drop me a line';

  @override
  String get couldNotOpenLink => 'Could not open the link';

  @override
  String get filterOriginal => 'Original';

  @override
  String get filterDocument => 'Document';

  @override
  String get filterGrayscale => 'Grayscale';

  @override
  String get filterBlackWhite => 'B&W';

  @override
  String get filterHighContrast => 'Contrast';

  @override
  String get qualityEconomy => 'Economy';

  @override
  String get qualityBalanced => 'Balanced';

  @override
  String get qualityHigh => 'High';
}
