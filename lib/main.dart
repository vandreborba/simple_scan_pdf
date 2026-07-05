import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/document_channel.dart';
import 'services/settings_service.dart';
import 'session.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  runApp(SimpleScanApp(settings: settings));
}

class SimpleScanApp extends StatefulWidget {
  const SimpleScanApp({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<SimpleScanApp> createState() => _SimpleScanAppState();

  /// Troca o idioma do app em tempo real a partir de qualquer tela filha.
  static void setLocale(BuildContext context, Locale? locale) {
    context.findAncestorStateOfType<_SimpleScanAppState>()!.setLocale(locale);
  }
}

class _SimpleScanAppState extends State<SimpleScanApp> {
  final ScanSession session = ScanSession();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  late Locale? _locale = widget.settings.locale;

  @override
  void initState() {
    super.initState();
    documentChannel.setMethodCallHandler((call) async {
      if (call.method == 'onNewDocument' && call.arguments is String) {
        _openIncomingDocument(call.arguments as String);
      }
    });
    // Documento que abriu o app com o app fechado (cold start).
    documentChannel
        .invokeMethod<String>('getInitialDocument')
        .then((path) {
          if (path != null && path.isNotEmpty) _openIncomingDocument(path);
        })
        .catchError((_) {});
  }

  void _openIncomingDocument(String path) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => documentReaderFor(path)),
      );
    });
  }

  void setLocale(Locale? locale) {
    widget.settings.locale = locale;
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      home: HomeScreen(settings: widget.settings, session: session),
    );
  }
}
