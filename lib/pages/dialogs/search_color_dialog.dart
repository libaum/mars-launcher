import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:mars_launcher/services/service_locator.dart';
import 'package:mars_launcher/theme/theme_constants.dart';
import 'package:mars_launcher/theme/theme_manager.dart';

/// Every pick applies live (the search field itself repaints behind the
/// dialog) and previews in the dialog's own title text; only "Cancel"
/// (including back/barrier dismiss) reverts to the color it was opened with.
class SearchColorDialog extends StatefulWidget {
  final bool isDark;

  const SearchColorDialog({super.key, required this.isDark});

  @override
  State<SearchColorDialog> createState() => _SearchColorDialogState();
}

class _SearchColorDialogState extends State<SearchColorDialog> {
  final _themeManager = getIt<ThemeManager>();

  late Color _selectedColor;
  late HSVColor _hsvColor;
  late final Color _originalColor;
  bool _confirmed = false;

  ColorType get _colorType =>
      widget.isDark ? ColorType.darkSearchTextColor : ColorType.lightSearchTextColor;

  /// The dialog sits on the actual configured background (not a fixed
  /// black), so the search color's contrast is visible while picking it.
  Color get _dialogBackground =>
      widget.isDark ? _themeManager.darkBackground : _themeManager.lightBackground;

  Color get _textColor => widget.isDark ? Colors.white : Colors.black;

  @override
  void initState() {
    super.initState();
    _originalColor = widget.isDark
        ? _themeManager.darkSearchTextColor
        : _themeManager.lightSearchTextColor;
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_confirmed) _apply(_originalColor);
      },
      child: AlertDialog(
        backgroundColor: _dialogBackground,
        title: Text('Search color', style: TEXT_STYLE_DIALOG_TITLE.copyWith(color: _selectedColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: SEARCH_COLOR_PRESETS
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
                                  ? _textColor
                                  : _textColor.withValues(alpha: 0.3),
                              width: _selectedColor == color ? 2.5 : 1,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
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
                      _apply(COLOR_ACCENT);
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
