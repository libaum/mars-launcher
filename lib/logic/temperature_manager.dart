import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:mars_launcher/constants/global.dart';
import 'package:mars_launcher/logic/apps_manager.dart';
import 'package:mars_launcher/logic/settings_manager.dart';
import 'package:mars_launcher/logic/temperature_reading.dart';
import 'package:mars_launcher/services/location_service.dart';
import 'package:mars_launcher/services/service_locator.dart';
import 'package:mars_launcher/services/shared_prefs_manager.dart';
import 'package:mars_launcher/strings.dart';
import 'package:open_meteo/open_meteo.dart';

/// Owns the temperature shown in the top row.
///
/// There is no periodic polling: location needs a foreground activity, so a
/// background timer could only ever fail. Instead we fetch when the launcher
/// becomes visible (startup and app resume) and only if the value we have is
/// older than [TEMPERATURE_MIN_REFRESH_MINUTES]. A failed fetch never touches
/// the display -- the last value stays until it ages out of
/// [TEMPERATURE_MAX_AGE_HOURS], then it disappears silently.
class TemperatureManager {
  final sharedPrefsManager = getIt<SharedPrefsManager>();

  /// null means: show nothing at all (no value yet, or the last one is stale).
  final temperatureNotifier = ValueNotifier<String?>(null);
  final sunriseSunsetNotifier = ValueNotifier("");

  final locationService = LocationService();
  final appsManager = getIt<AppsManager>();
  final settingsManager = getIt<SettingsManager>();

  final weatherApi = WeatherApi(temperatureUnit: TemperatureUnit.celsius);

  TemperatureReading? _reading;
  String sunriseSunsetString = "";
  DateTime _lastSunriseSunsetUpdate = DateTime(0);
  double? _lastLatitude;
  double? _lastLongitude;

  /// Fires exactly once, when the current reading ages out, so the value also
  /// disappears while the launcher sits open. No network involved.
  Timer? _expiryTimer;

  /// Throttles attempts so a resume plus the startup callback don't fetch
  /// twice. Deliberately a timestamp and not an "in flight" flag: a fetch
  /// interrupted by Android pausing the app never completes its future, and a
  /// flag would then stay set for the rest of the process -- which silently
  /// killed every later refresh.
  DateTime _lastAttempt = DateTime(0);
  static const _minGapBetweenAttempts = Duration(seconds: 20);

