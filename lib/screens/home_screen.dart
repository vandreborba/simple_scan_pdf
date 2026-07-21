import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/scan_models.dart';
import '../services/document_channel.dart';
import '../services/document_detector.dart';
import '../services/image_processor.dart';
import '../services/settings_service.dart';
import '../session.dart';
import 'camera_screen.dart';
import 'crop_screen.dart';
import 'review_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.settings, required this.session});

  final AppSettings settings;
  final ScanSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l.settings,
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
                l.homeTagline,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l.homeSubtitle,
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
                label: Text(l.scan),
                onPressed: () => _startScan(context),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                ),
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                label: Text(l.addPhoto),
                onPressed: () => _addPhoto(context),
              ),
              const SizedBox(height: 8),
              ListenableBuilder(
                listenable: session,
                builder: (context, _) {
                  if (session.isEmpty) return const SizedBox.shrink();
                  return TextButton.icon(
                    icon: const Icon(Icons.collections_outlined),
                    label: Text(l.continueDocument(session.pages.length)),
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
              const SizedBox(height: 32),
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

  /// Importa uma foto da galeria e a faz passar pelo mesmo fluxo da câmera:
  /// detecção de bordas (se ligada) → recorte → processamento → revisão.
  Future<void> _addPhoto(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    String? path;
    try {
      path = await pickImageFromDevice();
    } catch (_) {
      path = null;
    }
    if (path == null) return; // usuário cancelou

    final page = ScanPage(
      originalPath: path,
      corners: DocumentDetector.fullImageCorners(),
      filter: settings.defaultFilter,
    );
    if (settings.autoDetect) {
      page.corners = await DocumentDetector.detectFromFile(
        path,
        sensitivity: settings.detectionSensitivity,
      );
    }

    final confirmed = await navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) => CropScreen(
          page: page,
          posicaoLupa: settings.posicaoLupa,
        ),
      ),
    );
    if (confirmed != true) return;

    try {
      page.processedPath = await ImageProcessor.process(page);
      page.version++;
      session.addPage(page);
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ReviewScreen(session: session, settings: settings),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.processError('$e'))));
    }
  }
}
