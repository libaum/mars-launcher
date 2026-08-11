import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mars_launcher/data/app_info.dart';
import 'package:mars_launcher/data/mars_apps.dart';
import 'package:mars_launcher/logic/apps_manager.dart';
import 'package:mars_launcher/logic/settings_manager.dart';
import 'package:mars_launcher/logic/settings_transfer.dart';
import 'package:mars_launcher/logic/shortcut_manager.dart';
import 'package:mars_launcher/logic/utils.dart';
import 'package:mars_launcher/pages/dialogs/dialog_app_info.dart';
import 'package:mars_launcher/pages/fragments/cards/app_card.dart';
import 'package:mars_launcher/services/service_locator.dart';

enum AppSearchMode { openApp, chooseShortcut, chooseSpecialShortcut }

class AppSearchManager {
  final appsManager = getIt<AppsManager>();
  final appShortcutsManager = getIt<AppShortcutsManager>();
  final settingsManager = getIt<SettingsManager>();
  late final ValueNotifier<List<AppInfo>> filteredAppsNotifier;
  final Map<AppInfo, AppCard> memorizedAppCards = {};

  /// Temporary parameters that are set when AppSearchFragment is initialized
  AppSearchMode? appSearchMode;
  int? shortcutIndex;

  ValueNotifierWithKey<AppInfo>? specialShortcutAppNotifier;

  AppSearchManager() {
    filteredAppsNotifier = ValueNotifier(getFilteredApps());

    appsManager.appsNotifier.addListener(() {
      final currentPackageNames = appsManager.appsNotifier.value.map((a) => a.packageName).toSet();
      memorizedAppCards.removeWhere((appInfo, _) => !currentPackageNames.contains(appInfo.packageName));
      filteredAppsNotifier.value = getFilteredApps();
    });

    /// AppCard captures appInfo, but AppInfo equality is by packageName only —
    /// so a mutated displayName returns the same cached widget and Flutter skips
    /// the rebuild. Drop the cache so renamed apps get a fresh AppCard.
    appsManager.renamedAppsUpdatedNotifier.addListener(() {
      memorizedAppCards.clear();
      filteredAppsNotifier.value = getFilteredApps();
    });
  }

  List<AppInfo> getFilteredApps() {
    return appsManager.appsNotifier.value.where((app) => !app.isHidden).toList();
  }

  AppCard generateAppCard(AppInfo appInfo) {
    return AppCard(
      appInfo: appInfo,
      callbackHandleOnPress: handleOnPress,
      callbackHandleOnLongPress: handleOnLongPress,
    );
  }

  AppCard getMemorizedAppCard(AppInfo appInfo) {
    return memorizedAppCards.putIfAbsent(appInfo, () => generateAppCard(appInfo));
  }

  setTemporaryParameters(
      AppSearchMode appSearchMode, int? shortcutIndex, ValueNotifierWithKey<AppInfo>? specialShortcutAppNotifier) {
    this.appSearchMode = appSearchMode;
    this.shortcutIndex = shortcutIndex;
    this.specialShortcutAppNotifier = specialShortcutAppNotifier;
  }

  resetFilteredList() async {
    filteredAppsNotifier.value = getFilteredApps();

    appSearchMode = shortcutIndex = specialShortcutAppNotifier = null;
  }

  handleOnPress(BuildContext context, AppInfo appInfo) {
    switch (appSearchMode) {
      case AppSearchMode.openApp:
        openApp(appInfo);
        break;
      case AppSearchMode.chooseShortcut:
        replaceShortcut(context, appInfo);
        break;
      case AppSearchMode.chooseSpecialShortcut:
        replaceSpecialShortcut(context, appInfo);
        break;
      case null:
        break;
    }

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  handleOnLongPress(BuildContext context, AppInfo appInfo) async {
    final result = await showDialog(
      context: context,
      builder: (_) => AppInfoDialog(appInfo: appInfo),
    );

    // Handle the result
    if (result != null) {
      print("Dialog result: $result");
    }
  }

  openApp(AppInfo appInfo) {
    appInfo.open();
  }

  replaceShortcut(BuildContext context, AppInfo appInfo) {
    if (shortcutIndex != null) {
      print("[$runtimeType] Replacing shortcut app with index $shortcutIndex with ${appInfo.appName}");
      appShortcutsManager.shortcutAppsNotifier.replaceShortcut(shortcutIndex!, appInfo);
      Navigator.of(context).pop();
    }
  }

  replaceSpecialShortcut(BuildContext context, AppInfo appInfo) {
    if (specialShortcutAppNotifier != null) {
      print("[$runtimeType] Replacing special shortcut app ${specialShortcutAppNotifier!.key} with ${appInfo.appName}");
      appShortcutsManager.setSpecialShortcutValue(specialShortcutAppNotifier!, appInfo);
      Navigator.of(context).pop();
    }
  }

  /// Admin feedback for the hidden search codes. Uses Fluttertoast (not a
  /// SnackBar) because the search field keeps the keyboard open, over which the
  /// launcher's ScaffoldMessenger snackbars aren't reliably visible.
  void _adminToast(BuildContext context, String msg) {
    Fluttertoast.showToast(
        msg: msg,
        backgroundColor: Theme.of(context).primaryColor,
        textColor: Theme.of(context).scaffoldBackgroundColor);
  }

  updateFilteredApps(BuildContext context, String searchValue) async {
    /// Secret unlock: the whole field must equal the code exactly, so it can't
    /// fire while typing a normal app name. Only in normal open-app search.
    if (appSearchMode == AppSearchMode.openApp &&
        searchValue.trim().toLowerCase() == marsAppsUnlockCode) {
      if (settingsManager.marsAppsUnlockedNotifier.value) {
        _adminToast(context, "mars apps already unlocked");
      } else {
        settingsManager.unlockMarsApps();
        _adminToast(context, "mars apps unlocked");
      }
      filteredAppsNotifier.value = [];
      return;
    }

    /// Admin-only settings transfer — same exact-match rule, and only once the
    /// private apps are unlocked, so normal users can never reach it.
    if (appSearchMode == AppSearchMode.openApp &&
        settingsManager.marsAppsUnlockedNotifier.value) {
      final code = searchValue.trim().toLowerCase();
      if (code == statusBarBlendModeCode) {
        settingsManager.toggleStatusBarFullyHidden();
        final mode = settingsManager.statusBarFullyHiddenNotifier.value ? "hidden" : "blend";
        _adminToast(context, "status bar mode: $mode");
        filteredAppsNotifier.value = [];
        return;
      }
      if (code == exportSettingsCode || code == importSettingsCode) {
        final path = code == exportSettingsCode
            ? await exportSettings()
            : await importSettings();
        if (context.mounted) {
          if (path == null) {
            final action = code == exportSettingsCode ? "export" : "import";
            _adminToast(context, "settings $action failed");
          } else if (code == importSettingsCode) {
            _adminToast(context, "settings imported — restart app");
          } else {
            _adminToast(context, "settings exported:\n$path");
          }
        }
        filteredAppsNotifier.value = [];
        return;
      }
    }

    final query = searchValue.toLowerCase();
    List<AppInfo> filteredApps = appsManager.appsNotifier.value
        .where((app) => app.displayNameLower.contains(query) && !app.isHidden)
        .toList();
    if (filteredApps.length == 1) {
      handleOnPress(context, filteredApps.first);
    }
    filteredAppsNotifier.value = filteredApps;
  }
}
