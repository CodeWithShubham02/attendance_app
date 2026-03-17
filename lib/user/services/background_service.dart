import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {

  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  Timer.periodic(const Duration(seconds: 60), (timer) async {

    final prefs = await SharedPreferences.getInstance();
    final attendanceId = prefs.getString('attendance_id');

    if (attendanceId == null || attendanceId.isEmpty) {
      timer.cancel();
      service.stopSelf();
      return;
    }

    try {

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 60),
      );

      print("📡 Sending location: ${pos.latitude}, ${pos.longitude}");

      final response = await http.post(
        Uri.parse(
          "https://fms.bizipac.com/apinew/attendance/track_location.php",
        ),
        body: {
          "attendance_id": attendanceId,
          "lat": pos.latitude.toString(),
          "lng": pos.longitude.toString(),
          "status": "active",
        },
      );

      print("API Response: ${response.body}");

    } catch (e) {
      print("❌ Location/API error: $e");
    }

  });

  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}