import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydra/app.dart';
import 'package:hydra/data/providers/hydra_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Onboarding completes and user can log a glass of water',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const HydraApp(),
      ),
    );
    await tester.pump();

    // SplashScreen visible al arrancar
    expect(find.text('Hydra'), findsOneWidget);
    expect(find.text('Tu hidratación, simple'), findsOneWidget);

    // Transición automática del Splash al Onboarding
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 400));

    // Pantalla de onboarding visible
    expect(find.text('Hydra'), findsOneWidget);
    expect(find.text('Omitir'), findsOneWidget);

    // Completar onboarding rápidamente
    await tester.tap(find.text('Omitir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Pantalla principal Hoy visible
    expect(find.text('vasos hoy'), findsOneWidget);
    final addGlassBtn = find.textContaining('Añadir 1 vaso');
    expect(addGlassBtn, findsOneWidget);

    // Añadir 1 vaso
    await tester.tap(addGlassBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('1 registro'), findsOneWidget);

    // Navegar a Progreso
    await tester.tap(find.text('Progreso'));
    await tester.pump();
    expect(find.text('Racha actual'), findsOneWidget);
    expect(find.text('Constancia · 28 días'), findsOneWidget);

    // Navegar a Ajustes
    await tester.tap(find.text('Ajustes'));
    await tester.pump();
    expect(find.text('RECORDATORIOS INTELIGENTES'), findsOneWidget);
  });
}
