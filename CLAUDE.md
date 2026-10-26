# CLAUDE.md

Mars Launcher — a distraction-free Android home screen: a text-based app list,
swipe gestures and an optional top row (clock, weather, battery, calendar,
to-do). Released on Play.

Shared conventions: `../DESIGN.md` (this app predates it in places — see below).

## Commands

```bash
flutter run
flutter test
flutter analyze
./run_debug.sh                    # debug, com.cloudcatcher.mars_launcher.debug
./install_release.sh              # build, archive under apk_archive/, install
./install_release.sh list | restore [versionCode]
cd android && bundle exec fastlane alpha | production | metadata
# Store screenshots as goldens, offline → ../graphix/mars_launcher/screenshots/
flutter test --update-goldens store_screenshots/
```

Store screenshots (`store_screenshots/`, not part of `flutter test`): the real
app with `showcase_settings.json`, a fixed app list and mocked platform
channels (installed apps, calendar event), on a 1080×2340 / 3.0 phone with a
drawn three-button nav bar. The files keep their `.jpg` names but hold PNG
data — `slides_v2.yaml` and the Instagram decks reference them; the renderer
reads either. Then re-render the slides with
`/usr/bin/python3 ../graphix/tools/make_slides_v2.py ../graphix/mars_launcher/slides_v2.yaml`.

The applicationId is `com.cloudcatcher.mars_launcher` — published, never change
it. Version is `name+versionCode` in `pubspec.yaml`; changelogs go in
`android/fastlane/metadata/android/en-US/changelogs/<versionCode>.txt`.

## Deviations from the Mars standard

- User-configurable accent/search text colours and backgrounds in `ThemeManager`.
- `SharedPrefsManager` (loaded async before GetIt setup) instead of a
  `LocalStorageService`; persisted values use `ValueNotifierWithKey`.
- Debug flags in `lib/constants/global.dart`: `CLEAR_SHARED_PREFS_ON_DEBUG_START`,
  `LOAD_APPS_FROM_JSON`.

## Gestures

Home is three vertically stacked views (`HomeView`): swipe down → other Mars
apps (`lib/data/mars_apps.dart`; opens the app or its Play listing), swipe up →
search, left/right → cycle shortcuts. One drag = one transition. Long-press →
Settings, double-tap → theme. The bottom-edge dead zone is covered by
`test/home_gesture_gate_test.dart`.

## Gotchas

- **`CalenderManager`** (typo kept on purpose — grep before renaming) is not in
  GetIt; each `EventView` creates its own. Audit all uses before registering it.
- **Top row:** `spaceBetween` with three groups — Clock · (Battery + Weather as
  one `Row(mainAxisSize: min)`) · Calendar, so both gaps stay equal. Calendar is
  capped at 45 % width. Never put a `LayoutBuilder` inside the `TextButton` in
  `EventView` (it gets unconstrained width) — it must stay outside.
- **Focus on Android:** `IconButton` steals focus from a `TextField`. Where the
  field must stay focused (to-do input) use a `GestureDetector` around a plain
  `Icon`, and set `onEditingComplete: () {}` to suppress `nextFocus()`.
- **Permissions are lazy:** calendar only if that widget is on (re-requested
  when enabled), location only on the first weather update. Defaults: clock and
  calendar on, weather and battery off.
- Tests use `mocktail`; managers are mocked at the GetIt boundary.

## Hidden admin codes (search field)

Exact whole-field matches, handled in `AppSearchManager.updateFilteredApps`, so
they can never fire by accident:

- `#unlockallmarsapps` — reveals private Mars apps and "+ add app" (any package,
  stored in `customMarsApps`; long-press removes). A rename wins; otherwise a
  custom app shows its label minus "Mars ", or the package name.
- `#exportsettings` / `#importsettings` — dump/restore all SharedPreferences as
  JSON at `/sdcard/Android/data/<applicationId>/files/mars_settings.json`; only
  after unlocking. Move it with `./settings.sh pull|push`, restart after import.
