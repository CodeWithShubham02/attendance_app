import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../model/attendance_location_model.dart';

class AttendanceRouteMapScreen extends StatefulWidget {
  final List<AttendanceLocationModel> data;

  const AttendanceRouteMapScreen({super.key, required this.data});

  @override
  State<AttendanceRouteMapScreen> createState() =>
      _AttendanceRouteMapScreenState();
}

class _AttendanceRouteMapScreenState extends State<AttendanceRouteMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _routePoints = [];

  late LatLng _initialPosition;//= const LatLng(19.0760, 72.8777); // fallback

  @override
  void initState() {
    super.initState();
    _prepareMapData();
  }

  void _prepareMapData() {
    if (widget.data.isEmpty) return;

    _loadOfficeMarker();
    _loadRoute();

    setState(() {});
  }

  void _loadOfficeMarker() {
    final officeLat = _toDouble(widget.data.first.blatitude);
    final officeLng = _toDouble(widget.data.first.blongitude);

    if (officeLat == 0 || officeLng == 0) return;

    final officeLatLng = LatLng(officeLat, officeLng);

    _markers.add(
      Marker(
        markerId: const MarkerId('office'),
        position: officeLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
        infoWindow: const InfoWindow(title: "Office Location"),
      ),
    );

    _initialPosition = officeLatLng;
  }

  void _loadRoute() {
    for (int i = 0; i < widget.data.length; i++) {
      final item = widget.data[i];

      final lat = double.tryParse(item.latitude);
      final lng = double.tryParse(item.longitude);

      if (lat == null || lng == null) continue;

      final point = LatLng(lat, lng);
      _routePoints.add(point);

      _markers.add(
        Marker(
          markerId: MarkerId('point_$i'),
          position: point,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: item.name ?? 'User',
            snippet: item.createdAt,
          ),
        ),
      );
    }

    if (_routePoints.length >= 2) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('user_route'),
          points: _routePoints,
          width: 5,
          color: Colors.blue,
        ),
      );
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  /// 🔥 Auto fit camera to route
  Future<void> _fitCameraToRoute() async {
    if (_routePoints.isEmpty) return;

    final controller = await _controller.future;

    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (var p in _routePoints) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initialPosition == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Route Tracking"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 400,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 18,
              ),
              mapType: MapType.normal,
              markers: _markers,
              polylines: _polylines,
              zoomControlsEnabled: true,
              onMapCreated: (controller) {
                _controller.complete(controller);
                _fitCameraToRoute(); // 🔥 IMPORTANT
              },
            ),
          ),
          Expanded(
            child: widget.data.isEmpty
                ? const Center(child: Text("No location data"))
                : ListView.builder(
              itemCount: widget.data.length,
              itemBuilder: (context, index) {
                final item = widget.data[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.location_on,
                        color: Colors.green),
                    title: Text(item.name ?? 'User'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Lat: ${item.latitude}"),
                        Text("Lng: ${item.longitude}"),
                        Text("Time: ${item.createdAt}"),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
