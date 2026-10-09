import 'package:flutter/material.dart';
import 'package:mars_launcher/logic/settings_manager.dart';
import 'package:mars_launcher/services/service_locator.dart';

/// Multiplies the inherited text scale by [factor], keeping the system font
/// scale in effect.
class ScaleText extends StatelessWidget {
  final double factor;
  final Widget child;

  const ScaleText({super.key, required this.factor, required this.child});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final system = mq.textScaler.scale(100) / 100;
    return MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.linear(system * factor)),
      child: child,
    );
  }
}

/// Applies the user's font size setting to everything below it. Place it above
/// the Navigator so every page follows the setting.
class AppFontScale extends StatelessWidget {
  final Widget child;

  AppFontScale({super.key, required this.child});

  final _settings = getIt<SettingsManager>();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _settings.fontScaleLevelNotifier,
      builder: (context, level, _) =>
          ScaleText(factor: FONT_SCALE_FACTORS[level], child: child),
    );
  }
}

/// Cancels [AppFontScale] for [child]; used for the top row, which keeps its
/// fixed size.
class UnscaledFont extends StatelessWidget {
  final Widget child;

  UnscaledFont({super.key, required this.child});

  final _settings = getIt<SettingsManager>();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _settings.fontScaleLevelNotifier,
      builder: (context, level, _) =>
          ScaleText(factor: 1 / FONT_SCALE_FACTORS[level], child: child),
    );
  }
}
