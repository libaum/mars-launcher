import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:mars_launcher/constants/global.dart';

class LocationService {
  final location = new Location();
  LocationData? locationData;

  /// Set by [checkPermission]. True once the user has permanently denied
  /// location access ("don't ask again") -- Android won't show the system
  /// dialog again after that, so the only way forward is the app's settings.
  bool isPermanentlyDenied = false;

  Future<bool> isServiceEnabled() async {
    try {
      return await location.serviceEnabled();
    } on PlatformException {
      return false;
    }
  }

  /// Permission check that never pops a dialog. Deliberately does not care
  /// whether location services are switched on: a caller that has cached
  /// coordinates can still do useful work without a fresh fix.
  Future<bool> hasPermissionGranted() async {
    try {
      final status = await location.hasPermission();
      return status == PermissionStatus.granted || status == PermissionStatus.grantedLimited;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> checkPermission() async {
    isPermanentlyDenied = false;
    bool serviceEnabled = await isServiceEnabled();

    if (!serviceEnabled && !await location.requestService()) {
      /// User denied turning on location services
      return false;
    }

    /// Check the permission status
    PermissionStatus permissionStatus = await location.hasPermission();

    if (permissionStatus == PermissionStatus.denied) {
      /// Request location permission if not granted. No-op if the user
      /// already denied it permanently (deniedForever) -- Android won't show
      /// the dialog again in that case, so this just returns deniedForever.
      permissionStatus = await location.requestPermission();
    }

    isPermanentlyDenied = permissionStatus == PermissionStatus.deniedForever;
    return permissionStatus == PermissionStatus.granted ||
        permissionStatus == PermissionStatus.grantedLimited;
  }

  /// [getLocation] can hang indefinitely when the GPS fix never arrives, so
  /// give up after [LOCATION_TIMEOUT_SECONDS]; callers fall back to the last
  /// known coordinates.
  updateLocation() async {
    locationData = await location
        .getLocation()
        .timeout(const Duration(seconds: LOCATION_TIMEOUT_SECONDS));
  }
}
