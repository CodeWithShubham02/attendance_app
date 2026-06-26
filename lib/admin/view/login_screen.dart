import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:joizone/admin/model/user_model.dart';
import 'package:joizone/services/notification_service.dart';
import 'package:joizone/user/controller/user_login_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../user/view/employee_screen.dart';
import 'admin_home_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';


class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = 'user';
  final UserController userController=UserController();
  final TextEditingController userIdCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
NotificationService notificationService=NotificationService();
  final TextEditingController userId = TextEditingController();
  final TextEditingController userPassword = TextEditingController();
  bool isLoading = false;
  late GoogleSignIn googleSignIn;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkLogin1();
    notificationService.requestNotificationPermission();
  }

  void login() async {
    try {
      if (userId.text.isEmpty || userPassword.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter all fields")),
        );
        return;
      }

      setState(() => isLoading = true);

      final result = await userController.loginUser(
        userid: userId.text.trim(),
        password: userPassword.text.trim(),
      );

      setState(() => isLoading = false);

      if (result['status'] == true) {
        final data = result['data'];

        print("------data--------------------");
        print(data);
        print("-----------------------------");

        UserModel userModel = UserModel(
          uid: data['uid']?.toString() ?? '',
          cid: data['cid']?.toString() ?? '',
          userid: data['userid']?.toString() ?? '',
          password: data['userPassword']?.toString() ?? '',
          userToken: data['user_token']?.toString() ?? '',
          userImg: data['userImg']?.toString() ?? '',
          imeiNo: data['imei_no']?.toString() ?? '',
          fullName: data['userName']?.toString() ?? '',
          userEmail: data['userEmail']?.toString() ?? '',
          userPhone: data['userPhone']?.toString() ?? '',
          gender: data['userGender']?.toString() ?? '',
          fullAddress: data['full_address']?.toString() ?? '',
          branchId: data['storeId']?.toString() ?? '',
          branchName: data['storeName']?.toString() ?? '',
          branchDistance: data['storeDistance']?.toString() ?? '',
          branchLat: data['storeLat']?.toString() ?? '',
          branchLong: data['storeLong']?.toString() ?? '',
          departmentId: data['department_id']?.toString() ?? '',
          departmentName: data['department_name']?.toString() ?? '',
          shiftId: data['shift_id']?.toString() ?? '',
          shiftStart: data['shift_start']?.toString() ?? '',
          shiftEnd: data['shift_end']?.toString() ?? '',
          dateOfJoining: data['date_of_joining']?.toString() ?? '',
          lastworkingdate: data['last_working_date']?.toString() ?? '',
          status: data['status']?.toString() ?? '',
          role: data['role']?.toString() ?? '',
          createdAt: data['createdAt']?.toString() ?? '',
          updatedAt: data['updatedAt']?.toString() ?? '',
          lastName: data['lastName']?.toString() ?? '',
          middleName: data['middleName']?.toString() ?? '',
          cityName: data['cityName']?.toString() ?? '',
          pinCode: data['pinCode']?.toString() ?? '',
          districtName: data['districtName']?.toString() ?? '',
          reportingPosition: data['reportingPosition']?.toString() ?? '',
        );

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('uid', userModel.uid);
        await prefs.setString('branchLat', userModel.branchLat);
        await prefs.setString('branchLong', userModel.branchLong);
        await prefs.setString('role', userModel.role);
        await prefs.setString('userimg', userModel.userImg);
        await prefs.setString(
          'user_model',
          jsonEncode(userModel.toJson()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Welcome ${userModel.userid}"),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmployeeHomeScreen(
              userModel: userModel,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Login failed"),
          ),
        );
      }
    } catch (e, stackTrace) {
      setState(() => isLoading = false);

      print("LOGIN ERROR:");
      print(e);
      print(stackTrace);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user_model');

    if (userString != null) {
      final json = jsonDecode(userString);
      return UserModel.fromJson(json);
    }
    return null;
  }
  Future<bool> isAttendanceActive(String attendanceId) async {
    try {
      final response = await http.post(
        Uri.parse("http://15.206.209.30/attendance/check_status.php"),
        body: {
          "attendance_id": attendanceId,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        /// Expected response:
        /// { "status": "active" } OR { "status": "closed" }

        return data["attendance_status"] == "active";
      }
    } catch (e) {
      print("Error checking attendance: $e");
    }

    return false;
  }
  Future<void> checkLogin1() async {
    final prefs = await SharedPreferences.getInstance();

    String? attendanceId = prefs.getString('attendance_id');

    /// 🔥 Get cached user
    UserModel? userModel = await getSavedUser();

    print("Attendance ID: $attendanceId");
    print("UserModel: $userModel");

    /// ❌ If no user → stay on login (DO NOTHING)
    if (userModel == null) return;

    /// ✅ If attendance active → Dashboard
    if (attendanceId != null && attendanceId.isNotEmpty) {
      bool isActive = await isAttendanceActive(attendanceId);
      print("---------------");
      print(isActive);
      print("---------------");
      if (!isActive) {
        /// 🔥 REMOVE OLD attendance_id
        await prefs.remove('attendance_id');

        print("❌ Old attendance removed");

        return; // stay on login
      }
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmployeeHomeScreen(userModel: userModel),
        ),
      );
    }

    /// ❌ If attendance not found → stay on login
  }

  // Future<void> checkLogin() async {
  //   final prefs = await SharedPreferences.getInstance();
  //
  //   String? uid = prefs.getString('uid');
  //   String? attendanceId =await  prefs.getString('attendance_id');
  //   String? userData =prefs.getString('user_model');
  //
  //   print("UID: $uid");
  //   print("Attendance ID: $attendanceId");
  //   print("UserData: $userData");
  //
  //   /// ✅ CASE 1: VALID LOGIN
  //   if (attendanceId != null &&
  //       attendanceId.isNotEmpty &&
  //       userData != null &&
  //       userData.isNotEmpty) {
  //     try {
  //       Map<String, dynamic> json = jsonDecode(userData);
  //       UserModel userModel = UserModel.fromJson(json);
  //
  //       if (!mounted) return;
  //
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(
  //           builder: (_) => EmployeeHomeScreen(userModel: userModel),
  //         ),
  //       );
  //       return;
  //
  //     } catch (e) {
  //       print("User model decode error: $e");
  //     }
  //   }
  //
  //   /// ❌ CASE 2: INVALID / LOGOUT → GO TO LOGIN
  //   if (!mounted) return;
  //
  //   return;
  // }



  Future<void> loginAdmin() async {

    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse("http://15.206.209.30/attendance/login.php"), // localhost fix
      body: {
        "user_id": userIdCtrl.text,
        "password": passwordCtrl.text,
      },
    );
    print(response);
    final data = json.decode(response.body);
    print(data);
    setState(() => isLoading = false);
    final cid=data['data']['cid'].toString();
    print("-----------cid : $cid");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cid', data['data']['cid'].toString());
    await prefs.setString('role', 'admin');

    if (data['status'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminHomeScreen(cid: data['data']['cid'].toString(),)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'])),
      );
    }
  }
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.blue,
          centerTitle: true,
          title: Text("Login",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: 20,),
            /// ROLE DROPDOWN
            DropdownButtonFormField<String>(
              value: selectedRole,
              items: const [
                DropdownMenuItem(value: "user", child: Text("User")),
                DropdownMenuItem(value: "admin", child: Text("Admin")),
              ],
              onChanged: (value) {
                setState(() => selectedRole = value!);
              },
              decoration: InputDecoration(
                labelText: "Login As",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            /// ADMIN FIELDS
            if (selectedRole == 'admin') ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: userIdCtrl,
                      decoration: InputDecoration(
                        labelText: "Admin User ID",
                        hintText: "Enter the admin id",
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12), // spacing between fields

                  Expanded(
                    child: TextField(
                      controller: passwordCtrl,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        labelText: "Password",
                        hintText: "Enter the password",
                        prefixIcon: const Icon(Icons.lock),

                        // 🔹 Show / Hide Icon
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),

                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if(selectedRole=='user')...[
              TextField(
                controller: userId,
                decoration: InputDecoration(
                  labelText: "User ID",
                  hint: Text("Enter the user id"),
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: userPassword,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: "Password",
                  // 🔹 Prefix Icon
                  hint: Text("Enter the password"),
                  prefixIcon: const Icon(Icons.lock),

                  // 🔹 Show / Hide Icon
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 24),

            /// LOGIN BUTTON
            selectedRole=='admin'?ElevatedButton(
              onPressed: isLoading ? null : loginAdmin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 5,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Login"),
            ):ElevatedButton(
              onPressed: isLoading ? null : login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 5,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}