import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // 🔔 Android foreground requirement (silent)
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  Timer.periodic(const Duration(seconds: 15), (timer) async {
    final prefs = await SharedPreferences.getInstance();
    final attendanceId = prefs.getString('attendance_id');

    // ❌ No attendance → stop service
    if (attendanceId == null || attendanceId.isEmpty) {
      timer.cancel();
      service.stopSelf();
      return;
    }

    // 🌐 Internet check
    bool hasInternet = false;
    try {
      final result = await InternetAddress.lookup('google.com');
      hasInternet = result.isNotEmpty;
    } catch (_) {}

    if (!hasInternet) return;

    // 📍 GPS enabled?
    final gpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!gpsEnabled) return;

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await http.post(
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
    } catch (_) {}
  });

  // 🛑 Stop from UI
  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}
