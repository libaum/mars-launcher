/// The Mars app family — revealed on swipe down from the home screen.
/// The launcher itself is intentionally omitted (it is the current app).

/// Typed into the app search field, this reveals the private Mars apps
/// (those with `private: true`) in the swipe-down overview and settings.
/// The whole search field must equal this exactly — so it never triggers by
/// accident. Change it to your own secret before a public release.
const marsAppsUnlockCode = "#unlockallmarsapps";

/// Same exact-match rule, gated behind [marsAppsUnlockCode]. Switches the
/// status bar from fully hidden (default) to the old color-blend behavior —
/// single-swipe notification pull, but icons stay faintly visible on custom
/// accent colors. See [SettingsManager.statusBarFullyHiddenNotifier].
const statusBarBlendModeCode = "#classicstatusbar";

class MarsApp {
  final String name;
  final String packageName;

  /// Private apps are hidden everywhere until the unlock code is entered.
  /// Flip to `false` when the app is published to the Play Store.
  final bool private;

  const MarsApp({
    required this.name,
    required this.packageName,
    this.private = false,
  });

  /// The name without the "Mars " prefix — used in listings that are already
  /// labelled "Mars apps", where repeating "Mars" on every row is redundant.
  String get displayName =>
      name.startsWith("Mars ") ? name.substring(5) : name;

  String get playStoreUrl =>
      "https://play.google.com/store/apps/details?id=$packageName";
}

const List<MarsApp> marsApps = [
  MarsApp(name: "Mars Timer", packageName: "com.catchingclouds.marstimer"),
  MarsApp(name: "Mars FX", packageName: "com.catchingclouds.marsfx"),
  MarsApp(name: "Mars Expense", packageName: "com.catchingclouds.marsexpense", private: true),
  MarsApp(name: "Mars Thoughts", packageName: "com.catchingclouds.marsthoughts", private: true),
  MarsApp(name: "Mars Sky", packageName: "com.catchingclouds.marssky", private: true),
  MarsApp(name: "Mars North", packageName: "com.catchingclouds.marsnorth", private: true),
  MarsApp(name: "Mars Log", packageName: "com.catchingclouds.marslog", private: true),
];

/// The Mars apps visible given the current unlock state: all public apps, plus
/// the private ones once [marsAppsUnlockCode] has been entered.
List<MarsApp> visibleMarsApps(bool unlocked) =>
    marsApps.where((app) => !app.private || unlocked).toList();
