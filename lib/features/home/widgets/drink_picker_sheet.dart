import 'package:flutter/material.dart';

import '../../../core/constants/drink_types.dart';
import '../../../core/utils/hydration_utils.dart';

class DrinkSelectionResult {
  const DrinkSelectionResult({
    required this.drinkType,
    required this.volumeMl,
  });

  final DrinkType drinkType;
  final int volumeMl;
}

Future<DrinkSelectionResult?> showDrinkPickerSheet(
  BuildContext context, {
  required int defaultGlassMl,
  required bool useOunces,
}) {
  return showModalBottomSheet<DrinkSelectionResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _DrinkPickerSheet(
      defaultGlassMl: defaultGlassMl,
      useOunces: useOunces,
    ),
  );
}

class _DrinkPickerSheet extends StatefulWidget {
  const _DrinkPickerSheet({
    required this.defaultGlassMl,
    required this.useOunces,
  });

  final int defaultGlassMl;
  final bool useOunces;

  @override
  State<_DrinkPickerSheet> createState() => _DrinkPickerSheetState();
}

class _DrinkPickerSheetState extends State<_DrinkPickerSheet> {
  DrinkType _selectedDrink = DrinkType.water;
  late int _volumeMl;

  @override
  void initState() {
    super.initState();
    _volumeMl = widget.defaultGlassMl;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveMl = (_volumeMl * _selectedDrink.hydrationFactor).round();
    final presets = {150, widget.defaultGlassMl, 350, 500}.toList()
      ..sort();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registrar bebida', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Cada bebida aplica su factor real de hidratación.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: DrinkType.values.map((drink) {
                final selected = drink == _selectedDrink;
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _selectedDrink = drink),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? drink.color.withValues(alpha: 0.14)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? drink.color
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(drink.icon, size: 18, color: drink.color),
                        const SizedBox(width: 8),
                        Text(
                          drink.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          drink.factorLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: drink.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cantidad', style: theme.textTheme.titleMedium),
                Text(
                  HydrationUtils.formatVolumeExact(
                    _volumeMl,
                    useOunces: widget.useOunces,
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: presets.map((ml) {
                return ChoiceChip(
                  label: Text(
                    HydrationUtils.formatVolumeExact(
                      ml,
                      useOunces: widget.useOunces,
                    ),
                  ),
                  selected: _volumeMl == ml,
                  onSelected: (_) => setState(() => _volumeMl = ml),
                );
              }).toList(),
            ),
            Slider(
              value: _volumeMl.toDouble(),
              min: 50,
              max: 1000,
              divisions: 19,
              onChanged: (v) => setState(() => _volumeMl = (v / 50).round() * 50),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.water_drop_rounded,
                    size: 18,
                    color: _selectedDrink.color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hidratación efectiva: +${HydrationUtils.formatVolumeExact(effectiveMl, useOunces: widget.useOunces)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(
                    DrinkSelectionResult(
                      drinkType: _selectedDrink,
                      volumeMl: _volumeMl,
                    ),
                  );
                },
                child: Text('Añadir ${_selectedDrink.label}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
