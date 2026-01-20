import 'package:flutter/material.dart';
import 'package:pharmatest/splash_screen.dart';
import 'package:pharmatest/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:pharmatest/pharmacy_repository.dart';

const String fetchTaskName = "fetchPharmaciesTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == fetchTaskName) {
      try {
        WidgetsFlutterBinding.ensureInitialized();
        final prefs = await SharedPreferences.getInstance();
        final repository = PharmacyRepository(prefs);

        // 1. Refresh Regions (Base data)
        await repository.getRegionsAndTowns();

        // 2. Refresh Favorites or Fallback
        final favorites = repository.getFavoriteCities();

        if (favorites.isNotEmpty) {
          // Update all favorite cities
          for (final cityKey in favorites) {
            final parts = cityKey.split('|');
            if (parts.length == 2) {
              await repository.updatePharmaciesInBackground(parts[0], parts[1]);
            }
          }
        } else {
          // Fallback: Refresh specific city if saved (Last Viewed)
          final lastRegion = prefs.getString('last_region');
          final lastCity = prefs.getString('last_city');

          if (lastRegion != null && lastCity != null) {
            await repository.updatePharmaciesInBackground(lastRegion, lastCity);
          }
        }
      } catch (e) {
        debugPrint("Background fetch error: $e");
        return Future.value(false);
      } finally {
        // Schedule the next run (Chain reaction)
        _scheduleNextFetch();
      }
    }
    return Future.value(true);
  });
}

void _scheduleNextFetch({ExistingWorkPolicy policy = ExistingWorkPolicy.replace}) {
  final now = DateTime.now();
  // Targets: Today 7am, Today 6pm, Tomorrow 7am
  final targets = [
    DateTime(now.year, now.month, now.day, 7, 0), // 7:00 AM
    DateTime(now.year, now.month, now.day, 18, 0), // 6:00 PM
    DateTime(now.year, now.month, now.day + 1, 7, 0), // Tomorrow 7:00 AM
  ];

  // Find the first target that is in the future
  final nextTarget = targets.firstWhere((t) => t.isAfter(now));
  final delay = nextTarget.difference(now);

  Workmanager().registerOneOffTask(
    "unique_fetch_task",
    fetchTaskName,
    initialDelay: delay,
    existingWorkPolicy: policy,
    constraints: Constraints(networkType: NetworkType.connected),
    backoffPolicy: BackoffPolicy.linear,
    backoffPolicyDelay: const Duration(minutes: 15),
  );
  debugPrint(
    "Next background fetch scheduled in ${delay.inHours} hours and ${delay.inMinutes % 60} minutes with policy ${policy.name}",
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Workmanager
  Workmanager().initialize(callbackDispatcher);

  // Schedule the first task based on current time
  // Use .keep to avoid resetting the timer every time the app opens
  _scheduleNextFetch(policy: ExistingWorkPolicy.keep);

  final prefs = await SharedPreferences.getInstance();

  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ValueNotifier<ThemeMode> _themeModeNotifier;

  @override
  void initState() {
    super.initState();
    _initThemeMode();
  }

  // Initialise le thème de manière synchrone pour éviter le flash au démarrage
  void _initThemeMode() {
    final savedTheme = widget.prefs.getString('theme_mode') ?? 'dark';
    ThemeMode initialMode;
    switch (savedTheme) {
      case 'light':
        initialMode = ThemeMode.light;
        break;
      case 'dark':
        initialMode = ThemeMode.dark;
        break;
      case 'system':
        initialMode = ThemeMode.system;
        break;
      default:
        initialMode = ThemeMode.dark;
    }
    _themeModeNotifier = ValueNotifier(initialMode);
  }

  // Sauvegarde la préférence de thème
  Future<void> _saveThemePreference(ThemeMode mode) async {
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }
    await widget.prefs.setString('theme_mode', modeString);
  }

  // Cycle entre les modes: dark -> light -> system -> dark
  void toggleTheme() {
    ThemeMode newMode;
    switch (_themeModeNotifier.value) {
      case ThemeMode.dark:
        newMode = ThemeMode.light;
        break;
      case ThemeMode.light:
        newMode = ThemeMode.system;
        break;
      case ThemeMode.system:
        newMode = ThemeMode.dark;
        break;
    }
    _themeModeNotifier.value = newMode;
    _saveThemePreference(newMode);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeModeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          themeAnimationDuration: const Duration(milliseconds: 500),
          themeAnimationCurve: Curves.easeInOut,
          home: SplashScreen(
            prefs: widget.prefs,
            toggleTheme: toggleTheme,
            themeModeNotifier: _themeModeNotifier,
          ),
        );
      },
    );
  }
}
