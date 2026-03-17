import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
      withData: true, // IMPORTANT
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

    final headers =
    sheet.rows.first.map((e) => e?.value.toString() ?? '').toList();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text("Roster", style: TextStyle(fontSize: 18,color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Image.asset("assets/image/img_1.png"),
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
                    Text("• cid – Client ID (Numeric)"),
                    Text("• uid – User ID (Numeric)"),
                    Text("• name – Employee Name"),
                    Text("• User Type – User Type Name"),
                    Text("• office_name – Office Name"),
                    Text("• status – HOLIDAY"),
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
    );
  }
}
