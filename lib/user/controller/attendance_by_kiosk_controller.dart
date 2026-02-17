import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/attendance_response_model.dart';
import '../model/attendance_record_model.dart';

class AttendanceController {
  static const String _url =
      "https://fms.bizipac.com/apinew/attendance/fetch_attendance_by_kiosk.php";

  static Future<List<Map<String, dynamic>>> fetchAttendance({
    required String officeName,
    required String fromDate,
    required String toDate,
  }) async {
    final res = await http.post(
      Uri.parse(_url),
      body: {
        "office_name": officeName,
        "from_date": fromDate,
        "to_date": toDate,
      },
    );

    final json = jsonDecode(res.body);
    final response = AttendanceResponse.fromJson(json);

    return response.data.map((e) => e.toUiMap()).toList();
  }
}
