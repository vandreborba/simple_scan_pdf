import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_scan_pdf/main.dart';
import 'package:simple_scan_pdf/services/settings_service.dart';

void main() {
  testWidgets('Home mostra o botão Escanear', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load();

    await tester.pumpWidget(SimpleScanApp(settings: settings));

    expect(find.text('Escanear'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
