import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Trecho de texto com formatação básica (negrito/itálico/sublinhado).
class OdtInline {
  const OdtInline(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.underline = false,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool underline;
}

enum OdtBlockType { heading, paragraph, listItem }

/// Um bloco do documento: título, parágrafo ou item de lista.
class OdtBlock {
  const OdtBlock({
    required this.type,
    required this.inlines,
    this.level = 0,
    this.indent = 0,
    this.marker = '',
  });

  final OdtBlockType type;
  final List<OdtInline> inlines;

  /// Nível do título (1..n).
  final int level;

  /// Nível de aninhamento em listas.
  final int indent;

  /// Marcador do item de lista (ex.: "•" ou "1.").
  final String marker;

  bool get isEmpty => inlines.every((i) => i.text.trim().isEmpty);
}

class OdtDocument {
  const OdtDocument(this.blocks);
  final List<OdtBlock> blocks;
}

/// Lê arquivos .odt (ZIP + XML) e extrai o conteúdo textual com formatação
/// básica, para leitura. Não reproduz o layout original fielmente.
class OdtService {
  static Future<OdtDocument> parseFile(String path) async {
    final bytes = await File(path).readAsBytes();
    return _OdtParser().parse(bytes);
  }
}

class _Flags {
  const _Flags({this.bold = false, this.italic = false, this.underline = false});
  final bool bold;
  final bool italic;
  final bool underline;

  _Flags merge(_ResolvedProps p) => _Flags(
        bold: p.bold ?? bold,
        italic: p.italic ?? italic,
        underline: p.underline ?? underline,
      );

  _Flags copyWith({bool? underline}) => _Flags(
        bold: bold,
        italic: italic,
        underline: underline ?? this.underline,
      );
}

class _RawProps {
  const _RawProps({this.bold, this.italic, this.underline, this.parent});
  final bool? bold;
  final bool? italic;
  final bool? underline;
  final String? parent;
}

class _ResolvedProps {
  const _ResolvedProps({this.bold, this.italic, this.underline});
  final bool? bold;
  final bool? italic;
  final bool? underline;
}

class _OdtParser {
  final Map<String, _RawProps> _styles = {};
  final Set<String> _orderedListStyles = {};
  final List<OdtBlock> _blocks = [];

  OdtDocument parse(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    _indexStyles(_xmlOf(archive, 'styles.xml'));
    final content = _xmlOf(archive, 'content.xml');
    if (content == null) return const OdtDocument([]);
    _indexStyles(content);

    final body = _firstElement(content.findAllElements('office:text'));
    if (body != null) {
      for (final el in body.childElements) {
        _walkBlock(el, 0);
      }
    }
    return OdtDocument(_blocks);
  }

  XmlDocument? _xmlOf(Archive archive, String name) {
    final file = archive.findFile(name);
    if (file == null) return null;
    try {
      return XmlDocument.parse(utf8.decode(file.readBytes()!, allowMalformed: true));
    } catch (_) {
      return null;
    }
  }

  void _indexStyles(XmlDocument? doc) {
    if (doc == null) return;

    for (final style in doc.findAllElements('style:style')) {
      final name = style.getAttribute('style:name');
      if (name == null) continue;
      final props = _firstElement(style.findElements('style:text-properties'));
      _styles[name] = _RawProps(
        parent: style.getAttribute('style:parent-style-name'),
        bold: _boolOr(props?.getAttribute('fo:font-weight'), 'bold'),
        italic: _boolOr(props?.getAttribute('fo:font-style'), 'italic'),
        underline: _underlineOf(props?.getAttribute('style:text-underline-style')),
      );
    }

    for (final listStyle in doc.findAllElements('text:list-style')) {
      final name = listStyle.getAttribute('style:name');
      if (name == null) continue;
      final ordered =
          listStyle.findAllElements('text:list-level-style-number').isNotEmpty;
      if (ordered) _orderedListStyles.add(name);
    }
  }

  bool? _boolOr(String? value, String truthy) {
    if (value == null) return null;
    return value == truthy;
  }

  bool? _underlineOf(String? value) {
    if (value == null) return null;
    return value != 'none';
  }

  _ResolvedProps _resolve(String? name, [Set<String>? seen]) {
    if (name == null) return const _ResolvedProps();
    final raw = _styles[name];
    if (raw == null) return const _ResolvedProps();
    final visited = seen ?? <String>{};
    if (!visited.add(name)) return const _ResolvedProps();
    final parent = _resolve(raw.parent, visited);
    return _ResolvedProps(
      bold: raw.bold ?? parent.bold,
      italic: raw.italic ?? parent.italic,
      underline: raw.underline ?? parent.underline,
    );
  }

