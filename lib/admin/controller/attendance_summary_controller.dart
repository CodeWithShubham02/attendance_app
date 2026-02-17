import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/attendance_summary_model.dart';

class AttendanceSummaryController {
  static const String url =
      "https://fms.bizipac.com/apinew/attendance/attendance_summary_report.php";

  static Future<List<AttendanceSummary>> fetchSummary({
    required String fromDate,
    required String toDate,
  }) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "from_date": fromDate,
        "to_date": toDate,
      }),
    );

    final data = jsonDecode(response.body);

    if (data['status'] == true) {
      return (data['data'] as List)
          .map((e) => AttendanceSummary.fromJson(e))
          .toList();
    }
    return [];
  }
}
