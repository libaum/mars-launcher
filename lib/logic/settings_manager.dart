import 'package:flutter/services.dart';
import 'package:mars_launcher/constants/global.dart';
import 'package:mars_launcher/data/mars_apps.dart';
import 'package:mars_launcher/logic/utils.dart';
import 'package:mars_launcher/services/service_locator.dart';
import 'package:mars_launcher/services/shared_prefs_manager.dart';
import 'package:mars_launcher/strings.dart';
import 'package:mars_launcher/constants/method_channels.dart';

class SettingsManager {
  static const MethodChannel _openDefaultLauncherSettingsChannel = MethodChannel(MethodChannels.openDefaultLauncherSettings);
  static const MethodChannel _statusBarChannel = MethodChannel(MethodChannels.statusBar);

  final sharedPrefsManager = getIt<SharedPrefsManager>();

  late final ValueNotifierWithKey<bool> weatherWidgetEnabledNotifier;
  late final ValueNotifierWithKey<bool> clockWidgetEnabledNotifier;
  late final ValueNotifierWithKey<bool> batteryWidgetEnabledNotifier;
  late final ValueNotifierWithKey<bool> calendarWidgetEnabledNotifier;
  late final ValueNotifierWithKey<int> numberOfShortcutItemsNotifier;
  late final ValueNotifierWithKey<bool> shortcutMode;
  late final ValueNotifierWithKey<bool> keyboardAutofocusEnabledNotifier;

  /// Package names of the Mars apps shown in the swipe-down overview.
  late final ValueNotifierWithKey<List<String>> enabledMarsAppsNotifier;

  /// Whether the private Mars apps have been revealed via the unlock code.
  late final ValueNotifierWithKey<bool> marsAppsUnlockedNotifier;

  /// Whether the status bar is fully hidden natively (default) rather than
  /// just color-blended. Fully hidden requires two swipes to pull the
  /// notification shade (system reveal, then drag) — toggled via
  /// [statusBarBlendModeCode].
  late final ValueNotifierWithKey<bool> statusBarFullyHiddenNotifier;

  late bool isFirstStartup;

  SettingsManager() {
    weatherWidgetEnabledNotifier = ValueNotifierWithKey(sharedPrefsManager.readData(Keys.weatherEnabled) ?? false, Keys.weatherEnabled);
    clockWidgetEnabledNotifier = ValueNotifierWithKey(sharedPrefsManager.readData(Keys.clockEnabled) ?? true, Keys.clockEnabled);
    batteryWidgetEnabledNotifier = ValueNotifierWithKey(sharedPrefsManager.readData(Keys.batteryEnabled) ?? false, Keys.batteryEnabled);
    calendarWidgetEnabledNotifier = ValueNotifierWithKey(sharedPrefsManager.readData(Keys.calendarEnabled) ?? true, Keys.calendarEnabled);
    numberOfShortcutItemsNotifier = ValueNotifierWithKey(sharedPrefsManager.readData(Keys.numOfShortcutItems) ?? NUMBER_OF_SHORTCUT_ITEMS_ON_STARTUP, Keys.numOfShortcutItems);
    shortcutMode = ValueNotifierWithKey(sharedPrefsManager.readData(Keys.shortcutMode) ?? true, Keys.shortcutMode);
    keyboardAutofocusEnabledNotifier = ValueNotifierWithKey<bool>(sharedPrefsManager.readData(Keys.keyboardAutofocusEnabled) ?? true, Keys.keyboardAutofocusEnabled);
    enabledMarsAppsNotifier = ValueNotifierWithKey<List<String>>(
        sharedPrefsManager.readStringList(Keys.enabledMarsApps) ?? marsApps.map((app) => app.packageName).toList(),
        Keys.enabledMarsApps);
    marsAppsUnlockedNotifier = ValueNotifierWithKey<bool>(
        sharedPrefsManager.readData(Keys.marsAppsUnlocked) ?? false, Keys.marsAppsUnlocked);
    statusBarFullyHiddenNotifier = ValueNotifierWithKey<bool>(
        sharedPrefsManager.readData(Keys.statusBarFullyHidden) ?? true, Keys.statusBarFullyHidden);
    _applyStatusBarVisibility();

    isFirstStartup = sharedPrefsManager.readData(Keys.isFirstStartup) ?? true;

    if (ASK_TO_BE_DEFAULT_LAUNCHER && isFirstStartup) {
      /// Ask on first startup to be default launcher
      isFirstStartup = false;
      sharedPrefsManager.saveData(Keys.isFirstStartup, false);
      openDefaultLauncherSettings();
    }
  }

  void setNotifierValueAndSave(ValueNotifierWithKey notifier) {
    switch (notifier.key) {
      case Keys.keyboardAutofocusEnabled:
      case Keys.shortcutMode:
      case Keys.weatherEnabled:
      case Keys.clockEnabled:
      case Keys.calendarEnabled:
      case Keys.batteryEnabled:
        notifier.value = !notifier.value;
        break;
      case Keys.numOfShortcutItems:
        notifier.value = (notifier.value + 1) % (MAX_NUM_OF_SHORTCUT_ITEMS+1);
    }
    sharedPrefsManager.saveData(notifier.key, notifier.value);
  }

  /// Reveal the private Mars apps. Called once the unlock code is entered.
  void unlockMarsApps() {
    if (marsAppsUnlockedNotifier.value) return;
    marsAppsUnlockedNotifier.value = true;
    sharedPrefsManager.saveData(Keys.marsAppsUnlocked, true);
  }

  /// Toggles between fully hiding the status bar (default) and the old
  /// color-blend behavior. Called from [statusBarBlendModeCode].
  void toggleStatusBarFullyHidden() {
    statusBarFullyHiddenNotifier.value = !statusBarFullyHiddenNotifier.value;
    sharedPrefsManager.saveData(Keys.statusBarFullyHidden, statusBarFullyHiddenNotifier.value);
    _applyStatusBarVisibility();
  }

  void _applyStatusBarVisibility() {
    _statusBarChannel.invokeMethod('setHidden', statusBarFullyHiddenNotifier.value);
  }

  /// Show/hide a Mars app in the swipe-down overview.
  void toggleMarsApp(String packageName) {
    final enabled = List<String>.from(enabledMarsAppsNotifier.value);
    if (enabled.contains(packageName)) {
      enabled.remove(packageName);
    } else {
      enabled.add(packageName);
    }
    enabledMarsAppsNotifier.value = enabled;
    sharedPrefsManager.saveData(Keys.enabledMarsApps, enabled);
  }

  Future<void> openDefaultLauncherSettings() async {
    try {
      await _openDefaultLauncherSettingsChannel.invokeMethod('openLauncherSettings');
    } on PlatformException catch (e) {
      throw 'Could not launch launcher settings: ${e.message}';
    }
  }
}
