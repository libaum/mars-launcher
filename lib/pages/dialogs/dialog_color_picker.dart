import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:mars_launcher/theme/theme_manager.dart';
import 'package:mars_launcher/services/service_locator.dart';
import 'package:mars_launcher/theme/theme_constants.dart';

const BUTTON_BACKGROUND_COLOR_DIALOG = Colors.black;
const BUTTON_TEXT_COLOR_DIALOG = Colors.white;



class ColorPickerDialog extends StatefulWidget {
  final ColorType colorType;
  final String? title;

  const ColorPickerDialog({Key? key, required this.colorType, this.title}) : super(key: key);

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  final themeManager = getIt<ThemeManager>();

  late Color selectedColor;
  late Color defaultColor;

  @override
  void initState() {
    super.initState();
    if (widget.colorType == ColorType.lightBackground) {
      selectedColor = themeManager.lightBackground;
      defaultColor = COLOR_LIGHT_BACKGROUND;
    } else if (widget.colorType == ColorType.darkBackground) {
      selectedColor = themeManager.darkBackground;
      defaultColor = COLOR_DARK_BACKGROUND;
    } else {
      selectedColor = themeManager.searchTextColor;
      defaultColor = COLOR_ACCENT;
    }
  }

  List<Color> get _presets {
    if (widget.colorType == ColorType.lightBackground) return LIGHT_BACKGROUND_PRESETS;
    if (widget.colorType == ColorType.darkBackground) return DARK_BACKGROUND_PRESETS;
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    const textButton = 'Apply';

    final buttonStyle = getDialogButtonStyle(themeManager.isDarkMode);
    final resetButtonStyle = getDialogButtonStyle(themeManager.isDarkMode, isDestructive: true);
    final presets = _presets;

    return AlertDialog(
      title: Text(
        widget.title ?? 'Background color',
        style: TEXT_STYLE_DIALOG_TITLE,
        // textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (presets.isNotEmpty) ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: presets.map((color) => GestureDetector(
                  onTap: () => setState(() => selectedColor = color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedColor == color ? COLOR_ACCENT : Colors.grey,
                        width: selectedColor == color ? 2.5 : 1,
                      ),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              Text('Custom', style: TEXT_STYLE_DIALOG_BODY),
              const SizedBox(height: 8),
            ],
            ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (Color color) {
                setState(() => selectedColor = color);
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
                    themeManager.setColor(widget.colorType, defaultColor);
                    Navigator.of(context).pop();
                  },
                  style: resetButtonStyle,
                  child: const Text('Reset'),
                ),
                TextButton(
                  onPressed: () {
                    themeManager.setColor(widget.colorType, selectedColor);
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
