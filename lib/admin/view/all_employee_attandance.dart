import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AllEmployeeAttendanceScreen extends StatefulWidget {
  final String cid;

  const AllEmployeeAttendanceScreen({super.key, required this.cid});

  @override
  State<AllEmployeeAttendanceScreen> createState() =>
      _AllEmployeeAttendanceScreenState();
}

class _AllEmployeeAttendanceScreenState
    extends State<AllEmployeeAttendanceScreen> {
  DateTime selectedDate = DateTime.now();
  String? selectedDepartment;

  List<Map<String, dynamic>> attendanceRecords = [];
  bool isLoading = false;

  // ---------------- DATE KEY ----------------
  String dateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // ---------------- API CALL ----------------
  Future<void> fetchAttendanceByDate() async {
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(
            "https://fms.bizipac.com/apinew/attendance/fetch_attendance_by_date.php"),
        body: {
          "cid": widget.cid,
          "date": dateKey(selectedDate),
        },
      );

      final jsonData = json.decode(response.body);
      print("----------");
      print(jsonData);
      if (jsonData['status'] == true) {
        setState(() {
          attendanceRecords =
          List<Map<String, dynamic>>.from(jsonData['data']);
        });
      } else {
        attendanceRecords = [];
      }
    } catch (e) {
      attendanceRecords = [];
    }

    setState(() => isLoading = false);
  }

  // ---------------- PICK DATE ----------------
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      fetchAttendanceByDate();
    }
  }

  // ---------------- FILTER ----------------
  void showFilterDialog() {
    final TextEditingController ctrl =
    TextEditingController(text: selectedDepartment);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Filter Kiosk "),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Kiosk Name",
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                selectedDepartment =
                ctrl.text.trim().isEmpty ? null : ctrl.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }

  // ---------------- GOOGLE MAP ----------------
  Future<void> openGoogleMap(double lat, double lng) async {
    final url = "https://www.google.com/maps?q=$lat,$lng";
    final uri = Uri.parse(url);

    if (!await launchUrl(
      uri,
      mode: LaunchMode.platformDefault, // 👈 IMPORTANT
    )) {
      throw 'Could not launch Google Maps';
    }
  }


  // ---------------- PDF EXPORT ----------------
  Future<void> exportAttendancePdf() async {
    if (attendanceRecords.isEmpty) return;

    var permission = await Permission.manageExternalStorage.request();
    if (!permission.isGranted) return;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) {
          return pw.Table.fromTextArray(
            headers: [
              "UID",
              "Name",
              "Department",
              "Date",
              "Punch In",
              "Punch Out",
              "Status",
              "Working Hours",
              "Break Minutes",
            ],
            data: attendanceRecords.map((e) {
              DateTime? punchIn = e['punch_in_time'] != null
                  ? DateTime.parse(e['punch_in_time'])
                  : null;
              DateTime? punchOut = e['punch_out_time'] != null
                  ? DateTime.parse(e['punch_out_time'])
                  : null;

              String working = "-";
              if (punchIn != null && punchOut != null) {
                final diff = punchOut.difference(punchIn);
                working =
                "${diff.inHours}h ${diff.inMinutes % 60}m";
              }

              return [
                e['uid'] ?? '-',
                e['name'] ?? '-',
                e['department'] ?? '-',
                punchIn != null
                    ? DateFormat('dd-MM-yyyy').format(punchIn)
                    : '-',
                punchIn != null
                    ? DateFormat('HH:mm').format(punchIn)
                    : '-',
                punchOut != null
                    ? DateFormat('HH:mm').format(punchOut)
                    : '-',
                e['status'] ?? '-',
                working,
                e['total_break_minutes']?.toString() ?? '-',
              ];
            }).toList(),
          );
        },
      ),
    );

    Directory dir = Directory("/storage/emulated/0/Download");
    final file =
    File("${dir.path}/Attendance_${Random().nextInt(9999)}.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)]);
  }

  @override
  void initState() {
    super.initState();
    fetchAttendanceByDate();
  }
  void showUpdateStatusDialog({
    required BuildContext context,
    required String attendanceId,
  }) {
    String selectedStatus = 'Present';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Update Attendance Status"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: "Select Status",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Present', child: Text("Present")),
                      DropdownMenuItem(value: 'ABSENT', child: Text("Absent")),
                      DropdownMenuItem(value: 'HOLYDAY', child: Text("Holiday")),
                      DropdownMenuItem(
                          value: 'AUTO_PUNCH_OUT',
                          child: Text("Auto Punch Out")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await updateAttendanceStatus(
                      context: context,
                      attendanceId: attendanceId,
                      status: selectedStatus,
                    );
                  },
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<void> updateAttendanceStatus({
    required BuildContext context,
    required String attendanceId,
    required String status,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(
          "https://fms.bizipac.com/apinew/attendance/update_attendance_status.php",
        ),
        body: {
          "attendance_id": attendanceId,
          "status": status,
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print(data);
        final isSuccess = data['status'] == true ||
            data['status'] == 1 ||
            data['status'].toString() == 'true';

        if (isSuccess) {
          Navigator.pop(context); // close dialog

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Attendance updated to $status"),
              backgroundColor: Colors.green,
            ),
          );

          // 🔄 OPTIONAL: refresh list
          // fetchAttendance();

        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? "Update failed"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: EdgeInsets.zero, // 🔥 full screen
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              // 🔍 Zoomable image
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 80,
                    ),
                  ),
                ),
              ),

              // ❌ Close button
              Positioned(
                top: 30,
                right: 20,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final filteredRecords = selectedDepartment == null
        ? attendanceRecords
        : attendanceRecords
        .where((e) => e['office_name']
        .toString()
        .toLowerCase()
        .contains(selectedDepartment!.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Attendance"),
        actions: [
          IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: pickDate),
          IconButton(
              icon: const Icon(Icons.filter_alt),
              onPressed: showFilterDialog),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredRecords.isEmpty
          ? const Center(child: Text("No attendance found"))
          : SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor:
            MaterialStateProperty.all(Colors.grey.shade300),
            border: TableBorder.all(
              color: Colors.black54,
              width: 1,
            ),
            columns: const [
              DataColumn(label: Text("Location")),
              DataColumn(label: Text("Date")),
              DataColumn(label: Text("Attendance ID")),
              DataColumn(label: Text("Name")),
              DataColumn(label: Text("Office Name")),
              DataColumn(label: Text("Department")),
              DataColumn(label: Text("Punch In")),
              DataColumn(label: Text("Punch In Remark")),
              DataColumn(label: Text("Punch In Image")),
              DataColumn(label: Text("Punch Out")),
              DataColumn(label: Text("Punch Out Remark")),
              DataColumn(label: Text("Punch Out Image")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Late")),
              DataColumn(label: Text("Working Hours")),
              DataColumn(label: Text("Break Min")),
            ],
            rows: filteredRecords.map((e) {
              DateTime? punchIn = e['punch_in_time'] != null
                  ? DateTime.parse(e['punch_in_time'])
                  : null;
              DateTime? punchOut = e['punch_out_time'] != null
                  ? DateTime.parse(e['punch_out_time'])
                  : null;

              String working = "-";
              if (punchIn != null && punchOut != null) {
                final diff = punchOut.difference(punchIn);
                working =
                "${diff.inHours}h ${diff.inMinutes % 60}m";
              }
              print("-----------------");
              print(e['punch_in_image']);
              print("-----------------");
              return DataRow(cells: [

                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.location_on,
                            color: Colors.red),
                        onPressed: () async{
                          final id=e['id'];
                          final res = await http.get(
                            Uri.parse("https://fms.bizipac.com/apinew/attendance/fetch_current_location.php?attendance_id=$id"),
                          );
                          print(res);
                          final json = jsonDecode(res.body);
                          print(json);
                          if (json['status']) {
                            double lat = double.parse(json['data']['latitude']);
                            double lng = double.parse(json['data']['longitude']);

                            openGoogleMap(lat, lng);
                          }

                        },
                      ),
                      IconButton(onPressed: () {
              final attendanceId = e['id']; // 👈 attendance id

                  showUpdateStatusDialog(
                  context: context,
                  attendanceId: attendanceId.toString(),
                  );
              }, icon: Icon(Icons.edit)),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.red),
                        onPressed: () async{
                          final attendanceId=e['id'] ?? '-';
                          print(attendanceId);
                          final res = await http.post(
                            Uri.parse("https://fms.bizipac.com/apinew/attendance/delete_attendance_by_id.php"),
                            body: {
                              "attendance_id": attendanceId,
                            },
                          );
                          if (res.statusCode == 200) {
                            final data = jsonDecode(res.body);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Attendance deleted (ID: $attendanceId)"),
                                backgroundColor: Colors.green,
                              ),
                            );

                            // 🔙 Go back & notify previous screen
                            Navigator.pop(context, true);
                          }
                        },
                      ),
                    ],
                  ),

                ),
                DataCell(Text(e['created_at'] ?? '-')),
                DataCell(Text(e['id'] ?? '-')),
                DataCell(Text(e['name'] ?? '-')),
                DataCell(Text(e['office_name'] ?? '-')),
                DataCell(Text(e['department'] ?? '-')),
                DataCell(Text(punchIn != null
                    ? DateFormat('HH:mm').format(punchIn)
                    : '-')),
                DataCell(Text(e['punch_in_remark'] ?? '-')),
                DataCell(
                  e['punch_in_image'] != null &&
                      e['punch_in_image'].toString().isNotEmpty
                      ? InkWell(
                    onTap: () {
                      _showImageDialog(
                        context,
                        e['punch_in_image'],
                      );
                    },
                    child: Image.network(
                      e['punch_in_image'],
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image),
                    ),
                  )
                      : const Icon(Icons.image_not_supported),
                ),

                DataCell(Text(punchOut != null
                    ? DateFormat('HH:mm').format(punchOut)
                    : '-')),
                DataCell(Text(e['punch_out_remark'] ?? '-')),
                DataCell(
                  e['punch_out_image'] != null &&
                      e['punch_out_image'].toString().isNotEmpty
                      ? InkWell(
                    onTap: () {
                      _showImageDialog(
                        context,
                        e['punch_out_image'],
                      );
                    },
                    child: Image.network(
                      e['punch_out_image'],
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image),
                    ),
                  )
                      : const Icon(Icons.image_not_supported),
                ),
                DataCell(Text(e['status'] ?? '-')),
                DataCell(Text(e['late'] ?? '-')),
                DataCell(Text(working)),
                DataCell(Text(
                    e['total_break_minutes']?.toString() ?? '-')),
              ]);
            }).toList(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: exportAttendancePdf,
        child: const Icon(Icons.download),
      ),
    );
  }
}
