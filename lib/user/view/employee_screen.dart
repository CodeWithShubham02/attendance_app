import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../admin/model/user_model.dart';
import '../../admin/view/login_screen.dart';
import '../controller/start_break_controller.dart';
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
    _timer?.cancel();
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
      await prefs.remove('uid');
      await prefs.remove('cid');

      // 🛑 STOP SERVICE
      FlutterBackgroundService().invoke('stopService');
      logout(context);
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
        await prefs.remove('cid');
        await prefs.remove('uid');

        // 🛑 STOP SERVICE
        FlutterBackgroundService().invoke('stopService');
        logout(context);
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
  /*----------------Logout------------------*/
  // Future<void> logout(BuildContext context) async {
  //   final prefs = await SharedPreferences.getInstance();
  //
  //   await prefs.clear();
  //
  //   Navigator.pushAndRemoveUntil(
  //     context,
  //     MaterialPageRoute(builder: (_) => LoginScreen()),
  //         (route) => false,
  //   );
  // }
  /*------------------------------------------*/
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
      const Duration(seconds: 60),
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
      await prefs.remove('cid'); // 2️⃣ remove local
      await prefs.remove('uid'); // 2️⃣ remove local
      setState(() => attendanceId = null);
      debugPrint("✅ Auto punch out done");
      logout(context);
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
          "You are outside Kiosk radius",
        );
        // await autoPunchOut(
        //   "You are outside Kiosk radius (${distance.toStringAsFixed(0)}m)",
        // );
        Get.offAll(()=>LoginScreen());
      }
    } catch (e) {
      debugPrint("❌ Distance check error: $e");
    }
  }

  /* ---------------- UI ---------------- */
  bool isOnline = false;
  Timer? _timer;
  int _seconds = 0;
  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (breakStartTime != null) {
        final diff = DateTime.now().difference(breakStartTime!);

        setState(() {
          _seconds = diff.inSeconds;
        });
      }
    });
  }


  void _startBreakDialog() {

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {

        return StatefulBuilder(
          builder: (context, setDialogState) {

            // Start timer when dialog builds
            _timer?.cancel();
            _timer = Timer.periodic(const Duration(seconds: 1), (_) {
              if (breakStartTime != null) {
                final diff = DateTime.now().difference(breakStartTime!);

                setDialogState(() {   // 👈 IMPORTANT
                  _seconds = diff.inSeconds;
                });
              }
            });

            return AlertDialog(
              title: const Text("Break Started"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.watch_later, size: 50),
                  const SizedBox(height: 10),
                  Text(
                    _formatTime(_seconds),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {

                    _timer?.cancel();   // 👈 stop timer first

                    try {

                      var response = await endBreakApi(
                        attendanceId: attendanceId!,
                        uid: widget.userModel.uid,
                      );

                      if (response['status'] == true) {

                        Navigator.pop(context);

                        setState(() {
                          isOnline = false;
                          breakStartTime = null;
                          _seconds = 0;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Break Ended\nDuration: ${response['break_minutes']} min",
                            ),
                          ),
                        );

                      }

                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("End Break API Error"),
                        ),
                      );
                    }
                  },
                  child: const Text("End Break"),
                ),
              ],
            );
          },
        );
      },
    );
  }


  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    return "${hours.toString().padLeft(2, '0')}:"
        "${minutes.toString().padLeft(2, '0')}:"
        "${secs.toString().padLeft(2, '0')}";
  }
  DateTime? breakStartTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Dashboard",style: TextStyle(color: Colors.white,fontSize: 22,fontFamily: 'impact'),),
        actions: [
          attendanceId == null
          ? SizedBox.shrink()
          : Row(
    children: [
      Switch(
        value: isOnline,
        activeColor: Colors.green,
        onChanged: (value) async {
          setState(() {
            isOnline = value;
          });

          if (isOnline) {
            try {
              var response = await startBreakApi(
                attendanceId: attendanceId!,
                uid: widget.userModel.uid,
              );

              if (response['status'] == true) {

                breakStartTime =
                    DateTime.parse(response['break_start_time']);

                _startTimer();       // ✅ only this timer
                _startBreakDialog(); // ✅ just open dialog

              } else {
                setState(() => isOnline = false);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(response['message'])),
                );
              }
            } catch (e) {
              setState(() => isOnline = false);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("API Error")),
              );
            }
          }
        },
      )
    ],
    ),
    CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade200,
            child: widget.userModel.userImg != null &&
                widget.userModel.userImg!.isNotEmpty
                ? ClipOval(
              child: Image.network(
                widget.userModel.userImg!,
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.grey,
                  );
                },
              ),
            )
                : const Icon(
              Icons.person,
              size: 20,
              color: Colors.grey,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout,color: Colors.white,),
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
        (attendanceId == null || widget.userModel.departmentName == "Team Leader")
            ? SizedBox.shrink()
            : dashboardBox(
          "Client Form",
          Icons.flight,
              () => Get.to(() => AirportFormScreen(userModel: widget.userModel)),
        ),

        (attendanceId == null || widget.userModel.departmentName == "Team Leader")
            ? SizedBox.shrink()
            : dashboardBox(
          "Submitted Form",
          Icons.description,
              () => widget.userModel.departmentName == "Users"
              ? Get.to(() => SubmitFormScreen(userModel: widget.userModel))
              : Get.to(() => GetReportKioskScreen(userModel: widget.userModel)),
        ),
        widget.userModel.departmentName == "Users"
            ? SizedBox.shrink()
            : dashboardBox(
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

  Widget dashboardBox(
      String title,
      IconData icon,
      VoidCallback onTap,
      ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Colors.blue, // 🔥 Border color
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 10,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 30,
                color: Colors.blue,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  /* ---------------- EMPLOYEE INFO ---------------- */

  Widget employeeInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Table(
          columnWidths: const {
            0: IntrinsicColumnWidth(),
            1: FlexColumnWidth(),
          },
          border: TableBorder.all(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
          children: [
            tableRow("User ID", widget.userModel.userid),
            tableRow("Name", widget.userModel.fullName),
            tableRow("Branch", widget.userModel.branchName),
            tableRow(
              "Shift",
              "${convertTo12Hour(widget.userModel.shiftStart)} - ${convertTo12Hour(widget.userModel.shiftEnd)}",
            ),
          ],
        ),
      ),
    );
  }
  String convertTo12Hour(String? time) {
    if (time == null || time.trim().isEmpty) {
      return "--";
    }

    try {
      DateTime parsedTime = DateFormat("HH:mm:ss").parse(time);
      return DateFormat("hh:mm a").format(parsedTime);
    } catch (e) {
      return "--";
    }
  }

  TableRow tableRow(String title, String? value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            value ?? "-",
            style: const TextStyle(
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

}
