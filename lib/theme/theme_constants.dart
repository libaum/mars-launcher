import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mars_launcher/constants/global.dart';

/// Colors
const COLOR_LIGHT_BACKGROUND = Colors.white;
const COLOR_LIGHT_PRIMARY = Colors.black;

const COLOR_DARK_BACKGROUND = Colors.black;
const COLOR_DARK_PRIMARY = Colors.white;

const COLOR_ACCENT = Color(0xffc9184a);
const COLOR_ACCENT_HIGHLIGHT = Color(0xffEA4876);
const COLOR_DIALOG_BUTTONS = Color(0xffFF6F5C);

/// Curated background presets offered alongside the free color picker.
/// Light presets stay light enough for black text, dark presets stay dark enough for white text.
/// Picked with clearly noticeable hue/saturation vs. the plain white/black default.
const List<Color> LIGHT_BACKGROUND_PRESETS = [
  Color(0xFFF3E4C8), // sand
  Color(0xFFD9E8DA), // sage
  Color(0xFFD6E4F0), // powder blue
  Color(0xFFF0DCE0), // blush
  Color(0xFFE3DCF0), // lavender
];
const List<Color> DARK_BACKGROUND_PRESETS = [
  Color(0xFF141C29), // navy
  Color(0xFF231A2C), // plum
  Color(0xFF0F2429), // teal
  Color(0xFF2A121B), // burgundy
  Color(0xFF291712), // rust
];

/// The one font. Mars is opinionated — no font switching.
const FONT = "Outfit";

/// Settings page text styles
const TEXT_STYLE_SETTINGS_TITLE = TextStyle(fontSize: 30, fontWeight: FontWeight.w300);
const TEXT_STYLE_SETTINGS_ITEM = TextStyle(fontSize: 19, height: 1, fontWeight: FontWeight.w200);
/// Second-column value next to a settings row (toggle state, count, etc.)
const TEXT_STYLE_SETTINGS_TRAILING = TextStyle(fontSize: 16, fontWeight: FontWeight.w300);

/// Named text styles — fontFamily intentionally omitted so they inherit from ThemeData
const TEXT_STYLE_APP_SMALL = TextStyle(fontSize: 20, fontWeight: FontWeight.w200);
const TEXT_STYLE_APP_LARGE = TextStyle(fontSize: 30, fontWeight: FontWeight.w300);
const TEXT_STYLE_TOP_ROW = TextStyle(fontSize: FONT_SIZE_TOP_ROW, fontWeight: FontWeight.w400, fontFeatures: [FontFeature.tabularFigures()]);

const TEXT_STYLE_CHEAT_SHEET = TextStyle(fontSize: 18, fontWeight: FontWeight.w200);
const TEXT_STYLE_INPUT_HINT = TextStyle(fontSize: 18, fontWeight: FontWeight.w300);
const TEXT_STYLE_ABOUT_BODY = TextStyle(fontSize: 15, fontWeight: FontWeight.w200);

const TEXT_STYLE_DIALOG_TITLE = TextStyle(fontSize: 20, fontWeight: FontWeight.w300);
const TEXT_STYLE_DIALOG_BODY = TextStyle(fontSize: 16, fontWeight: FontWeight.w200);
const TEXT_STYLE_DIALOG_BUTTON = TextStyle(fontSize: 14, fontWeight: FontWeight.w300);




/// Dialogs always have a black surface with white text, in both themes.
/// [isDestructive] is the only reason a dialog button should use [COLOR_ACCENT].
ButtonStyle getDialogButtonStyle(isDarkMode, {bool isDestructive = false}) {
  return ButtonStyle(
      overlayColor: WidgetStateProperty.all<Color>(
        isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
      ),
      foregroundColor: WidgetStateProperty.all<Color>(isDestructive ? COLOR_ACCENT : Colors.white),
      textStyle: WidgetStateProperty.all(TEXT_STYLE_DIALOG_BUTTON),
      shape: WidgetStateProperty.all(RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(3.0)),
      )));
}

const _kDialSurface = Color(0xFF1C1C1C);

