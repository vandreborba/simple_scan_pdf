import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_scan_pdf/l10n/app_localizations.dart';
import 'package:simple_scan_pdf/screens/md_reader_screen.dart';

void main() {
  testWidgets('Leitor de MD renderiza o conteúdo do arquivo', (tester) async {
    final diretorio = Directory.systemTemp.createTempSync('md_reader_test');
    addTearDown(() => diretorio.deleteSync(recursive: true));
    final arquivo = File('${diretorio.path}/exemplo.md');
    arquivo.writeAsStringSync('# Titulo\n\n**Negrito** e *italico*.');

    // IO real do arquivo exige runAsync; pump depois, fora dele.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MdReaderScreen(path: arquivo.path),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(find.text('Titulo'), findsOneWidget);
    expect(find.byType(RichText), findsWidgets);
  });

  testWidgets('Leitor de MD mostra aviso para arquivo vazio', (tester) async {
    final diretorio = Directory.systemTemp.createTempSync('md_reader_test');
    addTearDown(() => diretorio.deleteSync(recursive: true));
    final arquivo = File('${diretorio.path}/vazio.md');
    arquivo.writeAsStringSync('');

    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MdReaderScreen(path: arquivo.path),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    final localizacoes =
        AppLocalizations.of(tester.element(find.byType(MdReaderScreen)));
    expect(find.text(localizacoes.emptyDocument), findsOneWidget);
  });
}
