import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Logo oficial minimalista de Hydra (usa el ícono de la app con sombra suave).
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
    final radius = size * 0.24;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          'assets/icon/hydra_icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => DecoratedBox(
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
              ),
            ),
            child: Icon(
              Icons.water_drop_rounded,
              size: size * 0.52,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
