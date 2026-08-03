import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:mars_launcher/theme/theme_manager.dart';
import 'package:mars_launcher/services/service_locator.dart';
import 'package:mars_launcher/theme/theme_constants.dart';

const BUTTON_BACKGROUND_COLOR_DIALOG = Colors.black;
const BUTTON_TEXT_COLOR_DIALOG = Colors.white;



class ColorPickerDialog extends StatelessWidget {
  final ColorType colorType;
  final themeManager = getIt<ThemeManager>();
  final String? title;

  ColorPickerDialog({Key? key, required this.colorType, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const textButton = 'Apply';

    final buttonStyle = getDialogButtonStyle(themeManager.isDarkMode);
    final resetButtonStyle = getDialogButtonStyle(themeManager.isDarkMode, isDestructive: true);

    late Color selectedColor;
    late Color defaultColor;
    if (colorType == ColorType.lightBackground) {
      selectedColor = themeManager.lightBackground;
      defaultColor = COLOR_LIGHT_BACKGROUND;
    } else if (colorType == ColorType.darkBackground) {
      selectedColor = themeManager.darkBackground;
      defaultColor = COLOR_DARK_BACKGROUND;
    } else {
      selectedColor = themeManager.searchTextColor;
      defaultColor = COLOR_ACCENT;
    }

    return AlertDialog(
      title: Text(
        title ?? 'Background color',
        style: TEXT_STYLE_DIALOG_TITLE,
        // textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (Color color) {
                selectedColor = color;
              },
              labelTypes: [],
              enableAlpha: false,
              pickerAreaHeightPercent: 0.8,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    themeManager.setColor(colorType, defaultColor);
                    Navigator.of(context).pop();
                  },
                  style: resetButtonStyle,
                  child: const Text('Reset'),
                ),
                TextButton(
                  onPressed: () {
                    themeManager.setColor(colorType, selectedColor);
                    Navigator.of(context).pop();
                  },
                  style: buttonStyle,
                  child: const Text(textButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
