import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';

/// Modos de leitura aplicados como filtro de cor sobre o documento.
enum _ModoLeitura { original, sepia, noturno }

/// Ações do menu "mais opções" da barra superior.
enum _AcaoMenu { indice, modoOriginal, modoSepia, modoNoturno }

/// Leitor de PDF baseado em pdfrx: rolagem vertical contínua, busca com realce,
/// ir-para-página, zoom, modo de leitura, índice (outline), seleção/cópia de
/// texto e suporte a PDFs protegidos por senha.
///
/// IMPORTANTE (limitação do pdfrx 2.4.8 neste aparelho): reconstruir o
/// [PdfViewer] — ou reconstruir reactivamente widgets que leem o estado de
/// layout do controller (ex.: `calcMatrixFitWidthForPage`) — deixa o conteúdo
/// em branco. Por isso este `State` nunca usa `setState`, o viewer é uma
/// instância única e estável, e toda a cromagem é atualizada por
/// `ValueNotifier` (sem recálculo de layout).
class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({super.key, required this.path});

  final String path;

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final PdfViewerController _viewer = PdfViewerController();

  // Instâncias estáveis do pdfrx (criadas uma única vez).
  late final PdfDocumentRef _documentRef;
  late final PdfViewerParams _params;
  late final Widget _viewerWidget;

  final TextEditingController _buscaControlador = TextEditingController();

  // Estado reativo (atualizado sem `setState`).
  final ValueNotifier<int> _pagina = ValueNotifier<int>(1);
  final ValueNotifier<bool> _buscando = ValueNotifier<bool>(false);
  final ValueNotifier<_ModoLeitura> _modo =
      ValueNotifier<_ModoLeitura>(_ModoLeitura.original);
  final ValueNotifier<ColorFilter?> _filtro = ValueNotifier<ColorFilter?>(null);
  final ValueNotifier<_BuscaEstado> _buscaEstado = ValueNotifier<_BuscaEstado>(_BuscaEstado());
  final ValueNotifier<List<PdfOutlineNode>> _itensIndice =
      ValueNotifier<List<PdfOutlineNode>>(const []);
  final ValueNotifier<bool> _indiceCarregado = ValueNotifier<bool>(false);

  /// "Tique" que força a barra inferior a se atualizar (página/zoom) sem
  /// reconstruir o viewer nem chamar métodos de layout do controller.
  final ValueNotifier<int> _versao = ValueNotifier<int>(0);

  PdfTextSearcher? _searcher;

  String get _nomeArquivo {
    final segmento = widget.path.split('/').last;
    return segmento.isEmpty ? 'PDF' : segmento;
  }

  // ------------------------------------------------------------ inicialização

  @override
  void initState() {
    super.initState();
    _documentRef = PdfDocumentRefFile(
      widget.path,
      passwordProvider: _pedirSenha,
    );
    _params = PdfViewerParams(
      textSelectionParams: const PdfTextSelectionParams(enabled: true),
      pagePaintCallbacks: [_pintarRealces],
      loadingBannerBuilder: (context, baixados, total) {
        return const Center(child: CircularProgressIndicator());
      },
      errorBannerBuilder: (context, erro, pilha, ref) {
        final detalhe = erro is PdfPasswordException ? '' : erro.toString();
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              AppLocalizations.of(context).openDocError(detalhe).trim(),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
      onPageChanged: _aoMudarPagina,
      onDocumentLoadFinished: _aoTerminarCarga,
      onInteractionEnd: (details) => _versao.value++,
    );

    final viewer = PdfViewer(
      _documentRef,
      controller: _viewer,
      params: _params,
    );

    // O filtro de cor do modo leitura é aplicado sobre o viewer estável.
    _viewerWidget = ValueListenableBuilder<ColorFilter?>(
      valueListenable: _filtro,
      builder: (context, filtro, child) {
        final interno = child ?? viewer;
        if (filtro == null) return interno;
        return ColorFiltered(colorFilter: filtro, child: interno);
      },
      child: viewer,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  // --------------------------------------------------------------- busca ----

  void _garantirSearcher() {
    if (_searcher != null) return;
    final searcher = PdfTextSearcher(_viewer)..addListener(_aoMudarResultado);
    _searcher = searcher;
    _atualizarBuscaEstado();
  }

  void _aoMudarResultado() {
    _atualizarBuscaEstado();
  }

  void _atualizarBuscaEstado() {
    final s = _searcher;
    if (s == null) {
      _buscaEstado.value = _BuscaEstado();
      return;
    }
    _buscaEstado.value = _BuscaEstado(
      buscando: s.isSearching,
      indice: s.currentIndex,
      total: s.matches.length,
      temTermo: _buscaControlador.text.trim().isNotEmpty,
    );
  }

  void _buscar(String termo) {
    _garantirSearcher();
    final resultados = _searcher;
    if (resultados == null) return;
    final limpo = termo.trim();
    if (limpo.isEmpty) {
      resultados.resetTextSearch();
      _atualizarBuscaEstado();
      return;
    }
    resultados.startTextSearch(limpo, caseInsensitive: true);
  }

  Future<void> _moverResultado(int deslocamento) async {
    final resultados = _searcher;
    if (resultados == null || !resultados.hasMatches) return;
    final total = resultados.matches.length;
    final atual = resultados.currentIndex ?? 0;
    var alvo = (atual + deslocamento) % total;
    if (alvo < 0) alvo += total;
    await resultados.goToMatchOfIndex(alvo);
    _atualizarBuscaEstado();
  }

  void _fecharBusca() {
    _searcher?.resetTextSearch();
    _buscaControlador.clear();
    _atualizarBuscaEstado();
    _buscando.value = false;
  }

  /// Realça os termos encontrados pela busca; não faz nada sem busca ativa.
  void _pintarRealces(ui.Canvas canvas, Rect pageRect, PdfPage page) {
    _searcher?.pageTextMatchPaintCallback(canvas, pageRect, page);
  }

  String _textoResultado(_BuscaEstado estado, AppLocalizations l) {
    if (estado.buscando) return '…';
    if (estado.total > 0 && estado.indice != null) {
      return l.pdfResultsCount(estado.indice! + 1, estado.total);
    }
    if (estado.temTermo) return l.pdfNoResults;
    return l.pdfResultsCount(0, 0);
  }

  // ------------------------------------------------------------ carregar ----

  void _aoMudarPagina(int? pagina) {
    if (pagina == null) return;
    if (_pagina.value != pagina) _pagina.value = pagina;
    _versao.value++;
  }

  void _aoTerminarCarga(PdfDocumentRef ref, bool sucesso) {
    if (!mounted) return;
    if (sucesso) {
      _garantirSearcher();
      _pagina.value = _viewer.pageNumber ?? 1;
      _versao.value++;
      _carregarIndice();
    }
  }

  Future<void> _carregarIndice() async {
    final itens = await _viewer.useDocument(
      (document) => document.loadOutline(),
    );
    if (!mounted) return;
    _itensIndice.value = itens ?? const [];
    _indiceCarregado.value = true;
  }

  // --------------------------------------------------------------- senha ----

  Future<String?> _pedirSenha() async {
    if (!mounted) return null;
    final l = AppLocalizations.of(context);
    final campo = TextEditingController();
    final senha = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l.pdfPasswordTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.pdfPasswordMessage),
              const SizedBox(height: 16),
              TextField(
                controller: campo,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                onSubmitted: (valor) =>
                    Navigator.of(dialogContext).pop(valor),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(campo.text),
              child: Text(l.pdfPasswordOk),
            ),
          ],
        );
      },
    );
    campo.dispose();
    return senha;
  }

  // ---------------------------------------------------------- navegação -----

  Future<void> _irParaPagina() async {
    final l = AppLocalizations.of(context);
    final total = _viewer.isReady ? _viewer.pageCount : 0;
    if (total <= 0) return;
    final campo = TextEditingController();
    final escolha = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l.pdfGoToPageTitle),
          content: TextField(
            controller: campo,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: '1 – $total'),
            onSubmitted: (valor) {
              final pagina = int.tryParse(valor);
              if (pagina != null) Navigator.of(dialogContext).pop(pagina);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () {
                final pagina = int.tryParse(campo.text);
                if (pagina != null) Navigator.of(dialogContext).pop(pagina);
              },
              child: Text(l.pdfGoToPageConfirm),
            ),
          ],
        );
      },
    );
    if (escolha == null || !_viewer.isReady) return;
    final pagina = escolha.clamp(1, _viewer.pageCount);
    await _viewer.goToPage(pageNumber: pagina, anchor: PdfPageAnchor.top);
  }

  void _moverPagina(int deslocamento) {
    final total = _viewer.isReady ? _viewer.pageCount : 0;
    if (total <= 0) return;
    final alvo = (_pagina.value + deslocamento).clamp(1, total);
    _viewer.goToPage(pageNumber: alvo, anchor: PdfPageAnchor.top);
  }

  Future<void> _ajustarLargura() async {
    if (!_viewer.isReady) return;
    final pagina = _viewer.pageNumber ?? 1;
    await _viewer.goTo(
      _viewer.calcMatrixFitWidthForPage(pageNumber: pagina),
    );
  }

  // ------------------------------------------------------------- índice -----

  Future<void> _abrirIndice() async {
    final l = AppLocalizations.of(context);
    final itens = <_ItemIndice>[];
    void aplainar(List<PdfOutlineNode> nos, int nivel) {
      for (final no in nos) {
        itens.add(_ItemIndice(no, nivel));
        aplainar(no.children, nivel + 1);
      }
    }

    aplainar(_itensIndice.value, 0);
    if (itens.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  l.pdfOutline,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: itens.length,
                  itemBuilder: (context, indice) {
                    final item = itens[indice];
                    return ListTile(
                      dense: true,
                      title: Text(
                        item.no.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: item.nivel == 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      contentPadding: EdgeInsets.only(
                        left: 16.0 + item.nivel * 16.0,
                        right: 16,
                      ),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        final destino = item.no.dest;
                        if (destino != null) _viewer.goToDest(destino);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------- leitura ----

  ColorFilter? _filtroDeCor(_ModoLeitura modo) {
    switch (modo) {
      case _ModoLeitura.original:
        return null;
      case _ModoLeitura.sepia:
        return const ColorFilter.matrix(<double>[
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case _ModoLeitura.noturno:
        return const ColorFilter.matrix(<double>[
          -1, 0, 0, 0, 1,
          0, -1, 0, 0, 1,
          0, 0, -1, 0, 1,
          0, 0, 0, 1, 0,
        ]);
    }
  }

  void _selecionarModo(_ModoLeitura modo) {
    _modo.value = modo;
    _filtro.value = _filtroDeCor(modo);
  }

  // ------------------------------------------------------------------ UI ----

  void _aoSelecionarMenu(_AcaoMenu acao) {
    switch (acao) {
      case _AcaoMenu.indice:
        _abrirIndice();
      case _AcaoMenu.modoOriginal:
        _selecionarModo(_ModoLeitura.original);
      case _AcaoMenu.modoSepia:
        _selecionarModo(_ModoLeitura.sepia);
      case _AcaoMenu.modoNoturno:
        _selecionarModo(_ModoLeitura.noturno);
    }
  }

  PopupMenuEntry<_AcaoMenu> _itemDeMenu(
    _AcaoMenu acao,
    IconData icone,
    String texto,
  ) {
    return PopupMenuItem<_AcaoMenu>(
      value: acao,
      child: Row(
        children: [
          Icon(icone),
          const SizedBox(width: 12),
          Text(texto),
        ],
      ),
    );
  }

  PreferredSizeWidget _barraSuperior(AppLocalizations l) {
    return AppBar(
      leading: ValueListenableBuilder<bool>(
        valueListenable: _buscando,
        builder: (context, buscando, _) {
          if (!buscando) return const SizedBox.shrink();
          return IconButton(
            icon: const Icon(Icons.close),
            tooltip: l.pdfExitSearch,
            onPressed: _fecharBusca,
          );
        },
      ),
      titleSpacing: 0,
      title: ValueListenableBuilder<bool>(
        valueListenable: _buscando,
        builder: (context, buscando, _) {
          if (!buscando) {
            return Text(_nomeArquivo, overflow: TextOverflow.ellipsis);
          }
          return TextField(
            controller: _buscaControlador,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l.pdfSearchHint,
              border: InputBorder.none,
            ),
            onChanged: _buscar,
            onSubmitted: _buscar,
          );
        },
      ),
      actions: [
        ValueListenableBuilder<bool>(
          valueListenable: _buscando,
          builder: (context, buscando, _) {
            if (buscando) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: ValueListenableBuilder<_BuscaEstado>(
                        valueListenable: _buscaEstado,
                        builder: (context, estado, _) {
                          return Text(
                            _textoResultado(estado, l),
                            style: Theme.of(context).textTheme.labelMedium,
                          );
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up),
                    tooltip: l.pdfPreviousResult,
                    onPressed: () => _moverResultado(-1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    tooltip: l.pdfNextResult,
                    onPressed: () => _moverResultado(1),
                  ),
                ],
              );
            }
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: l.pdfSearch,
                  onPressed: () => _buscando.value = true,
                ),
                IconButton(
                  icon: const Icon(Icons.ios_share),
                  tooltip: l.share,
                  onPressed: () async {
                    await SharePlus.instance.share(
                      ShareParams(files: [XFile(widget.path)]),
                    );
                  },
                ),
                PopupMenuButton<_AcaoMenu>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: l.pdfMoreOptions,
                  onSelected: _aoSelecionarMenu,
                  itemBuilder: (context) {
                    final itens = <PopupMenuEntry<_AcaoMenu>>[];
                    if (_indiceCarregado.value && _itensIndice.value.isNotEmpty) {
                      itens.add(_itemDeMenu(_AcaoMenu.indice, Icons.list, l.pdfOutline));
                    }
                    if (itens.isNotEmpty) itens.add(const PopupMenuDivider());
                    itens
                      ..add(_itemDeMenu(
                        _AcaoMenu.modoOriginal,
                        Icons.remove_red_eye_outlined,
                        l.pdfModeOriginal,
                      ))
                      ..add(_itemDeMenu(
                        _AcaoMenu.modoSepia,
                        Icons.auto_stories_outlined,
                        l.pdfModeSepia,
                      ))
                      ..add(_itemDeMenu(
                        _AcaoMenu.modoNoturno,
                        Icons.dark_mode_outlined,
                        l.pdfModeNight,
                      ));
                    return itens;
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget? _barraInferior(AppLocalizations l) {
    final total = _viewer.isReady ? _viewer.pageCount : 0;
    if (total <= 0) return null;
    final esquema = Theme.of(context).colorScheme;
    final pag = _pagina.value.clamp(1, total);

    return Material(
      color: esquema.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: l.pdfPreviousPage,
                onPressed: pag > 1 ? () => _moverPagina(-1) : null,
              ),
              Expanded(
                child: TextButton(
                  onPressed: _irParaPagina,
                  child: Text(
                    l.pdfPageOf(pag, total),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: l.pdfNextPage,
                onPressed: pag < total ? () => _moverPagina(1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in),
                tooltip: l.pdfZoomIn,
                onPressed: () => _viewer.zoomUp(),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_out),
                tooltip: l.pdfZoomOut,
                onPressed: () => _viewer.zoomDown(),
              ),
              IconButton(
                icon: const Icon(Icons.settings_backup_restore),
                tooltip: l.pdfFitWidth,
                onPressed: _ajustarLargura,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final brilho = _modo.value == _ModoLeitura.noturno
        ? Brightness.dark
        : Theme.of(context).brightness;

    return Theme(
      data: buildAppTheme(brilho),
      child: Scaffold(
        appBar: _barraSuperior(l),
        body: _viewerWidget,
        bottomNavigationBar: ListenableBuilder(
          listenable: _versao,
          builder: (context, _) => _barraInferior(l) ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Estado reativo da busca (resultados/concorrência).
class _BuscaEstado {
  const _BuscaEstado({
    this.buscando = false,
    this.indice,
    this.total = 0,
    this.temTermo = false,
  });

  final bool buscando;
  final int? indice;
  final int total;
  final bool temTermo;
}

/// Item do índice (outline) já achatado, com o nível de aninhamento.
class _ItemIndice {
  const _ItemIndice(this.no, this.nivel);

  final PdfOutlineNode no;
  final int nivel;
}
