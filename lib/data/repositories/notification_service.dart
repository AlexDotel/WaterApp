import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/user_settings.dart';

class NotificationService {
  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _channelId = 'hydra_reminders';
  static const _channelName = 'Recordatorios de hidratación';
  static const _channelDescription =
      'Avisos suaves para ayudarte a cumplir tu meta diaria de agua en Hydra.';

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    try {
      tz_data.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: androidSettings,
          iOS: darwinSettings,
          macOS: darwinSettings,
        ),
      );
      _initialized = true;
    } catch (_) {
      // En entornos sin canal nativo (ej. pruebas de widgets) ignoramos con seguridad.
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    await initialize();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final androidGranted = await android?.requestNotificationsPermission();

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final iosGranted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      return (androidGranted ?? true) && (iosGranted ?? true);
    } catch (_) {
      return false;
    }
  }

  /// Reprograma los recordatorios según la configuración y si la meta de hoy ya se cumplió.
  Future<void> syncReminders({
    required UserSettings settings,
    required bool goalCompletedToday,
  }) async {
    if (kIsWeb) return;
    await initialize();
    if (!_initialized) return;

    try {
      await _plugin.cancelAll();
      if (!settings.remindersEnabled) return;

      final now = DateTime.now();
      final interval = settings.reminderIntervalMinutes.clamp(30, 360);
      final startHour = settings.wakeHour.clamp(0, 22);
      final endHour = settings.sleepHour.clamp(startHour + 1, 23);

      // Si el usuario ya cumplió su meta y activó "Silenciar al cumplir",
      // saltamos los recordatorios restantes de hoy y programamos desde mañana.
      final startDayOffset =
          (goalCompletedToday && settings.silenceRemindersOnGoal) ? 1 : 0;

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );

      const messages = [
        'Un sorbo ahora te mantiene con energía 💧',
        'Es buen momento para tu próximo vaso de agua.',
        'Tu cuerpo te lo agradecerá: tómate un respiro e hidrátate.',
        'Mantén tu racha viva en Hydra con un vaso de agua.',
      ];

      int notificationId = 100;
      for (int dayOffset = startDayOffset; dayOffset <= startDayOffset + 1; dayOffset++) {
        final baseDay = DateTime(now.year, now.month, now.day)
            .add(Duration(days: dayOffset));
        var slot = DateTime(baseDay.year, baseDay.month, baseDay.day, startHour);
        final endLimit =
            DateTime(baseDay.year, baseDay.month, baseDay.day, endHour);

        while (!slot.isAfter(endLimit) && notificationId < 140) {
          if (slot.isAfter(now.add(const Duration(minutes: 1)))) {
            final scheduled = tz.TZDateTime.from(slot, tz.local);
            final body = messages[notificationId % messages.length];
            await _plugin.zonedSchedule(
              id: notificationId,
              title: 'Hora de hidratarte · Hydra',
              body: body,
              scheduledDate: scheduled,
              notificationDetails: details,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
            notificationId++;
          }
          slot = slot.add(Duration(minutes: interval));
        }
      }
    } catch (_) {
      // Evita fallos en plataformas no soportadas.
    }
  }

  Future<bool> sendTestNotification() async {
    if (kIsWeb) return false;
    await initialize();
    if (!_initialized) return false;

    try {
      await requestPermissions();
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _plugin.show(
        id: 999,
        title: 'Hydra · Recordatorio activo',
        body: 'Así te avisaremos para que nunca pierdas tu racha 💧',
        notificationDetails: details,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
