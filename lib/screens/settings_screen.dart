import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../l10n/enum_labels.dart';
import '../main.dart';
import '../models/scan_models.dart';
import '../services/pdf_service.dart';
import '../services/settings_service.dart';

/// Preferências: tudo opcional, com bons padrões.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings get settings => widget.settings;

  // Página do desenvolvedor na Play Store. Tenta abrir direto no app da loja
  // (market://) e cai para o navegador se ele não estiver disponível.
  static final Uri _playStoreAppUri = Uri.parse(
    'market://dev?id=7961447969216777975',
  );
  static final Uri _playStoreWebUri = Uri.parse(
    'https://play.google.com/store/apps/dev?id=7961447969216777975',
  );

  // E-mail de contato do desenvolvedor. Não é texto de UI traduzível, então
  // fica como constante; o assunto já vem preenchido com o nome do app.
  static const String _emailDesenvolvedor = 'vandreapps@gmail.com';
  static final Uri _contatoDevUri = Uri(
    scheme: 'mailto',
    path: _emailDesenvolvedor,
    query: 'subject=Simple Scan PDF',
  );

  // Repositório público do app (GPLv3). URL fixa, não é texto de UI traduzível.
  static final Uri _repositorioUri = Uri.parse(
    'https://github.com/vandreborba/simple_scan_pdf',
  );

  Future<void> _openMoreApps() async {
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    final opened =
        await _tryLaunch(_playStoreAppUri) ||
        await _tryLaunch(_playStoreWebUri);
    if (!opened && mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l.couldNotOpenLink)));
    }
  }

  Future<void> _contatarDesenvolvedor() async {
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    final opened = await _tryLaunch(_contatoDevUri);
    if (!opened && mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l.couldNotOpenLink)));
    }
  }

  Future<void> _abrirRepositorio() async {
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    final opened = await _tryLaunch(_repositorioUri);
    if (!opened && mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l.couldNotOpenLink)));
    }
  }

  Future<bool> _tryLaunch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final localeCode = settings.locale?.languageCode ?? 'system';
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l.language),
            trailing: DropdownButton<String>(
              value: localeCode,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(value: 'system', child: Text(l.languageSystem)),
                const DropdownMenuItem(value: 'pt', child: Text('Português')),
                const DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (code) {
                final locale = code == null || code == 'system'
                    ? null
                    : Locale(code);
                SimpleScanApp.setLocale(context, locale);
                setState(() {});
              },
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(l.autoDetectTitle),
            subtitle: Text(l.autoDetectSubtitle),
            value: settings.autoDetect,
            onChanged: (v) => setState(() => settings.autoDetect = v),
          ),
          ListTile(
            enabled: settings.autoDetect,
            title: Text(l.detectionSensitivity),
            subtitle: Text(settings.detectionSensitivity.label(l)),
            trailing: DropdownButton<DetectionSensitivity>(
              value: settings.detectionSensitivity,
              underline: const SizedBox.shrink(),
              items: [
                for (final s in DetectionSensitivity.values)
                  DropdownMenuItem(value: s, child: Text(s.label(l))),
              ],
              onChanged: settings.autoDetect
                  ? (s) {
                      if (s != null) {
                        setState(() => settings.detectionSensitivity = s);
                      }
                    }
                  : null,
            ),
          ),
          SwitchListTile(
            title: Text(l.autoCaptureTitle),
            subtitle: Text(l.autoCaptureSubtitle),
            value: settings.autoCapture && settings.autoDetect,
            onChanged: settings.autoDetect
                ? (v) => setState(() => settings.autoCapture = v)
                : null,
          ),
          SwitchListTile(
            title: Text(l.reviewAfterCaptureTitle),
            subtitle: Text(l.reviewAfterCaptureSubtitle),
            value: settings.reviewAfterEachPage,
            onChanged: (v) => setState(() => settings.reviewAfterEachPage = v),
          ),
          SwitchListTile(
            title: Text(l.ocrOnExportTitle),
            subtitle: Text(l.ocrOnExportSubtitle),
            value: settings.ocrEnabled,
            onChanged: (v) => setState(() => settings.ocrEnabled = v),
          ),
          ListTile(
            title: Text(l.defaultFilter),
            subtitle: Text(settings.defaultFilter.label(l)),
            trailing: DropdownButton<ScanFilter>(
              value: settings.defaultFilter,
              underline: const SizedBox.shrink(),
              items: [
                for (final f in ScanFilter.values)
                  DropdownMenuItem(value: f, child: Text(f.label(l))),
              ],
              onChanged: (f) {
                if (f != null) setState(() => settings.defaultFilter = f);
              },
            ),
          ),
          ListTile(
            title: Text(l.defaultPdfQuality),
            subtitle: Text(settings.pdfQuality.label(l)),
            trailing: DropdownButton<PdfQuality>(
              value: settings.pdfQuality,
              underline: const SizedBox.shrink(),
              items: [
                for (final q in PdfQuality.values)
                  DropdownMenuItem(value: q, child: Text(q.label(l))),
              ],
              onChanged: (q) {
                if (q != null) setState(() => settings.pdfQuality = q);
              },
            ),
          ),
          ListTile(
            title: Text(l.loupePosition),
            subtitle: Text(settings.posicaoLupa.label(l)),
            trailing: DropdownButton<PosicaoLupa>(
              value: settings.posicaoLupa,
              underline: const SizedBox.shrink(),
              items: [
                for (final p in PosicaoLupa.values)
                  DropdownMenuItem(value: p, child: Text(p.label(l))),
              ],
              onChanged: (p) {
                if (p != null) setState(() => settings.posicaoLupa = p);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l.privacy),
            subtitle: Text(l.privacyDetail),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(l.sourceCode),
            subtitle: Text(l.sourceCodeSubtitle),
            trailing: const Icon(Icons.open_in_new),
            onTap: _abrirRepositorio,
          ),
          ListTile(
            leading: const Icon(Icons.apps),
            title: Text(l.moreApps),
            subtitle: Text(l.moreAppsSubtitle),
            trailing: const Icon(Icons.open_in_new),
            onTap: _openMoreApps,
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(l.contactDev),
            subtitle: Text('${l.contactDevSubtitle}\n$_emailDesenvolvedor'),
            isThreeLine: true,
            trailing: const Icon(Icons.open_in_new),
            onTap: _contatarDesenvolvedor,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
