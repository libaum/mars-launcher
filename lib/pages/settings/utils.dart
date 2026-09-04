import 'package:flutter/material.dart';
import 'package:mars_launcher/data/app_info.dart';
import 'package:mars_launcher/logic/utils.dart';
import 'package:mars_launcher/strings.dart';
import 'package:mars_launcher/theme/theme_constants.dart';

/// Generic button for the settings page. Set [showChevron] on rows that
/// navigate to another screen or open a dialog, so there's a visual cue
/// distinguishing them from plain toggles/value rows.
class GenericSettingsButton extends StatelessWidget {
  final Function onPressed;
  final String name;
  final TextStyle style;
  final bool showChevron;

  GenericSettingsButton({
    Key? key,
    required Function this.onPressed,
    required String this.name,
    this.style=TEXT_STYLE_SETTINGS_ITEM,
    this.showChevron = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: () {
          onPressed();
        },
        child: showChevron
            ? Row(
                children: [
                  Expanded(child: Text(name, style: style)),
                  // Compensates the TextButton's own default horizontal
                  // padding, so the chevron lands flush with the trailing
                  // value box used by ShowHideButton/numOfShortcutItems.
                  Transform.translate(
                    offset: const Offset(12, 0),
                    child: SizedBox(
                      width: 60,
                      child: Center(
                        child: Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Text(
                name,
                style: style,
              )
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


/// Two-line settings row for everything that has an app behind it.
///
/// The row carries the two meanings separately: the title plus the sublabel
/// say *which* app is set, the trailing toggle says *whether* the widget is
/// shown on the homescreen. Rows without homescreen visibility (swipe left /
/// swipe right) simply pass no [enabledNotifier].
///
/// Consequence rule: while the toggle is off, the widget is invisible anyway,
/// so the row drops its sublabel and cannot be tapped to pick an app.
class AppSettingsRow extends StatelessWidget {
  final String name;
  final ValueNotifierWithKey<AppInfo> appNotifier;
  final ValueNotifierWithKey<bool>? enabledNotifier;
  final VoidCallback onPressed;
  final VoidCallback? onToggle;

  const AppSettingsRow({
    Key? key,
    required this.name,
    required this.appNotifier,
    required this.onPressed,
    this.enabledNotifier,
    this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final enabledNotifier = this.enabledNotifier;
    if (enabledNotifier == null) {
      return _buildRow(context, enabled: true);
    }
    return ValueListenableBuilder<bool>(
      valueListenable: enabledNotifier,
      builder: (context, enabled, child) => _buildRow(context, enabled: enabled),
    );
  }

  Widget _buildRow(BuildContext context, {required bool enabled}) {
    final primary = Theme.of(context).primaryColor;
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: enabled ? onPressed : null,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TEXT_STYLE_SETTINGS_ITEM.copyWith(
                      color: primary.withValues(alpha: enabled ? 1.0 : 0.5),
                    ),
                  ),
                  if (enabled) ...[
                    const SizedBox(height: 4),
                    ValueListenableBuilder<AppInfo>(
                      valueListenable: appNotifier,
                      builder: (context, appInfo, child) {
                        final isSet =
                            appInfo.appName != Strings.appNameUninitialized;
                        return Text(
                          isSet ? appInfo.displayName : Strings.notSet,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w200,
                            color: primary.withValues(alpha: 0.45),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (enabledNotifier != null)
          ShowHideButton(
            notifier: enabledNotifier!,
            onPressed: onToggle!,
          ),
      ],
    );
  }
}
