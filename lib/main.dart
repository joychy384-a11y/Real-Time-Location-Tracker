import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LiveLocationTracker(),
    );
  }
}

class LiveLocationTracker extends StatefulWidget {
  const LiveLocationTracker({super.key});

  @override
  State<LiveLocationTracker> createState() => _LiveLocationTrackerState();
}

class _LiveLocationTrackerState extends State<LiveLocationTracker> {
  GoogleMapController? _mapController;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  List<LatLng> polylineCoordinates = [];

  Timer? _timer;

  LatLng currentLatLng = const LatLng(23.8103, 90.4125);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) {
        _getCurrentLocation();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    LatLng newPosition = LatLng(
      position.latitude,
      position.longitude,
    );

    polylineCoordinates.add(newPosition);

    _markers.clear();

    _markers.add(
      Marker(
        markerId: const MarkerId("currentLocation"),
        position: newPosition,
        infoWindow: InfoWindow(
          title: "My Current Location",
          snippet: "${position.latitude}, ${position.longitude}",
        ),
      ),
    );

    _polylines.clear();

    _polylines.add(
      Polyline(
        polylineId: const PolylineId("route"),
        points: polylineCoordinates,
        color: Colors.blue,
        width: 5,
      ),
    );

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: newPosition,
          zoom: 16,
        ),
      ),
    );

    setState(() {
      currentLatLng = newPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Real-Time Location Tracker"),
        backgroundColor: Colors.blue,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: currentLatLng,
          zoom: 14,
        ),
        markers: _markers,
        polylines: _polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
      ),
    );
  }
}
