import 'package:flutter/material.dart';

/// Editor de cantos arrastáveis sobre a imagem, para ajuste manual
/// do recorte. Trabalha com coordenadas normalizadas (0..1).
class CornerEditor extends StatefulWidget {
  const CornerEditor({
    super.key,
    required this.corners,
    required this.onChanged,
    required this.child,
  });

  /// Cantos TL, TR, BR, BL normalizados.
  final List<Offset> corners;
  final ValueChanged<List<Offset>> onChanged;

  /// A imagem sendo editada (deve preencher o espaço disponível).
  final Widget child;

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
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              CustomPaint(
                painter: _EditQuadPainter(
                  corners: widget.corners,
                  activeIndex: _dragIndex,
                  color: Theme.of(context).colorScheme.primary,
                  handleRadius: _handleRadius,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EditQuadPainter extends CustomPainter {
  _EditQuadPainter({
    required this.corners,
    required this.activeIndex,
    required this.color,
    required this.handleRadius,
  });

  final List<Offset> corners;
  final int? activeIndex;
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

    // Escurece a área fora do recorte.
    final overlay = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      path,
    );
    canvas.drawPath(
      overlay,
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    for (var i = 0; i < 4; i++) {
      final active = i == activeIndex;
      canvas.drawCircle(
        pts[i],
        active ? handleRadius * 1.4 : handleRadius,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        pts[i],
        (active ? handleRadius * 1.4 : handleRadius) - 3,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_EditQuadPainter oldDelegate) =>
      oldDelegate.corners != corners ||
      oldDelegate.activeIndex != activeIndex;
}
