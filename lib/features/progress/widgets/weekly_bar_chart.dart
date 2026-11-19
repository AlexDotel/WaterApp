import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/hydration_utils.dart';

class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({
    super.key,
    required this.dailyTotals,
    required this.dailyGoalMl,
    required this.today,
    required this.useOunces,
  });

  final Map<String, int> dailyTotals;
  final int dailyGoalMl;
  final DateTime today;
  final bool useOunces;

  static const _dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = List.generate(7, (i) {
      final date = HydrationUtils.startOfDay(today)
          .subtract(Duration(days: 6 - i));
      final key = HydrationUtils.dateKey(date);
      return (date: date, ml: dailyTotals[key] ?? 0);
    });

    final maxData = days.fold<int>(
      dailyGoalMl,
      (prev, d) => d.ml > prev ? d.ml : prev,
    );
    final maxScale = (maxData * 1.15).ceil();
    final goalFraction = (dailyGoalMl / maxScale).clamp(0.1, 0.95);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Últimos 7 días',
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Meta ${HydrationUtils.formatVolume(dailyGoalMl, useOunces: useOunces)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 162,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barAreaHeight = constraints.maxHeight - 36;
                  final goalLineTop = barAreaHeight * (1 - goalFraction);

                  return Stack(
                    children: [
                      Positioned(
                        top: goalLineTop,
                        left: 0,
                        right: 0,
                        child: CustomPaint(
                          size: const Size(double.infinity, 1),
                          painter: _DashedLinePainter(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: days.map((item) {
                          final fraction =
                              (item.ml / maxScale).clamp(0.0, 1.0);
                          final metGoal = item.ml >= dailyGoalMl;
                          final isToday = item.date ==
                              HydrationUtils.startOfDay(today);

                          return Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Tooltip(
                                      message: HydrationUtils.formatVolumeExact(
                                        item.ml,
                                        useOunces: useOunces,
                                      ),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 450),
                                        curve: Curves.easeOutCubic,
                                        width: 18,
                                        height: (barAreaHeight * fraction)
                                            .clamp(4.0, barAreaHeight),
                                        decoration: BoxDecoration(
                                          color: item.ml == 0
                                              ? theme.colorScheme
                                                  .surfaceContainerHighest
                                              : (metGoal
                                                  ? AppColors.success
                                                  : theme.colorScheme.primary
                                                      .withValues(
                                                          alpha: isToday
                                                              ? 1.0
                                                              : 0.65)),
                                          borderRadius:
                                              BorderRadius.circular(99),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _dayLabels[item.date.weekday - 1],
                                  maxLines: 1,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: isToday
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isToday
                                        ? theme.colorScheme.primary
                                        : theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
