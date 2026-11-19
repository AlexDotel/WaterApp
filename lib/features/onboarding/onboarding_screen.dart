import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/hydration_utils.dart';
import '../../core/widgets/hydra_logo.dart';
import '../../data/models/user_settings.dart';
import '../../data/providers/hydra_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _step = 0;

  late int _weightKg;
  late ActivityLevel _activityLevel;
  late int _dailyGoalMl;
  late int _glassSizeMl;
  late bool _remindersEnabled;
  late int _wakeHour;
  late int _sleepHour;
  late int _intervalMinutes;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(hydraProvider).settings;
    _weightKg = settings.weightKg;
    _activityLevel = settings.activityLevel;
    _dailyGoalMl = HydrationUtils.calculateRecommendedGoalMl(
      weightKg: _weightKg,
      activityLevel: _activityLevel,
    );
    _glassSizeMl = settings.glassSizeMl;
    _remindersEnabled = settings.remindersEnabled;
    _wakeHour = settings.wakeHour;
    _sleepHour = settings.sleepHour;
    _intervalMinutes = settings.reminderIntervalMinutes;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _recalculateGoal() {
    _dailyGoalMl = HydrationUtils.calculateRecommendedGoalMl(
      weightKg: _weightKg,
      activityLevel: _activityLevel,
    );
  }

  Future<void> _finish() async {
    final current = ref.read(hydraProvider).settings;
    await ref.read(hydraProvider.notifier).completeOnboarding(
          current.copyWith(
            weightKg: _weightKg,
            activityLevel: _activityLevel,
            dailyGoalMl: _dailyGoalMl,
            glassSizeMl: _glassSizeMl,
            remindersEnabled: _remindersEnabled,
            wakeHour: _wakeHour,
            sleepHour: _sleepHour,
            reminderIntervalMinutes: _intervalMinutes,
          ),
        );
  }

  void _nextStep() {
    if (_step < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  const HydraLogo(size: 36, showShadow: false),
                  const SizedBox(width: 10),
                  Text(
                    'Hydra',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Omitir',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: List.generate(3, (index) {
                  final active = index <= _step;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 4,
                      margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: active
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _step = index),
                children: [
                  _buildGoalStep(theme),
                  _buildGlassStep(theme),
                  _buildReminderStep(theme),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                children: [
                  if (_step > 0) ...[
                    OutlinedButton(
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      ),
                      child: const Text('Atrás'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: _nextStep,
                      child: Text(_step < 2 ? 'Continuar' : 'Comenzar con Hydra'),
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

  Widget _buildGoalStep(ThemeData theme) {
    final glasses = (_dailyGoalMl / _glassSizeMl).ceil();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu meta diaria\nde hidratación',
            style: theme.textTheme.headlineMedium?.copyWith(height: 1.15),
          ),
          const SizedBox(height: 8),
          Text(
            'Calculamos una meta sugerida según tu peso y actividad, o ajústala a tu gusto.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    HydrationUtils.formatVolumeExact(_dailyGoalMl),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aproximadamente $glasses vasos al día',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _dailyGoalMl.toDouble(),
                    min: 1200,
                    max: 4000,
                    divisions: 56,
                    onChanged: (v) =>
                        setState(() => _dailyGoalMl = (v / 50).round() * 50),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Calculadora rápida', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Peso corporal'),
                      Text(
                        '$_weightKg kg',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _weightKg.toDouble(),
                    min: 40,
                    max: 130,
                    divisions: 90,
                    onChanged: (v) {
                      setState(() {
                        _weightKg = v.round();
                        _recalculateGoal();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('Nivel de actividad'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ActivityLevel.values.map((level) {
                      final selected = level == _activityLevel;
                      return ChoiceChip(
                        label: Text(level.label),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _activityLevel = level;
                            _recalculateGoal();
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassStep(ThemeData theme) {
    const options = [
      (ml: 200, title: 'Vaso pequeño', subtitle: '200 ml · Ideal para tomas frecuentes'),
      (ml: 250, title: 'Vaso estándar', subtitle: '250 ml · El clásico recomendado'),
      (ml: 350, title: 'Vaso grande', subtitle: '350 ml · Taza o vaso alto'),
      (ml: 500, title: 'Botella', subtitle: '500 ml · Para quienes usan termo'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'El tamaño de tu\nvaso principal',
            style: theme.textTheme.headlineMedium?.copyWith(height: 1.15),
          ),
          const SizedBox(height: 8),
          Text(
            'Será el valor del botón rápido de un toque en tu pantalla principal.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),
          ...options.map((opt) {
            final selected = _glassSizeMl == opt.ml;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _glassSizeMl = opt.ml),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          opt.ml >= 500
                              ? Icons.local_drink_rounded
                              : Icons.water_drop_outlined,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(opt.title, style: theme.textTheme.titleMedium),
                            const SizedBox(height: 2),
                            Text(opt.subtitle, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: theme.colorScheme.primary,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReminderStep(ThemeData theme) {
    const intervals = [60, 90, 120, 180];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recordatorios\ninteligentes',
            style: theme.textTheme.headlineMedium?.copyWith(height: 1.15),
          ),
          const SizedBox(height: 8),
          Text(
            'Avisos discretos en tu horario activo. Cuando cumplas tu meta del día, Hydra se silencia automáticamente.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Activar recordatorios',
                                style: theme.textTheme.titleMedium),
                            Text('Puedes cambiar esto en cualquier momento',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Switch(
                        value: _remindersEnabled,
                        onChanged: (v) => setState(() => _remindersEnabled = v),
                      ),
                    ],
                  ),
                  if (_remindersEnabled) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(),
                    ),
                    Text('Frecuencia', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: intervals.map((min) {
                        final label = min == 60
                            ? 'Cada 1 h'
                            : min == 90
                                ? 'Cada 1.5 h'
                                : 'Cada ${min ~/ 60} h';
                        return ChoiceChip(
                          label: Text(label),
                          selected: _intervalMinutes == min,
                          onSelected: (_) =>
                              setState(() => _intervalMinutes = min),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _HourSelector(
                            label: 'Desde',
                            hour: _wakeHour,
                            onChanged: (h) {
                              setState(() {
                                _wakeHour = h;
                                if (_sleepHour <= _wakeHour) {
                                  _sleepHour = (_wakeHour + 1).clamp(1, 23);
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HourSelector(
                            label: 'Hasta',
                            hour: _sleepHour,
                            onChanged: (h) {
                              setState(() {
                                _sleepHour = h;
                                if (_sleepHour <= _wakeHour) {
                                  _wakeHour = (_sleepHour - 1).clamp(0, 22);
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HourSelector extends StatelessWidget {
  const _HourSelector({
    required this.label,
    required this.hour,
    required this.onChanged,
  });

  final String label;
  final int hour;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStepButton(
                icon: Icons.remove_rounded,
                onTap: hour > 5 ? () => onChanged(hour - 1) : null,
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    HydrationUtils.formatHour(hour),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              _MiniStepButton(
                icon: Icons.add_rounded,
                onTap: hour < 23 ? () => onChanged(hour + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStepButton extends StatelessWidget {
  const _MiniStepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null
              ? theme.colorScheme.onSurface
              : theme.disabledColor,
        ),
      ),
    );
  }
}
