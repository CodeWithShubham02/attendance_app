import 'dart:convert';
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
}
