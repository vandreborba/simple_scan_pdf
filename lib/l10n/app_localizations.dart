import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Simple Scan PDF'**
  String get appTitle;

  /// No description provided for @homeTagline.
  ///
  /// In en, this message translates to:
  /// **'Scan documents and create PDFs\nwith searchable text'**
  String get homeTagline;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything is processed on your device.\nNo account, no cloud, no ads.'**
  String get homeSubtitle;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @openDocument.
  ///
  /// In en, this message translates to:
  /// **'Open document'**
  String get openDocument;

  /// No description provided for @openDocError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the document.\n{error}'**
  String openDocError(String error);

  /// No description provided for @emptyDocument.
  ///
  /// In en, this message translates to:
  /// **'This document has no readable text.'**
  String get emptyDocument;

  /// No description provided for @pdfPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String pdfPageOf(int current, int total);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @continueDocument.
  ///
  /// In en, this message translates to:
  /// **'Continue document ({count} pg.)'**
  String continueDocument(int count);

  /// No description provided for @flashlight.
  ///
  /// In en, this message translates to:
  /// **'Flashlight'**
  String get flashlight;

  /// No description provided for @cameraError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the camera.\n{error}'**
  String cameraError(String error);

  /// No description provided for @captureError.
  ///
  /// In en, this message translates to:
  /// **'Capture error: {error}'**
  String captureError(String error);

  /// No description provided for @finishWithCount.
  ///
  /// In en, this message translates to:
  /// **'Finish\n({count} pg.)'**
  String finishWithCount(int count);

  /// No description provided for @adjustCrop.
  ///
  /// In en, this message translates to:
  /// **'Adjust crop'**
  String get adjustCrop;

  /// No description provided for @detect.
  ///
  /// In en, this message translates to:
  /// **'Detect'**
  String get detect;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @use.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get use;

  /// No description provided for @reviewDocument.
  ///
  /// In en, this message translates to:
  /// **'Review document'**
  String get reviewDocument;

  /// No description provided for @addPage.
  ///
  /// In en, this message translates to:
  /// **'Add page'**
  String get addPage;

  /// No description provided for @discardAll.
  ///
  /// In en, this message translates to:
  /// **'Discard all'**
  String get discardAll;

  /// No description provided for @noPagesCaptured.
  ///
  /// In en, this message translates to:
  /// **'No pages captured.'**
  String get noPagesCaptured;

  /// No description provided for @pageNumber.
  ///
  /// In en, this message translates to:
  /// **'Page {number}'**
  String pageNumber(int number);

  /// No description provided for @filterWithName.
  ///
  /// In en, this message translates to:
  /// **'Filter: {name}'**
  String filterWithName(String name);

  /// No description provided for @addFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get addFromCamera;

  /// No description provided for @addFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get addFromGallery;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @editPage.
  ///
  /// In en, this message translates to:
  /// **'Edit page'**
  String get editPage;

  /// No description provided for @removePage.
  ///
  /// In en, this message translates to:
  /// **'Remove page'**
  String get removePage;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @discardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard document?'**
  String get discardTitle;

  /// No description provided for @discardMessage.
  ///
  /// In en, this message translates to:
  /// **'All captured pages will be removed.'**
  String get discardMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @rotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get rotate;

  /// No description provided for @processError.
  ///
  /// In en, this message translates to:
  /// **'Processing error: {error}'**
  String processError(String error);

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get preparing;

  /// No description provided for @ocrProgress.
  ///
  /// In en, this message translates to:
  /// **'OCR of page {current} of {total}…'**
  String ocrProgress(int current, int total);

  /// No description provided for @generatingPdf.
  ///
  /// In en, this message translates to:
  /// **'Generating PDF…'**
  String get generatingPdf;

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Export error: {error}'**
  String exportError(String error);

  /// No description provided for @pdfGenerated.
  ///
  /// In en, this message translates to:
  /// **'PDF created: {name}.pdf'**
  String pdfGenerated(String name);

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @viewOcrText.
  ///
  /// In en, this message translates to:
  /// **'View recognized text (OCR)'**
  String get viewOcrText;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get fileName;

  /// No description provided for @quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// No description provided for @ocrSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'OCR (searchable text)'**
  String get ocrSwitchTitle;

  /// No description provided for @ocrSwitchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local, on-device recognition'**
  String get ocrSwitchSubtitle;

  /// No description provided for @generatePdf.
  ///
  /// In en, this message translates to:
  /// **'Generate PDF'**
  String get generatePdf;

  /// No description provided for @recognizedText.
  ///
  /// In en, this message translates to:
  /// **'Recognized text'**
  String get recognizedText;

  /// No description provided for @copyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get copyAll;

  /// No description provided for @textCopied.
  ///
  /// In en, this message translates to:
  /// **'Text copied'**
  String get textCopied;

  /// No description provided for @autoDetectTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic document detection'**
  String get autoDetectTitle;

  /// No description provided for @autoDetectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Suggests the crop automatically; manual adjustment stays available'**
  String get autoDetectSubtitle;

  /// No description provided for @detectionSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Detection sensitivity'**
  String get detectionSensitivity;

  /// No description provided for @sensitivityConservative.
  ///
  /// In en, this message translates to:
  /// **'Conservative'**
  String get sensitivityConservative;

  /// No description provided for @sensitivityBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get sensitivityBalanced;

  /// No description provided for @sensitivitySensitive.
  ///
  /// In en, this message translates to:
  /// **'Sensitive'**
  String get sensitivitySensitive;

  /// No description provided for @autoCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto capture'**
  String get autoCaptureTitle;

  /// No description provided for @autoCaptureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Takes the photo automatically when the document is steady (needs automatic detection)'**
  String get autoCaptureSubtitle;

  /// No description provided for @autoCaptureHint.
  ///
  /// In en, this message translates to:
  /// **'Hold steady…'**
  String get autoCaptureHint;

  /// No description provided for @ocrOnExportTitle.
  ///
  /// In en, this message translates to:
  /// **'OCR on export'**
  String get ocrOnExportTitle;

  /// No description provided for @ocrOnExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local text recognition for a searchable PDF'**
  String get ocrOnExportSubtitle;

  /// No description provided for @reviewAfterCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Review after each page'**
  String get reviewAfterCaptureTitle;

  /// No description provided for @reviewAfterCaptureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'After confirming, go to the document review. When off, stay on the camera to capture several pages in a row.'**
  String get reviewAfterCaptureSubtitle;

  /// No description provided for @defaultFilter.
  ///
  /// In en, this message translates to:
  /// **'Default filter'**
  String get defaultFilter;

  /// No description provided for @defaultPdfQuality.
  ///
  /// In en, this message translates to:
  /// **'Default PDF quality'**
  String get defaultPdfQuality;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @privacyDetail.
  ///
  /// In en, this message translates to:
  /// **'All processing (detection, filters, OCR and PDF) happens on your device. Nothing is sent to the internet.'**
  String get privacyDetail;

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get sourceCode;

  /// No description provided for @sourceCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View the open source project on GitHub'**
  String get sourceCodeSubtitle;

  /// No description provided for @moreApps.
  ///
  /// In en, this message translates to:
  /// **'More apps'**
  String get moreApps;

  /// No description provided for @moreAppsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover other apps by the same developer'**
  String get moreAppsSubtitle;

  /// No description provided for @contactDev.
  ///
  /// In en, this message translates to:
  /// **'Contact the developer'**
  String get contactDev;

  /// No description provided for @contactDevSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Questions, suggestions or issues? Drop me a line'**
  String get contactDevSubtitle;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link'**
  String get couldNotOpenLink;

  /// No description provided for @filterOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get filterOriginal;

  /// No description provided for @filterDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get filterDocument;

  /// No description provided for @filterGrayscale.
  ///
  /// In en, this message translates to:
  /// **'Grayscale'**
  String get filterGrayscale;

  /// No description provided for @filterBlackWhite.
  ///
  /// In en, this message translates to:
  /// **'B&W'**
  String get filterBlackWhite;

  /// No description provided for @filterHighContrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get filterHighContrast;

  /// No description provided for @qualityEconomy.
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get qualityEconomy;

  /// No description provided for @qualityBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get qualityBalanced;

  /// No description provided for @qualityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get qualityHigh;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
