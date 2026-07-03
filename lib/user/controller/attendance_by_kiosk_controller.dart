import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/attendance_response_model.dart';
import '../model/attendance_record_model.dart';

class AttendanceController {
  static const String _url =
      "http://15.206.209.30/attendance/fetch_attendance_by_kiosk.php";

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
    print("====================");
    print("====================");
    print(res);
    print(officeName);
    print(fromDate);
    print(toDate);
    print("====================");
    print("====================");

    final json = jsonDecode(res.body);
    final response = AttendanceResponse.fromJson(json);

    return response.data.map((e) => e.toUiMap()).toList();
  }
}
