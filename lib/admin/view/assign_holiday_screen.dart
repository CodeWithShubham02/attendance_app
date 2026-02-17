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
        title: const Text("Assign Holiday", style: TextStyle(fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "Select Excel File",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: uploadExcel,
              icon: const Icon(Icons.upload_file),
              label: const Text("Select File"),
            ),
          ],
        ),
      ),
    );
  }
}
