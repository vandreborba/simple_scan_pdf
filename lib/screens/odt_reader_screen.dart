import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../services/odt_service.dart';

/// Leitor simples de arquivos .odt: mostra o conteúdo textual com formatação
/// básica (títulos, negrito/itálico, listas) e permite exportar/compartilhar.
class OdtReaderScreen extends StatefulWidget {
  const OdtReaderScreen({super.key, required this.path});

  final String path;

  @override
  State<OdtReaderScreen> createState() => _OdtReaderScreenState();
}

class _OdtReaderScreenState extends State<OdtReaderScreen> {
  late final Future<OdtDocument> _future = OdtService.parseFile(widget.path);

  String get _fileName {
    final segment = widget.path.split('/').last;
    return segment.isEmpty ? 'ODT' : segment;
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(widget.path)]),
    );
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
      body: FutureBuilder<OdtDocument>(
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
          final blocks = snapshot.data?.blocks ?? const [];
          if (blocks.isEmpty) {
            return Center(child: Text(l.emptyDocument));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: blocks.length,
            itemBuilder: (context, index) => _BlockView(block: blocks[index]),
          );
        },
      ),
    );
  }
}

class _BlockView extends StatelessWidget {
  const _BlockView({required this.block});

  final OdtBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (block.type) {
      case OdtBlockType.heading:
        return Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text.rich(
            _spans(block, _headingStyle(theme, block.level)),
          ),
        );
      case OdtBlockType.paragraph:
        if (block.isEmpty) return const SizedBox(height: 10);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text.rich(_spans(block, theme.textTheme.bodyMedium)),
        );
      case OdtBlockType.listItem:
        return Padding(
          padding: EdgeInsets.only(
            left: 8.0 + block.indent * 20,
            top: 3,
            bottom: 3,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  block.marker,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Expanded(
                child: Text.rich(_spans(block, theme.textTheme.bodyMedium)),
              ),
            ],
          ),
        );
    }
  }

  TextStyle? _headingStyle(ThemeData theme, int level) {
    final text = theme.textTheme;
    final base = switch (level) {
      1 => text.headlineSmall,
      2 => text.titleLarge,
      3 => text.titleMedium,
      _ => text.titleSmall,
    };
    return base?.copyWith(fontWeight: FontWeight.bold);
  }

  TextSpan _spans(OdtBlock block, TextStyle? base) {
    return TextSpan(
      style: base,
      children: [
        for (final inline in block.inlines)
          TextSpan(
            text: inline.text,
            style: TextStyle(
              fontWeight: inline.bold ? FontWeight.bold : null,
              fontStyle: inline.italic ? FontStyle.italic : null,
              decoration:
                  inline.underline ? TextDecoration.underline : null,
            ),
          ),
      ],
    );
  }
}
