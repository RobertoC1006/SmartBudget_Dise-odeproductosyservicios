import 'package:flutter/material.dart';

class HeaderBackgroundPainter extends CustomPainter {
  const HeaderBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Top-left waving curve
    final paint1 = Paint()
      ..color = const Color(0xFFE2F3DA).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, 0);
    path1.lineTo(size.width, 0);
    path1.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.12,
      size.width * 0.45,
      size.height * 0.08,
    );
    path1.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.05,
      0,
      size.height * 0.14,
    );
    path1.close();
    canvas.drawPath(path1, paint1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
