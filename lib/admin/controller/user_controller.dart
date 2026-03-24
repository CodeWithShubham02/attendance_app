import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/js.dart';

import '../model/user_model.dart';

class UserController {
  // ✅ Change URL based on platform
  final String baseUrl = "https://fms.bizipac.com/apinew/attendance";
  // Android Emulator → http://10.0.2.2/joizone
  // Real device → http://YOUR_PC_IP/joizone

  Future<bool> createUser({
    required String cid,
    required String userid,
    required String password,
    required String userToken,
    required String userImg,
    required String fullName,
    required String userEmail,
    required String userPhone,
    required String gender,
    required String fullAddress,
    required String branchId,
    required String branchName,
    required String branchDistance,
    required String branchLat,
    required String branchLong,
    required String departmentId,
    required String departmentName,
    required String shiftId,
    required String shiftStart,
    required String shiftEnd,
    required String dateOfJoining,
    required String imeiNo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/add_user.php"),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "cid": cid,
          "userid": userid,
          "password": password,
          "user_token": userToken,
          "user_img": userImg,
          "full_name": fullName,
          "user_email": userEmail,
          "user_phone": userPhone,
          "gender": gender,
          "full_address": fullAddress,
          "branch_id": branchId,
          "branch_name": branchName,
          "branch_distance": branchDistance,
          "branch_lat": branchLat,
          "branch_long": branchLong,
          "department_id": departmentId,
          "department_name": departmentName,
          "shift_id": shiftId,
          "shift_start": shiftStart,
          "shift_end": shiftEnd,
          "date_of_joining": dateOfJoining,
          "imei_no": imeiNo,
        },
      );

      // 🔥 DEBUG LINE (VERY IMPORTANT)
      print("RAW RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map && decoded['status'] == true) {
          return true;
        } else {
          return false;
        }
      } else {
        throw Exception("Server error");
      }
    } catch (e) {
      print("Create User Error: $e");
      return false;
    }
  }
  Future<List<UserModel>> fetchUsers() async {
    final response = await http.get(
      Uri.parse("$baseUrl/get_users.php"),
    );

    final data = json.decode(response.body);

    if (data['status'] == true) {
      return (data['data'] as List)
          .map((e) => UserModel.fromJson(e))
          .toList();
    }
    return [];
  }
  /// Update user - send all fields
  Future<bool> updateUser({
    required String uid,
    required String cid,
    required String userid,
    required String password,
    required String userToken,
    required String userImg,
    required String imeiNo,
    required String fullName,
    required String userEmail,
    required String userPhone,
    required String gender,
    required String fullAddress,
    required String branchId,
    required String branchName,
    required String branchDistance,
    required String branchLat,
    required String branchLong,
    required String departmentId,
    required String departmentName,
    required String shiftId,
    required String shiftStart,
    required String shiftEnd,
    required String dateOfJoining,
    required String status,
    required String role,
    required String createdAt,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/update_user.php"),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "uid": uid,
        "cid": cid,
        "userid": userid,
        "password": password,
        "user_token": userToken,
        "user_img": userImg,
        "imei_no": imeiNo,
        "full_name": fullName,
        "user_email": userEmail,
        "user_phone": userPhone,
        "gender": gender,
        "full_address": fullAddress,
        "branch_id": branchId,
        "branch_name": branchName,
        "branch_distance": branchDistance,
        "branch_lat": branchLat,
        "branch_long": branchLong,
        "department_id": departmentId,
        "department_name": departmentName,
        "shift_id": shiftId,
        "shift_start": shiftStart,
        "shift_end": shiftEnd,
        "date_of_joining": dateOfJoining,
        "status": status,
        "role": role,
        "createdAt": createdAt,
      },
    );

    final data = json.decode(response.body);
    return data['status'] == true;
  }
  Future<void> callDeleteApi(String uid) async {
    try {
      final url = Uri.parse(
          "https://fms.bizipac.com/apinew/attendance/delete_user.php?uid=$uid");

      final response = await http.get(url);

      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == true) {
          ScaffoldMessenger.of(context as BuildContext).showSnackBar(
            const SnackBar(content: Text("User deleted successfully")),
          );

          fetchUsers(); // 🔄 refresh table
        } else {
          ScaffoldMessenger.of(context as BuildContext).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "Delete failed")),
          );
        }
      }
    } catch (e) {
      print("Delete Error: $e");
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    }
  }

}
