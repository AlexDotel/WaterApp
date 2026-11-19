import 'package:material_ui/material_ui.dart';

enum ActivityLevel {
  sedentary(label: 'Suave', bonusMl: 0, description: 'Oficina o poca actividad'),
  moderate(label: 'Moderado', bonusMl: 300, description: 'Caminatas o 2-3 días de ejercicio'),
  active(label: 'Activo', bonusMl: 600, description: 'Entrenamiento 4-5 días/semana'),
  veryActive(label: 'Intenso', bonusMl: 900, description: 'Deporte diario o clima caluroso');

  const ActivityLevel({
    required this.label,
    required this.bonusMl,
    required this.description,
  });

  final String label;
  final int bonusMl;
  final String description;

  static ActivityLevel fromName(String? name) {
    return ActivityLevel.values.firstWhere(
      (e) => e.name == name,
      orElse: () => ActivityLevel.moderate,
    );
  }
}

class UserSettings {
  const UserSettings({
    this.dailyGoalMl = 2000,
    this.glassSizeMl = 250,
    this.useOunces = false,
    this.themeMode = ThemeMode.system,
    this.remindersEnabled = true,
    this.reminderIntervalMinutes = 120,
    this.wakeHour = 8,
    this.sleepHour = 22,
    this.silenceRemindersOnGoal = true,
    this.onboardingCompleted = false,
    this.weightKg = 70,
    this.activityLevel = ActivityLevel.moderate,
    this.streakFreezeEnabled = true,
  });

  final int dailyGoalMl;
  final int glassSizeMl;
  final bool useOunces;
  final ThemeMode themeMode;
  final bool remindersEnabled;
  final int reminderIntervalMinutes;
  final int wakeHour;
  final int sleepHour;
  final bool silenceRemindersOnGoal;
  final bool onboardingCompleted;
  final int weightKg;
  final ActivityLevel activityLevel;
  final bool streakFreezeEnabled;

  int get dailyGoalGlasses => (dailyGoalMl / glassSizeMl).ceil();

  UserSettings copyWith({
    int? dailyGoalMl,
    int? glassSizeMl,
    bool? useOunces,
    ThemeMode? themeMode,
    bool? remindersEnabled,
    int? reminderIntervalMinutes,
    int? wakeHour,
    int? sleepHour,
    bool? silenceRemindersOnGoal,
    bool? onboardingCompleted,
    int? weightKg,
    ActivityLevel? activityLevel,
    bool? streakFreezeEnabled,
  }) {
    return UserSettings(
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      glassSizeMl: glassSizeMl ?? this.glassSizeMl,
      useOunces: useOunces ?? this.useOunces,
      themeMode: themeMode ?? this.themeMode,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderIntervalMinutes:
          reminderIntervalMinutes ?? this.reminderIntervalMinutes,
      wakeHour: wakeHour ?? this.wakeHour,
      sleepHour: sleepHour ?? this.sleepHour,
      silenceRemindersOnGoal:
          silenceRemindersOnGoal ?? this.silenceRemindersOnGoal,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      streakFreezeEnabled: streakFreezeEnabled ?? this.streakFreezeEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'dailyGoalMl': dailyGoalMl,
        'glassSizeMl': glassSizeMl,
        'useOunces': useOunces,
        'themeMode': themeMode.name,
        'remindersEnabled': remindersEnabled,
        'reminderIntervalMinutes': reminderIntervalMinutes,
        'wakeHour': wakeHour,
        'sleepHour': sleepHour,
        'silenceRemindersOnGoal': silenceRemindersOnGoal,
        'onboardingCompleted': onboardingCompleted,
        'weightKg': weightKg,
        'activityLevel': activityLevel.name,
        'streakFreezeEnabled': streakFreezeEnabled,
      };

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    final themeName = json['themeMode'] as String?;
    final themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == themeName,
      orElse: () => ThemeMode.system,
    );

    return UserSettings(
      dailyGoalMl: (json['dailyGoalMl'] as num?)?.toInt() ?? 2000,
      glassSizeMl: (json['glassSizeMl'] as num?)?.toInt() ?? 250,
      useOunces: json['useOunces'] as bool? ?? false,
      themeMode: themeMode,
      remindersEnabled: json['remindersEnabled'] as bool? ?? true,
      reminderIntervalMinutes:
          (json['reminderIntervalMinutes'] as num?)?.toInt() ?? 120,
      wakeHour: (json['wakeHour'] as num?)?.toInt() ?? 8,
      sleepHour: (json['sleepHour'] as num?)?.toInt() ?? 22,
      silenceRemindersOnGoal: json['silenceRemindersOnGoal'] as bool? ?? true,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      weightKg: (json['weightKg'] as num?)?.toInt() ?? 70,
      activityLevel: ActivityLevel.fromName(json['activityLevel'] as String?),
      streakFreezeEnabled: json['streakFreezeEnabled'] as bool? ?? true,
    );
  }
}
