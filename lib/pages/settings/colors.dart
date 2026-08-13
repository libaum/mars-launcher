import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mars_launcher/pages/dialogs/background_color_dialog.dart';
import 'package:mars_launcher/pages/dialogs/search_color_dialog.dart';
import 'package:mars_launcher/pages/settings/utils.dart';
import 'package:mars_launcher/theme/theme_constants.dart';
import 'package:mars_launcher/theme/theme_manager.dart';
import 'package:mars_launcher/services/service_locator.dart';
import 'package:mars_launcher/strings.dart';

class SettingsColors extends StatefulWidget {
  const SettingsColors({Key? key}) : super(key: key);

  @override
  State<SettingsColors> createState() => _SettingsColorsState();
}

class _SettingsColorsState extends State<SettingsColors> with WidgetsBindingObserver {
  final themeManager = getIt<ThemeManager>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
            padding: const EdgeInsets.fromLTRB(50, 20, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(Strings.settingsColorsTitle, style: TEXT_STYLE_SETTINGS_TITLE),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// BACKGROUND COLOR
                          ValueListenableBuilder<ThemeMode>(
                            valueListenable: themeManager.themeModeNotifier,
                            builder: (context, themeMode, child) {
                              return GenericSettingsButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return BackgroundColorDialog(isDark: themeManager.isDarkMode);
                                      },
                                    );
                                  },
                                  name: Strings.settingsColorsBackground
                              );
                            }
                          ),

                          ValueListenableBuilder<ThemeMode>(
                            valueListenable: themeManager.themeModeNotifier,
                            builder: (context, themeMode, child) {
                              return GenericSettingsButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return SearchColorDialog(isDark: themeManager.isDarkMode);
                                      },
                                    );
                                  },
                                  name: Strings.settingsColorsSearchColor,
                              style: TEXT_STYLE_SETTINGS_ITEM.copyWith(color: themeManager.searchTextColor),
                              );
                            }
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