  /// Right after a cold start or a resume the location plugin is often not
  /// bound yet, so the first attempt fails through no fault of the user. Retry
  /// a few times with a growing delay instead of leaving the top row empty
  /// until the next time they leave and come back.
  Timer? _retryTimer;
  int _failedAttempts = 0;
  static const _retryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 30),
  ];

  TemperatureManager() {
    print("[$runtimeType] INITIALIZING");

    _restoreFromPrefs();
    _publishTemperature();

    /// Requesting location needs a resumed activity -- wait for the first
    /// frame so the very first fetch isn't skipped by the foreground guard.
    WidgetsBinding.instance.addPostFrameCallback((_) => maybeUpdateTemperature());

    settingsManager.weatherWidgetEnabledNotifier.addListener(() {
      if (settingsManager.weatherWidgetEnabledNotifier.value) {
        updateTemperature(userInitiated: true);
      } else {
        _publishTemperature();
      }
    });
  }

  void _restoreFromPrefs() {
    final celsius = sharedPrefsManager.readData(Keys.temperatureCelsius);
    final updatedAt = sharedPrefsManager.readData(Keys.temperatureUpdatedAt);
    if (celsius is int && updatedAt is int) {
      _reading = TemperatureReading(celsius, DateTime.fromMillisecondsSinceEpoch(updatedAt));
    }

    _lastLatitude = _readDouble(Keys.temperatureLat);
    _lastLongitude = _readDouble(Keys.temperatureLon);

    final storedSunriseSunset = sharedPrefsManager.readData(Keys.sunriseSunsetText);
    sunriseSunsetString = storedSunriseSunset is String ? storedSunriseSunset : "";
    final sunUpdatedAt = sharedPrefsManager.readData(Keys.sunriseSunsetUpdatedAt);
    if (sunUpdatedAt is int) {
      _lastSunriseSunsetUpdate = DateTime.fromMillisecondsSinceEpoch(sunUpdatedAt);
    }
  }

  /// Coordinates are stored as strings -- [SharedPrefsManager.saveData] has
  /// no double branch.
  double? _readDouble(String key) {
    final stored = sharedPrefsManager.readData(key);
    return stored is String ? double.tryParse(stored) : null;
  }

  /// Called when the launcher becomes visible. Cheap when the value is still
  /// young enough -- it only re-evaluates visibility.
  void maybeUpdateTemperature() {
    if (!settingsManager.weatherWidgetEnabledNotifier.value) return;

    _publishTemperature();

    /// A fresh visit deserves a fresh set of retries.
    _failedAttempts = 0;

    final reading = _reading;
    if (reading == null || reading.needsRefresh(DateTime.now())) {
      updateTemperature();
    }
  }

  /// [userInitiated] marks calls that follow the user just flipping the
  /// weather toggle in Settings -- only then do we nudge towards the app's
  /// settings on a permanent permission denial.
  void updateTemperature({bool userInitiated = false, bool isRetry = false}) async {
    if (SHOWCASE_TEMPERATURE != null) {
      _setNewTemperature(SHOWCASE_TEMPERATURE!);
      _updateSunriseSunsetString("Sunrise: $SHOWCASE_SUNRISE\nSunset:  $SHOWCASE_SUNSET");
      return;
    }

    if (!settingsManager.weatherWidgetEnabledNotifier.value) {
      return _couldNotRetrieveNewTemperature("weather widget disabled", retry: false);
    }

    /// Location needs a foreground Activity -- requesting it while another app
    /// is in front throws MISSING_ACTIVITY. Skip; we retry on the next resume.
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return _couldNotRetrieveNewTemperature("app not in foreground, skipping", retry: false);
    }

    final bypassThrottle = userInitiated || isRetry;
    if (!bypassThrottle && DateTime.now().difference(_lastAttempt) < _minGapBetweenAttempts) {
      return;
    }
    _lastAttempt = DateTime.now();
    _retryTimer?.cancel();

    try {
      /// An automatic refresh only ever *checks* the permission. Asking for it
      /// would pop a system dialog, which sends the launcher to the background
      /// and looks exactly like the user opening another app -- the reason the
      /// [AppsManager.suppressLifecycleReset] dance existed here and kept
      /// swallowing the reset to the home view. Permission is asked for where
      /// the user can make sense of it: when enabling the widget in Settings.
      var hasPermission = await locationService.hasPermissionGranted();

      if (!hasPermission && userInitiated) {
        /// The user just flipped the toggle, so a dialog is expected here.
        appsManager.suppressLifecycleReset = true;
        try {
          hasPermission = await locationService.checkPermission();
        } finally {
          appsManager.suppressLifecycleReset = false;
        }
      }

      if (!hasPermission) {
        if (userInitiated && locationService.isPermanentlyDenied) {
          Fluttertoast.showToast(msg: "Location permission needed — opening app settings");
          await appsManager.openAppSettings(PACKAGE_NAME);
        }
        return _couldNotRetrieveNewTemperature("no permission for location.");
      }

      await _updateCoordinates();
      if (_lastLatitude == null || _lastLongitude == null) {
        return _couldNotRetrieveNewTemperature("no coordinates available");
      }

      print("[$runtimeType] Fetching new weather data");
      final now = DateTime.now();
      /// A hanging request would otherwise keep the whole update pending
      /// indefinitely.
      final response = await weatherApi
          .request(
            locations: {
              OpenMeteoLocation(
                latitude: _lastLatitude!,
                longitude: _lastLongitude!,
                startDate: now,
                endDate: now,
              )
            },
            current: {WeatherCurrent.temperature_2m},
            daily: {WeatherDaily.sunrise, WeatherDaily.sunset},
          )
          .timeout(const Duration(seconds: WEATHER_REQUEST_TIMEOUT_SECONDS));

      final temp = response.segments[0].currentData[WeatherCurrent.temperature_2m]?.value;
      if (temp == null) {
        return _couldNotRetrieveNewTemperature("response contained no temperature");
      }
      _failedAttempts = 0;
      _setNewTemperature(temp.round());

      if (_sunriseSunsetIsOutdated()) {
        final sunriseUnix = response.segments[0].dailyData[WeatherDaily.sunrise]?.values.values.first;
        final sunsetUnix = response.segments[0].dailyData[WeatherDaily.sunset]?.values.values.first;

        if (sunriseUnix != null && sunsetUnix != null) {
          final sunrise = DateTime.fromMillisecondsSinceEpoch(sunriseUnix.toInt() * 1000);
          final sunset = DateTime.fromMillisecondsSinceEpoch(sunsetUnix.toInt() * 1000);
          _updateSunriseSunsetString(
              "Sunrise: ${DateFormat.Hm().format(sunrise)}\nSunset:  ${DateFormat.Hm().format(sunset)}");
        }
      }
    } catch (e) {
      /// Covers the location plugin as well -- getLocation() can throw a
      /// PlatformException or time out.
      _couldNotRetrieveNewTemperature("Error fetching weather data: $e");
    }
  }

  /// Tries for a fresh fix; keeps the persisted coordinates on failure, since
  /// a temperature is coarse enough that yesterday's position still works.
  Future<void> _updateCoordinates() async {
    try {
      await locationService.updateLocation();
    } catch (e) {
      print("[$runtimeType] could not get location, using last known: $e");
      return;
    }

    final latitude = locationService.locationData?.latitude;
    final longitude = locationService.locationData?.longitude;
    if (latitude == null || longitude == null) return;

    _lastLatitude = latitude;
    _lastLongitude = longitude;
    sharedPrefsManager.saveData(Keys.temperatureLat, latitude.toString());
    sharedPrefsManager.saveData(Keys.temperatureLon, longitude.toString());
  }

  void _setNewTemperature(int celsius) {
    final reading = TemperatureReading(celsius, DateTime.now());
    _reading = reading;
    sharedPrefsManager.saveData(Keys.temperatureCelsius, celsius);
    sharedPrefsManager.saveData(Keys.temperatureUpdatedAt, reading.timestamp.millisecondsSinceEpoch);
    _publishTemperature();

    print("[$runtimeType] New Temperature value: ${reading.display}");
  }

  /// The single place deciding what the top row shows.
  void _publishTemperature() {
    final reading = _reading;
    final showValue = reading != null && reading.isFreshEnoughToShow(DateTime.now());
    temperatureNotifier.value = showValue ? reading.display : null;
    _scheduleExpiry();
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    final remaining = _reading?.timeUntilExpiry(DateTime.now());
    if (remaining == null) return;
    _expiryTimer = Timer(remaining, _publishTemperature);
  }

  /// A failed fetch must not change what is on screen -- only age does.
  void _couldNotRetrieveNewTemperature(String cause, {bool retry = true}) {
    print("[$runtimeType] $cause");
    _publishTemperature();
    if (retry) _scheduleRetry();
  }

  void _scheduleRetry() {
    if (_failedAttempts >= _retryDelays.length) return;
    final delay = _retryDelays[_failedAttempts];
    _failedAttempts++;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (settingsManager.weatherWidgetEnabledNotifier.value) {
        updateTemperature(isRetry: true);
      }
    });
  }

  /// Refresh once the values are stale or simply from another day, so the
  /// launcher never shows yesterday's sunrise.
  bool _sunriseSunsetIsOutdated() {
    if (sunriseSunsetString.isEmpty) return true;
    final now = DateTime.now();
    if (now.difference(_lastSunriseSunsetUpdate).inHours > SUNRISE_SUNSET_MAX_AGE_HOURS) return true;
    return !DateUtils.isSameDay(now, _lastSunriseSunsetUpdate);
  }

  void _updateSunriseSunsetString(String text) {
    sunriseSunsetString = text;
    _lastSunriseSunsetUpdate = DateTime.now();
    sharedPrefsManager.saveData(Keys.sunriseSunsetText, text);
    sharedPrefsManager.saveData(Keys.sunriseSunsetUpdatedAt, _lastSunriseSunsetUpdate.millisecondsSinceEpoch);
  }

  void showSunriseSunsetForAFewSeconds() async {
    if (sunriseSunsetString.isEmpty) return;
    sunriseSunsetNotifier.value = sunriseSunsetString;
    await Future.delayed(Duration(seconds: DURATION_SHOW_SUNRISE_SUNSET));
    sunriseSunsetNotifier.value = "";
  }
}
