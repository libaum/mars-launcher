import 'package:flutter/material.dart';
import 'package:mars_launcher/logic/temperature_manager.dart';
import 'package:mars_launcher/services/service_locator.dart';
import 'package:mars_launcher/theme/theme_constants.dart';

class Temperature extends StatelessWidget {
  final temperatureManager = getIt<TemperatureManager>();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
        valueListenable: temperatureManager.temperatureNotifier,
        builder: (context, temperature, child) {
          /// null = no value, or the last one is too old to be meaningful.
          /// Show nothing rather than a placeholder.
          if (temperature == null) return const SizedBox.shrink();
          return Text(temperature, style: TEXT_STYLE_TOP_ROW);
        });
  }
}
