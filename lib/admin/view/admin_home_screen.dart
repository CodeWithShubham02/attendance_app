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
  int presentCount = 0;
  int absentCount = 0;

  int maleCount = 0;
  int femaleCount = 0;

  int reportFilled = 0;
  int reportNotFilled = 0;
  List reportList = [];

  Future<void> fetchAttendance() async {
    final response = await http.post(
      Uri.parse("https://fms.bizipac.com/apinew/attendance/fetch_attendance_by_date.php"),
      body: {
        "cid": widget.cid,
        "date": formatDate(DateTime.now()), // 🔥 dynamic date
      },
    );

    final data = jsonDecode(response.body);

    int present = 0;
    int absent = 0;

    // 🔥 handle list response (most APIs return list)
    if (data['data'] != null) {
      for (var item in data['data']) {
        if (item['status'] == "Present") {
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
  }
  Future<void> fetchUsers() async {
    final response = await http.get(
      Uri.parse("https://fms.bizipac.com/apinew/attendance/get_users.php"),
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
      Uri.parse("https://fms.bizipac.com/apinew/attendance/get_report.php"),
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
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Today's Attendance"),
          ),
          SizedBox(
            height: 180,
            child: total == 0
                ? const Center(child: Text("No Data"))
                : PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    color: Colors.red,
                    // value: presentCount.toDouble(),
                    // title:
                    // "Absent\n${((presentCount / total) * 100).toStringAsFixed(1)}%",
                  ),
                  PieChartSectionData(
                    //value: absentCount.toDouble(),
                     color: Colors.green,
                    // title:
                    // "Present\n${((absentCount / total) * 100).toStringAsFixed(1)}%",
                  ),
                ],
              ),
            ),
          ),
          Text("Total Today Present Users : $total"),
        ],
      ),
    );
  }
  Widget userChart() {
    int total = maleCount + femaleCount;

    return Card(
      elevation: 4,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Employee Ratio"),
          ),
          SizedBox(
            height: 180,
            child: total == 0
                ? const Center(child: Text("No Data"))
                : PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    color: Colors.blue,
                    value: maleCount.toDouble(),
                    title:
                    "Male\n${((maleCount / total) * 100).toStringAsFixed(1)}%",
                  ),
                  PieChartSectionData(
                    color: Colors.pink,
                    value: femaleCount.toDouble(),
                    title:
                    "Female\n${((femaleCount / total) * 100).toStringAsFixed(1)}%",
                  ),
                ],
              ),
            ),
          ),
          Text("Total Users: $total"),
        ],
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
  List<PieChartSectionData> getSections(Map<String, int> data) {
    int total = data.values.fold(0, (sum, val) => sum + val);

    List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    int i = 0;

    return data.entries.map((entry) {
      final percent = (entry.value / total) * 100;

      final section = PieChartSectionData(
        color: colors[i % colors.length],
        value: entry.value.toDouble(),
        title: "${entry.key}\n${entry.value}",
        radius: 60,
        titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
      );

      i++;
      return section;
    }).toList();
  }
  Widget reportChart(List reports) {
    final kioskData = getKioskCounts(reports);
    final total = kioskData.values.fold(0, (sum, val) => sum + val);

    return Card(
      elevation: 4,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Kiosk Wise Reports"),
          ),
          SizedBox(
            height: 220,
            child: total == 0
                ? const Center(child: Text("No Data"))
                : PieChart(
              PieChartData(
                sections: getSections(kioskData),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          Text("Total Today Reports: $total"),
        ],
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
          }, child: Text("Kiosk Master")),
          SizedBox(
            width: 10,
          ),
          ElevatedButton(onPressed: (){
            Get.to(()=>ShiftScreen(cid:widget.cid));
          }, child: Text("Shift Master")),
          SizedBox(
            width: 10,
          ),
          ElevatedButton(onPressed: (){
            Get.to(()=>DepartmentScreen(cid: widget.cid));
          }, child: Text("Designation")),
          IconButton(
            icon: const Icon(Icons.refresh_outlined,color: Colors.white,),
            onPressed: () async {
              try {
                final res = await http.get(
                  Uri.parse(
                    'https://fms.bizipac.com/apinew/attendance/mark_absent.php',
                  ),
                );

                if (res.statusCode == 200) {
                  final data = jsonDecode(res.body);

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
      body: Padding(
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [

            // 🔵 HEADER
            UserAccountsDrawerHeader(
              accountName: Text("Joizone"),
              accountEmail: Text("joizone@gmail.com "),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40),
              ),
            ),

            // 🟢 PROFILE
            ListTile(
              leading: Icon(Icons.person),
              title: Text("Profile"),
              onTap: () {
                Get.back();
                Get.to(() => UsersTableScreen()); // change to ProfileScreen if you have
              },
            ),

            // 🟢 ATTENDANCE
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text("Attendance"),
              onTap: () {
                Get.back();
                Get.to(() => AllEmployeeAttendanceScreen(cid: widget.cid));
              },
            ),
            // 🟢 LOCATION CAPTURING
            ListTile(
              leading: Icon(Icons.file_copy),
              title: Text("Form"),
              onTap: () {
                Get.back();
                Get.to(()=>AllFormReportScreen());
              },
            ),
            ListTile(
              leading: Icon(Icons.file_copy),
              title: Text("Upload Remark"),
              onTap: () {
                Get.back();
                Get.to(()=>UploadRemarkScreen());
              },
            ),

            // 🟢 LOCATION REPORT
            ListTile(
              leading: Icon(Icons.map),
              title: Text("Real Time Location"),
              onTap: () {
                Get.back();
                Get.to(()=>LocationHistoryScreen(cid: widget.cid,));
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
