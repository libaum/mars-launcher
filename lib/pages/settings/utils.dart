import 'package:flutter/material.dart';
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
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
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