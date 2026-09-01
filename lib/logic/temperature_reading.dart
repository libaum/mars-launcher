import 'package:mars_launcher/constants/global.dart';

/// A single temperature measurement plus the moment it was fetched.
///
/// Deliberately free of GetIt and platform code so the freshness rules --
/// the only part of the weather logic with real edge cases -- stay unit
/// testable. The manager owns fetching; this owns "should we still show it
/// and should we fetch again".
class TemperatureReading {
  final int celsius;
  final DateTime timestamp;

  const TemperatureReading(this.celsius, this.timestamp);

  /// Old values are still worth showing -- the temperature barely moves
  /// within a few hours -- but past [TEMPERATURE_MAX_AGE_HOURS] we hide the
  /// value entirely rather than show a stale number or a placeholder.
  bool isFreshEnoughToShow(DateTime now) =>
      now.difference(timestamp) < const Duration(hours: TEMPERATURE_MAX_AGE_HOURS);

  bool needsRefresh(DateTime now) =>
      now.difference(timestamp) >= const Duration(minutes: TEMPERATURE_MIN_REFRESH_MINUTES);

  /// When the value stops being displayable, or null if that already happened.
  Duration? timeUntilExpiry(DateTime now) {
    final remaining = timestamp.add(const Duration(hours: TEMPERATURE_MAX_AGE_HOURS)).difference(now);
    return remaining.isNegative ? null : remaining;
  }

  String get display => "$celsius°C";
}
