import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Detecção automática de documento'),
            subtitle: const Text(
                'Sugere o recorte automaticamente; o ajuste manual continua disponível'),
            value: settings.autoDetect,
            onChanged: (v) => setState(() => settings.autoDetect = v),
          ),
          SwitchListTile(
            title: const Text('OCR ao exportar'),
            subtitle: const Text(
                'Reconhecimento de texto local para PDF pesquisável'),
            value: settings.ocrEnabled,
            onChanged: (v) => setState(() => settings.ocrEnabled = v),
          ),
          ListTile(
            title: const Text('Filtro padrão'),
            subtitle: Text(settings.defaultFilter.label),
            trailing: DropdownButton<ScanFilter>(
              value: settings.defaultFilter,
              underline: const SizedBox.shrink(),
              items: [
                for (final f in ScanFilter.values)
                  DropdownMenuItem(value: f, child: Text(f.label)),
              ],
              onChanged: (f) {
                if (f != null) setState(() => settings.defaultFilter = f);
              },
            ),
          ),
          ListTile(
            title: const Text('Qualidade padrão do PDF'),
            subtitle: Text(settings.pdfQuality.label),
            trailing: DropdownButton<PdfQuality>(
              value: settings.pdfQuality,
              underline: const SizedBox.shrink(),
              items: [
                for (final q in PdfQuality.values)
                  DropdownMenuItem(value: q, child: Text(q.label)),
              ],
              onChanged: (q) {
                if (q != null) setState(() => settings.pdfQuality = q);
              },
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Privacidade'),
            subtitle: Text(
                'Todo o processamento (detecção, filtros, OCR e PDF) acontece no seu aparelho. Nada é enviado para a internet.'),
          ),
        ],
      ),
    );
  }
}
