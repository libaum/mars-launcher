import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:mars_launcher/constants/global.dart';
import 'package:mars_launcher/logic/apps_manager.dart';
import 'package:mars_launcher/logic/settings_manager.dart';
import 'package:mars_launcher/logic/shortcut_manager.dart';
import 'package:mars_launcher/services/location_service.dart';
import 'package:mars_launcher/services/permission_service.dart';
import 'package:mars_launcher/services/service_locator.dart';
import 'package:mars_launcher/services/shared_prefs_manager.dart';
import 'package:mars_launcher/strings.dart';
import 'package:mars_launcher/theme/theme_manager.dart';
import 'package:open_meteo/open_meteo.dart';

class TemperatureManager {
  final sharedPrefsManager = getIt<SharedPrefsManager>();
  final temperatureNotifier = ValueNotifier(Strings.defaultTemperatureString);
  final sunriseSunsetNotifier = ValueNotifier("");
  var sunriseSunsetString = "";
  final locationService = LocationService();
  final appShortcutManager = getIt<AppShortcutsManager>();
  final permissionService = getIt<PermissionService>();
  final settingsManager = getIt<SettingsManager>();
  final themeManager = getIt<ThemeManager>();
  final appsManager = getIt<AppsManager>();

  final weatherApi = WeatherApi(temperatureUnit: TemperatureUnit.celsius);
  Timer? timer;
  DateTime lastTemperatureUpdate = DateTime(0);
  DateTime lastSunriseSunsetUpdate = DateTime(0);

  TemperatureManager() {
    print("[$runtimeType] INITIALIZING");

    if (settingsManager.weatherWidgetEnabledNotifier.value) {
      updateTemperature();
    }

    /// Setup timer to update temperature every 5min only when weatherWidget is enabled
    timer = Timer.periodic(Duration(minutes: UPDATE_TEMPERATURE_EVERY), (timer) {
      if (settingsManager.weatherWidgetEnabledNotifier.value) {
        updateTemperature();
      }
    });

    settingsManager.weatherWidgetEnabledNotifier.addListener(() {
      if (settingsManager.weatherWidgetEnabledNotifier.value) {
        updateTemperature(userInitiated: true);
      }
    });
  }

  /// [userInitiated] marks calls that follow the user just flipping the
  /// weather toggle in Settings, as opposed to the periodic background
  /// refresh -- only then do we nudge towards the app's settings on a
  /// permanent permission denial, so we don't spam that every 5 minutes.
  void updateTemperature({bool userInitiated = false}) async {
    if (SHOWCASE_TEMPERATURE != null) {
      setNewTemperature(SHOWCASE_TEMPERATURE);
      sunriseSunsetString = "Sunrise: $SHOWCASE_SUNRISE\nSunset:  $SHOWCASE_SUNSET";
      lastSunriseSunsetUpdate = DateTime.now();
      return;
    }

    /// Check if weather is enabled
    if (!settingsManager.weatherWidgetEnabledNotifier.value) {
      return couldNotRetrieveNewTemperature("[$runtimeType] weather widget disabled");
    }

    /// Requesting location permission needs a foreground Activity -- if the
    /// app is backgrounded (e.g. periodic timer firing while another app is
    /// open), location.requestPermission() throws MISSING_ACTIVITY. Skip
    /// the update in that case; it'll retry on the next timer tick or when
    /// the user reopens the app.
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return couldNotRetrieveNewTemperature("[$runtimeType] app not in foreground, skipping");
    }

    /// Check if permission for location is granted. Requesting it can pop up
    /// a system dialog, which briefly sends the app to the background --
    /// suppress the usual "app left -> reset to home" handling for that.
    appsManager.suppressLifecycleReset = true;
    final hasPermission = await locationService.checkPermission();
    if (!hasPermission) {
      if (userInitiated && locationService.isPermanentlyDenied) {
        Fluttertoast.showToast(msg: "Location permission needed — opening app settings");
        await appsManager.openAppSettings(PACKAGE_NAME);
      }
      return couldNotRetrieveNewTemperature("[$runtimeType] no permission for location.");
    }

    /// Get current location from locationService
    await locationService.updateLocation();
    if (locationService.locationData?.latitude == null || locationService.locationData?.longitude == null) {
      return couldNotRetrieveNewTemperature("[$runtimeType] latitude or longitude == null");
    }

    /// Request the current weather for location data
    print("[$runtimeType] Fetching new weather data");

    DateTime now = DateTime.now();
    try {
      final response = await weatherApi.request(
        locations: {
          OpenMeteoLocation(
          latitude: locationService.locationData!.latitude,
          longitude: locationService.locationData!.longitude,
          startDate: now,
          endDate: now,
          )
        },
        current: {WeatherCurrent.temperature_2m},
        daily: {WeatherDaily.sunrise, WeatherDaily.sunset},
      );

      final temp = response.segments[0].currentData[WeatherCurrent.temperature_2m]?.value.round() ?? "-";
      print(response.segments[0].dailyData[WeatherDaily.sunset]?.values.values.first);
      setNewTemperature(temp);

      /// Update sunrise/sunset data if last update later than 10h (10h * 60min * 60s)
      bool isMoreThanTenHours = DateTime.now().difference(lastSunriseSunsetUpdate).inHours > 10;
      if (isMoreThanTenHours) {
        final sunriseUnix = response.segments[0].dailyData[WeatherDaily.sunrise]?.values.values.first;
        final sunsetUnix = response.segments[0].dailyData[WeatherDaily.sunset]?.values.values.first;

        if (sunriseUnix != null && sunsetUnix != null) {
          DateTime sunriseDateTime = DateTime.fromMillisecondsSinceEpoch(sunriseUnix.toInt() * 1000);
          DateTime sunsetDateTime = DateTime.fromMillisecondsSinceEpoch(sunsetUnix.toInt() * 1000);
          updateSunriseSunset(sunsetDateTime, sunriseDateTime);
        }
      }

        } catch (e) {
      couldNotRetrieveNewTemperature("[$runtimeType] Error fetching weather data: $e");
    }

  }

  void setNewTemperature(temp) {
    temperatureNotifier.value = "$temp°C";
    lastTemperatureUpdate = DateTime.now();

    print("[$runtimeType] New Temperature value: ${temperatureNotifier.value}");
  }

  void updateSunriseSunset(DateTime sunset, DateTime sunrise) {
    sunriseSunsetString = "Sunrise: ${DateFormat.Hm().format(sunrise)}\nSunset:  ${DateFormat.Hm().format(sunset)}";
    lastSunriseSunsetUpdate = DateTime.now();
  }

  void couldNotRetrieveNewTemperature(String cause) {
    print("[$runtimeType] $cause");
    bool isMoreThanThreeHours = DateTime.now().difference(lastTemperatureUpdate).inHours > 3;
    if (isMoreThanThreeHours) {
      /// If lastUpdated more than 3h ago delete value
      temperatureNotifier.value = Strings.defaultTemperatureString;
    } else if (temperatureNotifier.value != Strings.defaultTemperatureString){
      /// Append * in front of temperature to signal it is not latest
      if (!temperatureNotifier.value.contains("*")) {
        temperatureNotifier.value = "*" + temperatureNotifier.value;
      }
    }
  }

  void showSunriseSunsetForAFewSeconds() async {
    sunriseSunsetNotifier.value = sunriseSunsetString;
    await Future.delayed(Duration(seconds: DURATION_SHOW_SUNRISE_SUNSET));
    sunriseSunsetNotifier.value = "";
  }
}
