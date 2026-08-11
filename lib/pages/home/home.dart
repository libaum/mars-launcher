import 'package:flutter/material.dart';
import 'package:mars_launcher/logic/app_search_manager.dart';
import 'package:mars_launcher/logic/apps_manager.dart';
import 'package:mars_launcher/logic/settings_manager.dart';
import 'package:mars_launcher/logic/shortcut_manager.dart';
import 'package:mars_launcher/logic/temperature_manager.dart';
import 'package:mars_launcher/pages/home/app_shortcuts_fragment.dart';
import 'package:mars_launcher/pages/home/app_search_fragment.dart';
import 'package:mars_launcher/pages/home/mars_apps_fragment.dart';
import 'package:mars_launcher/pages/home/top_row/top_row.dart';
import 'package:mars_launcher/theme/theme_manager.dart';
import 'package:mars_launcher/pages/settings/settings.dart';
import 'package:mars_launcher/services/service_locator.dart';
import 'package:mars_launcher/services/shared_prefs_manager.dart';
import 'package:mars_launcher/strings.dart';
import 'package:mars_launcher/pages/settings/cheat_sheet.dart';

const double HEIGHT_SIZED_BOX = 50;
const double BOTTOM_GESTURE_DEAD_ZONE = 16;

/// The three vertically-stacked home views. Swipe up reveals search, swipe
/// down reveals the Mars app family — shortcuts sit in between.
enum HomeView { marsApps, shortcuts, search }

class Home extends StatefulWidget {
  final Widget? topRowOverride;
  final Widget Function()? appShortcutsBuilder;
  final Widget Function()? appSearchBuilder;
  final Widget Function()? marsAppsBuilder;

  @override
  _HomeState createState() => _HomeState();

  const Home({
    super.key,
    this.topRowOverride,
    this.appShortcutsBuilder,
    this.appSearchBuilder,
    this.marsAppsBuilder,
  });
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  final themeManager = getIt<ThemeManager>();
  final settingsManager = getIt<SettingsManager>();
  final appShortcutsManager = getIt<AppShortcutsManager>();
  final temperatureManager = getIt<TemperatureManager>();
  final appsManager = getIt<AppsManager>();
  final sharedPrefsManager = getIt<SharedPrefsManager>();
  final sensitivity = 8;

