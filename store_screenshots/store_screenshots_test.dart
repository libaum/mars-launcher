// Play Store screenshots as goldens — the real home screen with the showcase
// settings (showcase_settings.json) and a fixed app list, rendered offline:
//
//   flutter test --update-goldens store_screenshots/
//
// Writes 1080×2340 PNGs straight into graphix/apps/launcher/screenshots/,
// where graphix/tools/make_slides_v2.py picks them up. The names keep their
// old .jpg ending (the slide decks reference them); the renderer reads the
// PNG data regardless. Outside test/ on purpose: these are not regression
// tests.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mars_launcher/constants/method_channels.dart';
import 'package:mars_launcher/logic/app_search_manager.dart';
import 'package:mars_launcher/logic/apps_manager.dart';
import 'package:mars_launcher/logic/battery_manager.dart';
import 'package:mars_launcher/logic/settings_manager.dart';
import 'package:mars_launcher/logic/shortcut_manager.dart';
import 'package:mars_launcher/logic/temperature_manager.dart';
import 'package:mars_launcher/logic/todo_manager.dart';
import 'package:mars_launcher/main.dart';
import 'package:mars_launcher/pages/home/top_row/clock.dart';
import 'package:mars_launcher/pages/home/top_row/event.dart';
import 'package:mars_launcher/services/permission_service.dart';
import 'package:mars_launcher/services/service_locator.dart';
import 'package:mars_launcher/services/shared_prefs_manager.dart';
import 'package:mars_launcher/strings.dart';
import 'package:mars_launcher/theme/theme_constants.dart';
import 'package:mars_launcher/theme/theme_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _out = '../../graphix/apps/launcher/screenshots';

/// The phone the old screenshots were taken on: 1080×2340 at 480 dpi,
/// three-button navigation (48 dp), and a top inset that puts the top row
/// where it was — measured against those screenshots to the pixel.
const _size = Size(1080, 2340);
const _pixelRatio = 3.0;
const _navBarHeight = 144.0;
const _topInset = 103.0;

/// What "installed" means in the screenshots — no real apps.
const _installedApps = [
  'WhatsApp', 'Spotify', 'Maps', 'Chrome', 'Gmail', 'Calculator', 'Clock', 'Camera', 'Calendar', //
  'Contacts', 'Phone', 'Photos', 'YouTube', 'Notes', 'Play Store', 'Netflix', 'Docs', 'Meet',
];
const _todos = ['Team meeting prep', 'Call mom', 'Book flight'];
const _clock = '10:10';
const _event = 'Meeting';
final _eventStart = DateTime.utc(2026, 1, 1, 11, 30);

/// Names for the background presets, in their order in theme_constants.
const _lightNames = ['sand', 'sage', 'powder', 'blush', 'lavender'];
const _darkNames = ['navy', 'plum', 'teal', 'burgundy', 'rust'];

/// Picked with the free colour picker instead of a preset.
const _customLight = {'lemon': Color(0xFFF3EDB8)};
const _customDark = {'forest': Color(0xFF23361F)};

void main() {
  late ThemeManager theme;

  setUpAll(() async {
    await _loadFonts();
    _mockPlatform();
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      ...(jsonDecode(File('showcase_settings.json').readAsStringSync()) as Map).cast<String, Object>(),
      Keys.onboardingCompleted: true,
      Keys.todoList: _todos,
      Keys.temperatureCelsius: 21,
      Keys.temperatureUpdatedAt: DateTime.now().millisecondsSinceEpoch,
    });

    // As setupGetIt, with a temperature that never fetches.
    getIt
      ..registerSingleton<SharedPrefsManager>(await SharedPrefsManager.getInstance())
      ..registerSingleton<SettingsManager>(SettingsManager())
      ..registerSingleton<PermissionService>(PermissionService())
      ..registerSingleton<AppsManager>(AppsManager())
      ..registerSingleton<ThemeManager>(ThemeManager())
      ..registerSingleton<AppShortcutsManager>(AppShortcutsManager())
      ..registerSingleton<AppSearchManager>(AppSearchManager())
      ..registerSingleton<TemperatureManager>(_StoredTemperature())
      ..registerSingleton<BatteryManager>(BatteryManager())
      ..registerSingleton<TodoManager>(TodoManager());
    theme = getIt<ThemeManager>();
  });

  setUp(_mockPlatform);

  /// The launcher, dark or light on [background], with the demo clock and a
  /// three-button navigation bar drawn over the bottom inset.
  Future<void> launch(WidgetTester tester, {required bool dark, Color? background}) async {
    tester.view
      ..physicalSize = _size
      ..devicePixelRatio = _pixelRatio
      ..padding = const FakeViewPadding(top: _topInset, bottom: _navBarHeight)
      ..viewPadding = const FakeViewPadding(top: _topInset, bottom: _navBarHeight);
    addTearDown(tester.view.reset);
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;

    if (background != null) theme.setColor(dark ? ColorType.darkBackground : ColorType.lightBackground, background);
    theme.themeModeNotifier.value = dark ? ThemeMode.dark : ThemeMode.light;
    final bg = dark ? theme.darkBackground : theme.lightBackground;

    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: [
        MarsLauncher(),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: _navBarHeight / _pixelRatio,
          child: CustomPaint(painter: _NavBar(bg, dark: dark)),
        ),
      ],
    ));
    await tester.pumpAndSettle();

    // The clock follows the real time; the calendar event comes from the
    // mocked device calendar.
    final clock = tester.widget<ValueListenableBuilder<String>>(
        find.descendant(of: find.byType(Clock), matching: find.byType(ValueListenableBuilder<String>)));
    (clock.valueListenable as ValueNotifier<String>).value = _clock;
    await tester.pumpAndSettle();
  }

  /// The whole view in device pixels: the root's layer carries the pixel ratio.
  Future<void> shoot(String name) => expectLater(find.byType(View), matchesGoldenFile('$_out/$name.jpg'));

  testWidgets('Home', (tester) async {
    await launch(tester, dark: true, background: Colors.black);
    await shoot('Home');
  });

  testWidgets('Search', (tester) async {
    await launch(tester, dark: true, background: Colors.black);
    await tester.drag(find.text('Maps'), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ca');
    await tester.pumpAndSettle();
    await shoot('Search');
  });

  testWidgets('Todo', (tester) async {
    await launch(tester, dark: true, background: Colors.black);
    await tester.longPress(find.byType(EventView));
    await tester.pumpAndSettle();
    await shoot('Todo');
  });

  final light = {
    for (final (i, name) in _lightNames.indexed) name: LIGHT_BACKGROUND_PRESETS[i],
    'white': Colors.white,
    ..._customLight,
  };
  for (final MapEntry(key: name, value: color) in light.entries) {
    testWidgets('fan_$name', (tester) async {
      await launch(tester, dark: false, background: color);
      await shoot('fan_$name');
    });
  }

  final dark = {for (final (i, name) in _darkNames.indexed) name: DARK_BACKGROUND_PRESETS[i], ..._customDark};
  for (final MapEntry(key: name, value: color) in dark.entries) {
    testWidgets('dark_fan_$name', (tester) async {
      await launch(tester, dark: true, background: color);
      await shoot('dark_fan_$name');
    });
  }
}

