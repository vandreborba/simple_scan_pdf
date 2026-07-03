import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Exibe o texto reconhecido pelo OCR, com opção de copiar.
class OcrTextScreen extends StatelessWidget {
  const OcrTextScreen({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Texto reconhecido'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copiar tudo',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Texto copiado')),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(text),
      ),
    );
  }
}
