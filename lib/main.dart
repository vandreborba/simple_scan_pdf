import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  runApp(SimpleScanApp(settings: settings));
}

class SimpleScanApp extends StatelessWidget {
  SimpleScanApp({super.key, required this.settings});

  final AppSettings settings;
  final ScanSession session = ScanSession();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Scan PDF',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(settings: settings, session: session),
    );
  }
}
