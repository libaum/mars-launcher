class Strings {
  /// Settings page names
  static const settingsTitle = "Settings";
  static const settingsClockApp = "clock app";
  static const settingsBattery = "battery";
  static const settingsWeatherApp = "weather app";
  static const settingsCalendarApp = "calendar app";
  static const settingsSwipeLeft = "swipe left";
  static const settingsSwipeRight = "swipe right";
  static const settingsHiddenApps = "hidden apps";
  static const settingsMarsApps = "mars apps";
  static const marsAppsTitle = "Mars apps";
  static const settingsCredits = "about";
  static const settingsColors = "colors";
  static const settingsMore = "more";
  static const settingsChangeDefaultLauncher = "set default launcher";
  static const settingsAppNumber = "app number";
  static const String settingsKeyboardAutofocus = "Keyboard";

  static const settingsGroupAppShortcuts = " app shortcuts";
  static const settingsGroupAppearance = " appearance";
  static const settingsGroupOther = " other";

  static const creditsTitle = "About";
  static const cheatSheetTitle = "Cheat Sheet";
  static const settingsColorsTitle = "Colors";
  static const settingsColorsSearchColor = "search color";
  static const settingsColorsLightBackground = "light background";
  static const settingsColorsDarkBackground = "dark background";

  /// Standard names
  static const defaultTemperatureString = "-°C";
  static const appNameUninitialized = slotDefault;
  static const packageNameClockUninitialized = "uninitialized clock app";
  static const packageNameBatteryUninitialized = "uninitialized battery app";
  static const packageNameCalendarUninitialized = "uninitialized calendar app";
  static const packageNameWeatherUninitialized = "uninitialized weather app";
  static const packageNameSwipeLeftUninitialized = "uninitialized swipe left app";
  static const packageNameSwipeRightUninitialized = "uninitialized swipe right app";
  static const textCalendarEmpty = "no events";

  /// Default slots
  static const slotDefault = ' + ';

  /// Shortcut placeholders — shown for uninitialized slots until reassigned.
  /// Indices 0..3 carry first-launch tutorial hints; later slots fall back
  /// to [shortcutPlaceholderDefault].
  static const shortcutPlaceholders = [
    'hold here to set an app',
    'swipe up to search',
    'hold void for settings',
    'double tap to flip theme',
  ];
  static const shortcutPlaceholderDefault = 'hold to set an app';

  /// First-launch tip shown as a SnackBar.
  static const firstLaunchTip = 'tip: find all commands in cheat sheet';
  static const firstLaunchTipAction = 'open';

  /// Flight manual
  static const settingsFlightManual = "cheat sheet";
}

/// Shared preferences keys
class Keys {
  static const weatherEnabled = "weatherEnabled";
  static const clockEnabled = "clockEnabled";
  static const batteryEnabled = "batteryEnabled";
  static const calendarEnabled = "calendarEnabled";
  static const numOfShortcutItems = "numOfShortcutItems";
  static const shortcutMode = "shortcutMode";
  static const isFirstStartup = "isFirstStartup";
  static const todoList = "todoList";
  static const hiddenApps = "hiddenApps";
  static const enabledMarsApps = "enabledMarsApps";
  static const marsAppsUnlocked = "marsAppsUnlocked";
  static const renamedApps = 'renamedApps';
  static const appsAreSaved = "appsAreSaved";
  static const typeAppClock = "clockApp";
  static const typeAppBattery = "batteryApp";
  static const typeAppCalendar = "calendarApp";
  static const typeAppWeather = "weatherApp";
  static const typeAppSwipeLeft = "swipeLeftApp";
  static const typeAppSwipeRight = "swipeRightApp";
  static const themeMode = "themeMode";
  static const lightBackground = "light_background";
  static const searchColor = "search_color";
  static const darkBackground = "dark_background";
  static const weatherActivatedAtLeastOnce = "weatherActivatedAtLeastOnce";
  static const keyboardAutofocusEnabled = "keyboard_autofocus_enabled";
  static const isFirstLaunch = "isFirstLaunch";
}

class JsonKeys {
  static const packageName = "packageName";
  static const appName = "appName";
  static const systemApp = "systemApp";
  static const displayName = "appDisplayName";
  static const appIsHidden = "appIsHidden";
}

