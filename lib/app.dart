import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'data/providers/hydra_providers.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/splash/splash_screen.dart';

class HydraApp extends ConsumerStatefulWidget {
  const HydraApp({
    super.key,
    this.showSplash = true,
  });

  final bool showSplash;

  @override
  ConsumerState<HydraApp> createState() => _HydraAppState();
}

class _HydraAppState extends ConsumerState<HydraApp> {
  late bool _showingSplash;

  @override
  void initState() {
    super.initState();
    _showingSplash = widget.showSplash;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(hydraProvider.select((s) => s.settings));

    final Widget home;
    if (_showingSplash) {
      home = SplashScreen(
        onFinished: () => setState(() => _showingSplash = false),
      );
    } else if (settings.onboardingCompleted) {
      home = const HydraShell();
    } else {
      home = const OnboardingScreen();
    }

    return MaterialApp(
      title: 'Hydra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        child: home,
      ),
    );
  }
}

class HydraShell extends StatefulWidget {
  const HydraShell({super.key});

  @override
  State<HydraShell> createState() => _HydraShellState();
}

class _HydraShellState extends State<HydraShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    ProgressScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.colorScheme.outline, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.water_drop_outlined),
              selectedIcon: Icon(Icons.water_drop_rounded),
              label: 'Hoy',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'Progreso',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune_rounded),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }
}
