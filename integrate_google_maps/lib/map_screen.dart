import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:get/get.dart';
import 'package:background_fetch/background_fetch.dart';

class MapController extends GetxController {
  var markers = <Marker>[].obs;
  var userLocation = LatLng(37.77483, -122.41942).obs;
  var isLocationServiceEnabled = false.obs;
  var permissionGranted = false.obs;

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
    // Handle geofence checks here

    // Signal completion of the task.
    BackgroundFetch.finish(taskId);
  }
}

class MapScreen extends StatelessWidget {
  final MapController controller = Get.put(MapController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Google Map')),
      body: Obx(() {
        if (!controller.permissionGranted.value) {
          return Center(child: Text('Location permission denied'));
        }

        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: controller.userLocation.value,
            zoom: 12,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          markers: Set<Marker>.of(controller.markers),
          onTap: (position) {
            controller.addMarker(position);
          },
        );
      }),
    );
  }
}