  _Flags _mergeStyle(_Flags inherited, String? styleName) =>
      inherited.merge(_resolve(styleName));

  void _walkBlock(XmlElement el, int indent) {
    switch (el.qualifiedName) {
      case 'text:h':
        final level = int.tryParse(el.getAttribute('text:outline-level') ?? '1') ?? 1;
        _blocks.add(OdtBlock(
          type: OdtBlockType.heading,
          level: level.clamp(1, 6),
          inlines: _paragraphInlines(el),
        ));
        break;
      case 'text:p':
        _blocks.add(OdtBlock(
          type: OdtBlockType.paragraph,
          inlines: _paragraphInlines(el),
        ));
        break;
      case 'text:list':
        _walkList(el, indent);
        break;
      case 'table:table':
        _walkTable(el);
        break;
      case 'text:section':
        for (final child in el.childElements) {
          _walkBlock(child, indent);
        }
        break;
      default:
        break;
    }
  }

  void _walkList(XmlElement listEl, int indent) {
    final ordered =
        _orderedListStyles.contains(listEl.getAttribute('text:style-name'));
    var counter = 0;
    for (final item in listEl.childElements) {
      if (item.qualifiedName != 'text:list-item') continue;
      counter++;
      var markerUsed = false;
      for (final child in item.childElements) {
        switch (child.qualifiedName) {
          case 'text:p':
          case 'text:h':
            _blocks.add(OdtBlock(
              type: OdtBlockType.listItem,
              indent: indent,
              marker: markerUsed ? '' : (ordered ? '$counter.' : '•'),
              inlines: _paragraphInlines(child),
            ));
            markerUsed = true;
            break;
          case 'text:list':
            _walkList(child, indent + 1);
            break;
        }
      }
    }
  }

  void _walkTable(XmlElement tableEl) {
    for (final row in tableEl.findAllElements('table:table-row')) {
      final cells = <String>[];
      for (final cell in row.childElements) {
        if (cell.qualifiedName != 'table:table-cell') continue;
        final inlines = <OdtInline>[];
        for (final p in cell.childElements) {
          if (p.qualifiedName == 'text:p' || p.qualifiedName == 'text:h') {
            _collect(p, _mergeStyle(const _Flags(), p.getAttribute('text:style-name')),
                inlines);
          }
        }
        final text = inlines.map((i) => i.text).join().trim();
        if (text.isNotEmpty) cells.add(text);
      }
      if (cells.isNotEmpty) {
        _blocks.add(OdtBlock(
          type: OdtBlockType.paragraph,
          inlines: [OdtInline(cells.join('    '))],
        ));
      }
    }
  }

  List<OdtInline> _paragraphInlines(XmlElement el) {
    final out = <OdtInline>[];
    final base = _mergeStyle(const _Flags(), el.getAttribute('text:style-name'));
    _collect(el, base, out);
    return out;
  }

  void _collect(XmlElement el, _Flags inherited, List<OdtInline> out) {
    for (final node in el.children) {
      if (node is XmlText) {
        final text = node.value.replaceAll(RegExp(r'\s+'), ' ');
        if (text.isNotEmpty) {
          out.add(OdtInline(
            text,
            bold: inherited.bold,
            italic: inherited.italic,
            underline: inherited.underline,
          ));
        }
      } else if (node is XmlElement) {
        switch (node.qualifiedName) {
          case 'text:span':
            _collect(node, _mergeStyle(inherited, node.getAttribute('text:style-name')),
                out);
            break;
          case 'text:a':
            _collect(node, inherited.copyWith(underline: true), out);
            break;
          case 'text:line-break':
            out.add(const OdtInline('\n'));
            break;
          case 'text:tab':
            out.add(const OdtInline('\t'));
            break;
          case 'text:s':
            final count = int.tryParse(node.getAttribute('text:c') ?? '1') ?? 1;
            out.add(OdtInline(
              ' ' * count,
              bold: inherited.bold,
              italic: inherited.italic,
              underline: inherited.underline,
            ));
            break;
          case 'office:annotation':
          case 'text:tracked-changes':
            break;
          default:
            _collect(node, inherited, out);
        }
      }
    }
  }

  XmlElement? _firstElement(Iterable<XmlElement> elements) {
    for (final e in elements) {
      return e;
    }
    return null;
  }
}
