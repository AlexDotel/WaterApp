import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/achievements.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/hydration_utils.dart';
import '../../../data/providers/hydra_providers.dart';
import 'widgets/hydration_heatmap.dart';
import 'widgets/weekly_bar_chart.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hydra = ref.watch(hydraProvider);
    final settings = hydra.settings;
    final now = DateTime.now();

    final totals = hydra.dailyTotals;
    final streaks = hydra.streaks(now);
    final unlocked = hydra.unlockedAchievements(now);

    // Promedio de los últimos 7 días
    int sum7 = 0;
    for (int i = 0; i < 7; i++) {
      final d = HydrationUtils.startOfDay(now).subtract(Duration(days: i));
      sum7 += totals[HydrationUtils.dateKey(d)] ?? 0;
    }
    final avg7Ml = (sum7 / 7).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progreso'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.streak,
                    value: '${streaks.currentStreak}',
                    unit: streaks.currentStreak == 1 ? 'día' : 'días',
                    label: 'Racha actual',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.emoji_events_rounded,
                    color: AppColors.warning,
                    value: '${streaks.bestStreak}',
                    unit: streaks.bestStreak == 1 ? 'día' : 'días',
                    label: 'Mejor racha',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.ac_unit_rounded,
                    color: AppColors.freeze,
                    value: '${streaks.availableFreezes}',
                    unit: '/ 2',
                    label: 'Escudos de racha',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.water_drop_rounded,
                    color: AppColors.primary,
                    value: HydrationUtils.formatVolume(
                      avg7Ml,
                      useOunces: settings.useOunces,
                    ),
                    unit: '',
                    label: 'Promedio 7 días',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            WeeklyBarChart(
              dailyTotals: totals,
              dailyGoalMl: settings.dailyGoalMl,
              today: now,
              useOunces: settings.useOunces,
            ),
            const SizedBox(height: 16),
            HydrationHeatmap(
              dailyTotals: totals,
              dailyGoalMl: settings.dailyGoalMl,
              frozenDayKeys: streaks.frozenDayKeys,
              today: now,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Logros', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  '${unlocked.length} / ${AppAchievements.all.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: AppAchievements.all.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 152,
              ),
              itemBuilder: (context, index) {
                final badge = AppAchievements.all[index];
                final isUnlocked = unlocked.contains(badge.id);

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Opacity(
                      opacity: isUnlocked ? 1.0 : 0.45,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: (isUnlocked
                                          ? badge.color
                                          : theme.colorScheme.outline)
                                      .withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(
                                  badge.icon,
                                  size: 18,
                                  color: isUnlocked
                                      ? badge.color
                                      : theme.textTheme.bodySmall?.color,
                                ),
                              ),
                              const Spacer(),
                              if (isUnlocked)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: AppColors.success,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            badge.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              badge.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.unit,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(unit, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