  final ValueNotifier<HomeView> homeViewNotifier = ValueNotifier(HomeView.shortcuts);
  bool _allowVerticalDrag = true;
  bool _verticalDragConsumed = false;
  bool _tipMounted = false;
  bool _tipVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appsManager.loadAndSyncApps();
    });
    final isFirstLaunch =
        sharedPrefsManager.readData(Keys.isFirstLaunch) ?? true;
    if (isFirstLaunch) {
      _tipMounted = true;
      sharedPrefsManager.saveData(Keys.isFirstLaunch, false);
      Future.delayed(const Duration(seconds: 20), () {
        if (mounted) setState(() => _tipVisible = false);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      appsManager.suppressLifecycleReset = false;
    }
    if ((state == AppLifecycleState.inactive || state == AppLifecycleState.paused) && mounted) {
      if (appsManager.suppressLifecycleReset) return;
      homeViewNotifier.value = HomeView.shortcuts;
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    print("BUILDING HOME SCREEN");
    return PopScope( /// Detect back button to close app search
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {_onWillPop(didPop);},
      child: GestureDetector(
        /// SWIPE DETECTION
        onHorizontalDragUpdate: _horizontalDragHandler,
        onVerticalDragStart: (details) => _verticalDragStartHandler(context, details),
        onVerticalDragUpdate: _verticalDragHandler,
        onVerticalDragEnd: (_) => _resetVerticalDragGate(),
        onVerticalDragCancel: _resetVerticalDragGate,
        onLongPress: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Settings()),
          );
        },
        onDoubleTap: () {
          themeManager.toggleTheme();
        },
        onPanDown: (details) {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus &&
              currentFocus.focusedChild != null) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },

        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    widget.topRowOverride ?? TopRow(),
                    SizedBox(
                      height: HEIGHT_SIZED_BOX,
                      child: ValueListenableBuilder<String>(
                        valueListenable: temperatureManager.sunriseSunsetNotifier,
                        builder: (context, sunriseSunset, child) {
                          return Center(child: Text(sunriseSunset));
                    })),
                    Expanded(
                      child: ValueListenableBuilder<HomeView>(
                          valueListenable: homeViewNotifier,
                          builder: (context, view, child) {
                          switch (view) {
                            case HomeView.search:
                              return widget.appSearchBuilder?.call() ??
                                  AppSearchFragment(appSearchMode: AppSearchMode.openApp);
                            case HomeView.marsApps:
                              return widget.marsAppsBuilder?.call() ??
                                  Align(
                                      alignment: Alignment.centerLeft, // Center only vertically
                                      child: MarsAppsFragment());
                            case HomeView.shortcuts:
                              return widget.appShortcutsBuilder?.call() ??
                                  Align(
                                      alignment: Alignment.centerLeft, // Center only vertically
                                      child: AppShortcutsFragment());
                          }
                        },
                      ),
                    )
                  ],
                ),
              ),
              if (_tipMounted)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: SafeArea(
                    child: AnimatedOpacity(
                      opacity: _tipVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      onEnd: () {
                        if (!_tipVisible && mounted) {
                          setState(() => _tipMounted = false);
                        }
                      },
                      child: _buildFirstLaunchTip(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirstLaunchTip(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final accent = Theme.of(context).colorScheme.secondary;
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() => _tipVisible = false);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FlightManual()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: primary.withValues(alpha: 0.45),
              ),
              children: [
                TextSpan(text: '${Strings.firstLaunchTip}   '),
                TextSpan(
                  text: Strings.firstLaunchTipAction,
                  style: TextStyle(color: accent),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  _onWillPop(didPop) async {
    homeViewNotifier.value = HomeView.shortcuts;
    return;
  }

  _horizontalDragHandler(details) {
    /// Horizontal shortcuts only react on the shortcuts view.
    if (homeViewNotifier.value != HomeView.shortcuts) {
      return;
    }

    if (details.delta.dx > sensitivity) {
      /// Right Swipe
      appShortcutsManager.swipeRightAppNotifier.value.open();
    } else if (details.delta.dx < -sensitivity) {
      /// Left Swipe
      appShortcutsManager.swipeLeftAppNotifier.value.open();
    }
  }

  _verticalDragHandler(details) {
    if (!_allowVerticalDrag || _verticalDragConsumed) {
      return;
    }

    if (details.delta.dy > sensitivity) { /// Down Swipe: search -> shortcuts -> marsApps
      if (homeViewNotifier.value == HomeView.search) {
        homeViewNotifier.value = HomeView.shortcuts;
      } else if (homeViewNotifier.value == HomeView.shortcuts) {
        homeViewNotifier.value = HomeView.marsApps;
      }
      _verticalDragConsumed = true;
    } else if (details.delta.dy < -sensitivity) { /// Up Swipe: marsApps -> shortcuts -> search
      if (homeViewNotifier.value == HomeView.marsApps) {
        homeViewNotifier.value = HomeView.shortcuts;
      } else if (homeViewNotifier.value == HomeView.shortcuts) {
        homeViewNotifier.value = HomeView.search;
      }
      _verticalDragConsumed = true;
    }
  }

  void _verticalDragStartHandler(BuildContext context, DragStartDetails details) {
    _verticalDragConsumed = false; /// One view transition per drag gesture
    _allowVerticalDrag = _isDragStartAboveSystemGestureArea(context, details.globalPosition.dy) &&
        _isDragStartBelowStatusBar(context, details.globalPosition.dy);
  }

  void _resetVerticalDragGate() {
    _allowVerticalDrag = true;
  }

  bool _isDragStartAboveSystemGestureArea(BuildContext context, double globalDy) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewPadding.bottom;
    final screenHeight = mediaQuery.size.height;
    final bottomEdgeLimit = screenHeight - (bottomInset + BOTTOM_GESTURE_DEAD_ZONE);
    return globalDy < bottomEdgeLimit;
  }

  /// While the status bar is fully hidden natively, the top edge is the
  /// system's own reveal-gesture area — leave it to the OS instead of also
  /// reacting to it here, or a swipe that narrowly misses the status bar
  /// would trigger the Mars apps view too. A generous top-eighth dead zone
  /// (rather than just the status bar's own height) makes this reliable.
  bool _isDragStartBelowStatusBar(BuildContext context, double globalDy) {
    if (!settingsManager.statusBarFullyHiddenNotifier.value) {
      return true;
    }
    final topEdgeLimit = MediaQuery.of(context).size.height / 8;
    return globalDy > topEdgeLimit;
  }
}
