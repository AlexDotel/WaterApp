import 'package:material_ui/material_ui.dart';

class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
}

abstract final class AppAchievements {
  static const List<AchievementDef> all = [
    AchievementDef(
      id: 'first_drop',
      title: 'Primer sorbo',
      description: 'Registra tu primer vaso de agua.',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF0EA5E9),
    ),
    AchievementDef(
      id: 'early_bird',
      title: 'Madrugador',
      description: 'Toma agua antes de las 8:30 AM.',
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFF59E0B),
    ),
    AchievementDef(
      id: 'first_goal',
      title: 'Meta diaria',
      description: 'Completa el 100% de tu meta en un día.',
      icon: Icons.verified_rounded,
      color: Color(0xFF10B981),
    ),
    AchievementDef(
      id: 'streak_3',
      title: 'En ritmo',
      description: 'Mantén una racha de 3 días seguidos.',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFF97316),
    ),
    AchievementDef(
      id: 'streak_7',
      title: 'Semana perfecta',
      description: 'Cumple tu meta 7 días consecutivos.',
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFF8B5CF6),
    ),
    AchievementDef(
      id: 'total_25l',
      title: '25 Litros',
      description: 'Acumula 25 litros de hidratación total.',
      icon: Icons.waves_rounded,
      color: Color(0xFF06B6D4),
    ),
    AchievementDef(
      id: 'variety',
      title: 'Explorador',
      description: 'Registra al menos 3 tipos de bebida distintos.',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFEC4899),
    ),
    AchievementDef(
      id: 'streak_30',
      title: 'Hábito sólido',
      description: 'Alcanza una racha de 30 días.',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFEAB308),
    ),
  ];
}