TimePickerThemeData _timePickerTheme({required bool border}) => TimePickerThemeData(
  backgroundColor: Colors.black,
  dialBackgroundColor: _kDialSurface,
  hourMinuteColor: WidgetStateColor.resolveWith((states) =>
    states.contains(WidgetState.selected) ? COLOR_ACCENT : _kDialSurface),
  hourMinuteTextColor: Colors.white,
  dayPeriodColor: WidgetStateColor.resolveWith((states) =>
    states.contains(WidgetState.selected) ? COLOR_ACCENT : _kDialSurface),
  dayPeriodTextColor: Colors.white,
  dialHandColor: COLOR_ACCENT,
  dialTextColor: Colors.white,
  entryModeIconColor: Colors.white,
  helpTextStyle: const TextStyle(color: Colors.white54, fontSize: 12),
  cancelButtonStyle: ButtonStyle(
    foregroundColor: WidgetStateProperty.all(Colors.white),
  ),
  confirmButtonStyle: ButtonStyle(
    foregroundColor: WidgetStateProperty.all(Colors.white),
  ),
  shape: RoundedRectangleBorder(
    borderRadius: const BorderRadius.all(Radius.circular(4.0)),
    side: border ? const BorderSide(color: Color(0x5FFFFFFF), width: 0.7) : BorderSide.none,
  ),
);

ThemeData buildLightTheme() => ThemeData(
  colorScheme: ColorScheme.light(
    surface: COLOR_LIGHT_BACKGROUND,
    primary: COLOR_LIGHT_PRIMARY,
    secondary: COLOR_ACCENT,
    brightness: Brightness.light,
  ),
  primaryTextTheme: TextTheme(
    bodyLarge: TextStyle(color: COLOR_LIGHT_PRIMARY),
    bodyMedium: TextStyle(color: COLOR_LIGHT_PRIMARY),
    bodySmall: TextStyle(color: COLOR_LIGHT_PRIMARY),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: COLOR_LIGHT_PRIMARY,
    contentTextStyle: TextStyle(color: COLOR_LIGHT_BACKGROUND),
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontFamily: FONT,
      fontWeight: FontWeight.w300,
      color: COLOR_LIGHT_BACKGROUND,
    ),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4.0))),
  ),
  dialogBackgroundColor: COLOR_LIGHT_PRIMARY,
  primaryColor: Colors.black,
  disabledColor: COLOR_ACCENT,
  fontFamily: FONT,
  scaffoldBackgroundColor: COLOR_LIGHT_BACKGROUND,
  brightness: Brightness.light,
  iconTheme: IconThemeData(color: COLOR_LIGHT_PRIMARY),
  textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all<Color>(COLOR_LIGHT_PRIMARY),
          overlayColor: WidgetStateProperty.all<Color>(Colors.transparent))),
  timePickerTheme: _timePickerTheme(border: false),
);

ThemeData buildDarkTheme() => ThemeData(
  colorScheme: ColorScheme.dark(
    surface: COLOR_DARK_BACKGROUND,
    primary: COLOR_DARK_PRIMARY,
    secondary: COLOR_ACCENT,
    brightness: Brightness.dark,
  ),
  primaryTextTheme: TextTheme(
    bodyLarge: TextStyle(color: COLOR_DARK_PRIMARY),
    bodyMedium: TextStyle(color: COLOR_DARK_PRIMARY),
    bodySmall: TextStyle(color: COLOR_DARK_PRIMARY),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: COLOR_DARK_BACKGROUND,
    contentTextStyle: TextStyle(color: COLOR_DARK_PRIMARY),
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontFamily: FONT,
      fontWeight: FontWeight.w300,
      color: COLOR_DARK_PRIMARY,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      side: BorderSide(color: Color(0x5FFFFFFF), width: 0.7),
    ),
  ),
  primaryColor: COLOR_DARK_PRIMARY,
  disabledColor: COLOR_ACCENT,
  fontFamily: FONT,
  scaffoldBackgroundColor: COLOR_DARK_BACKGROUND,
  brightness: Brightness.dark,
  iconTheme: IconThemeData(color: COLOR_DARK_PRIMARY),
  textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all<Color>(COLOR_DARK_PRIMARY),
          overlayColor: WidgetStateProperty.all<Color>(Colors.transparent))),
  timePickerTheme: _timePickerTheme(border: true),
);

// systemNavigationBarContrastEnforced: false — on Android 15+ (edge-to-edge is
// forced) the system otherwise draws a contrast scrim over the nav bar that
// ignores systemNavigationBarColor and reads light. Turning it off lets the
// (dark/light) Scaffold background show through behind the transparent bar.
SystemUiOverlayStyle lightSystemUiOverlayStyle = const SystemUiOverlayStyle(
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.light,
  systemNavigationBarContrastEnforced: false,
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
);

SystemUiOverlayStyle darkSystemUiOverlayStyle = const SystemUiOverlayStyle(
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarContrastEnforced: false,
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
);
