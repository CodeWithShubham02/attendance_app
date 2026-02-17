import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:joizone/admin/view/add_user_screen.dart';
import 'package:joizone/admin/view/shift_screen.dart';
import 'package:joizone/admin/view/user_attendance_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../controller/attendance_location_controller.dart';
import 'all_branch_screen.dart';
import 'all_employee_attandance.dart';
import 'all_employee_list.dart';
import 'all_form_report_screen.dart';
import 'assign_holiday_screen.dart';
import 'attendance_location_screen.dart';
import 'branch_screen.dart';
import 'department_screen.dart';
import 'holiday_screen.dart';
import 'login_screen.dart';
import 'monthly_attendance_screen.dart';
import 'monthly_summary_screen.dart';

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

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
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
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () {
              final parentContext = context;

              showDialog(
                context: context,
                builder: (dialogContext) {
                  TextEditingController attendanceController =
                  TextEditingController();

                  return AlertDialog(
                    title: const Text("Track Users"),
                    content: TextField(
                      controller: attendanceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: "Enter the userid",
                        border: OutlineInputBorder()
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          String attendanceId =
                          attendanceController.text.trim();
                          if (attendanceId.isEmpty) return;
                          Navigator.pop(dialogContext); // close dialog
                          final data =
                          await AttendanceLocationService
                              .fetchByAttendanceId(attendanceId);

                          if (!parentContext.mounted) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttendanceRouteMapScreen(
                                data: data, // full list
                              ),
                            ),
                          );

                        },
                        child: const Text("Search"),
                      ),
                    ],
                  );
                },
              );
            },
          )

        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Company ID: ${widget.cid}",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.8,
                children: [
                  _dashboardBox(
                    title: "Create Kiosk",
                    icon: Icons.account_tree,
                    onTap: () {
                      Get.to(()=>AddBranchScreen(cid:widget.cid));
                    },
                  ),
                  _dashboardBox(
                    title: "Create Shift",
                    icon: Icons.schedule,
                    onTap: () {
                      Get.to(()=>ShiftScreen(cid:widget.cid));
                    },
                  ),
                  _dashboardBox(
                    title: "Create Users",
                    icon: Icons.person_add,
                    onTap: () {
                     Get.to(()=>AddUserScreen());
                    },
                  ),
                  _dashboardBox(
                    title: "All Users",
                    icon: Icons.people,
                    onTap: () {
                      Get.to(()=>UsersTableScreen ());
                    },
                  ),
                  _dashboardBox(
                    title: "Daily Attendance",
                    icon: Icons.fact_check,
                    onTap: () {
                      Get.to(()=>AllEmployeeAttendanceScreen(cid:widget.cid));
                    },
                  ),
                  _dashboardBox(
                    title: "All Kiosk",
                    icon: Icons.fact_check,
                    onTap: () {
                      Get.to(()=>BranchListScreen(cid: widget.cid));
                    },
                  ),
                  _dashboardBox(
                    title: "Create Depart..",
                    icon: Icons.fact_check,
                    onTap: () {
                      Get.to(()=>DepartmentScreen(cid: widget.cid));
                    },
                  ),
                  _dashboardBox(
                    title: "Monthly Atten..",
                    icon: Icons.fact_check,
                    onTap: () {
                      Get.to(()=>MonthlyAttendanceScreen(cid:"1"));
                    },
                  ),
                  _dashboardBox(
                    title: "Form Data",
                    icon: Icons.data_exploration_outlined,
                    onTap: () {
                      Get.to(()=>AllFormReportScreen());
                    },
                  ),
                  _dashboardBox(
                    title: "Monthly Summary",
                    icon: Icons.calendar_month,
                    onTap: () {
                      Get.to(()=>AttendanceSummaryScreen());
                    },
                  ),
                  // _dashboardBox(
                  //   title: "Holiday",
                  //   icon: Icons.weekend_outlined,
                  //   onTap: () {
                  //     Get.to(()=>HolidayScreen());
                  //   },
                  // ),
                  _dashboardBox(
                    title: "User Holiday",
                    icon: Icons.weekend_outlined,
                    onTap: () {
                      Get.to(()=>AssignHolidayScreen());
                    },
                  ),
                  _dashboardBox(
                    title: "User Attendance",
                    icon: Icons.person,
                    onTap: () {
                      Get.to(()=>UserAttendanceDetailScreen());
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardBox({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
