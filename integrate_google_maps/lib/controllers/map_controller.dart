import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:get/get.dart';
import 'package:background_fetch/background_fetch.dart';
import 'dart:math';

class MapController extends GetxController {
  var markers = <Marker>[].obs;
  var userLocation = LatLng(37.77483, -122.41942).obs;
  var isLocationServiceEnabled = false.obs;
  var permissionGranted = false.obs;

  final List<Map<String, dynamic>> geofences = [
    {
      'id': 'geofence1',
      'location': LatLng(37.77483, -122.41942),
      'radius': 100, // radius in meters
    },
    // Add more geofences as needed
  ];

  @override
  void onInit() {
    super.onInit();
    _getUserLocation();
    _configureBackgroundFetch();
  }

  void addMarker(LatLng position) {
    final marker = Marker(
      markerId: MarkerId(position.toString()),
      position: position,
      infoWindow: InfoWindow(
        title: 'Marker',
        snippet: 'Marker at ${position.latitude}, ${position.longitude}',
      ),
    );
    markers.add(marker);
  }

  Future<void> _getUserLocation() async {
    final location = Location();

    isLocationServiceEnabled.value = await location.serviceEnabled();
    if (!isLocationServiceEnabled.value) {
      isLocationServiceEnabled.value = await location.requestService();
      if (!isLocationServiceEnabled.value) return;
    }

    final permissionStatus = await location.hasPermission();
    permissionGranted.value = permissionStatus == PermissionStatus.granted;
    if (!permissionGranted.value) {
      permissionGranted.value = (await location.requestPermission()) == PermissionStatus.granted;
      if (!permissionGranted.value) return;
    }

    final userLocationData = await location.getLocation();
    userLocation.value = LatLng(userLocationData.latitude!, userLocationData.longitude!);
  }

  void _configureBackgroundFetch() {
    BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        enableHeadless: true,
      ),
      _onBackgroundFetch,
    ).then((int status) {
      print('[BackgroundFetch] configure success: $status');
    }).catchError((e) {
      print('[BackgroundFetch] configure ERROR: $e');
    });
  }

  void _onBackgroundFetch(String taskId) async {
    // Check user location against geofences
    final location = Location();
    final userLocationData = await location.getLocation();
    final currentLocation = LatLng(userLocationData.latitude!, userLocationData.longitude!);

    for (var geofence in geofences) {
      final geofenceLocation = geofence['location'] as LatLng;
      final radius = geofence['radius'] as double;

      final distance = _calculateDistance(currentLocation, geofenceLocation);
      if (distance <= radius) {
        print('User entered geofence: ${geofence['id']}');
        // Handle geofence entry
      }
    }

    // Signal completion of the task.
    BackgroundFetch.finish(taskId);
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371000; // in meters

    final double dLat = _degreesToRadians(end.latitude - start.latitude);
    final double dLon = _degreesToRadians(end.longitude - start.longitude);

    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_degreesToRadians(start.latitude)) * cos(_degreesToRadians(end.latitude)) * sin(dLon / 2) * sin(dLon / 2));

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}
