import 'package:flutter/material.dart';
import 'package:mars_launcher/data/app_info.dart';
import 'package:mars_launcher/logic/utils.dart';
import 'package:mars_launcher/theme/theme_constants.dart';

const MAX_LENGTH_RENAMED_APP = 30;

class RenameAppDialog extends StatelessWidget {
  final AppInfo appInfo;

  RenameAppDialog({
    Key? key,
    required this.appInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Rename \"${appInfo.appName}\"",
        style: TEXT_STYLE_DIALOG_TITLE,
      ),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppNameTextFieldWithValidation(appInfo.displayName, appInfo.appName),
        ],
      ),
    );
  }
}

class AppNameTextFieldWithValidation extends StatefulWidget {
  final String currentDisplayName;
  final String appName;

  const AppNameTextFieldWithValidation(this.currentDisplayName, this.appName);

  @override
  _AppNameTextFieldWithValidation createState() => _AppNameTextFieldWithValidation();
}

class _AppNameTextFieldWithValidation extends State<AppNameTextFieldWithValidation> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.currentDisplayName;
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayNameEqualsAppName = widget.currentDisplayName == widget.appName;

    bool isDarkMode = isThemeDark(context);
    final buttonStyle = getDialogButtonStyle(isDarkMode);
    final resetButtonStyle = getDialogButtonStyle(isDarkMode, isDestructive: true);

    return Column(
      children: [
        TextField(
          maxLength: MAX_LENGTH_RENAMED_APP,
          controller: _controller,
          cursorColor: isDarkMode ? Colors.white : Colors.black,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
              errorText: _errorText,
              filled: true,
              fillColor: isDarkMode ? Colors.white.withValues(alpha: 0.07) : Colors.white,
              focusColor: isDarkMode ? Colors.white : Colors.black,
              hintText: "Enter new name",
              hintStyle: TextStyle(
                color: Colors.black54,
              )),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                  onPressed: () {
                    if (displayNameEqualsAppName) {
                      Navigator.pop(context, null);
                    } else {
                      _controller.text = widget.appName;
                      Navigator.pop(context, widget.appName);
                    }
                  },
                  style: resetButtonStyle,
                  child: const Text("Reset")),
              TextButton(
                onPressed: () {
                  var newName = _controller.text.trim();
                  if (newName.isEmpty) {
                    setErrorText("Name can't be empty.");
                  } else if (newName == widget.currentDisplayName && displayNameEqualsAppName) {
                    /// If name didn't change, don't call logic
                    Navigator.pop(context, null);
                  } else {
                    /// If name did change return newName
                    Navigator.pop(context, newName);
                  }
                },
                style: buttonStyle,
                child: const Text("Change"),
              ),
            ],
          ),
        )
      ],
    );
  }

  void setErrorText(String? errorText) {
    setState(() {
      _errorText = errorText;
    });
  }
}
