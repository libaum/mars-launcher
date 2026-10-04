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

  /// Added by the user via package name in the Mars apps settings (only
  /// possible once unlocked). Always private; its name comes from the
  /// installed app, see [label].
  final bool custom;

  const MarsApp({
    required this.name,
    required this.packageName,
    this.private = false,
    this.custom = false,
  });

  /// A user-added app — the package name stands in as name until installed.
  const MarsApp.custom(this.packageName)
      : name = packageName,
        private = true,
        custom = true;

  /// The name without the "Mars " prefix — used in listings that are already
  /// labelled "Mars apps", where repeating "Mars" on every row is redundant.
  String get displayName => _stripMarsPrefix(name);

  /// The name shown in the Mars apps listings. A name the user set via
  /// rename wins as-is; a custom app falls back to its installed label
  /// (prefix stripped), then to the package name.
  String label({String? renamedName, String? installedName}) {
    if (renamedName != null) return renamedName;
    if (custom && installedName != null) return _stripMarsPrefix(installedName);
    return displayName;
  }

  String get playStoreUrl =>
      "https://play.google.com/store/apps/details?id=$packageName";
}

const List<MarsApp> marsApps = [
  MarsApp(name: "Mars Timer", packageName: "com.catchingclouds.marstimer"),
  MarsApp(name: "Mars Currency", packageName: "com.catchingclouds.marsfx"),
  MarsApp(name: "Mars Expense", packageName: "com.catchingclouds.marsexpense", private: true),
  MarsApp(name: "Mars Thoughts", packageName: "com.catchingclouds.marsthoughts"),
  MarsApp(name: "Mars Thoughts", packageName: "com.catchingclouds.marsthoughts.personal", private: true),
  MarsApp(name: "Mars Sky", packageName: "com.catchingclouds.marssky", private: true),
  MarsApp(name: "Mars North", packageName: "com.catchingclouds.marsnorth", private: true),
  MarsApp(name: "Mars Log", packageName: "com.catchingclouds.marslog", private: true),
  // New vendor prefix (NEW_APP.md) — release build, not the `.debug` variant.
  MarsApp(name: "Mars Books", packageName: "com.catchingcomets.marsbooks", private: true),
];

String _stripMarsPrefix(String name) =>
    name.startsWith("Mars ") ? name.substring(5) : name;

/// Loose Java package name check: at least two dot-separated segments, each
/// starting with a letter.
final _packageNamePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$');

bool isValidPackageName(String packageName) =>
    _packageNamePattern.hasMatch(packageName);

/// The Mars apps visible given the current unlock state: all public apps, plus
/// the private ones and the user-added [customPackages] once
/// [marsAppsUnlockCode] has been entered.
List<MarsApp> visibleMarsApps(bool unlocked,
    {List<String> customPackages = const []}) {
  final builtIn = marsApps.map((app) => app.packageName).toSet();
  return [
    ...marsApps,
    for (final packageName in customPackages)
      if (!builtIn.contains(packageName)) MarsApp.custom(packageName),
  ].where((app) => !app.private || unlocked).toList();
}
