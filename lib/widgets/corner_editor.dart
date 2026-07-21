import 'package:flutter/material.dart';

import '../models/scan_models.dart';

/// Editor de cantos arrastáveis sobre a imagem, para ajuste manual
/// do recorte. Trabalha com coordenadas normalizadas (0..1).
class CornerEditor extends StatefulWidget {
  const CornerEditor({
    super.key,
    required this.corners,
    required this.onChanged,
    required this.child,
    this.posicaoLupa = PosicaoLupa.proximoAoDedo,
  });

  /// Cantos TL, TR, BR, BL normalizados.
  final List<Offset> corners;
  final ValueChanged<List<Offset>> onChanged;

  /// A imagem sendo editada (deve preencher o espaço disponível).
  final Widget child;

  /// Onde a lupa aparece enquanto um canto é arrastado.
  final PosicaoLupa posicaoLupa;

  @override
  State<CornerEditor> createState() => _CornerEditorState();
}

class _CornerEditorState extends State<CornerEditor> {
  int? _dragIndex;

  static const _touchRadius = 36.0;
  static const _handleRadius = 13.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            final local = details.localPosition;
            var bestDist = _touchRadius;
            int? best;
            for (var i = 0; i < 4; i++) {
              final p = Offset(
                widget.corners[i].dx * size.width,
                widget.corners[i].dy * size.height,
              );
              final d = (p - local).distance;
              if (d < bestDist) {
                bestDist = d;
                best = i;
              }
            }
            setState(() => _dragIndex = best);
          },
          onPanUpdate: (details) {
            final i = _dragIndex;
            if (i == null) return;
            final local = details.localPosition;
            final updated = List<Offset>.from(widget.corners);
            updated[i] = Offset(
              (local.dx / size.width).clamp(0.0, 1.0),
              (local.dy / size.height).clamp(0.0, 1.0),
            );
            widget.onChanged(updated);
          },
          onPanEnd: (_) => setState(() => _dragIndex = null),
          onPanCancel: () => setState(() => _dragIndex = null),
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              CustomPaint(
                painter: _EditQuadPainter(
                  corners: widget.corners,
                  activeIndex: _dragIndex,
                  // Enquanto arrasta, a lupa amplia estes pixels — sem
                  // escurecer fora do recorte, para o zoom ficar legível.
                  escurecerFora: _dragIndex == null,
                  color: Theme.of(context).colorScheme.primary,
                  handleRadius: _handleRadius,
                ),
              ),
              if (_dragIndex != null) _buildMagnifier(size, _dragIndex!),
            ],
          ),
        );
      },
    );
  }

  /// Lupa flutuante que amplia a região em volta do canto sendo arrastado.
  /// Usa [RawMagnifier], que amplia os pixels já renderizados (imagem +
  /// linhas), então não precisa refazer a matemática de rotação/escala.
  Widget _buildMagnifier(Size size, int index) {
    const loupeSize = 120.0;
    const loupeRadius = loupeSize / 2;
    // Espaço generoso entre o dedo e a lupa (modo perto do dedo).
    const gap = 48.0;
    const margemCanto = 12.0;
    final color = Theme.of(context).colorScheme.primary;

    final focal = Offset(
      widget.corners[index].dx * size.width,
      widget.corners[index].dy * size.height,
    );

    final center = switch (widget.posicaoLupa) {
      PosicaoLupa.cantoOposto => _centroCantoOposto(
          size,
          focal,
          loupeRadius,
          margemCanto,
        ),
      PosicaoLupa.proximoAoDedo => _centroPertoDoDedo(
          size,
          focal,
          loupeRadius,
          gap,
        ),
    };

    return Positioned(
      left: center.dx - loupeRadius,
      top: center.dy - loupeRadius,
      child: IgnorePointer(
        child: RawMagnifier(
          size: const Size(loupeSize, loupeSize),
          magnificationScale: 2,
          // O ponto observado, relativo ao centro da lupa (ver _RenderMagnification).
          focalPointOffset: focal - center,
          decoration: const MagnifierDecoration(
            shape: CircleBorder(
              side: BorderSide(color: Colors.white, width: 2.5),
            ),
            shadows: [
              BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 1),
            ],
          ),
          child: CustomPaint(painter: _CrosshairPainter(color)),
        ),
      ),
    );
  }

  /// Acima do toque; se não couber, desce para baixo. Mantém a lupa na tela.
  Offset _centroPertoDoDedo(
    Size size,
    Offset focal,
    double loupeRadius,
    double gap,
  ) {
    var centerY = focal.dy - gap - loupeRadius;
    if (centerY - loupeRadius < 0) {
      centerY = focal.dy + gap + loupeRadius;
    }
    final maxX = size.width - loupeRadius;
    final maxY = size.height - loupeRadius;
    return Offset(
      maxX > loupeRadius ? focal.dx.clamp(loupeRadius, maxX) : size.width / 2,
      maxY > loupeRadius ? centerY.clamp(loupeRadius, maxY) : size.height / 2,
    );
  }

  /// Canto da imagem no quadrante oposto ao dedo.
  Offset _centroCantoOposto(
    Size size,
    Offset focal,
    double loupeRadius,
    double margem,
  ) {
    final maxX = size.width - loupeRadius - margem;
    final maxY = size.height - loupeRadius - margem;
    final min = loupeRadius + margem;
    return Offset(
      maxX > min
          ? (focal.dx < size.width / 2 ? maxX : min)
          : size.width / 2,
      maxY > min
          ? (focal.dy < size.height / 2 ? maxY : min)
          : size.height / 2,
    );
  }
}

/// Mira desenhada sobre o conteúdo ampliado, marcando o ponto exato.
class _CrosshairPainter extends CustomPainter {
  _CrosshairPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const r = 12.0;
    final line = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), line);
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), line);
    canvas.drawCircle(c, 3, line);
  }

  @override
  bool shouldRepaint(_CrosshairPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _EditQuadPainter extends CustomPainter {
  _EditQuadPainter({
    required this.corners,
    required this.activeIndex,
    required this.escurecerFora,
    required this.color,
    required this.handleRadius,
  });

  final List<Offset> corners;
  final int? activeIndex;
  final bool escurecerFora;
  final Color color;
  final double handleRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = corners
        .map((c) => Offset(c.dx * size.width, c.dy * size.height))
        .toList();

    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < 4; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    path.close();

    // Escurece a área fora do recorte (desligado durante o arraste da lupa).
    if (escurecerFora) {
      final overlay = Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        path,
      );
      canvas.drawPath(
        overlay,
        Paint()..color = Colors.black.withValues(alpha: 0.45),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    for (var i = 0; i < 4; i++) {
      final active = i == activeIndex;
      if (active) {
        // Anel vazado: deixa o ponto exato à mostra (inclusive dentro da lupa).
        final r = handleRadius * 1.5;
        canvas.drawCircle(
          pts[i],
          r,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
        canvas.drawCircle(
          pts[i],
          r,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      } else {
        canvas.drawCircle(pts[i], handleRadius, Paint()..color = Colors.white);
        canvas.drawCircle(pts[i], handleRadius - 3, Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(_EditQuadPainter oldDelegate) =>
      oldDelegate.corners != corners ||
      oldDelegate.activeIndex != activeIndex ||
      oldDelegate.escurecerFora != escurecerFora;
}
