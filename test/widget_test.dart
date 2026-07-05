import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_scan_pdf/main.dart';
import 'package:simple_scan_pdf/services/settings_service.dart';

void main() {
  testWidgets('Home mostra o botão de escanear e o de configurações',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load();

    await tester.pumpWidget(SimpleScanApp(settings: settings));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
