import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UploadRemarkScreen extends StatefulWidget {
  const UploadRemarkScreen({super.key});

  @override
  State<UploadRemarkScreen> createState() => _UploadRemarkScreenState();
}

class _UploadRemarkScreenState extends State<UploadRemarkScreen> {
  List<List<dynamic>> excelData = [];

  Future<void> uploadExcelData() async {

    if (excelData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload excel first")),
      );
      return;
    }

    List<Map<String, dynamic>> rows = [];

    for (int i = 1; i < excelData.length; i++) {

      rows.add({
        "application_number": excelData[i][6].toString(),
        "remark": excelData[i][16].toString(),
      });

    }

    try {

      var response = await http.post(
        Uri.parse("https://fms.bizipac.com/apinew/attendance/update_excel_remark.php"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: jsonEncode({"rows": rows}),
      );

      print("STATUS CODE: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.body.isEmpty) {



        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Empty response from server")),
        );
        return;
      }

      var data = jsonDecode(response.body);

      if (data["status"] == true) {
        int uploadedCount = rows.length;
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Upload Remark Successful. $uploadedCount file uploaded"),
             duration: const Duration(seconds: 4),),

        );

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Upload Failed")),
        );

        setState(() {});
      }

    } catch (e) {

      print("API ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );

    }
  }
  // PICK EXCEL FILE
  Future<void> pickExcelFile() async {

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result != null) {

      var bytes = result.files.single.bytes;

      var excel = Excel.decodeBytes(bytes!);

      excelData.clear();

      for (var table in excel.tables.keys) {
        for (var row in excel.tables[table]!.rows) {

          List<dynamic> rowData = [];

          for (var cell in row) {
            rowData.add(cell?.value ?? "");
          }

          excelData.add(rowData);
        }
      }

      setState(() {});
    }
  }
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Upload Remark",style: TextStyle(fontSize: 16,color: Colors.white),),
        actions: [
          // IconButton(
          //   onPressed: () {
          //     pickExcelFile();
          //   },
          //   icon: const Icon(Icons.download,color: Colors.white,),
          // ),
          // IconButton(
          //   onPressed: () {
          //     uploadExcelData();
          //   },
          //   icon: const Icon(Icons.cloud_upload,color: Colors.white,),
          // ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Remarks Final Upload File"),
                    content: const Text("-----------------------"),
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          pickExcelFile();
                          Get.back();
                        },
                        child: Row(
                          children: [
                            Container(child: Text("Select Remark file")),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          uploadExcelData();
                        },
                        child: Row(
                          children: [
                            Container(child: Text("Upload Remark file")),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.menu),
          ),
        ],
      ),
      body: excelData.isEmpty
          ? const Center(child: Text("Upload Excel File"))
          : Scrollbar(
        controller: _verticalController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _verticalController,
          scrollDirection: Axis.vertical,
          child: Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: excelData.first.length * 150,
                ),
                child: DataTable(
                  border: TableBorder.all(color: Colors.grey),
                  headingRowColor:
                  MaterialStateProperty.all(Colors.blue.shade100),

                  columns: excelData.first
                      .map(
                        (e) => DataColumn(
                      label: Text(
                        e.toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                      .toList(),

                  rows: excelData
                      .skip(1)
                      .map(
                        (row) => DataRow(
                      cells: row
                          .map(
                            (cell) => DataCell(
                          SizedBox(
                            width: 150,
                            child: Text(cell.toString()),
                          ),
                        ),
                      )
                          .toList(),
                    ),
                  )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
