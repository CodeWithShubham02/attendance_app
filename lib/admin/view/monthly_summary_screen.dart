import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../controller/attendance_summary_controller.dart';
import '../model/attendance_summary_model.dart';

class AttendanceSummaryScreen extends StatefulWidget {
  const AttendanceSummaryScreen({super.key});

  @override
  State<AttendanceSummaryScreen> createState() =>
      _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  bool isLoading = false;
  List<AttendanceSummary> records = [];

  Future<void> pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => isLoading = true);

      final from = DateFormat('yyyy-MM-dd').format(picked.start);
      final to = DateFormat('yyyy-MM-dd').format(picked.end);

      records = await AttendanceSummaryController.fetchSummary(
        fromDate: from,
        toDate: to,
      );

      setState(() => isLoading = false);
    }
  }

  String formatDate(String date) {
    if (date.isEmpty) return "-";
    return DateFormat('dd MMM yyyy')
        .format(DateTime.parse(date));
  }
  Future<void> downloadSummaryExcel(List<AttendanceSummary> records) async {
    if (records.isEmpty) {
      Get.snackbar("No Data", "No summary data to export");
      return;
    }

    final excel = Excel.createExcel();
    final sheet = excel['Attendance Summary'];

    // 🟢 HEADER ROW (same as DataTable)
    sheet.appendRow([
      TextCellValue("UID"),
      TextCellValue("Name"),
      TextCellValue("Executive"),
      TextCellValue("Office Name"),
      TextCellValue("Total Days"),
      TextCellValue("Total Present"),
      TextCellValue("Total Absent"),
      TextCellValue("Total Holiday"),
      TextCellValue("Missed Punch"),
      TextCellValue("Total Minutes"),
      TextCellValue("From Date"),
      TextCellValue("To Date"),
    ]);

    // 🔵 DATA ROWS
    for (final r in records) {
      sheet.appendRow([
        TextCellValue(r.uid.toString()),
        TextCellValue(r.name),
        TextCellValue(r.department), // Executive
        TextCellValue(r.officeName),
        TextCellValue(r.totalDays.toString()),
        TextCellValue(r.totalPresent.toString()),
        TextCellValue(r.totalAbsent.toString()),
        TextCellValue(r.totalHoliday.toString()),
        TextCellValue(r.missedPunchOut.toString()),
        TextCellValue(r.totalHour.toString()),
        TextCellValue(r.fromDate),
        TextCellValue(r.toDate),
      ]);
    }

    // 📁 SAVE FILE
    final directory = await getApplicationDocumentsDirectory();
    final filePath =
        "${directory.path}/attendance_summary_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx";

    final fileBytes = excel.encode();
    final file = File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes!);

    // 📤 SHARE FILE
    await Share.shareXFiles(
      [XFile(filePath)],
      text: "Attendance Summary Report",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Summary"),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: pickRange,
          ),
          IconButton(onPressed: (){downloadSummaryExcel(records);}, icon: Icon(Icons.download))
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : records.isEmpty
          ? const Center(child: Text("No Data Found"))
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  border: TableBorder.all(
                    color: Colors.grey,
                    width: 1,
                  ),
                  headingRowColor:
                  MaterialStateProperty.all(
                      Colors.blue.shade50),
                  headingRowHeight: 48,
                  dataRowHeight: 46,
                  columns: const [
                    DataColumn(label: Text("UID")),
                    DataColumn(label: Text("Name")),
                    DataColumn(label: Text("Executive")),
                    DataColumn(label: Text("Office Name")),
                    DataColumn(label: Text("Total Days")),
                    DataColumn(label: Text("Total Present")),
                    DataColumn(label: Text("Total Absent")),
                    DataColumn(label: Text("Total GPS Off")),
                    DataColumn(label: Text("Total Internet Off")),
                    DataColumn(label: Text("Total Outside Kiosk")),
                    // DataColumn(label: Text("Total Late")),
                    DataColumn(label: Text("Total Holiday")),
                    DataColumn(label: Text("Missed Punch")),
                    DataColumn(label: Text("Total Minutes")),
                    DataColumn(label: Text("From Date")),
                    DataColumn(label: Text("To Date")),
                  ],
                  rows: records.map((r) {
                    print("----------");
                    print(r.totalHour);
                    print("============");
                    return DataRow(
                      cells: [
                        DataCell(Text(r.uid.toString())),
                        DataCell(Text(r.name)),
                        DataCell(Text(r.department)),
                        DataCell(Text(r.officeName)),
                        DataCell(Text(r.totalDays.toString())),
                        DataCell(Text(r.totalPresent.toString())),
                        DataCell(Text(r.totalAbsent.toString())),
                        DataCell(Text(r.totalGps.toString())),
                        DataCell(Text(r.totalInternet.toString())),
                        DataCell(Text(r.totalOutside.toString())),
                        // DataCell(Text(r.totalLate.toString())),
                        DataCell(Text(r.totalHoliday.toString())),
                        DataCell(Text(r.missedPunchOut.toString())),
                        DataCell(Text(r.totalHour.toString())),
                        DataCell(Text(formatDate(r.fromDate))),
                        DataCell(Text(formatDate(r.toDate))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
