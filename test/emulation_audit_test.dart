import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydra/app.dart';
import 'package:hydra/core/constants/drink_types.dart';
import 'package:hydra/data/models/user_settings.dart';
import 'package:hydra/data/models/water_entry.dart';
import 'package:hydra/data/providers/hydra_providers.dart';
import 'package:hydra/data/repositories/storage_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<SharedPreferences> createPrefs({
    UserSettings? settings,
    List<WaterEntry>? entries,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageRepository(prefs);
    if (settings != null) await storage.saveSettings(settings);
    if (entries != null) await storage.saveEntries(entries);
    return prefs;
  }

  group('Emulación virtual multi-dispositivo y flujos completos', () {
    testWidgets(
      'Flujo completo de Onboarding paso a paso en pantalla compacta (360x640)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final prefs = await createPrefs();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: const HydraApp(showSplash: false),
          ),
        );
        await tester.pump();

        // Paso 1: seleccionar nivel de actividad "Activo" y avanzar
        await tester.ensureVisible(find.text('Activo'));
        await tester.tap(find.text('Activo'));
        await tester.pump();

        await tester.tap(find.text('Continuar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Paso 2: elegir vaso de 350 ml y avanzar
        await tester.ensureVisible(find.text('Vaso grande'));
        await tester.pump();
        await tester.tap(find.text('Vaso grande'));
        await tester.pump();

        await tester.tap(find.text('Continuar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Paso 3: elegir frecuencia "Cada 1.5 h" y finalizar
        await tester.ensureVisible(find.text('Cada 1.5 h'));
        await tester.pump();
        await tester.tap(find.text('Cada 1.5 h'));
        await tester.pump();

        await tester.tap(find.text('Comenzar con Hydra'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verifica llegada a Hoy con el vaso de 350 ml configurado
        expect(find.textContaining('350 ml'), findsWidgets);
      },
    );

    testWidgets(
      'Flujo completo de Hoy: registrar agua, deshacer, bebida con factor y eliminar',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final prefs = await createPrefs(
          settings: const UserSettings(
            onboardingCompleted: true,
            dailyGoalMl: 1000,
            glassSizeMl: 250,
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: const HydraApp(showSplash: false),
          ),
        );
        await tester.pump();

        // 1. Añadir 1 vaso (250 ml)
        await tester.tap(find.textContaining('Añadir 1 vaso'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('1 registro'), findsOneWidget);

        // 2. Deshacer desde SnackBar
        await tester.tap(find.text('Deshacer'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('0 registros'), findsOneWidget);

        // 3. Abrir selector de bebida y añadir Café (250 ml * 80% = 200 ml)
        await tester.tap(find.text('Bebida'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('Registrar bebida'), findsOneWidget);
        await tester.tap(find.text('Café'));
        await tester.pump();
        expect(find.textContaining('200 ml'), findsWidgets);

        await tester.tap(find.text('Añadir Café'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('1 registro'), findsOneWidget);
        expect(find.text('+200 ml'), findsOneWidget);

        // Desplazar la lista hacia arriba para despejar el SnackBar flotante y deslizar para eliminar
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -220));
        await tester.pump();
        await tester.drag(find.byType(Dismissible).first, const Offset(-500, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('0 registros'), findsOneWidget);
      },
    );

    testWidgets(
      'Emulación de Progreso y Ajustes con historial de 10 días, Escudo de racha, tema oscuro y texto grande (1.3x)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day, 9, 0);
        final entries = <WaterEntry>[];

        // 7 días cumplidos (gana 1 escudo), día -2 omitido (congelado), ayer y hoy cumplidos
        for (final offset in [9, 8, 7, 6, 5, 4, 3, 1, 0]) {
          final day = today.subtract(Duration(days: offset));
          entries.add(
            WaterEntry(
              id: 'e_$offset',
              timestamp: day,
              volumeMl: 2000,
              drinkType: offset == 0
                  ? DrinkType.water
                  : (offset == 1 ? DrinkType.tea : DrinkType.electrolytes),
            ),
          );
        }

        final prefs = await createPrefs(
          settings: const UserSettings(
            onboardingCompleted: true,
            dailyGoalMl: 2000,
            glassSizeMl: 250,
            themeMode: ThemeMode.dark,
          ),
          entries: entries,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 640),
                textScaler: TextScaler.linear(1.3),
              ),
              child: const HydraApp(showSplash: false),
            ),
          ),
        );
        await tester.pump();

        // Navegar a Progreso y hacer scroll completo para detectar overflows
        await tester.tap(find.text('Progreso'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.drag(find.byType(ListView).first, const Offset(0, -400));
        await tester.pump();
        await tester.drag(find.byType(ListView).first, const Offset(0, -400));
        await tester.pump();

        expect(find.text('Logros'), findsOneWidget);

        // Navegar a Ajustes, abrir modales y cambiar a onzas + modo claro
        await tester.tap(find.text('Ajustes'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Abrir modal de Meta diaria
        await tester.tap(find.text('Meta diaria'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.text('Guardar meta'), findsOneWidget);
        await tester.tap(find.text('Guardar meta'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Cambiar a onzas (oz)
        await tester.tap(find.text('Mostrar en onzas (oz)'));
        await tester.pump();

        // Abrir modal de Frecuencia y horario
        await tester.drag(find.byType(ListView).last, const Offset(0, -420));
        await tester.pump();
        await tester.tap(find.text('Frecuencia y horario'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.text('Guardar horario'), findsOneWidget);
        await tester.tap(find.text('Guardar horario'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Scroll hasta selector de Tema y cambiar a Claro
        await tester.drag(find.byType(ListView).last, const Offset(0, -450));
        await tester.pump();
        await tester.drag(find.byType(ListView).last, const Offset(0, -450));
        await tester.pump();
        await tester.tap(find.text('Claro'));
        await tester.pump();
      },
    );
  });
}
