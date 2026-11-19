import 'package:flutter/material.dart';

/// Tipos de bebida soportados y su factor de hidratación efectiva.
enum DrinkType {
  water(
    id: 'water',
    label: 'Agua',
    hydrationFactor: 1.0,
    icon: Icons.water_drop_rounded,
    color: Color(0xFF0EA5E9),
  ),
  sparkling(
    id: 'sparkling',
    label: 'Agua con gas',
    hydrationFactor: 1.0,
    icon: Icons.bubble_chart_rounded,
    color: Color(0xFF06B6D4),
  ),
  tea(
    id: 'tea',
    label: 'Té / Infusión',
    hydrationFactor: 0.95,
    icon: Icons.emoji_food_beverage_rounded,
    color: Color(0xFF10B981),
  ),
  coffee(
    id: 'coffee',
    label: 'Café',
    hydrationFactor: 0.80,
    icon: Icons.coffee_rounded,
    color: Color(0xFF92400E),
  ),
  electrolytes(
    id: 'electrolytes',
    label: 'Electrolitos',
    hydrationFactor: 1.10,
    icon: Icons.bolt_rounded,
    color: Color(0xFF6366F1),
  );

  const DrinkType({
    required this.id,
    required this.label,
    required this.hydrationFactor,
    required this.icon,
    required this.color,
  });

  final String id;
  final String label;
  final double hydrationFactor;
  final IconData icon;
  final Color color;

  String get factorLabel => '${(hydrationFactor * 100).round()}%';

  static DrinkType fromId(String? id) {
    return DrinkType.values.firstWhere(
      (e) => e.id == id,
      orElse: () => DrinkType.water,
    );
  }
}
