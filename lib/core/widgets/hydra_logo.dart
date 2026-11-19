import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Logo oficial minimalista de Hydra (squircle degradado azul agua + gota blanca).
class HydraLogo extends StatelessWidget {
  const HydraLogo({
    super.key,
    this.size = 80,
    this.showShadow = true,
  });

  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.25;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.primary,
            AppColors.primaryDeep,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: size * 0.32,
                  offset: Offset(0, size * 0.12),
                ),
              ]
            : null,
      ),
      child: CustomPaint(
        painter: _HydraDropPainter(),
      ),
    );
  }
}

class _HydraDropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final dropPath = Path()
      ..moveTo(w * 0.50, h * 0.20)
      ..cubicTo(
        w * 0.50,
        h * 0.20,
        w * 0.275,
        h * 0.455,
        w * 0.275,
        h * 0.60,
      )
      ..cubicTo(
        w * 0.275,
        h * 0.725,
        w * 0.376,
        h * 0.82,
        w * 0.50,
        h * 0.82,
      )
      ..cubicTo(
        w * 0.624,
        h * 0.82,
        w * 0.725,
        h * 0.725,
        w * 0.725,
        h * 0.60,
      )
      ..cubicTo(
        w * 0.725,
        h * 0.455,
        w * 0.50,
        h * 0.20,
        w * 0.50,
        h * 0.20,
      )
      ..close();

    final dropPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(dropPath, dropPaint);

    // Brillo interior sutil
    final highlightPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;

    final highlightPath = Path()
      ..moveTo(w * 0.39, h * 0.61)
      ..quadraticBezierTo(w * 0.395, h * 0.71, w * 0.49, h * 0.72);
    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
