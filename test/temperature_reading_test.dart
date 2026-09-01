import 'package:flutter_test/flutter_test.dart';
import 'package:mars_launcher/logic/temperature_reading.dart';

void main() {
  final now = DateTime(2026, 9, 1, 12, 0);

  TemperatureReading agedBy(Duration age) => TemperatureReading(21, now.subtract(age));

  group('display', () {
    test('formats as celsius', () {
      expect(agedBy(Duration.zero).display, '21°C');
    });

    test('formats negative values', () {
      expect(TemperatureReading(-4, now).display, '-4°C');
    });
  });

  group('isFreshEnoughToShow', () {
    test('a fresh value is shown', () {
      expect(agedBy(Duration.zero).isFreshEnoughToShow(now), isTrue);
    });

    test('a 5h old value is still shown', () {
      expect(agedBy(const Duration(hours: 5)).isFreshEnoughToShow(now), isTrue);
    });

    test('a 7h old value is hidden', () {
      expect(agedBy(const Duration(hours: 7)).isFreshEnoughToShow(now), isFalse);
    });
  });

  group('needsRefresh', () {
    test('not within the refresh window', () {
      expect(agedBy(const Duration(minutes: 10)).needsRefresh(now), isFalse);
    });

    test('once the refresh window has passed', () {
      expect(agedBy(const Duration(minutes: 45)).needsRefresh(now), isTrue);
    });
  });

  group('timeUntilExpiry', () {
    test('reports the remaining lifetime', () {
      expect(agedBy(const Duration(hours: 5)).timeUntilExpiry(now), const Duration(hours: 1));
    });

    test('is null once expired', () {
      expect(agedBy(const Duration(hours: 7)).timeUntilExpiry(now), isNull);
    });
  });
}
