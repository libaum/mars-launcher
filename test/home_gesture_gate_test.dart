import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mars_launcher/logic/apps_manager.dart';
import 'package:mars_launcher/logic/settings_manager.dart';
import 'package:mars_launcher/logic/shortcut_manager.dart';
import 'package:mars_launcher/logic/temperature_manager.dart';
import 'package:mars_launcher/pages/home/home.dart';
import 'package:mars_launcher/logic/utils.dart';
import 'package:mars_launcher/strings.dart';
import 'package:mars_launcher/services/shared_prefs_manager.dart';
import 'package:mars_launcher/theme/theme_manager.dart';

class MockThemeManager extends Mock implements ThemeManager {}
class MockAppShortcutsManager extends Mock implements AppShortcutsManager {}
class MockTemperatureManager extends Mock implements TemperatureManager {}
class MockAppsManager extends Mock implements AppsManager {}
class MockSharedPrefsManager extends Mock implements SharedPrefsManager {}
class MockSettingsManager extends Mock implements SettingsManager {}

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();

    final mockThemeManager = MockThemeManager();
    final mockAppShortcutsManager = MockAppShortcutsManager();
    final mockTemperatureManager = MockTemperatureManager();
    final mockAppsManager = MockAppsManager();
    final mockSharedPrefsManager = MockSharedPrefsManager();
    final mockSettingsManager = MockSettingsManager();

    /// The home tree reads every widget toggle; default them all to off so the
    /// top row stays empty and the gesture assertions are the only variable.
    for (final entry in {
      Keys.clockEnabled: () => mockSettingsManager.clockWidgetEnabledNotifier,
      Keys.batteryEnabled: () => mockSettingsManager.batteryWidgetEnabledNotifier,
      Keys.weatherEnabled: () => mockSettingsManager.weatherWidgetEnabledNotifier,
      Keys.calendarEnabled: () => mockSettingsManager.calendarWidgetEnabledNotifier,
      Keys.statusBarFullyHidden: () => mockSettingsManager.statusBarFullyHiddenNotifier,
    }.entries) {
      when(entry.value).thenReturn(ValueNotifierWithKey<bool>(false, entry.key));
    }
    when(() => mockSettingsManager.enabledMarsAppsNotifier)
        .thenReturn(ValueNotifierWithKey<List<String>>([], Keys.enabledMarsApps));
    when(() => mockSettingsManager.marsAppsUnlockedNotifier)
        .thenReturn(ValueNotifierWithKey<bool>(false, Keys.marsAppsUnlocked));

    when(() => mockTemperatureManager.sunriseSunsetNotifier)
        .thenReturn(ValueNotifier<String>(""));
    when(() => mockTemperatureManager.maybeUpdateTemperature())
        .thenReturn(null);

    when(() => mockAppsManager.appsNotifier)
        .thenReturn(ValueNotifier([]));
    when(() => mockAppsManager.syncingNotifier)
        .thenReturn(ValueNotifier(false));
    when(() => mockAppsManager.loadAndSyncApps())
        .thenAnswer((_) async {});

    when(() => mockSharedPrefsManager.readData(any()))
        .thenReturn(null);
    when(() => mockSharedPrefsManager.readData('isFirstLaunch'))
        .thenReturn(false);

    getIt.registerSingleton<ThemeManager>(mockThemeManager);
    getIt.registerSingleton<AppShortcutsManager>(mockAppShortcutsManager);
    getIt.registerSingleton<TemperatureManager>(mockTemperatureManager);
    getIt.registerSingleton<AppsManager>(mockAppsManager);
    getIt.registerSingleton<SharedPrefsManager>(mockSharedPrefsManager);
    getIt.registerSingleton<SettingsManager>(mockSettingsManager);
  });

  testWidgets("Swipe from bottom edge does not open search", (tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(400, 800);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            viewPadding: EdgeInsets.only(bottom: 24),
          ),
          child: Home(
            topRowOverride: const SizedBox.shrink(),
            appShortcutsBuilder: () => const SizedBox(key: Key("shortcuts")),
            appSearchBuilder: () => const SizedBox(key: Key("search")),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key("shortcuts")), findsOneWidget);
    expect(find.byKey(const Key("search")), findsNothing);

    await tester.dragFrom(const Offset(200, 790), const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.byKey(const Key("search")), findsNothing);
    expect(find.byKey(const Key("shortcuts")), findsOneWidget);
  });

  testWidgets("Swipe above bottom edge opens search", (tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(400, 800);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            viewPadding: EdgeInsets.only(bottom: 24),
          ),
          child: Home(
            topRowOverride: const SizedBox.shrink(),
            appShortcutsBuilder: () => const SizedBox(key: Key("shortcuts")),
            appSearchBuilder: () => const SizedBox(key: Key("search")),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key("shortcuts")), findsOneWidget);
    expect(find.byKey(const Key("search")), findsNothing);

    await tester.dragFrom(const Offset(200, 740), const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.byKey(const Key("search")), findsOneWidget);
    expect(find.byKey(const Key("shortcuts")), findsNothing);
  });

  testWidgets("Swipe down reveals the Mars apps", (tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(400, 800);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            viewPadding: EdgeInsets.only(bottom: 24),
          ),
          child: Home(
            topRowOverride: const SizedBox.shrink(),
            appShortcutsBuilder: () => const SizedBox(key: Key("shortcuts")),
            appSearchBuilder: () => const SizedBox(key: Key("search")),
            marsAppsBuilder: () => const SizedBox(key: Key("marsApps")),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key("shortcuts")), findsOneWidget);
    expect(find.byKey(const Key("marsApps")), findsNothing);

    // A single down-swipe steps shortcuts -> marsApps (and no further).
    await tester.dragFrom(const Offset(200, 300), const Offset(0, 120));
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.byKey(const Key("marsApps")), findsOneWidget);
    expect(find.byKey(const Key("shortcuts")), findsNothing);
    expect(find.byKey(const Key("search")), findsNothing);

    // Swiping back up returns to the shortcuts view.
    await tester.dragFrom(const Offset(200, 300), const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.byKey(const Key("shortcuts")), findsOneWidget);
    expect(find.byKey(const Key("marsApps")), findsNothing);
  });
}
