import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/drink_types.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/hydration_utils.dart';
import '../../../data/models/water_entry.dart';
import '../../../data/providers/hydra_providers.dart';
import 'widgets/drink_picker_sheet.dart';
import 'widgets/liquid_progress_vessel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _logDrink(
    BuildContext context,
    WidgetRef ref, {
    required int volumeMl,
    DrinkType drinkType = DrinkType.water,
  }) async {
    HapticFeedback.lightImpact();
    final stateBefore = ref.read(hydraProvider);
    final now = DateTime.now();
    final wasCompleted = stateBefore.isTodayGoalCompleted(now);

    final entry = await ref.read(hydraProvider.notifier).addEntry(
          volumeMl: volumeMl,
          drinkType: drinkType,
        );

    final stateAfter = ref.read(hydraProvider);
    final nowCompleted = stateAfter.isTodayGoalCompleted(now);
    if (!wasCompleted && nowCompleted) {
      HapticFeedback.mediumImpact();
    }

    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          !wasCompleted && nowCompleted
              ? '¡Meta diaria completada! 🎉'
              : '+${HydrationUtils.formatVolumeExact(entry.effectiveMl, useOunces: stateAfter.settings.useOunces)} de ${drinkType.label}',
        ),
        action: SnackBarAction(
          label: 'Deshacer',
          textColor: AppColors.primaryLight,
          onPressed: () {
            ref.read(hydraProvider.notifier).undoLastAdded();
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hydra = ref.watch(hydraProvider);
    final settings = hydra.settings;
    final now = DateTime.now();

    final todayEntries = hydra.entriesForDay(now);
    final todayMl = hydra.todayEffectiveMl(now);
    final streaks = hydra.streaks(now);
    final pacing = hydra.pacing(now);
    final dateText = _formatSpanishDate(now);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hydra',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                          ),
                        ),
                        Text(dateText, style: theme.textTheme.bodySmall),
                      ],
                    ),
                    const Spacer(),
                    if (streaks.availableFreezes > 0 &&
                        settings.streakFreezeEnabled) ...[
                      _StatusPill(
                        icon: Icons.ac_unit_rounded,
                        label: '${streaks.availableFreezes}',
                        color: AppColors.freeze,
                        tooltip: 'Escudos de racha disponibles',
                      ),
                      const SizedBox(width: 8),
                    ],
                    _StatusPill(
                      icon: Icons.local_fire_department_rounded,
                      label: '${streaks.currentStreak}d',
                      color: streaks.currentStreak > 0
                          ? AppColors.streak
                          : theme.textTheme.bodySmall?.color ??
                              AppColors.lightTextSecondary,
                      tooltip: 'Racha actual',
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: LiquidProgressVessel(
                    currentMl: todayMl,
                    goalMl: settings.dailyGoalMl,
                    glassSizeMl: settings.glassSizeMl,
                    useOunces: settings.useOunces,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
              sliver: SliverToBoxAdapter(
                child: _PacingCard(pacing: pacing),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _logDrink(
                          context,
                          ref,
                          volumeMl: settings.glassSizeMl,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 22),
                        label: Text(
                          'Añadir 1 vaso (${HydrationUtils.formatVolumeExact(settings.glassSizeMl, useOunces: settings.useOunces)})',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickChipButton(
                            icon: Icons.water_drop_outlined,
                            label:
                                '+${HydrationUtils.formatVolumeExact((settings.glassSizeMl / 2).round(), useOunces: settings.useOunces)}',
                            onTap: () => _logDrink(
                              context,
                              ref,
                              volumeMl: (settings.glassSizeMl / 2).round(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickChipButton(
                            icon: Icons.local_drink_outlined,
                            label:
                                '+${HydrationUtils.formatVolumeExact(500, useOunces: settings.useOunces)}',
                            onTap: () => _logDrink(
                              context,
                              ref,
                              volumeMl: 500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickChipButton(
                            icon: Icons.tune_rounded,
                            label: 'Bebida',
                            onTap: () async {
                              final result = await showDrinkPickerSheet(
                                context,
                                defaultGlassMl: settings.glassSizeMl,
                                useOunces: settings.useOunces,
                              );
                              if (result != null && context.mounted) {
                                await _logDrink(
                                  context,
                                  ref,
                                  volumeMl: result.volumeMl,
                                  drinkType: result.drinkType,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 10),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text('Tomas de hoy', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Text(
                      '${todayEntries.length} ${todayEntries.length == 1 ? 'registro' : 'registros'}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            if (todayEntries.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
                sliver: SliverToBoxAdapter(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 28,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.water_drop_outlined,
                            size: 28,
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.7),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Aún no has registrado agua hoy',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Toca el botón azul arriba para sumar tu primer vaso.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
                sliver: SliverList.separated(
                  itemCount: todayEntries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = todayEntries[index];
                    return _EntryTile(
                      entry: entry,
                      useOunces: settings.useOunces,
                      onDelete: () =>
                          ref.read(hydraProvider.notifier).removeEntry(entry.id),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatSpanishDate(DateTime date) {
    const weekdays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.tooltip,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PacingCard extends StatelessWidget {
  const _PacingCard({required this.pacing});

  final PacingResult pacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (IconData icon, Color accent) = switch (pacing.status) {
      PacingStatus.completed => (Icons.check_circle_rounded, AppColors.success),
      PacingStatus.ahead => (Icons.trending_up_rounded, AppColors.primary),
      PacingStatus.onTrack => (Icons.schedule_rounded, AppColors.primaryLight),
      PacingStatus.behind => (Icons.notifications_active_outlined, AppColors.warning),
      PacingStatus.beforeStart => (Icons.wb_twilight_rounded, AppColors.primaryLight),
      PacingStatus.afterEnd => (Icons.nights_stay_outlined, AppColors.lightTextSecondary),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                pacing.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChipButton extends StatelessWidget {
  const _QuickChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.useOunces,
    required this.onDelete,
  });

  final WaterEntry entry;
  final bool useOunces;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = DateFormat('HH:mm').format(entry.timestamp);
    final drink = entry.drinkType;
    final hasFactor = drink.hydrationFactor != 1.0;

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
      ),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: theme.colorScheme.outline),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: drink.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(drink.icon, size: 19, color: drink.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drink.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      hasFactor
                          ? '$timeStr · ${HydrationUtils.formatVolumeExact(entry.volumeMl, useOunces: useOunces)} (${drink.factorLabel})'
                          : timeStr,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '+${HydrationUtils.formatVolumeExact(entry.effectiveMl, useOunces: useOunces)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
