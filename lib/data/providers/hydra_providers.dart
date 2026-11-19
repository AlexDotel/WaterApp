import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/drink_types.dart';
import '../../core/utils/hydration_utils.dart';
import '../models/user_settings.dart';
import '../models/water_entry.dart';
import '../repositories/notification_service.dart';
import '../repositories/storage_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider debe ser sobreescrito en main()');
});

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(ref.watch(sharedPreferencesProvider));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class HydraState {
  const HydraState({
    required this.settings,
    required this.entries,
    this.lastAddedEntry,
  });

  final UserSettings settings;
  final List<WaterEntry> entries;
  final WaterEntry? lastAddedEntry;

  HydraState copyWith({
    UserSettings? settings,
    List<WaterEntry>? entries,
    WaterEntry? lastAddedEntry,
    bool clearLastAdded = false,
  }) {
    return HydraState(
      settings: settings ?? this.settings,
      entries: entries ?? this.entries,
      lastAddedEntry:
          clearLastAdded ? null : (lastAddedEntry ?? this.lastAddedEntry),
    );
  }

  List<WaterEntry> entriesForDay(DateTime day) {
    final key = HydrationUtils.dateKey(day);
    return entries
        .where((e) => HydrationUtils.dateKey(e.timestamp) == key)
        .toList();
  }

  int todayEffectiveMl(DateTime now) {
    return entriesForDay(now).fold<int>(0, (sum, e) => sum + e.effectiveMl);
  }

  double todayProgress(DateTime now) {
    if (settings.dailyGoalMl <= 0) return 0;
    return (todayEffectiveMl(now) / settings.dailyGoalMl).clamp(0.0, 1.5);
  }

  bool isTodayGoalCompleted(DateTime now) =>
      todayEffectiveMl(now) >= settings.dailyGoalMl;

  Map<String, int> get dailyTotals => HydrationUtils.totalsByDay(entries);

  StreakSummary streaks(DateTime now) => HydrationUtils.calculateStreaks(
        dailyTotals: dailyTotals,
        dailyGoalMl: settings.dailyGoalMl,
        today: now,
        freezeEnabled: settings.streakFreezeEnabled,
      );

  PacingResult pacing(DateTime now) => HydrationUtils.calculatePacing(
        currentMl: todayEffectiveMl(now),
        dailyGoalMl: settings.dailyGoalMl,
        glassSizeMl: settings.glassSizeMl,
        wakeHour: settings.wakeHour,
        sleepHour: settings.sleepHour,
        now: now,
      );

  Set<String> unlockedAchievements(DateTime now) =>
      HydrationUtils.computeUnlockedAchievements(
        entries: entries,
        streaks: streaks(now),
      );
}

class HydraNotifier extends Notifier<HydraState> {
  @override
  HydraState build() {
    final storage = ref.watch(storageRepositoryProvider);
    return HydraState(
      settings: storage.loadSettings(),
      entries: storage.loadEntries(),
    );
  }

  StorageRepository get _storage => ref.read(storageRepositoryProvider);
  NotificationService get _notifications =>
      ref.read(notificationServiceProvider);

  Future<WaterEntry> addEntry({
    required int volumeMl,
    DrinkType drinkType = DrinkType.water,
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now();
    final entry = WaterEntry(
      id: '${now.microsecondsSinceEpoch}_${state.entries.length}',
      timestamp: now,
      volumeMl: volumeMl,
      drinkType: drinkType,
    );

    final updated = [entry, ...state.entries]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    state = state.copyWith(entries: updated, lastAddedEntry: entry);
    await _storage.saveEntries(updated);
    await _syncReminders();
    return entry;
  }

  Future<void> removeEntry(String id) async {
    final updated = state.entries.where((e) => e.id != id).toList();
    state = state.copyWith(
      entries: updated,
      clearLastAdded: state.lastAddedEntry?.id == id,
    );
    await _storage.saveEntries(updated);
    await _syncReminders();
  }

  Future<void> undoLastAdded() async {
    final last = state.lastAddedEntry;
    if (last == null) return;
    await removeEntry(last.id);
  }

  Future<void> updateSettings(UserSettings newSettings) async {
    state = state.copyWith(settings: newSettings);
    await _storage.saveSettings(newSettings);
    await _syncReminders();
  }

  Future<void> completeOnboarding(UserSettings configuredSettings) async {
    final completed = configuredSettings.copyWith(onboardingCompleted: true);
    state = state.copyWith(settings: completed);
    await _storage.saveSettings(completed);
    if (completed.remindersEnabled) {
      await _notifications.requestPermissions();
    }
    await _syncReminders();
  }

  Future<void> _syncReminders() async {
    await _notifications.syncReminders(
      settings: state.settings,
      goalCompletedToday: state.isTodayGoalCompleted(DateTime.now()),
    );
  }
}

final hydraProvider = NotifierProvider<HydraNotifier, HydraState>(
  HydraNotifier.new,
);
