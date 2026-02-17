import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../admin/model/user_model.dart';
import '../../admin/view/login_screen.dart';
import '../view/punch_in_out_screen.dart';
import '../view/user_attendance_screen.dart';
import '../view/airport_form_screen.dart';
import '../view/submit_form_screen.dart';
import '../view/get_report_kiosk_screen.dart';
import '../view/google_location_screen.dart';
import '../view/attendance_screen.dart';

class EmployeeHomeScreen extends StatefulWidget {
  final UserModel userModel;

  const EmployeeHomeScreen({super.key, required this.userModel});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  String? attendanceId;
  Position? currentPosition;

  Timer? gpsTimer;
  StreamSubscription<List<ConnectivityResult>>? connectivitySub;

  bool internetDialogShown = false;

  /* ---------------- INIT ---------------- */

  @override
  void initState() {
    super.initState();
    loadAttendanceId();
    loadLiveLocation();
    startGpsMonitor();
    startInternetMonitor(); // 🔥 ADD THIS
    syncOfflinePunchOutIfAny();
  }

  @override
  void dispose() {
    gpsTimer?.cancel();
    connectivitySub?.cancel();
    super.dispose();
  }


  /* ---------------- INTERNET MONITOR ---------------- */

  void startInternetMonitor() {
    connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      final hasInternet = await hasRealInternet();

      /// 🔴 INTERNET OFF
      if (!hasInternet && attendanceId != null && !internetDialogShown) {
        internetDialogShown = true;

        await autoPunchOutInternet(
          "Internet turned off - Auto Punch Out",
        );

        if (!mounted) return;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const AlertDialog(
              title: Text("Internet Off"),
              content: Text(
                "Your internet connection is turned off.\n"
                    "You have been auto punched out.",
              ),
            ),
          );
        });
      }

      /// 🟢 INTERNET BACK
      if (hasInternet) {
        internetDialogShown = false;
        await syncOfflinePunchOutIfAny();
      }
    });
  }

  Future<bool> hasRealInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /* ---------------- LOCAL OFFLINE SAVE ---------------- */

  Future<void> saveLocalPunchOut(String reason) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool("offline_punchout_pending", true);
    await prefs.setString("offline_attendance_id", attendanceId ?? "");
    await prefs.setString("offline_reason", reason);
    await prefs.setString(
        "offline_lat", currentPosition?.latitude.toString() ?? "0");
    await prefs.setString(
        "offline_lng", currentPosition?.longitude.toString() ?? "0");
    await prefs.setString(
        "offline_time", DateTime.now().toIso8601String());

    debugPrint("📦 Offline punch-out saved");
  }

  /* ---------------- OFFLINE SYNC ---------------- */

  Future<void> syncOfflinePunchOutIfAny() async {
    final prefs = await SharedPreferences.getInstance();

    final pending = prefs.getBool("offline_punchout_pending") ?? false;
    if (!pending) return;

    final savedAttendanceId =
        prefs.getString("offline_attendance_id") ?? "";
    if (savedAttendanceId.isEmpty) return;

    final internet = await hasRealInternet();
    if (!internet) return;

    final res = await http.post(
      Uri.parse(
        "https://fms.bizipac.com/apinew/attendance/attendance_punch_out.php"
            "?attendance_id=$savedAttendanceId",
      ),
      body: {
        "action": "punch_out",
        "status": "Present",
        "remark": prefs.getString("offline_reason") ?? "",
        "lat": prefs.getString("offline_lat") ?? "0",
        "lng": prefs.getString("offline_lng") ?? "0",
        "image": "NA",
      },
    );

    if (res.statusCode == 200) {
      await prefs.remove("offline_punchout_pending");
      await prefs.remove("offline_attendance_id");
      await prefs.remove("offline_reason");
      await prefs.remove("offline_lat");
      await prefs.remove("offline_lng");
      await prefs.remove("offline_time");
      await prefs.remove("attendance_id");

      debugPrint("✅ Offline punch-out synced");
// ❌ REMOVE attendance_id
      await prefs.remove('attendance_id');

      // 🛑 STOP SERVICE
      FlutterBackgroundService().invoke('stopService');
      if (mounted) {
        Get.offAll(() => LoginScreen());
      }
    }
  }

  /* ---------------- AUTO PUNCH OUT ---------------- */

  Future<void> autoPunchOutInternet(String reason) async {
    final prefs = await SharedPreferences.getInstance();
    final savedAttendanceId = prefs.getString('attendance_id');
    if (savedAttendanceId == null) return;

    final internet = await hasRealInternet();

    if (internet) {
      try {
        await http.post(
          Uri.parse(
            "https://fms.bizipac.com/apinew/attendance/attendance_punch_out.php"
                "?attendance_id=$savedAttendanceId",
          ),
          body: {
            "action": "punch_out",
            "status": "Present",
            "uid": widget.userModel.uid,
            "cid": widget.userModel.cid,
            "lat": currentPosition?.latitude.toString() ?? "0",
            "lng": currentPosition?.longitude.toString() ?? "0",
            "remark": reason,
            "image": "NA",
          },
        );
        // ❌ REMOVE attendance_id
        await prefs.remove('attendance_id');

        // 🛑 STOP SERVICE
        FlutterBackgroundService().invoke('stopService');
      } catch (_) {
        await saveLocalPunchOut(reason);
      }
    } else {
      await saveLocalPunchOut(reason);
    }

    await stopLocationTracking();

    if (mounted) {
      setState(() => attendanceId = null);
    }
  }

  /* ---------------- ATTENDANCE ID ---------------- */

  Future<void> loadAttendanceId() async {
    final prefs = await SharedPreferences.getInstance();
    attendanceId = prefs.getString('attendance_id');
    if (mounted) setState(() {});
  }
  /* ---------------- LOGOUT ---------------- */

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
    );
  }

  /* ---------------- ATTENDANCE ID ---------------- */
  //
  // Future<void> loadAttendanceId() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     attendanceId = prefs.getString('attendance_id');
  //   });
  // }

  /* ---------------- LOCATION ---------------- */

  Future<Position> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw 'Location service disabled';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission permanently denied';
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> loadLiveLocation() async {
    try {
      final pos = await getCurrentLocation();
      if (!mounted) return;
      setState(() => currentPosition = pos);
    } catch (e) {
      debugPrint("Location  s error: $e");
    }
  }

  /* ---------------- GPS MONITOR ---------------- */

  void startGpsMonitor() {
    gpsTimer?.cancel();

    gpsTimer = Timer.periodic(
      const Duration(seconds: 10),
          (_) async {
        await  loadAttendanceId();
        await loadLiveLocation(); // update currentPosition
        await checkGpsAndAutoPunchOut();
        await checkDistanceAndAutoPunchOut(); // 🔥 radius check
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      },
    );
  }

  Future<void> checkGpsAndAutoPunchOut() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled && attendanceId != null) {
      await autoPunchOut("GPS Turn Off - Auto Punch");
      Get.offAll(()=>LoginScreen());
    }
  }

  /* ---------------- AUTO PUNCH OUT ---------------- */

  Future<void> autoPunchOut(String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAttendanceId = prefs.getString('attendance_id');
      if (savedAttendanceId == null) return;

      await http.post(
        Uri.parse(
          "https://fms.bizipac.com/apinew/attendance/attendance_punch_out.php?attendance_id=$savedAttendanceId",
        ),
        body: {
          "action": "punch_out",
          "status": "Present",
          "uid": widget.userModel.uid,
          "cid": widget.userModel.cid,
          "lat": currentPosition?.latitude.toString() ?? "0",
          "lng": currentPosition?.longitude.toString() ?? "0",
          "remark": reason,
          "image": "NA",
        },
      );
      await stopLocationTracking();
      // ❌ REMOVE attendance_id
      await prefs.remove('attendance_id');

      // 🛑 STOP SERVICE
      FlutterBackgroundService().invoke('stopService');
      await prefs.remove('attendance_id'); // 2️⃣ remove local
      setState(() => attendanceId = null);
      debugPrint("✅ Auto punch out done");
    } catch (e) {
      debugPrint("❌ Auto punch out failed: $e");
    }
  }

  /* ---------------- STOP TRACKING ---------------- */

  Future<void> stopLocationTracking() async {
    gpsTimer?.cancel();
    gpsTimer = null;

    if (attendanceId == null) return;

    try {
      final internet = await hasRealInternet();

      if (internet) {
        await http.post(
          Uri.parse(
            "https://fms.bizipac.com/apinew/attendance/track_location.php",
          ),
          body: {
            "attendance_id": attendanceId!,
            "status": "stop",
          },
        );

        debugPrint("✅ Tracking stopped on server");
      } else {
        debugPrint("📴 Tracking stop saved locally (offline)");
      }
    } catch (e) {
      debugPrint("⚠ Tracking stop failed but ignored");
    }
  }


  /* ---------------- checkDistanceAndAutoPunchOut ---------------- */
  Future<void> checkDistanceAndAutoPunchOut() async {
    if (attendanceId == null) return;

    try {
      // Ensure current location available
      final pos = currentPosition ?? await getCurrentLocation();

      // Branch details from userModel
      final double branchLat = double.parse(widget.userModel.branchLat);
      final double branchLng = double.parse(widget.userModel.branchLong);
      final double allowedRadius =
      double.parse(widget.userModel.branchDistance); // in meters

      // Calculate distance
      final double distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        branchLat,
        branchLng,
      );

      debugPrint("📍 Distance from Kiosk : ${distance.toStringAsFixed(2)} m");

      // If user is OUTSIDE radius
      if (distance > allowedRadius) {

        await autoPunchOut(
          "You are outside Kiosk radius (${distance.toStringAsFixed(0)}m)",
        );
        Get.offAll(()=>LoginScreen());
      }
    } catch (e) {
      debugPrint("❌ Distance check error: $e");
    }
  }

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
         CircleAvatar(
           child: Image.network(widget.userModel.userImg),
         ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            employeeInfoCard(),
            const SizedBox(height: 20),
            Expanded(child: dashboardGrid()),
          ],
        ),
      ),
    );
  }

  /* ---------------- DASHBOARD ---------------- */

  Widget dashboardGrid() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.4,
      children: [
        dashboardBox(
          "Punch In / Out",
          Icons.fingerprint,
              () => Get.to(() => PunchInOutScreen(userModel: widget.userModel)),
        ),
        dashboardBox(
          "My Attendance",
          Icons.event_available,
              () => Get.to(() => AttendanceScreen(
            cid: widget.userModel.cid,
            uid: widget.userModel.uid,
          )),
        ),
        attendanceId==null?SizedBox.shrink():dashboardBox(
          "Client Form",
          Icons.flight,
              () => Get.to(() => AirportFormScreen(userModel: widget.userModel)),
        ),
        attendanceId==null?SizedBox.shrink():dashboardBox(
          "Submitted Form",
          Icons.description,
              () => widget.userModel.departmentName == "Users"
              ? Get.to(() => SubmitFormScreen(userModel: widget.userModel))
              : Get.to(() => GetReportKioskScreen(userModel: widget.userModel)),
        ),
        widget.userModel.departmentName=="Users"?SizedBox.shrink():dashboardBox(
          "User Attendance",
          Icons.event_available,
              () => Get.to(() => OfficeAttendanceScreen(
            officeName: widget.userModel.branchName,
          )),
        ),
        widget.userModel.departmentName=="Users"?SizedBox.shrink():dashboardBox(
          "Client Submitted Form",
          Icons.event_available,
              () => Get.to(() => GetReportKioskScreen(
            userModel: widget.userModel,
          )),
        ),

      ],
    );
  }

  Widget dashboardBox(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  /* ---------------- EMPLOYEE INFO ---------------- */

  Widget employeeInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            infoRow("User ID", widget.userModel.userid),
            infoRow("Name", widget.userModel.fullName),
            infoRow("Branch", widget.userModel.branchName),
            infoRow(
              "Shift",
              "${widget.userModel.shiftStart} - ${widget.userModel.shiftEnd}",
            ),
          ],
        ),
      ),
    );
  }

  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text("$title:")),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
