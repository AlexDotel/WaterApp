import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/hydration_utils.dart';

/// Visualizador circular minimalista con animación de doble ola líquida.
class LiquidProgressVessel extends StatefulWidget {
  const LiquidProgressVessel({
    super.key,
    required this.currentMl,
    required this.goalMl,
    required this.glassSizeMl,
    required this.useOunces,
  });

  final int currentMl;
  final int goalMl;
  final int glassSizeMl;
  final bool useOunces;

  @override
  State<LiquidProgressVessel> createState() => _LiquidProgressVesselState();
}

class _LiquidProgressVesselState extends State<LiquidProgressVessel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ratio = widget.goalMl > 0
        ? (widget.currentMl / widget.goalMl).clamp(0.0, 1.0)
        : 0.0;
    final percent = widget.goalMl > 0
        ? ((widget.currentMl / widget.goalMl) * 100).round()
        : 0;
    final glasses = widget.glassSizeMl > 0
        ? (widget.currentMl / widget.glassSizeMl)
        : 0.0;
    final goalGlasses =
        widget.glassSizeMl > 0 ? (widget.goalMl / widget.glassSizeMl).ceil() : 8;
    final glassesLabel = glasses == glasses.roundToDouble()
        ? glasses.toInt().toString()
        : glasses.toStringAsFixed(1);

    final completed = widget.currentMl >= widget.goalMl;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: ratio),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, animatedRatio, _) {
        final useLightText = animatedRatio > 0.56;
        final primaryTextColor = useLightText
            ? Colors.white
            : theme.colorScheme.onSurface;
        final secondaryTextColor = useLightText
            ? Colors.white.withValues(alpha: 0.88)
            : theme.textTheme.bodySmall?.color;

        return Container(
          width: 244,
          height: 244,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surface,
            border: Border.all(
              color: completed
                  ? AppColors.success.withValues(alpha: 0.55)
                  : theme.colorScheme.outline,
              width: completed ? 2 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (completed ? AppColors.success : AppColors.primary)
                    .withValues(alpha: isDark ? 0.14 : 0.10),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipOval(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _LiquidWavePainter(
                          progress: animatedRatio,
                          phase: _waveController.value * 2 * math.pi,
                          backColor: (completed
                                  ? AppColors.success
                                  : AppColors.primaryLight)
                              .withValues(alpha: isDark ? 0.45 : 0.35),
                          frontColor: completed
                              ? AppColors.success
                              : AppColors.primary,
                          backgroundColor: isDark
                              ? AppColors.darkSurfaceMuted.withValues(alpha: 0.45)
                              : AppColors.primarySoftLight.withValues(alpha: 0.45),
                        ),
                      );
                    },
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (useLightText
                                ? Colors.black.withValues(alpha: 0.16)
                                : theme.colorScheme.surface
                                    .withValues(alpha: 0.85)),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '$percent%',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: useLightText
                              ? Colors.white
                              : (completed
                                  ? AppColors.success
                                  : theme.colorScheme.primary),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: glassesLabel,
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                              height: 1.0,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          TextSpan(
                            text: ' / $goalGlasses',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: secondaryTextColor,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'vasos hoy',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${HydrationUtils.formatVolumeExact(widget.currentMl, useOunces: widget.useOunces)} · meta ${HydrationUtils.formatVolume(widget.goalMl, useOunces: widget.useOunces)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: secondaryTextColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LiquidWavePainter extends CustomPainter {
  _LiquidWavePainter({
    required this.progress,
    required this.phase,
    required this.backColor,
    required this.frontColor,
    required this.backgroundColor,
  });

  final double progress;
  final double phase;
  final Color backColor;
  final Color frontColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    if (progress <= 0.005) return;

    final baseHeight = size.height * (1.0 - progress);
    final amplitude = (progress >= 0.99 || progress <= 0.02) ? 2.5 : 7.5;

    _drawWave(
      canvas: canvas,
      size: size,
      baseHeight: baseHeight,
      amplitude: amplitude * 0.85,
      phaseShift: phase + math.pi * 0.75,
      color: backColor,
    );
    _drawWave(
      canvas: canvas,
      size: size,
      baseHeight: baseHeight,
      amplitude: amplitude,
      phaseShift: phase,
      color: frontColor,
    );
  }

  void _drawWave({
    required Canvas canvas,
    required Size size,
    required double baseHeight,
    required double amplitude,
    required double phaseShift,
    required Color color,
  }) {
    final path = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 2) {
      final y = baseHeight +
          math.sin((x / size.width) * 2 * math.pi + phaseShift) * amplitude;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phase != phase ||
        oldDelegate.frontColor != frontColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