/// Answers the platform channels the home screen talks to: the installed
/// apps, calendar permission and one event today.
void _mockPlatform() {
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  void mock(String channel, Object? Function(MethodCall call) answer) =>
      messenger.setMockMethodCallHandler(MethodChannel(channel), (call) async => answer(call));

  mock(MethodChannels.installedApps, (call) => [
        for (final name in _installedApps)
          {'packageName': 'demo.${name.toLowerCase().replaceAll(' ', '')}', 'appName': name, 'isSystemApp': 'false'},
      ]);
  mock(MethodChannels.statusBar, (_) => null);
  mock(MethodChannels.launchApp, (_) => false);
  mock('flutter.baseflow.com/permissions/methods', (call) => switch (call.method) {
        'checkPermissionStatus' => 1, // granted
        'requestPermissions' => {for (final p in call.arguments as List) p: 1},
        _ => null,
      });
  mock('plugins.builttoroam.com/device_calendar', (call) => switch (call.method) {
        'hasPermissions' || 'requestPermissions' => true,
        'retrieveCalendars' => jsonEncode([
            {'id': '1', 'name': 'Personal', 'isReadOnly': false, 'isDefault': true, 'color': 0},
          ]),
        'retrieveEvents' => jsonEncode([
            {
              'eventId': '1',
              'calendarId': '1',
              'eventTitle': _event,
              'eventStartDate': _eventStart.millisecondsSinceEpoch,
              'eventStartTimeZone': 'UTC',
              'eventEndDate': _eventStart.add(const Duration(hours: 1)).millisecondsSinceEpoch,
              'eventEndTimeZone': 'UTC',
              'eventAllDay': false,
            },
          ]),
        _ => null,
      });
}

/// The stored 21 °C, never refreshed — no location, no network, and no
/// expiry timer left pending after a test.
class _StoredTemperature extends TemperatureManager {
  @override
  void maybeUpdateTemperature() {}
}

/// Samsung's three-button bar as on the old screenshots: back, home and
/// recents in a muted tone of the text colour — outlined on dark
/// backgrounds, single strokes on light ones. Measured in device pixels from
/// those screenshots.
class _NavBar extends CustomPainter {
  final Color background;
  final bool dark;

  _NavBar(this.background, {required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..scale(1 / _pixelRatio)
      ..drawRect(Offset.zero & size * _pixelRatio, Paint()..color = background);
    final ink = Color.alphaBlend(dark ? Colors.white.withValues(alpha: 0.32) : Colors.black.withValues(alpha: 0.51), background);
    const cy = 71.5;

    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Dark: a thick stroke with a thinner one in the background colour on
    // top, which leaves just its outline.
    void icon(Path path, {required double width, required double gap}) {
      if (!dark) {
        canvas.drawPath(path, stroke(ink, 5));
        return;
      }
      canvas
        ..drawPath(path, stroke(ink, width))
        ..drawPath(path, stroke(background, gap));
    }

    icon(
      Path()
        ..moveTo(244, cy - 20.5)
        ..lineTo(222, cy)
        ..lineTo(244, cy + 20.5),
      width: 13,
      gap: 5.5,
    );
    icon(
      Path()
        ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: const Offset(534.5, cy), width: 42, height: 42), const Radius.circular(12))),
      width: 11,
      gap: 4.5,
    );
    for (final x in [819.0, 837.5, 856.0]) {
      icon(
        Path()
          ..moveTo(x, cy - (dark ? 20 : 19))
          ..lineTo(x, cy + (dark ? 20 : 19)),
        width: 11,
        gap: 4.5,
      );
    }
  }

  @override
  bool shouldRepaint(_NavBar old) => old.background != background || old.dark != dark;
}

/// The app's fonts (Outfit, Material Icons) instead of the test font.
Future<void> _loadFonts() async {
  final manifest = jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
  for (final f in manifest.cast<Map>()) {
    final loader = FontLoader(f['family'] as String);
    for (final a in (f['fonts'] as List).cast<Map>()) {
      loader.addFont(rootBundle.load(a['asset'] as String));
    }
    await loader.load();
  }
}
