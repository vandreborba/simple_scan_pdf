import 'package:flutter/material.dart';

/// Desenha o quadrilátero detectado sobre o preview da câmera.
class QuadPainter extends CustomPainter {
  QuadPainter({required this.corners, required this.color});

  /// Cantos normalizados (0..1) em ordem TL, TR, BR, BL, ou null.
  final List<Offset>? corners;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = corners;
    if (pts == null || pts.length != 4) return;

    final path = Path()
      ..moveTo(pts[0].dx * size.width, pts[0].dy * size.height);
    for (var i = 1; i < 4; i++) {
      path.lineTo(pts[i].dx * size.width, pts[i].dy * size.height);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(QuadPainter oldDelegate) =>
      oldDelegate.corners != corners || oldDelegate.color != color;
}
