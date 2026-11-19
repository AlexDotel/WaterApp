import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/hydration_utils.dart';
import '../../data/models/user_settings.dart';
import '../../data/providers/hydra_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hydra = ref.watch(hydraProvider);
    final settings = hydra.settings;
    final notifier = ref.read(hydraProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
          physics: const BouncingScrollPhysics(),
          children: [
            _SectionLabel(label: 'Meta e hidratación'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.flag_outlined),
                    title: const Text('Meta diaria'),
                    subtitle: Text(
                      '${HydrationUtils.formatVolumeExact(settings.dailyGoalMl, useOunces: settings.useOunces)} · ${settings.dailyGoalGlasses} vasos',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showGoalDialog(context, settings, notifier),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.water_drop_outlined),
                    title: const Text('Tamaño del vaso principal'),
                    subtitle: Text(
                      HydrationUtils.formatVolumeExact(
                        settings.glassSizeMl,
                        useOunces: settings.useOunces,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () =>
                        _showGlassSizeDialog(context, settings, notifier),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  SwitchListTile(
                    secondary: const Icon(Icons.straighten_rounded),
                    title: const Text('Mostrar en onzas (oz)'),
                    subtitle: Text(
                      settings.useOunces ? 'Usando onzas fluidas' : 'Usando mililitros (ml)',
                    ),
                    value: settings.useOunces,
                    onChanged: (v) =>
                        notifier.updateSettings(settings.copyWith(useOunces: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _SectionLabel(label: 'Recordatorios inteligentes'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text('Activar recordatorios'),
                    subtitle: Text(
                      settings.remindersEnabled
                          ? 'Cada ${_formatInterval(settings.reminderIntervalMinutes)} (${HydrationUtils.formatHour(settings.wakeHour)} – ${HydrationUtils.formatHour(settings.sleepHour)})'
                          : 'Desactivados',
                    ),
                    value: settings.remindersEnabled,
                    onChanged: (v) async {
                      if (v) {
                        await ref
                            .read(notificationServiceProvider)
                            .requestPermissions();
                      }
                      await notifier.updateSettings(
                        settings.copyWith(remindersEnabled: v),
                      );
                    },
                  ),
                  if (settings.remindersEnabled) ...[
                    const Divider(indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.schedule_rounded),
                      title: const Text('Frecuencia y horario'),
                      subtitle: Text(
                        '${HydrationUtils.formatHour(settings.wakeHour)} a ${HydrationUtils.formatHour(settings.sleepHour)} · Cada ${_formatInterval(settings.reminderIntervalMinutes)}',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () =>
                          _showReminderDialog(context, settings, notifier),
                    ),
                    const Divider(indent: 16, endIndent: 16),
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_off_outlined),
                      title: const Text('Silenciar al cumplir la meta'),
                      subtitle: const Text(
                        'Pausa los avisos del día al llegar al 100%',
                      ),
                      value: settings.silenceRemindersOnGoal,
                      onChanged: (v) => notifier.updateSettings(
                        settings.copyWith(silenceRemindersOnGoal: v),
                      ),
                    ),
                    const Divider(indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.send_outlined),
                      title: const Text('Probar recordatorio'),
                      subtitle: const Text('Envía una notificación de prueba ahora'),
                      onTap: () async {
                        final sent = await ref
                            .read(notificationServiceProvider)
                            .sendTestNotification();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              sent
                                  ? 'Notificación de prueba enviada 💧'
                                  : 'Las notificaciones locales están disponibles en Android e iOS.',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            _SectionLabel(label: 'Rachas y apariencia'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.ac_unit_rounded),
                    title: const Text('Escudo de racha automático'),
                    subtitle: const Text(
                      'Ganas 1 escudo cada 7 días cumplidos para proteger tu racha',
                    ),
                    value: settings.streakFreezeEnabled,
                    onChanged: (v) => notifier.updateSettings(
                      settings.copyWith(streakFreezeEnabled: v),
                    ),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tema', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<ThemeMode>(
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.system,
                                label: Text('Auto'),
                                icon: Icon(Icons.brightness_auto_rounded, size: 16),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                label: Text('Claro'),
                                icon: Icon(Icons.light_mode_rounded, size: 16),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                label: Text('Oscuro'),
                                icon: Icon(Icons.dark_mode_rounded, size: 16),
                              ),
                            ],
                            selected: {settings.themeMode},
                            onSelectionChanged: (selection) {
                              notifier.updateSettings(
                                settings.copyWith(themeMode: selection.first),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatInterval(int minutes) {
    if (minutes == 60) return '1 h';
    if (minutes == 90) return '1.5 h';
    return '${minutes ~/ 60} h';
  }

  Future<void> _showGoalDialog(
    BuildContext context,
    UserSettings settings,
    HydraNotifier notifier,
  ) async {
    int goalMl = settings.dailyGoalMl;
    int weightKg = settings.weightKg;
    ActivityLevel activity = settings.activityLevel;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Meta diaria', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        HydrationUtils.formatVolumeExact(
                          goalMl,
                          useOunces: settings.useOunces,
                        ),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    Slider(
                      value: goalMl.toDouble(),
                      min: 1200,
                      max: 4500,
                      divisions: 66,
                      onChanged: (v) =>
                          setModalState(() => goalMl = (v / 50).round() * 50),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('Recalcular según peso ($weightKg kg)',
                        style: theme.textTheme.titleSmall),
                    Slider(
                      value: weightKg.toDouble(),
                      min: 40,
                      max: 130,
                      divisions: 90,
                      onChanged: (v) {
                        setModalState(() {
                          weightKg = v.round();
                          goalMl = HydrationUtils.calculateRecommendedGoalMl(
                            weightKg: weightKg,
                            activityLevel: activity,
                          );
                        });
                      },
                    ),
                    Wrap(
                      spacing: 8,
                      children: ActivityLevel.values.map((lvl) {
                        return ChoiceChip(
                          label: Text(lvl.label),
                          selected: activity == lvl,
                          onSelected: (_) {
                            setModalState(() {
                              activity = lvl;
                              goalMl = HydrationUtils.calculateRecommendedGoalMl(
                                weightKg: weightKg,
                                activityLevel: activity,
                              );
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          notifier.updateSettings(
                            settings.copyWith(
                              dailyGoalMl: goalMl,
                              weightKg: weightKg,
                              activityLevel: activity,
                            ),
                          );
                          Navigator.of(context).pop();
                        },
                        child: const Text('Guardar meta'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showGlassSizeDialog(
    BuildContext context,
    UserSettings settings,
    HydraNotifier notifier,
  ) async {
    int size = settings.glassSizeMl;
    const presets = [150, 200, 250, 300, 350, 500];

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tamaño del vaso', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presets.map((ml) {
                        return ChoiceChip(
                          label: Text(
                            HydrationUtils.formatVolumeExact(
                              ml,
                              useOunces: settings.useOunces,
                            ),
                          ),
                          selected: size == ml,
                          onSelected: (_) => setModalState(() => size = ml),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          notifier.updateSettings(
                            settings.copyWith(glassSizeMl: size),
                          );
                          Navigator.of(context).pop();
                        },
                        child: const Text('Guardar tamaño'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showReminderDialog(
    BuildContext context,
    UserSettings settings,
    HydraNotifier notifier,
  ) async {
    int interval = settings.reminderIntervalMinutes;
    int wake = settings.wakeHour;
    int sleep = settings.sleepHour;
    const intervals = [60, 90, 120, 180];

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Horario de recordatorios',
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Text('Frecuencia', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: intervals.map((min) {
                        return ChoiceChip(
                          label: Text('Cada ${_formatInterval(min)}'),
                          selected: interval == min,
                          onSelected: (_) =>
                              setModalState(() => interval = min),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Horario activo: ${HydrationUtils.formatHour(wake)} – ${HydrationUtils.formatHour(sleep)}',
                      style: theme.textTheme.titleSmall,
                    ),
                    RangeSlider(
                      values: RangeValues(wake.toDouble(), sleep.toDouble()),
                      min: 5,
                      max: 23,
                      divisions: 18,
                      onChanged: (range) {
                        final start = range.start.round();
                        final end = range.end.round();
                        if (end - start >= 2) {
                          setModalState(() {
                            wake = start;
                            sleep = end;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          notifier.updateSettings(
                            settings.copyWith(
                              reminderIntervalMinutes: interval,
                              wakeHour: wake,
                              sleepHour: sleep,
                            ),
                          );
                          Navigator.of(context).pop();
                        },
                        child: const Text('Guardar horario'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
