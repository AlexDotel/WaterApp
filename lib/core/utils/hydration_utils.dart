import '../../data/models/user_settings.dart';
import '../../data/models/water_entry.dart';

enum PacingStatus {
  completed,
  ahead,
  onTrack,
  behind,
  beforeStart,
  afterEnd,
}

class PacingResult {
  const PacingResult({
    required this.status,
    required this.expectedMl,
    required this.deltaMl,
    required this.message,
  });

  final PacingStatus status;
  final int expectedMl;
  final int deltaMl;
  final String message;
}

class StreakSummary {
  const StreakSummary({
    required this.currentStreak,
    required this.bestStreak,
    required this.availableFreezes,
    required this.frozenDayKeys,
    required this.completedDaysCount,
  });

  final int currentStreak;
  final int bestStreak;
  final int availableFreezes;
  final Set<String> frozenDayKeys;
  final int completedDaysCount;
}

abstract final class HydrationUtils {
  static const double _mlPerOz = 29.5735;

  static String dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Calcula la meta diaria recomendada (redondeada a múltiplos de 50 ml).
  static int calculateRecommendedGoalMl({
    required int weightKg,
    required ActivityLevel activityLevel,
  }) {
    final base = weightKg * 33;
    final raw = (base + activityLevel.bonusMl).clamp(1500, 4500);
    return ((raw / 50).round() * 50);
  }

  static String formatVolume(int ml, {bool useOunces = false}) {
    if (useOunces) {
      final oz = ml / _mlPerOz;
      return '${oz.toStringAsFixed(oz >= 10 ? 0 : 1)} oz';
    }
    if (ml >= 1000 && ml % 100 == 0) {
      final liters = ml / 1000;
      return '${liters.toStringAsFixed(liters.truncateToDouble() == liters ? 0 : 1)} L';
    }
    return '$ml ml';
  }

  static String formatVolumeExact(int ml, {bool useOunces = false}) {
    if (useOunces) {
      final oz = ml / _mlPerOz;
      return '${oz.toStringAsFixed(1)} oz';
    }
    return '$ml ml';
  }

  static String formatHour(int hour) {
    final normalized = hour.clamp(0, 23);
    return '${normalized.toString().padLeft(2, '0')}:00';
  }

  /// Agrupa ml efectivos por día (`yyyy-MM-dd`).
  static Map<String, int> totalsByDay(List<WaterEntry> entries) {
    final map = <String, int>{};
    for (final entry in entries) {
      final key = dateKey(entry.timestamp);
      map[key] = (map[key] ?? 0) + entry.effectiveMl;
    }
    return map;
  }

  /// Calcula el ritmo inteligente del día (Pacing).
  static PacingResult calculatePacing({
    required int currentMl,
    required int dailyGoalMl,
    required int glassSizeMl,
    required int wakeHour,
    required int sleepHour,
    required DateTime now,
  }) {
    if (currentMl >= dailyGoalMl) {
      return PacingResult(
        status: PacingStatus.completed,
        expectedMl: dailyGoalMl,
        deltaMl: currentMl - dailyGoalMl,
        message: '¡Meta cumplida! Tu hidratación de hoy está completa.',
      );
    }

    final startMinutes = wakeHour * 60;
    final endMinutes = sleepHour > wakeHour ? sleepHour * 60 : (wakeHour + 14) * 60;
    final nowMinutes = now.hour * 60 + now.minute;

    if (nowMinutes < startMinutes) {
      return PacingResult(
        status: PacingStatus.beforeStart,
        expectedMl: 0,
        deltaMl: currentMl,
        message: 'Buen comienzo. Tu horario activo inicia a las ${formatHour(wakeHour)}.',
      );
    }

    if (nowMinutes >= endMinutes) {
      final remaining = dailyGoalMl - currentMl;
      return PacingResult(
        status: PacingStatus.afterEnd,
        expectedMl: dailyGoalMl,
        deltaMl: -remaining,
        message: 'Te faltaron $remaining ml para cerrar el día al 100%.',
      );
    }

    final elapsedFraction =
        (nowMinutes - startMinutes) / (endMinutes - startMinutes);
    final expectedMl = (dailyGoalMl * elapsedFraction).round();
    final delta = currentMl - expectedMl;
    final tolerance = (glassSizeMl * 0.5).round();

    if (delta >= tolerance) {
      final aheadGlasses = (delta / glassSizeMl).round().clamp(1, 20);
      final label = aheadGlasses == 1 ? '1 vaso' : '$aheadGlasses vasos';
      return PacingResult(
        status: PacingStatus.ahead,
        expectedMl: expectedMl,
        deltaMl: delta,
        message: 'Vas $label adelantado respecto a tu ritmo ideal.',
      );
    }

    if (delta <= -tolerance) {
      final behindGlasses = ((-delta) / glassSizeMl).ceil().clamp(1, 20);
      final label = behindGlasses == 1 ? 'Un vaso' : '$behindGlasses vasos';
      return PacingResult(
        status: PacingStatus.behind,
        expectedMl: expectedMl,
        deltaMl: delta,
        message: '$label ahora te pone al día con tu meta.',
      );
    }

    return PacingResult(
      status: PacingStatus.onTrack,
      expectedMl: expectedMl,
      deltaMl: delta,
      message: 'Vas justo en tu ritmo ideal para hoy.',
    );
  }

