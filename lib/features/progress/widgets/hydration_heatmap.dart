import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/hydration_utils.dart';

/// Heatmap de los últimos 28 días mostrando intensidad de cumplimiento y días con Escudo.
class HydrationHeatmap extends StatelessWidget {
  const HydrationHeatmap({
    super.key,
    required this.dailyTotals,
    required this.dailyGoalMl,
    required this.frozenDayKeys,
    required this.today,
  });

  final Map<String, int> dailyTotals;
  final int dailyGoalMl;
  final Set<String> frozenDayKeys;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseToday = HydrationUtils.startOfDay(today);
    final days = List.generate(
      28,
      (i) => baseToday.subtract(Duration(days: 27 - i)),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Constancia · 28 días', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _LegendDot(
                      color: theme.colorScheme.surfaceContainerHighest,
                      label: '0%',
                    ),
                    _LegendDot(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      label: 'Parcial',
                    ),
                    const _LegendDot(color: AppColors.success, label: '100%'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: days.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final day = days[index];
                final key = HydrationUtils.dateKey(day);
                final ml = dailyTotals[key] ?? 0;
                final ratio = dailyGoalMl > 0 ? ml / dailyGoalMl : 0.0;
                final isFrozen = frozenDayKeys.contains(key);
                final isToday = day == baseToday;

                Color cellColor;
                if (isFrozen) {
                  cellColor = AppColors.freeze.withValues(alpha: 0.25);
                } else if (ratio >= 1.0) {
                  cellColor = AppColors.success;
                } else if (ratio >= 0.65) {
                  cellColor = AppColors.primary.withValues(alpha: 0.72);
                } else if (ratio > 0) {
                  cellColor = AppColors.primary.withValues(alpha: 0.30);
                } else {
                  cellColor = theme.colorScheme.surfaceContainerHighest;
                }

                return Tooltip(
                  message: isFrozen
                      ? '${day.day}/${day.month} · Protegido con escudo'
                      : '${day.day}/${day.month} · ${(ratio * 100).round()}%',
                  child: Container(
                    decoration: BoxDecoration(
                      color: cellColor,
                      borderRadius: BorderRadius.circular(10),
                      border: isToday
                          ? Border.all(
                              color: theme.colorScheme.onSurface,
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Center(
                      child: isFrozen
                          ? const Icon(
                              Icons.ac_unit_rounded,
                              size: 14,
                              color: AppColors.freeze,
                            )
                          : Text(
                              '${day.day}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: ratio >= 0.65
                                    ? Colors.white
                                    : theme.textTheme.bodySmall?.color,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
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

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
