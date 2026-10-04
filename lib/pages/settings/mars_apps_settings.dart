/// Lets the user choose which Mars apps appear in the swipe-down overview.
/// Each app has a show/hide toggle; the selection is persisted.
/// Once unlocked, further apps can be added by package name (long press a
/// user-added app to remove it).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mars_launcher/data/app_info.dart';
import 'package:mars_launcher/data/mars_apps.dart';
import 'package:mars_launcher/logic/apps_manager.dart';
import 'package:mars_launcher/logic/settings_manager.dart';
import 'package:mars_launcher/logic/utils.dart';
import 'package:mars_launcher/services/service_locator.dart';
import 'package:mars_launcher/strings.dart';
import 'package:mars_launcher/theme/theme_constants.dart';
import 'package:mars_launcher/theme/theme_manager.dart';

class MarsAppsSettings extends StatelessWidget {
  MarsAppsSettings({Key? key}) : super(key: key);

  final themeManager = getIt<ThemeManager>();
  final settingsManager = getIt<SettingsManager>();
  final appsManager = getIt<AppsManager>();

  Future<void> _addApp(BuildContext context) async {
    final packageName = await showDialog<String>(
      context: context,
      builder: (context) => _AddMarsAppDialog(
        isTaken: (packageName) =>
            marsApps.any((app) => app.packageName == packageName) ||
            settingsManager.customMarsAppsNotifier.value.contains(packageName),
      ),
    );
    if (packageName != null) settingsManager.addCustomMarsApp(packageName);
  }

  Future<void> _removeApp(BuildContext context, String name, String packageName) async {
    final buttonStyle = getDialogButtonStyle(isThemeDark(context));
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        actionsAlignment: MainAxisAlignment.spaceBetween,
        title: Text("Remove \"$name\"?", style: TEXT_STYLE_DIALOG_TITLE),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: buttonStyle,
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: getDialogButtonStyle(isThemeDark(context), isDestructive: true),
            child: const Text("Remove"),
          ),
        ],
      ),
    );
    if (remove == true) settingsManager.removeCustomMarsApp(packageName);
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
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(50, 20, 0, 0),
                  child: Text(
                    Strings.marsAppsTitle,
                    textAlign: TextAlign.left,
                    style: TEXT_STYLE_SETTINGS_TITLE,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 20, 40, 40),
                    child: ValueListenableBuilder<List<String>>(
                      valueListenable: settingsManager.customMarsAppsNotifier,
                      builder: (context, customPackages, child) =>
                          ValueListenableBuilder<List<String>>(
                        valueListenable: settingsManager.enabledMarsAppsNotifier,
                        builder: (context, enabled, child) =>
                            ValueListenableBuilder<List<AppInfo>>(
                          valueListenable: appsManager.appsNotifier,
                          builder: (context, installedApps, child) {
                            final installed = {
                              for (final app in installedApps)
                                app.packageName: app
                            };
                            final unlocked =
                                settingsManager.marsAppsUnlockedNotifier.value;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final app in visibleMarsApps(unlocked,
                                    customPackages: customPackages))
                                  Builder(builder: (context) {
                                    final name = app.label(
                                      renamedName: appsManager
                                          .renamedApps[app.packageName],
                                      installedName:
                                          installed[app.packageName]?.appName,
                                    );
                                    return _MarsAppToggleRow(
                                      name: name,
                                      enabled: enabled.contains(app.packageName),
                                      onPressed: () => settingsManager
                                          .toggleMarsApp(app.packageName),
                                      onLongPress: app.custom
                                          ? () => _removeApp(
                                              context, name, app.packageName)
                                          : null,
                                    );
                                  }),
                                if (unlocked)
                                  TextButton(
                                    onPressed: () => _addApp(context),
                                    child: const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(Strings.marsAppsAdd,
                                          style: TEXT_STYLE_SETTINGS_ITEM),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarsAppToggleRow extends StatelessWidget {
  final String name;
  final bool enabled;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  const _MarsAppToggleRow({
    required this.name,
    required this.enabled,
    required this.onPressed,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: onPressed,
            onLongPress: onLongPress,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(name, style: TEXT_STYLE_SETTINGS_ITEM),
            ),
          ),
        ),
        TextButton(
          onPressed: onPressed,
          child: SizedBox(
            width: 70,
            child: Center(
              child: Text(
                enabled ? "●" : "○",
                style: TEXT_STYLE_SETTINGS_ITEM,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Asks for a package name; pops with the trimmed name, or null on cancel.
class _AddMarsAppDialog extends StatefulWidget {
  final bool Function(String packageName) isTaken;

  const _AddMarsAppDialog({required this.isTaken});

  @override
  State<_AddMarsAppDialog> createState() => _AddMarsAppDialogState();
}

class _AddMarsAppDialogState extends State<_AddMarsAppDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final packageName = _controller.text.trim();
    String? error;
    if (!isValidPackageName(packageName)) {
      error = "Not a valid package name.";
    } else if (widget.isTaken(packageName)) {
      error = "Already in the list.";
    }
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    Navigator.pop(context, packageName);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = isThemeDark(context);
    final buttonStyle = getDialogButtonStyle(isDarkMode);

    return AlertDialog(
      actionsAlignment: MainAxisAlignment.spaceBetween,
      title: const Text(Strings.marsAppsAddTitle, style: TEXT_STYLE_DIALOG_TITLE),
      content: TextField(
        controller: _controller,
        autofocus: true,
        autocorrect: false,
        enableSuggestions: false,
        keyboardType: TextInputType.url,
        cursorColor: isDarkMode ? Colors.white : Colors.black,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          errorText: _errorText,
          filled: true,
          fillColor: isDarkMode ? Colors.white.withValues(alpha: 0.07) : Colors.white,
          focusColor: isDarkMode ? Colors.white : Colors.black,
          hintText: "com.example.app",
          hintStyle: const TextStyle(color: Colors.black54),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          style: buttonStyle,
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: _submit,
          style: buttonStyle,
          child: const Text("Add"),
        ),
      ],
    );
  }
}