  /// Calcula racha actual, mejor racha y días protegidos por Escudo de Racha.
  ///
  /// Regla de Escudo de Racha (Streak Freeze):
  /// - Por cada 7 días cumplidos acumulados se gana 1 escudo (máximo 2 almacenados).
  /// - Si `freezeEnabled` es true y falta un día entre días cumplidos (o ayer si hoy aún no termina),
  ///   un escudo disponible protege la racha automáticamente.
  static StreakSummary calculateStreaks({
    required Map<String, int> dailyTotals,
    required int dailyGoalMl,
    required DateTime today,
    bool freezeEnabled = true,
  }) {
    final completedDays = dailyTotals.entries
        .where((e) => e.value >= dailyGoalMl)
        .map((e) => e.key)
        .toSet();

    if (completedDays.isEmpty) {
      return const StreakSummary(
        currentStreak: 0,
        bestStreak: 0,
        availableFreezes: 0,
        frozenDayKeys: {},
        completedDaysCount: 0,
      );
    }

    final sortedDates = completedDays
        .map(DateTime.parse)
        .toList()
      ..sort((a, b) => a.compareTo(b));

    final firstDate = startOfDay(sortedDates.first);
    final todayDay = startOfDay(today);

    int bestStreak = 0;
    int runningStreak = 0;
    int completedCounter = 0;
    int freezesPool = 0;
    final frozenDays = <String>{};

    var cursor = firstDate;
    while (!cursor.isAfter(todayDay)) {
      final key = dateKey(cursor);
      final isToday = cursor == todayDay;
      final isCompleted = completedDays.contains(key);

      if (isCompleted) {
        runningStreak++;
        completedCounter++;
        if (completedCounter % 7 == 0 && freezesPool < 2) {
          freezesPool++;
        }
        if (runningStreak > bestStreak) {
          bestStreak = runningStreak;
        }
      } else if (isToday) {
        // Hoy aún está en curso: no rompe la racha de ayer.
      } else if (freezeEnabled && runningStreak > 0 && freezesPool > 0) {
        freezesPool--;
        frozenDays.add(key);
        // Mantiene la racha viva sin incrementar el contador de días cumplidos.
      } else {
        runningStreak = 0;
      }

      cursor = cursor.add(const Duration(days: 1));
    }

    return StreakSummary(
      currentStreak: runningStreak,
      bestStreak: bestStreak,
      availableFreezes: freezesPool,
      frozenDayKeys: frozenDays,
      completedDaysCount: completedDays.length,
    );
  }

  /// Calcula los IDs de logros desbloqueados.
  static Set<String> computeUnlockedAchievements({
    required List<WaterEntry> entries,
    required StreakSummary streaks,
  }) {
    final unlocked = <String>{};
    if (entries.isEmpty) return unlocked;

    unlocked.add('first_drop');

    final hasEarlyBird = entries.any(
      (e) => e.timestamp.hour < 8 || (e.timestamp.hour == 8 && e.timestamp.minute <= 30),
    );
    if (hasEarlyBird) unlocked.add('early_bird');

    if (streaks.completedDaysCount >= 1) unlocked.add('first_goal');
    if (streaks.bestStreak >= 3) unlocked.add('streak_3');
    if (streaks.bestStreak >= 7) unlocked.add('streak_7');
    if (streaks.bestStreak >= 30) unlocked.add('streak_30');

    final totalEffectiveMl = entries.fold<int>(0, (sum, e) => sum + e.effectiveMl);
    if (totalEffectiveMl >= 25000) unlocked.add('total_25l');

    final distinctDrinks = entries.map((e) => e.drinkType).toSet();
    if (distinctDrinks.length >= 3) unlocked.add('variety');

    return unlocked;
  }
}
