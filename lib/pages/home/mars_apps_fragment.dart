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
import 'package:mars_launcher/theme/theme_constants.dart';

const _GRAY = Color(0xFF888888);

class MarsAppsFragment extends StatelessWidget {
  final appsManager = getIt<AppsManager>();
  final settingsManager = getIt<SettingsManager>();

  MarsAppsFragment({super.key});

  Future<void> _handleTap(MarsApp app, bool installed) async {
    if (installed) {
      appsManager.launchApp(app.packageName);
      return;
    }
    /// Prefer the Play Store app, fall back to the web listing.
    final market = Uri.parse("market://details?id=${app.packageName}");
    if (await canLaunchUrl(market)) {
      await launchUrl(market);
    } else {
      await launchUrl(Uri.parse(app.playStoreUrl),
          mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(30.0, 0, 30, 20),
      child: ValueListenableBuilder<List<String>>(
        valueListenable: settingsManager.enabledMarsAppsNotifier,
        builder: (context, enabledPackages, child) {
          final enabled = enabledPackages.toSet();
          return ValueListenableBuilder<List<AppInfo>>(
            valueListenable: appsManager.appsNotifier,
            builder: (context, installedApps, child) {
              final installedPackages =
                  installedApps.map((app) => app.packageName).toSet();
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
                          for (final app in visibleMarsApps(unlocked))
                            if (enabled.contains(app.packageName))
                              _MarsAppCard(
                                app: app,
                                installed: installedPackages
                                    .contains(app.packageName),
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
    );
  }
}

class _MarsAppCard extends StatelessWidget {
  final MarsApp app;
  final bool installed;
  final Color primaryColor;
  final Future<void> Function(MarsApp, bool) onTap;

  const _MarsAppCard({
    required this.app,
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
              app.displayName,
              style: TEXT_STYLE_APP_LARGE.copyWith(letterSpacing: 1.0),
              maxLines: 1,
            ),
            if (!installed)
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
