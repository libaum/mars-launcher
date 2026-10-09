/// Mars family fragment — appears on swipe down. Lists the other Mars apps.
/// Tap an installed app to open it; tap an uninstalled one to get it on the
/// Play Store.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mars_launcher/data/app_info.dart';
import 'package:mars_launcher/data/mars_apps.dart';
import 'package:mars_launcher/logic/apps_manager.dart';
import 'package:mars_launcher/logic/settings_manager.dart';
import 'package:mars_launcher/services/service_locator.dart';
import 'package:mars_launcher/services/shared_prefs_manager.dart';
import 'package:mars_launcher/strings.dart';
import 'package:mars_launcher/theme/theme_constants.dart';

const _GRAY = Color(0xFF888888);

class MarsAppsFragment extends StatelessWidget {
  final appsManager = getIt<AppsManager>();
  final settingsManager = getIt<SettingsManager>();
  final _prefs = getIt<SharedPrefsManager>();

  MarsAppsFragment({super.key});

  Future<void> _handleTap(MarsApp app, bool installed) async {
    if (installed) {
      appsManager.launchApp(app.packageName);
      return;
    }

    /// Private apps have no store listing yet.
    if (app.private) return;

    /// Prefer the Play Store app, fall back to the web listing.
    final market = Uri.parse("market://details?id=${app.packageName}");
    if (await canLaunchUrl(market)) {
      await launchUrl(market);
    } else {
      await launchUrl(Uri.parse(app.playStoreUrl),
          mode: LaunchMode.externalApplication);
    }
  }

  /// Package names of the installed apps, with the Mars ones cached across
  /// launches: until the first app sync finishes, [installedApps] is empty and
  /// would grey out every row for a moment.
  Set<String> _installedPackages(List<AppInfo> installedApps) {
    if (installedApps.isEmpty) {
      return (_prefs.readStringList(Keys.installedMarsApps) ?? []).toSet();
    }
    final all = {for (final app in installedApps) app.packageName};
    final mars = {
      for (final app in marsApps)
        if (all.contains(app.packageName)) app.packageName,
      ...all.intersection(settingsManager.customMarsAppsNotifier.value.toSet()),
    };
    final cached = _prefs.readStringList(Keys.installedMarsApps);
    if (cached == null || cached.toSet().difference(mars).isNotEmpty ||
        mars.difference(cached.toSet()).isNotEmpty) {
      _prefs.saveData(Keys.installedMarsApps, mars.toList());
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(30.0, 0, 30, 20),
      child: ValueListenableBuilder<List<String>>(
        valueListenable: settingsManager.customMarsAppsNotifier,
        builder: (context, customPackages, child) =>
            ValueListenableBuilder<List<String>>(
          valueListenable: settingsManager.enabledMarsAppsNotifier,
          builder: (context, enabledPackages, child) {
            final enabled = enabledPackages.toSet();
            return ValueListenableBuilder<List<AppInfo>>(
              valueListenable: appsManager.appsNotifier,
              builder: (context, installedApps, child) {
                final installed = {
                  for (final app in installedApps) app.packageName: app
                };
                final installedPackages = _installedPackages(installedApps);
                final unlocked = settingsManager.marsAppsUnlockedNotifier.value;
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final app in visibleMarsApps(unlocked,
                                customPackages: customPackages))
                              if (enabled.contains(app.packageName))
                                _MarsAppCard(
                                  app: app,
                                  label: app.label(
                                    renamedName: appsManager
                                        .renamedApps[app.packageName],
                                    installedName:
                                        installed[app.packageName]?.appName,
                                  ),
                                  installed:
                                      installedPackages.contains(app.packageName),
                                  primaryColor: primary,
                                  onTap: _handleTap,
                                ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MarsAppCard extends StatelessWidget {
  final MarsApp app;
  final String label;
  final bool installed;
  final Color primaryColor;
  final Future<void> Function(MarsApp, bool) onTap;

  const _MarsAppCard({
    required this.app,
    required this.label,
    required this.installed,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
      alignment: Alignment.topLeft,
      child: TextButton(
        onPressed: () => onTap(app, installed),
        style: ButtonStyle(
          foregroundColor:
              WidgetStateProperty.all(installed ? primaryColor : _GRAY),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TEXT_STYLE_APP_LARGE.copyWith(letterSpacing: 1.0),
              maxLines: 1,
            ),

            /// Private apps have no store listing to point to.
            if (!installed && !app.private)
              const Text(
                "play store ↗",
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w300, color: _GRAY),
              ),
          ],
        ),
      ),
    );
  }
}
