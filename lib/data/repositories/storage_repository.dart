import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_settings.dart';
import '../models/water_entry.dart';

class StorageRepository {
  StorageRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _settingsKey = 'hydra_user_settings_v1';
  static const _entriesKey = 'hydra_water_entries_v1';

  UserSettings loadSettings() {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) {
      return const UserSettings();
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return UserSettings.fromJson(decoded);
    } catch (_) {
      return const UserSettings();
    }
  }

  Future<void> saveSettings(UserSettings settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  List<WaterEntry> loadEntries() {
    final raw = _prefs.getString(_entriesKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(WaterEntry.fromJson)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveEntries(List<WaterEntry> entries) async {
    final payload = entries.map((e) => e.toJson()).toList();
    await _prefs.setString(_entriesKey, jsonEncode(payload));
  }
}
