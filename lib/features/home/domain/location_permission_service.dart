enum LocationPermissionStatus {
  unknown,
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

class LocationCoordinates {
  const LocationCoordinates({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

abstract class LocationPermissionService {
  Future<LocationPermissionStatus> requestPermission();
  Future<LocationCoordinates?> getCurrentCoordinates();
}
