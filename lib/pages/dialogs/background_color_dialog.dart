import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:mars_launcher/services/service_locator.dart';
import 'package:mars_launcher/theme/theme_constants.dart';
import 'package:mars_launcher/theme/theme_manager.dart';

/// Every pick applies live behind the dialog as a preview; only "Cancel"
/// (including back/barrier dismiss) reverts to the color it was opened with.
class BackgroundColorDialog extends StatefulWidget {
  final bool isDark;

  const BackgroundColorDialog({super.key, required this.isDark});

  @override
  State<BackgroundColorDialog> createState() => _BackgroundColorDialogState();
}

class _BackgroundColorDialogState extends State<BackgroundColorDialog> {
  final _themeManager = getIt<ThemeManager>();

  late Color _selectedColor;
  late HSVColor _hsvColor;
  late final Color _originalColor;
  bool _confirmed = false;

  ColorType get _colorType =>
      widget.isDark ? ColorType.darkBackground : ColorType.lightBackground;

  Color get _defaultColor =>
      widget.isDark ? COLOR_DARK_BACKGROUND : COLOR_LIGHT_BACKGROUND;

  List<Color> get _presets =>
      widget.isDark ? DARK_BACKGROUND_PRESETS : LIGHT_BACKGROUND_PRESETS;

  @override
  void initState() {
    super.initState();
    _originalColor = widget.isDark
        ? _themeManager.darkBackground
        : _themeManager.lightBackground;
    _selectedColor = _originalColor;
    _hsvColor = HSVColor.fromColor(_originalColor);
  }

  void _preview(Color color) {
    setState(() {
      _selectedColor = color;
      _hsvColor = HSVColor.fromColor(color);
    });
    _apply(color);
  }

  void _previewHsv(HSVColor hsv) => _preview(hsv.toColor());

  void _apply(Color color) {
    _themeManager.setColor(_colorType, color);
  }

  /// A shade of the currently selected color to ring it with — darker in
  /// light mode, lighter in dark mode — so the selection stays visible
  /// against any preset without relying on a fixed accent color.
  Color get _selectionRingColor {
    final hsl = HSLColor.fromColor(_selectedColor);
    final lightness = widget.isDark
        ? (hsl.lightness + 0.55).clamp(0.0, 1.0)
        : (hsl.lightness - 0.4).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// A faint version of the dialog's own text color, rather than a fixed
  /// gray — reads more cleanly against the wide range of preset hues than
  /// one flat tone does.
  Color get _unselectedRingColor =>
      (widget.isDark ? Colors.white : Colors.black).withValues(alpha: 0.3);

  /// The dialog's own background now tracks the live preview, so its text
  /// can no longer rely on the fixed "always white on a black surface"
  /// dialog theme — it must follow light/dark mode instead.
  Color get _textColor => widget.isDark ? Colors.white : Colors.black;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_confirmed) _apply(_originalColor);
      },
      child: AlertDialog(
        backgroundColor: _selectedColor,
        title: Text('Background color', style: TEXT_STYLE_DIALOG_TITLE.copyWith(color: _textColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _presets
                    .map(
                      (color) => GestureDetector(
                        onTap: () => _preview(color),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3.0),
                            border: Border.all(
                              color: _selectedColor == color
                                  ? _selectionRingColor
                                  : _unselectedRingColor,
                              width: _selectedColor == color ? 2.5 : 1,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              // Built from the picker's lower-level pieces (area + hue
              // slider) instead of the bundled `ColorPicker` widget, which
              // always renders an extra circular swatch next to the slider —
              // redundant here since the dialog's own background already
              // previews the color.
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: SizedBox(
                          width: width,
                          height: width * 0.7,
                          child: ColorPickerArea(
                            _hsvColor,
                            _previewHsv,
                            PaletteType.hsv,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: width,
                        height: 40,
                        child: ColorPickerSlider(
                          TrackType.hue,
                          _hsvColor,
                          _previewHsv,
                        ),
                      ),
                    ],
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    style: getDialogButtonStyle(widget.isDark).copyWith(
                      foregroundColor: WidgetStateProperty.all(_textColor.withValues(alpha: 0.6)),
                    ),
                    onPressed: () {
                      _confirmed = true;
                      _apply(_defaultColor);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Reset'),
                  ),
                  TextButton(
                    style: getDialogButtonStyle(widget.isDark).copyWith(
                      foregroundColor: WidgetStateProperty.all(_textColor),
                    ),
                    onPressed: () {
                      _confirmed = true;
                      Navigator.of(context).pop();
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
