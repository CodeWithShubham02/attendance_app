import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

class UserController {
  final String baseUrl = "https://fms.bizipac.com/apinew/attendance"; // emulator
  // For real device → replace with your PC's IP

  // Get Android device ID
  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (kIsWeb) {
        // ✅ Flutter Web safe ID
        final webInfo = await deviceInfo.webBrowserInfo;
        return webInfo.userAgent ?? "WEB_DEVICE";
      }

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id ?? "ANDROID_UNKNOWN";
      }

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? "IOS_UNKNOWN";
      }

      return "UNKNOWN_DEVICE";
    } catch (e) {
      return "DEVICE_ERROR";
    }
  }

  Future<Map<String, dynamic>> loginUser({
    required String userid,
    required String password,
  }) async {
    final imeiNo = await getDeviceId(); // fetch device ID

    final response = await http.post(
      Uri.parse("$baseUrl/user_login.php"),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "userid": userid,
        "password": password,
        "imei_no": imeiNo,
      },
    );

    try {
      final data = json.decode(response.body);
      return data; // {"status": true/false, "message": "...", "data": {...}}
    } catch (e) {
      return {"status": false, "message": "Invalid response from server"};
    }
  }
}
