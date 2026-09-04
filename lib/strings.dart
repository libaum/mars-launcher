class Strings {
  /// Settings page names
  static const settingsTitle = "Settings";
  static const settingsClockApp = "Clock";
  static const settingsBattery = "Battery";
  static const settingsWeatherApp = "Weather";
  static const settingsCalendarApp = "Calendar";
  static const settingsSwipeLeft = "Swipe left";
  static const settingsSwipeRight = "Swipe right";
  static const settingsHiddenApps = "Hidden apps";
  static const settingsMarsApps = "Mars apps";
  static const marsAppsTitle = "Mars apps";
  static const settingsCredits = "About";
  static const settingsColors = "Colors";
  static const settingsMore = "More";
  static const settingsChangeDefaultLauncher = "Set default launcher";
  static const settingsAppNumber = "App number";
  static const String settingsKeyboardAutofocus = "Keyboard";

  static const settingsGroupAppShortcuts = " App shortcuts";
  static const settingsGroupAppearance = " Appearance";
  static const settingsGroupOther = " Other";

  static const creditsTitle = "About";
  static const cheatSheetTitle = "Cheat Sheet";
  static const settingsColorsTitle = "Colors";
  static const settingsColorsSearchColor = "Search color";
  static const settingsColorsBackground = "Background color";

  /// Standard names
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

  /// Shown wherever no app is set yet: in an empty shortcut slot and as the
  /// sublabel of a settings row. The gestures themselves are explained once
  /// by the first-run onboarding overlay, so the slots stay plain.
  static const notSet = 'Not set';

  /// Flight manual
  static const settingsFlightManual = "Cheat sheet";
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
  static const lightSearchColor = "light_search_color";
  static const darkSearchColor = "dark_search_color";
  static const darkBackground = "dark_background";
  static const weatherActivatedAtLeastOnce = "weatherActivatedAtLeastOnce";
  static const keyboardAutofocusEnabled = "keyboard_autofocus_enabled";
  static const onboardingCompleted = "onboardingCompleted";
  static const statusBarFullyHidden = "statusBarFullyHidden";
  static const temperatureCelsius = "temperatureCelsius";
  static const temperatureUpdatedAt = "temperatureUpdatedAt";
  static const temperatureLat = "temperatureLat";
  static const temperatureLon = "temperatureLon";
  static const sunriseSunsetText = "sunriseSunsetText";
  static const sunriseSunsetUpdatedAt = "sunriseSunsetUpdatedAt";
}

class JsonKeys {
  static const packageName = "packageName";
  static const appName = "appName";
  static const systemApp = "systemApp";
  static const displayName = "appDisplayName";
  static const appIsHidden = "appIsHidden";
}

