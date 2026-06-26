import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:joizone/admin/view/add_user_screen.dart';
import 'package:joizone/admin/view/shift_screen.dart';
import 'package:joizone/admin/view/user_attendance_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../controller/attendance_location_controller.dart';
import '../controller/user_controller.dart';
import '../model/user_model.dart';
import '../notification/send_notification_screen.dart';
import 'all_branch_screen.dart';
import 'all_employee_attandance.dart';
import 'all_employee_list.dart';
import 'all_form_report_screen.dart';
import 'assign_holiday_screen.dart';
import 'attendance_location_screen.dart';
import 'branch_screen.dart';
import 'department_screen.dart';
import 'google_map_screen.dart';
import 'holiday_screen.dart';
import 'location_history_screen.dart';
import 'login_screen.dart';
import 'monthly_attendance_screen.dart';
import 'monthly_summary_screen.dart';
import 'upload_remark_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final String cid;
  const AdminHomeScreen({super.key, required this.cid});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
    );
  }
  final UserController controller = UserController();
  bool isLoading = true;
  List<UserModel> users = [];
  UserModel? selectedUser; // 🔹 selected user

  @override
  void initState() {
    super.initState();
    loadUsers();
    fetchAttendance();
    fetchUsers();
    fetchTodayReport();
  }
  //---chart
  String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }


  int maleCount = 0;
  int femaleCount = 0;

  int reportFilled = 0;
  int reportNotFilled = 0;
  List reportList = [];

  int presentCount = 0;
  int absentCount = 0;
  Future<void> fetchAttendance() async {
    try {
      final response = await http.post(
        Uri.parse("http://15.206.209.30/attendance/attedance_chart.php"),
        body: {
          "cid": widget.cid,
          "date": formatDate(DateTime.now()),
        },
      );

      print(response.body);

      final jsonData = jsonDecode(response.body);

      int present = 0;
      int absent = 0;

      if (jsonData['status'] == true &&
          jsonData['data'] != null &&
          jsonData['data'] is List) {

        for (var item in jsonData['data']) {

          String status = item['attendance_status']
              .toString()
              .trim()
              .toUpperCase();

          if (status == "PRESENT") {
            present++;
          } else {
            absent++;
          }
        }
      }

      setState(() {
        presentCount = present;
        absentCount = absent;
      });

    } catch (e) {
      debugPrint("Attendance Error: $e");
    }
  }

  Future<void> fetchUsers() async {
    final response = await http.get(
      Uri.parse("http://15.206.209.30/attendance/get_users.php"),
    );

    final data = jsonDecode(response.body);

    int male = 0;
    int female = 0;

    for (var user in data['data']) {
      if ((user['gender'] ?? "").toString().toLowerCase() == "male") {
        male++;
      } else if ((user['gender'] ?? "").toString().toLowerCase() == "female") {
        female++;
      }
    }

    setState(() {
      maleCount = male;
      femaleCount = female;
    });
  }
  Future<void> fetchTodayReport() async {
    final response = await http.post(
      Uri.parse("http://15.206.209.30/attendance/get_report.php"),
      body: {
        "cid": widget.cid,
        "date": formatDate(DateTime.now()),
      },
    );

    final data = jsonDecode(response.body);

    int filled = 0;
    int notFilled = 0;
    List tempList = [];

    if (data['data'] != null) {
      for (var item in data['data']) {

        // 👉 full list store karo
        tempList.add(item);

        // 👉 existing logic (optional)
        if (item['duplicate_from'] == "yes" || item['duplicate_from'] == "no") {
          filled++;
        } else {
          notFilled++;
        }
      }
    }

    setState(() {
      reportFilled = filled;
      reportNotFilled = notFilled;

      // 🔥 THIS IS IMPORTANT
      reportList = tempList;
    });
  }

  Widget attendanceChart() {
    int total = presentCount + absentCount;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              "Today's Attendance",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 200,
              child: total == 0
                  ? const Center(child: Text("No Data"))
                  : PieChart(
                PieChartData(
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: presentCount.toDouble(),
                      color: Colors.green,
                      title: "$presentCount",
                      radius: 70,
                    ),
                    PieChartSectionData(
                      value: absentCount.toDouble(),
                      color: Colors.red,
                      title: "$absentCount",
                      radius: 70,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  "🟢 Present: $presentCount",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "🔴 Absent: $absentCount",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              "Total Users : $total",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget userChart() {
    int total = maleCount + femaleCount;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              "",
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 160,
              child: total == 0
                  ? const Center(
                child: Text("No Data"),
              )
                  : PieChart(
                PieChartData(
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  sections: [
                    PieChartSectionData(
                      value: maleCount.toDouble(),
                      color: Colors.blue,
                      radius: 70,
                      title:
                      "${((maleCount / total) * 100).toStringAsFixed(0)}%",
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: femaleCount.toDouble(),
                      color: Colors.pink,
                      radius: 70,
                      title:
                      "${((femaleCount / total) * 100).toStringAsFixed(0)}%",
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Male\n$maleCount",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      color: Colors.pink,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Female\n$femaleCount",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              "Total Employees : $total",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Map<String, int> getKioskCounts(List reports) {
    Map<String, int> kioskCount = {};

    for (var item in reports) {
      String kiosk = item['kiosk_name'] ?? 'Unknown';

      if (kioskCount.containsKey(kiosk)) {
        kioskCount[kiosk] = kioskCount[kiosk]! + 1;
      } else {
        kioskCount[kiosk] = 1;
      }
    }

    return kioskCount;
  }

  List<PieChartSectionData> getSections(
      Map<String, int> kioskData,
      int total,
      ) {
    return kioskData.entries.map((entry) {
      return PieChartSectionData(
        color: getKioskColor(entry.key),
        value: entry.value.toDouble(),
        radius: 70,
        title:
        "${((entry.value / total) * 100).toStringAsFixed(0)}%",
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }).toList();
  }
  Color getKioskColor(String kiosk) {
    switch (kiosk.toUpperCase()) {
      case "AMDT1-LB":
        return Colors.blue;
      case "LKOT1-LG":
        return Colors.orange;
      case "BOMT2-LG":
        return Colors.purple;
      case "JAIT1-LG":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  Widget reportChart(List reports) {
    final kioskData = getKioskCounts(reports);
    final total = kioskData.values.fold(0, (sum, val) => sum + val);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              "Kiosk Wise Reports",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 220,
              child: total == 0
                  ? const Center(
                child: Text("No Data"),
              )
                  : PieChart(
                PieChartData(
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  sections: getSections(kioskData, total),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Wrap(
              spacing: 16,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: kioskData.entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: getKioskColor(entry.key),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${entry.key} (${entry.value})",
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            Text(
              "Total Reports : $total",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  //----
  Future<void> loadUsers() async {
    final fetchedUsers = await controller.fetchUsers();
    setState(() {
      users = fetchedUsers;
      isLoading = false;
    });
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(
          color: Colors.white
        ),
        title: const Text("Dashboard",style: TextStyle(color: Colors.white,fontSize: 18,),),

        actions: [
          ElevatedButton(onPressed: (){
            Get.to(()=>AddBranchScreen(cid:widget.cid));
          },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5), // Perfect square corners
                ),
              ),child: Text("Kiosk Master")),
          SizedBox(
            width: 10,
          ),
          ElevatedButton(onPressed: (){
            Get.to(()=>ShiftScreen(cid:widget.cid));
          }, style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5), // Perfect square corners
            ),
          ),child: Text("Shift Master")),
          SizedBox(
            width: 10,
          ),
          ElevatedButton(onPressed: (){
            Get.to(()=>DepartmentScreen(cid: widget.cid));
          },style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5), // Perfect square corners
            ),
          ), child: Text("Designation")),
          IconButton(
            icon: const Icon(Icons.refresh_outlined,color: Colors.white,),
            onPressed: () async {
              try {
                final res = await http.get(
                  Uri.parse(
                    'http://15.206.209.30/attendance/mark_absent.php',
                  ),
                );

                if (res.statusCode == 200) {
                  final data = jsonDecode(res.body);
                  print(data);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(data['message'] ?? 'Success'),
                      backgroundColor: data['status'] == true
                          ? Colors.green
                          : Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Server error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                print(e.toString());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),



        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Company ID: ${widget.cid}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  IconButton(onPressed: (){
                    fetchAttendance();
                    fetchTodayReport();
                  }, icon: Icon(Icons.refresh_outlined))
                ],
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: attendanceChart()),
                      SizedBox(width: 10),
                      Expanded(child: userChart()),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: reportChart(reportList)),
                      SizedBox(width: 10),
                      Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // 🔵 HEADER
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue, // Change drawer header background color
              ),
              accountName: const Text("Joizone"),
              accountEmail: const Text("joizone@gmail.com"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40),
              ),
            ),
            // 🟢 PROFILE
            ListTile(
              leading: Icon(Icons.person),
              title: Text("User Profile"),
              onTap: () {
                Get.back();
                Get.to(() => UsersTableScreen()); // change to ProfileScreen if you have
              },
            ),

            // 🟢 ATTENDANCE
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text("Daily Attendance"),
              onTap: () {
                Get.back();
                Get.to(() => AllEmployeeAttendanceScreen(cid: widget.cid));
              },
            ),
            // 🟢 LOCATION CAPTURING
            ListTile(
              leading: Icon(Icons.file_copy),
              title: Text("Form Details"),
              onTap: () {
                Get.back();
                Get.to(()=>AllFormReportScreen());
              },
            ),
            // ListTile(
            //   leading: Icon(Icons.file_copy),
            //   title: Text("Upload Remark"),
            //   onTap: () {
            //     Get.back();
            //     Get.to(()=>UploadRemarkScreen());
            //   },
            // ),

            // 🟢 LOCATION REPORT
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text("Location History"),
              onTap: () {
                Get.back();
                Get.to(()=>LocationHistoryScreen(cid: widget.cid,));
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text("Send Notifications"),
              onTap: () {
                Get.back();
                Get.to(()=>SendNotificationScreen(cid: widget.cid,));
              },
            ),
            const Divider(),

            // 🔴 LOGOUT
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text("Logout"),
              onTap: () => logout(context),
            ),
          ],
        ),
      ),
    );
  }


}
