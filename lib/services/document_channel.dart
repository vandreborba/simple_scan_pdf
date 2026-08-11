import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../screens/md_reader_screen.dart';
import '../screens/odt_reader_screen.dart';
import '../screens/pdf_reader_screen.dart';

/// Canal com o lado nativo (Android) para:
/// - receber documentos abertos de fora do app ("Abrir com" / ACTION_VIEW);
/// - escolher um documento do aparelho (seletor nativo / ACTION_OPEN_DOCUMENT).
const MethodChannel documentChannel =
    MethodChannel('app.simple_scan_pdf/incoming_document');

/// Abre o seletor de arquivos nativo (PDF, ODT ou Markdown) e devolve o caminho
/// de um arquivo copiado para o cache do app, ou `null` se o usuário cancelar.
Future<String?> pickDocumentFromDevice() =>
    documentChannel.invokeMethod<String>('pickDocument');

/// Abre o seletor nativo filtrando imagens e devolve o caminho de uma imagem
/// copiada para o cache do app, ou `null` se o usuário cancelar.
Future<String?> pickImageFromDevice() =>
    documentChannel.invokeMethod<String>('pickImage');

/// Escolhe a tela de leitura conforme a extensão do arquivo.
Widget documentReaderFor(String path) {
  final nome = path.toLowerCase();
  if (nome.endsWith('.odt')) {
    return OdtReaderScreen(path: path);
  }
  if (nome.endsWith('.md') || nome.endsWith('.markdown') || nome.endsWith('.txt')) {
    return MdReaderScreen(path: path);
  }
  return PdfReaderScreen(path: path);
}
