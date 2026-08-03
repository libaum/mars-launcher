import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mars_launcher/data/app_info.dart';
import 'package:mars_launcher/logic/app_search_manager.dart';
import 'package:mars_launcher/logic/settings_manager.dart';
import 'package:mars_launcher/logic/shortcut_manager.dart';
import 'package:mars_launcher/pages/settings/about.dart';
import 'package:mars_launcher/pages/dialogs/dialog_color_picker.dart';

import 'package:mars_launcher/pages/settings/cheat_sheet.dart';
import 'package:mars_launcher/services/location_service.dart';
import 'package:mars_launcher/services/shared_prefs_manager.dart';
import 'package:mars_launcher/theme/theme_manager.dart';
import 'package:mars_launcher/logic/utils.dart';
import 'package:mars_launcher/pages/home/app_search_fragment.dart';
import 'package:mars_launcher/pages/settings/utils.dart';
import 'package:mars_launcher/theme/theme_constants.dart';
import 'package:mars_launcher/pages/settings/hidden_apps.dart';
import 'package:mars_launcher/pages/settings/mars_apps_settings.dart';
import 'package:mars_launcher/services/permission_service.dart';
import 'package:mars_launcher/services/service_locator.dart';
import 'package:mars_launcher/strings.dart';

const ROW_PADDING_RIGHT = 50.0; // TODO look for overflow

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> with WidgetsBindingObserver {
  final appShortcutsManager = getIt<AppShortcutsManager>();
  final themeManager = getIt<ThemeManager>();
  final permissionService = getIt<PermissionService>();
  final settingsManager = getIt<SettingsManager>();
  final sharedPrefsManager = getIt<SharedPrefsManager>();

  //bool isDarkMode = true; //isThemeDark(context);
  //final buttonStyle = getDialogButtonStyle(isDarkMode);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void pushAppSearch(ValueNotifierWithKey<AppInfo> specialAppNotifier) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (_) => Scaffold(
                appBar: defaultTargetPlatform == TargetPlatform.linux
                    ? AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        iconTheme: IconThemeData(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      )
                    : null,
                body: SafeArea(
                    child: AppSearchFragment(
                  appSearchMode: AppSearchMode.chooseSpecialShortcut,
                  specialShortcutAppNotifier: specialAppNotifier,
                )))),
    );
  }

  void pushOtherPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        themeManager.toggleTheme();
      },
      child: Scaffold(
        appBar: defaultTargetPlatform == TargetPlatform.linux
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                iconTheme: IconThemeData(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              )
            : null,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 20, ROW_PADDING_RIGHT, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                  child: Text(Strings.settingsTitle, style: TEXT_STYLE_SETTINGS_TITLE),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0,18, 0, 40),
                    child: SingleChildScrollView(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// FLIGHT MANUAL
                            GenericSettingsButton(
                                onPressed: () {
                                  pushOtherPage(FlightManual());
                                },
                                name: Strings.settingsFlightManual,
                                showChevron: true),

                            /// SET DEFAULT LAUNCHER
                            GenericSettingsButton(
                                onPressed: () {
                                  settingsManager.openDefaultLauncherSettings();
                                },
                                name: Strings.settingsChangeDefaultLauncher),

                            /// ---- App Shortcuts ----
                            _sectionHeader(context, Strings.settingsGroupAppShortcuts),

                            buildAppsNumberRow(),

                            GenericSettingsButton(
                                onPressed: () {
                                  pushAppSearch(
                                      appShortcutsManager.swipeLeftAppNotifier);
                                },
                                name: Strings.settingsSwipeLeft),

                            GenericSettingsButton(
                                onPressed: () {
                                  pushAppSearch(appShortcutsManager
                                      .swipeRightAppNotifier);
                                },
                                name: Strings.settingsSwipeRight),

                            buildTopRowAppRow(
                                specialShortcutAppNotifier:
                                    appShortcutsManager.clockAppNotifier,
                                widgetEnabledNotifier:
                                    settingsManager.clockWidgetEnabledNotifier,
                                name: Strings.settingsClockApp),

                            buildWeatherAppRow(context),

                            buildTopRowAppRow(
                                specialShortcutAppNotifier:
                                appShortcutsManager.batteryAppNotifier,
                                widgetEnabledNotifier: settingsManager
                                    .batteryWidgetEnabledNotifier,
                                name: Strings.settingsBattery),

                            buildTopRowAppRow(
                                specialShortcutAppNotifier:
                                    appShortcutsManager.calendarAppNotifier,
                                widgetEnabledNotifier: settingsManager
                                    .calendarWidgetEnabledNotifier,
                                name: Strings.settingsCalendarApp),



                            /// ---- Appearance ----
                            _sectionHeader(context, Strings.settingsGroupAppearance),

                            GenericSettingsButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return ColorPickerDialog(colorType: ColorType.lightBackground, title: 'Light background');
                                    },
                                  );
                                },
                                name: Strings.settingsColorsLightBackground
                            ),

                            GenericSettingsButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return ColorPickerDialog(colorType: ColorType.darkBackground, title: 'Dark background');
                                    },
                                  );
                                },
                                name: Strings.settingsColorsDarkBackground
                            ),

                            ValueListenableBuilder<ThemeMode>(
                                valueListenable: themeManager.themeModeNotifier,
                                builder: (context, themeMode, child) {
                                  return GenericSettingsButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return ColorPickerDialog(colorType: ColorType.searchTextColor, title: 'Search color',);
                                        },
                                      );
                                    },
                                    name: Strings.settingsColorsSearchColor,
                                    style: TEXT_STYLE_SETTINGS_ITEM.copyWith(color: themeManager.searchTextColor),
                                  );
                                }
                            ),

                            // GenericSettingsButton(
                            //     onPressed: () {
                            //       pushOtherPage(SettingsColors());
                            //     },
                            //     name: Strings.settingsColors),
                            //

                            /// ---- Other ----
                            _sectionHeader(context, Strings.settingsGroupOther),

                            GenericSettingsButton(
                                onPressed: () {
                                  pushOtherPage(HiddenApps());
                                },
                                name: Strings.settingsHiddenApps,
                                showChevron: true),

                            GenericSettingsButton(
                                onPressed: () {
                                  pushOtherPage(MarsAppsSettings());
                                },
                                name: Strings.settingsMarsApps,
                                showChevron: true),

                            /// KEYBOARD AUTOFOCUS
                            ///buildKeyboardAutofocusRow(),

                            GenericSettingsButton(
                                onPressed: () {
                                  pushOtherPage(Credits());
                                },
                                name: Strings.settingsCredits,
                                showChevron: true),
                          ]),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 0, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Row buildTopRowAppRow(
      {required ValueNotifierWithKey<AppInfo> specialShortcutAppNotifier,
      required ValueNotifierWithKey<bool> widgetEnabledNotifier,
      required String name}) {
    return Row(
      children: [
        GenericSettingsButton(
            onPressed: () {
              pushAppSearch(specialShortcutAppNotifier);
            },
            name: name),
        Expanded(
          child: Container(),
        ),
        ShowHideButton(
          notifier: widgetEnabledNotifier,
          onPressed: () {
            settingsManager.setNotifierValueAndSave(widgetEnabledNotifier);
          },
        ),
      ],
    );
  }

  Row buildWeatherAppRow(BuildContext context) {
    return Row(
      children: [
        GenericSettingsButton(
            onPressed: () {
              pushAppSearch(appShortcutsManager.weatherAppNotifier);
            },
            name: Strings.settingsWeatherApp),
        Expanded(child: Container()),
        ShowHideButton(
          notifier: settingsManager.weatherWidgetEnabledNotifier,
          onPressed: () async {
            // Check if this is the first time enabling weather
            if (sharedPrefsManager.readData(Keys.weatherActivatedAtLeastOnce) ==
                null) {
              final bool? accepted = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    final Color dialogTextColor = Theme.of(context)
                            .dialogTheme
                            .contentTextStyle
                            ?.color ??
                        Theme.of(context).colorScheme.onSurface;
                    final buttonStyle = getDialogButtonStyle(isThemeDark(context));
                    return AlertDialog(
                      actionsAlignment: MainAxisAlignment.spaceBetween,
                      title: Text(
                        "Enable Weather?",
                        style: TEXT_STYLE_DIALOG_TITLE,
                      ),
                      content: Text(
                        "To show the current temperature, your location is sent anonymously to Open-Meteo.\n\nThis data is used only for weather updates and is never tracked or sold.",
                        style: TEXT_STYLE_DIALOG_BODY.copyWith(
                          color: dialogTextColor,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          style: buttonStyle,
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                          style: buttonStyle,
                          child: const Text('Enable'),
                        ),
                      ],
                    );
                  });

              if (accepted == true) {
                // Request location permission
                final locationService = LocationService();
                final bool permissionGranted = await locationService.checkPermission();

                if (permissionGranted) {
                  // Permission granted, enable weather widget
                  sharedPrefsManager.saveData(
                      Keys.weatherActivatedAtLeastOnce, true);
                  settingsManager.setNotifierValueAndSave(
                      settingsManager.weatherWidgetEnabledNotifier);
                } else {
                  // Permission denied, show info
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Location permission is required for weather updates'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              }
            } else {
              // Toggle normal (on/off) - permission already handled
              settingsManager.setNotifierValueAndSave(
                  settingsManager.weatherWidgetEnabledNotifier);
            }
          },
        ),
      ],
    );
  }


  Row buildAppsNumberRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        GenericSettingsButton(
            onPressed: () {
              settingsManager.setNotifierValueAndSave(
                  settingsManager.numberOfShortcutItemsNotifier);
            },
            name: Strings.settingsAppNumber),
        Expanded(child: Container()),
        ValueListenableBuilder<int>(
            valueListenable: settingsManager.numberOfShortcutItemsNotifier,
            builder: (context, numOfShortcutItems, child) {
              return SizedBox(
                  width: 60,
                  child: TextButton(
                    onPressed: () {
                      settingsManager.setNotifierValueAndSave(
                          settingsManager.numberOfShortcutItemsNotifier);
                    },
                    child: Center(
                        child: Text(numOfShortcutItems.toString(),
                            style: TEXT_STYLE_SETTINGS_TRAILING)),
                  ));
            }),
      ],
    );
  }

  Row buildKeyboardAutofocusRow() {
    return Row(
      children: [
        GenericSettingsButton(
            onPressed: () {
              settingsManager.setNotifierValueAndSave(
                  settingsManager.keyboardAutofocusEnabledNotifier);
            },
            name: Strings.settingsKeyboardAutofocus),
        Expanded(child: Container()),
        ShowHideButton(
          notifier: settingsManager.keyboardAutofocusEnabledNotifier,
          onPressed: () {
            settingsManager.setNotifierValueAndSave(
                settingsManager.keyboardAutofocusEnabledNotifier);
          },
        ),
      ],
    );
  }
}

class ShowHideButton extends StatelessWidget {
  const ShowHideButton(
      {Key? key, required this.notifier, required this.onPressed})
      : super(key: key);

  final ValueNotifierWithKey<bool> notifier;
  final Function onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: TextButton(
        onPressed: () {
          onPressed();
        },
        child: ValueListenableBuilder<bool>(
            valueListenable: notifier,
            builder: (context, enabled, child) {
              return Center(
                child: Text(
                  enabled ? "●" : "○",
                  style: TEXT_STYLE_SETTINGS_TRAILING,
                ),
              );
            }),
      ),
    );
  }
}
