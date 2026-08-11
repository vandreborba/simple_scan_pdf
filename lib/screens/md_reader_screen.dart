import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

/// Leitor simples de Markdown (.md) e texto puro (.txt): mostra o conteúdo
/// renderizado com o tema do app e permite compartilhar o arquivo original.
class MdReaderScreen extends StatefulWidget {
  const MdReaderScreen({super.key, required this.path});

  final String path;

  @override
  State<MdReaderScreen> createState() => _MdReaderScreenState();
}

class _MdReaderScreenState extends State<MdReaderScreen> {
  late final Future<String> _future = _carregarConteudo();

  String get _fileName {
    final segment = widget.path.split('/').last;
    return segment.isEmpty ? 'MD' : segment;
  }

  /// Lê o arquivo como bytes e decodifica em UTF-8 de forma tolerante, para
  /// não quebrar em acentos ou em bytes inválidos no meio do texto.
  Future<String> _carregarConteudo() async {
    final bytes = await File(widget.path).readAsBytes();
    return utf8.decode(bytes, allowMalformed: true);
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(widget.path)]),
    );
  }

  /// Abre links http(s)/mailto do documento no app externo; para outros
  /// esquemas (ex.: endereços relativos) simplesmente ignora.
  Future<void> _abrirLink(String? href) async {
    if (href == null) return;
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    final esquema = uri.scheme.toLowerCase();
    if (esquema != 'http' && esquema != 'https' && esquema != 'mailto') {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    var aberto = false;
    try {
      aberto = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      aberto = false;
    }
    if (!aberto && mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l.couldNotOpenLink)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_fileName, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: l.share,
            onPressed: _share,
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  l.openDocError('${snapshot.error}'),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final conteudo = snapshot.data ?? '';
          if (conteudo.trim().isEmpty) {
            return Center(child: Text(l.emptyDocument));
          }
          return Markdown(
            data: conteudo,
            selectable: true,
            // Diretório do arquivo, para imagens relativas locais resolverem.
            imageDirectory: File(widget.path).parent.path,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
            onTapLink: (_, href, _) => _abrirLink(href),
          );
        },
      ),
    );
  }
}
