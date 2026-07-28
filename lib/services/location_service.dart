import 'package:flutter/services.dart';
import 'package:location/location.dart';

class LocationService {
  final location = new Location();
  LocationData? locationData;

  Future<bool> isServiceEnabled() async {
    try {
      return await location.serviceEnabled();
    } on PlatformException {
      return false;
    }
  }

  Future<bool> checkPermission() async {
    bool serviceEnabled = await isServiceEnabled();

    if (!serviceEnabled && !await location.requestService()) {
      /// User denied turning on location services
      return false;
    }

    /// Check the permission status
    PermissionStatus permissionStatus = await location.hasPermission();

    if (permissionStatus == PermissionStatus.denied) {
      /// Request location permission if not granted
      permissionStatus = await location.requestPermission();
      if (permissionStatus != PermissionStatus.granted) {
        /// User denied location permission
        return false;
      }
    }

    /// Location services are enabled, and permission is granted
    return true;
  }

  updateLocation() async {
    locationData = await location.getLocation();
  }
}
