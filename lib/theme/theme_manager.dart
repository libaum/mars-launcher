/// All logic according to dark and light theme

import 'package:flutter/material.dart';
import 'package:mars_launcher/services/service_locator.dart';
import 'package:mars_launcher/services/shared_prefs_manager.dart';
import 'package:mars_launcher/strings.dart';
import 'package:mars_launcher/theme/theme_constants.dart';


enum ColorType {
  lightBackground,
  darkBackground,
  lightSearchTextColor,
  darkSearchTextColor,
}

class ThemeManager {
  final sharedPrefsManager = getIt<SharedPrefsManager>();

  late final themeModeNotifier;

  late Color lightBackground;
  late Color darkBackground;
  late Color lightSearchTextColor;
  late Color darkSearchTextColor;

  ThemeManager() {
    themeModeNotifier = ThemeModeNotifier<ThemeMode>(
        sharedPrefsManager.readDataWithDefault(Keys.themeMode, true) ? ThemeMode.dark : ThemeMode.light
    );
    lightBackground = Color(sharedPrefsManager.readData(Keys.lightBackground) ?? Colors.white.value);
    darkBackground = Color(sharedPrefsManager.readData(Keys.darkBackground) ?? Colors.black.value);
    lightSearchTextColor = Color(sharedPrefsManager.readData(Keys.lightSearchColor) ?? COLOR_ACCENT.value);
    darkSearchTextColor = Color(sharedPrefsManager.readData(Keys.darkSearchColor) ?? COLOR_ACCENT.value);
  }

  bool get isDarkMode {
    return themeModeNotifier.value == ThemeMode.dark;
  }

  /// The search text color for whichever theme is currently active.
  Color get searchTextColor => isDarkMode ? darkSearchTextColor : lightSearchTextColor;

  ThemeData get lightTheme {
    return buildLightTheme().copyWith(
      scaffoldBackgroundColor: lightBackground,
      colorScheme: ColorScheme.light(
        surface: lightBackground,
        primary: COLOR_LIGHT_PRIMARY,
        secondary: lightSearchTextColor,
        brightness: Brightness.light,
      ),
    );
  }

  ThemeData get darkTheme {
    return buildDarkTheme().copyWith(
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.light(
        surface: darkBackground,
        primary: COLOR_DARK_PRIMARY,
        secondary: darkSearchTextColor,
        brightness: Brightness.dark,
      ),
    );
  }

  get systemUiOverlayStyle {
    /// Status bar icons are binary (light or dark) on Android. To hide them,
    /// pick the icon tone that matches the background's own tone (dark icons
    /// on a dark background, light icons on a light one) so they blend in,
    /// based on the actual color's luminance instead of only matching the
    /// exact black/white defaults.
    final activeBackground = isDarkMode ? darkBackground : lightBackground;
    final statusBarIconBrightness = ThemeData.estimateBrightnessForColor(activeBackground);
    final systemUiOverlayStyle = isDarkMode ?
      lightSystemUiOverlayStyle.copyWith(
          systemNavigationBarColor: darkBackground,
          statusBarColor: darkBackground,
          statusBarIconBrightness: statusBarIconBrightness
      ) :
      darkSystemUiOverlayStyle.copyWith(
          systemNavigationBarColor: lightBackground,
          statusBarColor: lightBackground,
          statusBarIconBrightness: statusBarIconBrightness
      );

    return systemUiOverlayStyle;
  }

  void toggleTheme() {
    if (themeModeNotifier.value == ThemeMode.light) {
      themeModeNotifier.value = ThemeMode.dark;
    } else {
      themeModeNotifier.value = ThemeMode.light;
    }
    sharedPrefsManager.saveData(Keys.themeMode, isDarkMode);
    print("Changed themeMode to ${themeModeNotifier.value}");
  }

  void setColor(ColorType colorType, Color color) {
    switch (colorType) {
      case ColorType.darkBackground:
        darkBackground = color;
        sharedPrefsManager.saveData(Keys.darkBackground, color.value);
        break;
      case ColorType.lightBackground:
        lightBackground = color;
        sharedPrefsManager.saveData(Keys.lightBackground, color.value);
        break;
      case ColorType.lightSearchTextColor:
        lightSearchTextColor = color;
        sharedPrefsManager.saveData(Keys.lightSearchColor, color.value);
        break;
      case ColorType.darkSearchTextColor:
        darkSearchTextColor = color;
        sharedPrefsManager.saveData(Keys.darkSearchColor, color.value);
        break;
    }
    themeModeNotifier.notify();
  }
}

class ThemeModeNotifier<T> extends ValueNotifier<T> {
  ThemeModeNotifier(T value) : super(value);

  void notify() {
    notifyListeners();
  }
}
