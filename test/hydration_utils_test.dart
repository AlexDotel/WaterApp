import 'package:flutter_test/flutter_test.dart';
import 'package:hydra/core/constants/drink_types.dart';
import 'package:hydra/core/utils/hydration_utils.dart';
import 'package:hydra/data/models/user_settings.dart';
import 'package:hydra/data/models/water_entry.dart';

void main() {
  group('HydrationUtils.calculateRecommendedGoalMl', () {
    test('calculates rounded goal based on weight and activity level', () {
      expect(
        HydrationUtils.calculateRecommendedGoalMl(
          weightKg: 70,
          activityLevel: ActivityLevel.sedentary,
        ),
        2300,
      );
      expect(
        HydrationUtils.calculateRecommendedGoalMl(
          weightKg: 70,
          activityLevel: ActivityLevel.active,
        ),
        2900,
      );
    });
  });

  group('HydrationUtils.calculatePacing', () {
    test('reports completed when daily goal is reached', () {
      final result = HydrationUtils.calculatePacing(
        currentMl: 2000,
        dailyGoalMl: 2000,
        glassSizeMl: 250,
        wakeHour: 8,
        sleepHour: 22,
        now: DateTime(2026, 11, 19, 15, 0),
      );
      expect(result.status, PacingStatus.completed);
    });

    test('reports ahead when user is above expected midpoint', () {
      final result = HydrationUtils.calculatePacing(
        currentMl: 1500,
        dailyGoalMl: 2000,
        glassSizeMl: 250,
        wakeHour: 8,
        sleepHour: 22,
        now: DateTime(2026, 11, 19, 15, 0), // 50% of day => 1000 ml expected
      );
      expect(result.status, PacingStatus.ahead);
    });

    test('reports behind when user is below expected midpoint', () {
      final result = HydrationUtils.calculatePacing(
        currentMl: 250,
        dailyGoalMl: 2000,
        glassSizeMl: 250,
        wakeHour: 8,
        sleepHour: 22,
        now: DateTime(2026, 11, 19, 15, 0),
      );
      expect(result.status, PacingStatus.behind);
    });
  });

  group('HydrationUtils.calculateStreaks & Streak Freeze', () {
    test('earns a freeze after 7 completed days and protects a missed day', () {
      final start = DateTime(2026, 11, 1);
      final totals = <String, int>{};

      // 7 días seguidos cumplidos (Nov 1..Nov 7) -> gana 1 escudo
      for (int i = 0; i < 7; i++) {
        totals[HydrationUtils.dateKey(start.add(Duration(days: i)))] = 2000;
      }
      // Nov 8 se omite (protegido por escudo)
      // Nov 9 se cumple
      totals[HydrationUtils.dateKey(DateTime(2026, 11, 9))] = 2000;

      final summary = HydrationUtils.calculateStreaks(
        dailyTotals: totals,
        dailyGoalMl: 2000,
        today: DateTime(2026, 11, 9),
        freezeEnabled: true,
      );

      expect(summary.currentStreak, 8);
      expect(summary.bestStreak, 8);
      expect(summary.frozenDayKeys, contains('2026-11-08'));
      expect(summary.availableFreezes, 0);
    });

    test('breaks streak when freeze is disabled', () {
      final start = DateTime(2026, 11, 1);
      final totals = <String, int>{};
      for (int i = 0; i < 7; i++) {
        totals[HydrationUtils.dateKey(start.add(Duration(days: i)))] = 2000;
      }
      totals[HydrationUtils.dateKey(DateTime(2026, 11, 9))] = 2000;

      final summary = HydrationUtils.calculateStreaks(
        dailyTotals: totals,
        dailyGoalMl: 2000,
        today: DateTime(2026, 11, 9),
        freezeEnabled: false,
      );

      expect(summary.currentStreak, 1);
      expect(summary.bestStreak, 7);
      expect(summary.frozenDayKeys, isEmpty);
    });
  });

  group('WaterEntry hydration factor', () {
    test('applies drink hydration factors accurately', () {
      final coffee = WaterEntry(
        id: '1',
        timestamp: DateTime(2026, 11, 19, 9, 0),
        volumeMl: 250,
        drinkType: DrinkType.coffee,
      );
      final electrolytes = WaterEntry(
        id: '2',
        timestamp: DateTime(2026, 11, 19, 10, 0),
        volumeMl: 500,
        drinkType: DrinkType.electrolytes,
      );

      expect(coffee.effectiveMl, 200);
      expect(electrolytes.effectiveMl, 550);
    });
  });
}
