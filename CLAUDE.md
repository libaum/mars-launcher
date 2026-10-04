# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mars Launcher is a minimalist Flutter Android launcher app. It replaces the system home screen with a text-based app list, swipe gestures, and an optional widget bar (clock, weather, battery, calendar, to-do).

## Common Commands

```bash
# Run app
flutter run

# Run tests
flutter test
flutter test test/home_gesture_gate_test.dart

# Lint / static analysis
flutter analyze

# Debug: run on a connected device via flutter run (hot reload)
./run_debug.sh                 # com.cloudcatcher.mars_launcher.debug ("Mars Launcher DEBUG")

# Release: build + archive an APK, then install (coexists with debug)
./install_release.sh           # build release APK, archive under apk_archive/, install
./install_release.sh list      # list archived APKs (newest first)
./install_release.sh restore    # reinstall most recent archived APK (no rebuild)
./install_release.sh restore 21 # reinstall archived APK for versionCode 21

# Deploy to Google Play via Fastlane (from android/)
cd android && bundle exec fastlane production  # build + upload to Production
cd android && bundle exec fastlane alpha       # build + upload to Alpha (closed testing, draft)
cd android && bundle exec fastlane metadata    # update store listing text/images only
```

## Architecture

### Dependency Injection

All global state lives in singleton "Manager" classes registered via `GetIt` in `lib/services/service_locator.dart`. To access a manager anywhere: `getIt<SettingsManager>()`. Managers are initialized once in `main()` before `runApp`.

### State Management

Managers expose state via `ValueNotifier` (or `ValueNotifierWithKey` for persisted values). UI widgets subscribe with `ValueListenableBuilder`. There is no Bloc/Provider/Riverpod — pure Flutter primitives.

### Key Managers

| Manager | Responsibility |
|---|---|
| `SettingsManager` | All user preferences (widget toggles, shortcut count, first-run flag) |
| `AppsManager` | Load/sync installed apps from Android; maintains the displayed app list |
| `AppSearchManager` | Filters apps list for search |
| `AppShortcutsManager` | Swipe-accessible quick-launch shortcuts |
| `ThemeManager` | Dark/light mode, custom accent colors |
| `TemperatureManager` | Weather via open-meteo API + sunrise/sunset |
| `BatteryManager` | Battery level/charging state |
| `TodoManager` | Persisted to-do list (SharedPreferences) |
| `SharedPrefsManager` | Thin wrapper around SharedPreferences, loaded async before GetIt setup |

### Home Screen Gesture System

`lib/pages/home/home.dart` is the central UI. It owns a `GestureDetector` that maps gestures to navigation. The home screen is three vertically-stacked views (`HomeView` enum: `marsApps` / `shortcuts` / `search`) selected by `homeViewNotifier`; each vertical drag steps one view (gated by `_verticalDragConsumed` so one gesture = one transition):
- Swipe up → `search` (`AppSearchFragment`)
- Swipe down → `marsApps` (`MarsAppsFragment`): the other Mars family apps — tap to open if installed, else open the Play Store listing. The family list lives in `lib/data/mars_apps.dart`.
- Swipe left/right → cycle through `AppShortcutsFragment` (only on the `shortcuts` view)
- Long press → Settings
- Double tap → toggle theme

The bottom-edge swipe dead zone behavior is tested in `test/home_gesture_gate_test.dart`.

### Android Integration

Method channels (constants in `lib/constants/method_channels.dart`) bridge to Kotlin for:
- Registering the app-change broadcast receiver (notifies `AppsManager` when apps install/uninstall)
- Opening system default-launcher settings

### Persistence

All user data is stored locally in `SharedPreferences`. There is no backend or remote sync.

## Key Files

- `lib/main.dart` — entry point; calls `setupGetIt()`, then `runApp`, then registers the Android broadcast receiver
- `lib/services/service_locator.dart` — GetIt registration order matters (SharedPrefsManager first)
- `lib/constants/global.dart` — feature flags: `CLEAR_SHARED_PREFS_ON_DEBUG_START`, `LOAD_APPS_FROM_JSON`
- `lib/theme/theme_constants.dart` — color/style definitions for light and dark themes

## Testing

Tests use `flutter_test` + `mocktail`. Managers are mocked at the GetIt boundary. Widget tests call `testWidgets` and inject mock managers before pumping the widget under test.

## Known Architecture Notes

### CalenderManager (typo intentional — don't rename without grep)
`CalenderManager` is **not** registered in GetIt. It is instantiated directly inside `EventView` (`lib/pages/home/top_row/event.dart`). This is intentional for now but means each EventView gets its own timer and state. Don't add it to service_locator without auditing all usages.

### Top Row Layout
The top row (`lib/pages/home/top_row/top_row.dart`) uses `MainAxisAlignment.spaceBetween` with three logical groups to give Battery+Weather equal spacing to Clock (left) and Calendar text (right):
```
[Clock]   [Battery + Weather]   [Calendar]
```
Battery+Weather are a nested `Row(mainAxisSize: min)` so `spaceBetween` treats them as one unit. Calendar is bounded by `ConstrainedBox(maxWidth: rowWidth * 0.45)` to prevent overflow; EventView's TextButton has `minimumSize: Size.zero` so it shrinks to its actual text width. With `spaceBetween`, the two gaps are always equal regardless of text length. Do not add a `LayoutBuilder` inside `TextButton` — it gets unconstrained width. The `LayoutBuilder` in `EventView` must stay outside the `TextButton`.

### Permissions
- Calendar permission is only requested at startup if the calendar widget is enabled. Re-requested when user enables it via settings (`PermissionService` listens to `calendarWidgetEnabledNotifier`).
- Weather/location permission is requested lazily on first `updateTemperature()` call, which only runs when the weather widget is enabled.
- Battery requires no permission.
- Default widget states: Clock=on, Calendar=on, Weather=off, Battery=off.

### Text Input + Focus on Android
`IconButton` participates in Flutter's focus system and steals focus from `TextField` on tap. When a `TextField` must stay focused after a button press (e.g. todo input), use `GestureDetector` wrapping a plain `Icon` instead of `IconButton`. Also set `onEditingComplete: () {}` on the `TextField` to suppress the default `FocusScope.nextFocus()` behavior when the keyboard action button is pressed.

### Releases
Changelogs live in `android/fastlane/metadata/android/en-US/changelogs/<versionCode>.txt`. Version is set in `pubspec.yaml` as `name+versionCode` (e.g. `1.2.0+18`).

### Hidden admin features (search-field keywords)
The app search field, in normal open-app mode, matches a few exact-string secret codes (see `lib/data/mars_apps.dart` and `lib/logic/settings_transfer.dart`). They must equal the whole field exactly so they never trigger by accident, and are handled in `AppSearchManager.updateFilteredApps`:
- `#unlockallmarsapps` — reveal the private Mars apps (`private: true`) in the swipe-down overview and settings; persisted in SharedPreferences. Once unlocked, the Mars apps settings page also offers "+ add app" (add any app by package name, stored in `customMarsApps`; long-press removes it). Names: a rename wins as-is; a custom app otherwise shows its installed label minus the "Mars " prefix, or the package name if it isn't installed.
- `#exportsettings` / `#importsettings` — dump/restore the full SharedPreferences state as JSON at `/sdcard/Android/data/<applicationId>/files/mars_settings.json`. Only work once the Mars apps are unlocked (admin gate). Use `./settings.sh pull|push` to move the file via adb; restart the launcher after an import so managers reload. Change the codes to your own secrets before a public release.
