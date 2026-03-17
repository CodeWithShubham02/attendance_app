import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:joizone/admin/model/user_model.dart';
import 'package:joizone/user/controller/user_login_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../user/view/employee_screen.dart';
import 'admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = 'user';
  final UserController userController=UserController();
  final TextEditingController userIdCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  final TextEditingController userId = TextEditingController();
  final TextEditingController userPassword = TextEditingController();
  bool isLoading = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
      checkLogin();
  }
  Future<void> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();

    String? uid = prefs.getString('uid');
    print("--------------check in-----------------");
    print(uid);
    String? userData = prefs.getString('user_model');

    if (uid != null && uid.isNotEmpty && userData != null && userData.isNotEmpty) {
      try {

        Map<String, dynamic> json = jsonDecode(userData);
        UserModel userModel = UserModel.fromJson(json);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmployeeHomeScreen(userModel: userModel),
          ),
        );

      } catch (e) {
        print("User model decode error: $e");
      }
    }
  }
  void login() async {
    if (userId.text.isEmpty || userPassword.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Enter all fields")));
      return;
    }

    setState(() => isLoading = true);

    final result = await userController.loginUser(
      userid: userId.text.trim(),
      password: userPassword.text.trim(),
    );

    setState(() => isLoading = false);

    if (result['status'] == true) {
      // Login successful

      final data = result['data'];
      // Save UID in SharedPreferences
      print("------data--------------------");
      print(data);
      print("--------------------------");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Welcome ${data['userid']}")),
      );

      UserModel userModel=UserModel(
          uid: data['uid'],
          cid: data['cid'],
          userid: data['userid'],
          password: data['userPassword'],
          userToken: data['user_token'],
          userImg: data['userImg'],
          imeiNo: data['imei_no'],
          fullName: data['userName'],
          userEmail: data['userEmail'],
          userPhone: data['userPhone'],
          gender: data['userGender'],
          fullAddress: data['full_address'],
          branchId: data['storeId'],
          branchName: data['storeName'],
          branchDistance: data['storeDistance'],
          branchLat: data['storeLat'],
          branchLong: data['storeLong'],
          departmentId: data['department_id'],
          departmentName: data['department_name'],
          shiftId: data['shift_id'],
          shiftStart: data['shift_start'],
          shiftEnd: data['shift_end'],
          dateOfJoining: data['date_of_joining'],
          status: data['status'],
          role: data['role'],
          createdAt: data['createdAt'],
          updatedAt: data['updatedAt'],);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('uid', data['uid'].toString());
      await prefs.setString('branchLat',userModel.branchLat);
      await prefs.setString('branchLong',userModel.branchLong);
      await prefs.setString('role', 'user');
      final userJson = jsonEncode(userModel.toJson());
      print("------------------------------");
      print(userJson);
      print(userModel);
      print("------------------------------");
      await prefs.setString('user_model', userJson);
      // Navigate to your home screen
       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => EmployeeHomeScreen(userModel: userModel,)));
    } else {
      // Login failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Login failed")),
      );
    }
  }
  Future<void> loginAdmin() async {
    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse("https://fms.bizipac.com/apinew/attendance/login.php"), // localhost fix
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
              TextField(
                controller: userIdCtrl,
                decoration: InputDecoration(
                  labelText: "Admin User ID",
                  hint: Text("Enter the admin id"),
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: passwordCtrl,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  hint: Text("Enter the password"),
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
                  borderRadius: BorderRadius.circular(12),
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
                  borderRadius: BorderRadius.circular(12),
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
