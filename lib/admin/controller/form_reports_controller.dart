import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:joizone/user/model/client_form_report_model.dart';

class ReportController {

  static const String apiUrl =
      "https://fms.bizipac.com/apinew/attendance/get_report.php";

  static Future<List<ClientFormReportModel>> fetchReports() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {

        final decoded = jsonDecode(response.body);

        if (decoded["status"] == true) {

          List data = decoded["data"];

          return data
              .map((e) => ClientFormReportModel.fromJson(e))
              .toList();
        }
      }

      return [];
    } catch (e) {
      print("Error fetching reports: $e");
      return [];
    }
  }
  static Future<List<ClientFormReportModel>> fetchReportDuplicate() async {
    try {
      final response = await http.get(Uri.parse("https://fms.bizipac.com/apinew/attendance/get_duplicate_form.php"));

      if (response.statusCode == 200) {

        final decoded = jsonDecode(response.body);

        if (decoded["status"] == true) {

          List data = decoded["data"];

          return data
              .map((e) => ClientFormReportModel.fromJson(e))
              .toList();
        }
      }

      return [];
    } catch (e) {
      print("Error fetching reports: $e");
      return [];
    }
  }
  static Future<List<ClientFormReportModel>> fetchReports1({
    String? fromDate,
    String? toDate,
  }) async {
    try {
      String url = apiUrl;

      if (fromDate != null && toDate != null) {
        url += "?from_date=$fromDate&to_date=$toDate";
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded["status"] == true) {
          List data = decoded["data"];
          return data.map((e) => ClientFormReportModel.fromJson(e)).toList();
        }
      }

      return [];
    } catch (e) {
      print("Error fetching reports: $e");
      return [];
    }
  }
  static Future<bool> updateDuplicate({
    required int id,
    required String duplicateFrom,
  }) async {
    try {
      // Example API call using http
      final response = await http.post(
        Uri.parse("https://fms.bizipac.com/apinew/attendance/update_form.php"),
        body: {
          "id": id.toString(),
          "duplicate_from": duplicateFrom, // "yes"
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == true;
      }
      return false;
    } catch (e) {
      print("Error updating duplicate: $e");
      return false;
    }
  }
  static Future<bool> updateFormDetails({
    required int id,
    required String applicationNo,
    required String relation,
    required String variant,
    required String status,
    required String remarks,
    required String managerRemark,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("https://fms.bizipac.com/apinew/attendance/update_forms.php"),
        body: {
          "id": id.toString(),
          "application_no": applicationNo,
          "relation": relation,
          "variant": variant,
          "status": status,
          "remarks": remarks,
          "manager_remark": managerRemark,
        },
      );
      print("=======================");
      print(id);
      print(applicationNo);
      print(relation);
      print(variant);
      print(status);
      print(remarks);
      print(managerRemark);
      print(response.body);
      print("=======================");

      final data = jsonDecode(response.body);
      if (data["status"] == true) {
        return true;   // ✅ success
      } else {
        return false;  // ❌ failed
      }
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }
}
