import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../session.dart';
import 'camera_screen.dart';
import 'review_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.settings, required this.session});

  final AppSettings settings;
  final ScanSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Scan PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurações',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(settings: settings),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.document_scanner_outlined,
                size: 96,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Escaneie documentos e gere PDFs\ncom texto pesquisável',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Tudo processado no seu aparelho.\nSem conta, sem nuvem, sem propaganda.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 40),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Escanear'),
                onPressed: () => _startScan(context),
              ),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: session,
                builder: (context, _) {
                  if (session.isEmpty) return const SizedBox.shrink();
                  return TextButton.icon(
                    icon: const Icon(Icons.collections_outlined),
                    label: Text(
                      'Continuar documento (${session.pages.length} pág.)',
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReviewScreen(
                          session: session,
                          settings: settings,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startScan(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraScreen(session: session, settings: settings),
      ),
    );
  }
}
