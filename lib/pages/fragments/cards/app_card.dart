import 'package:flutter/material.dart';
import 'package:mars_launcher/data/app_info.dart';
import 'package:mars_launcher/theme/theme_constants.dart';

class AppCard extends StatelessWidget {
  final AppInfo appInfo;
  final bool isShortcutItem;
  final String? placeholderText;
  final Function(BuildContext, AppInfo) callbackHandleOnPress;
  final Function(BuildContext, AppInfo) callbackHandleOnLongPress;

  const AppCard({
    required this.appInfo,
    required this.callbackHandleOnPress,
    required this.callbackHandleOnLongPress,
    this.isShortcutItem = false,
    this.placeholderText,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = placeholderText != null;
    final letterSpacing = isShortcutItem ? 1.0 : 0.0;
    final baseColor = isShortcutItem
        ? Theme.of(context).primaryColor
        : Theme.of(context).colorScheme.secondary;
    /// An empty slot keeps the type size of a set app and only dims, so the
    /// four slots read as one column either way.
    final textColor = isPlaceholder ? baseColor.withValues(alpha: 0.45) : baseColor;
    const textStyle = TEXT_STYLE_APP_LARGE;

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
      alignment: Alignment.topLeft,
      child: TextButton(
        onPressed: () {
          callbackHandleOnPress(context, appInfo);
        },
        onLongPress: () {
          callbackHandleOnLongPress(context, appInfo);
        },
        child: Text(
          placeholderText ?? appInfo.displayName,
          style: textStyle.copyWith(letterSpacing: letterSpacing),
          maxLines: isShortcutItem ? 1 : 2,
        ),
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(textColor),
        ),
      ),
    );
  }
}
