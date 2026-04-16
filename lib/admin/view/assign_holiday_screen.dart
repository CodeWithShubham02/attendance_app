import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;
class AssignHolidayScreen extends StatefulWidget {
  const AssignHolidayScreen({super.key});

  @override
  State<AssignHolidayScreen> createState() => _AssignHolidayScreenState();
}

class _AssignHolidayScreenState extends State<AssignHolidayScreen> {

  Future<void> uploadExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (result == null) return;

    final bytes = result.files.single.bytes;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to read file")),
      );
      return;
    }

    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first];

    if (sheet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid Excel sheet")),
      );
      return;
    }

    // ✅ EXPECTED HEADERS
    List<String> expectedHeaders = [
      "cid",
      "uid",
      "name",
      "user_type",
      "office_name",
      "status",
      "roster_date",
      "shift_start",
      "shift_end"
    ];

    // ✅ FILE HEADERS
    final headers =
    sheet.rows.first.map((e) => e?.value.toString().trim() ?? '').toList();

    // 🔥 CHECK HEADER MATCH
    bool isValid = expectedHeaders.length == headers.length &&
        expectedHeaders.every((h) => headers.contains(h));

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Something went wrong! Invalid Excel format")),
      );
      return;
    }

    // ✅ READ DATA
    List<Map<String, dynamic>> rows = [];

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      Map<String, dynamic> data = {};

      for (int j = 0; j < headers.length; j++) {
        data[headers[j]] =
        j < row.length ? row[j]?.value.toString() ?? '' : '';
      }

      rows.add(data);
    }

    await sendToApi(rows);
  }

  Future<void> sendToApi(List<Map<String, dynamic>> data) async {
    try {
      final res = await http.post(
        Uri.parse("https://fms.bizipac.com/apinew/attendance/user_holiday.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"records": data}),
      );
      print("----------------");
      print(data);
      print("----------------");
      final response = jsonDecode(res.body);
      print("----------------");
      print(response);
      print("----------------");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Upload completed'),
          backgroundColor:
          response['status'] == true ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final res = await http.get(
      Uri.parse("https://fms.bizipac.com/apinew/attendance/get_users.php"),
    );

    final data = jsonDecode(res.body);

    if (data['status'] == true) {
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      return [];
    }
  }
  Future<void> downloadTemplate() async {
    try {
      if (!kIsWeb) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Storage permission denied")),
          );
          return;
        }
      }

      final excel = Excel.createExcel();

      // 🟢 Sheet 1 → Template
      final sheet1 = excel['Template'];

      sheet1.appendRow([
        TextCellValue("cid"),
        TextCellValue("uid"),
        TextCellValue("name"),
        TextCellValue("user_type"),
        TextCellValue("office_name"),
        TextCellValue("status"),
        TextCellValue("roster_date"),
        TextCellValue("shift_start"),
        TextCellValue("shift_end"),
      ]);

      // 🟡 Sheet 2 → Users Data
      final sheet2 = excel['Users'];

      sheet2.appendRow([
        TextCellValue("cid"),
        TextCellValue("uid"),
        TextCellValue("agent_id"),
        TextCellValue("agent_name"),
        TextCellValue("user_type"),
        TextCellValue("site_name"),
        TextCellValue("status"),
      ]);

      // 🔥 API CALL
      List<Map<String, dynamic>> users = await fetchUsers();

      // ⚠️ Safety check
      if (users.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No users data found")),
        );
      }

      // ✅ Fill Users Sheet
      for (var user in users) {
        sheet2.appendRow([
          TextCellValue("${user['cid'] ?? ''}"),
          TextCellValue("${user['uid'] ?? ''}"),
          TextCellValue("${user['userid'] ?? ''}"),
          TextCellValue("${user['full_name'] ?? ''}"),
          TextCellValue("${user['user_type'] ?? ''}"),
          TextCellValue("${user['branch_name'] ?? ''}"),
          TextCellValue("${user['status'] ?? ''}"),
        ]);
      }

      // ❗ Default "Sheet1" remove (important)
      excel.delete('Sheet1');

      final fileBytes = excel.encode();
      if (fileBytes == null) return;

      if (kIsWeb) {
        downloadForWeb(fileBytes);
      } else {
        final dir = await getExternalStorageDirectory();
        final filePath = "${dir!.path}/roster_template.xlsx";

        final file = File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Saved at: $filePath")),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
  void downloadForWeb(List<int> bytes) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "roster_template.xlsx")
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text("Roster", style: TextStyle(fontSize: 18,color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Image.asset("assets/image/img_2.png"),
                ElevatedButton.icon(
                  onPressed:downloadTemplate,
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
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Download Templete"),
                ),
                Text(
                  "⚠ If the cid, uid, or office_name does not match, the roster upload will be rejected.",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                Card(
                  margin: EdgeInsets.all(12),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "📌 Roster Upload Rules",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text("• cid – Company ID (Numeric)"),
                        Text("• uid – User ID (Numeric)"),
                        Text("• name – Employee Name"),
                        Text("• User Type – User Type Name"),
                        Text("• office_name – Office Name"),
                        Text("• status – WO"),
                        Text("• roster_date – DD-MM-YYYY"),
                        Text("• shift_start – HH:MM (24 Hour)"),
                        Text("• shift_end – HH:MM (24 Hour)"),
                        SizedBox(height: 6),
                        Text(
                          "⚠ Date & Time format strictly follow karein.",
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                )
                    ,
                const SizedBox(height: 20),
                const Text(
                  "This formate excel file upload.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: uploadExcel,
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
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Select File"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
