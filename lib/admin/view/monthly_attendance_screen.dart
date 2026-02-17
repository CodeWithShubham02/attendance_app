import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/gestures.dart';

class MonthlyAttendanceScreen extends StatefulWidget {
  final String cid;

  const MonthlyAttendanceScreen({super.key, required this.cid});

  @override
  State<MonthlyAttendanceScreen> createState() =>
      _MonthlyAttendanceScreenState();
}

class _MonthlyAttendanceScreenState extends State<MonthlyAttendanceScreen> {
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredRecords = [];
  void filterByName(String query) {
    setState(() {
      filteredRecords = attendanceRecords.where((row) {
        final name = row['name']?.toString().toLowerCase() ?? '';
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  List<Map<String, dynamic>> attendanceRecords = [];
  bool isLoading = false;

  // ---------------- PICK DATE ----------------
  Future<void> pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? fromDate : toDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  // ---------------- FETCH API ----------------
  Future<void> fetchAttendance() async {
    setState(() => isLoading = true);

    final url = Uri.parse(
        "https://fms.bizipac.com/apinew/attendance/fetch_attendance_range.php?cid=${widget.cid}&from_date=${DateFormat('yyyy-MM-dd').format(fromDate)}&to_date=${DateFormat('yyyy-MM-dd').format(toDate)}");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);

        if (res['status'] == true) {
          setState(() {
            attendanceRecords = List<Map<String, dynamic>>.from(res['data'] ?? []).map((e) {
              // Convert all numeric fields to String safely
              return {
                'id': e['id']?.toString() ?? '-',
                'uid': e['uid']?.toString() ?? '-',
                'name': e['name']?.toString() ?? '-',
                'department': e['department']?.toString() ?? '-',
                'office_name': e['office_name']?.toString() ?? '-',
                'status': e['status']?.toString() ?? '-',
                'punch_in_time': e['punch_in_time']?.toString() ?? '-',
                'punch_in_lat': e['punch_in_lat']?.toString() ?? '-',
                'punch_in_lng': e['punch_in_lng']?.toString() ?? '-',
                'punch_out_time': e['punch_out_time']?.toString() ?? '-',
                'punch_out_lat': e['punch_out_lat']?.toString() ?? '-',
                'punch_out_lng': e['punch_out_lng']?.toString() ?? '-',
                'shift_start': e['shift_start']?.toString() ?? '-',
                'shift_end': e['shift_end']?.toString() ?? '-',
                'punch_in_image': e['punch_in_image']?.toString() ?? '-',
                'punch_out_image': e['punch_out_image']?.toString() ?? '-',
                'punch_in_remark': e['punch_in_remark']?.toString() ?? '-',
                'punch_out_remark': e['punch_out_remark']?.toString() ?? '-',
                'total_break_minutes': e['total_break_minutes']?.toString() ?? '-',
                'late': e['late']?.toString() ?? '-',
                'working_minutes': e['working_minutes']?.toString() ?? '-',
                'total_working_minutes': e['total_working_minutes']?.toString() ?? '-',
                'created_at': e['created_at']?.toString() ?? '-',
              };
            }).toList();
            filteredRecords = attendanceRecords;

          });
        } else {
          setState(() {
            attendanceRecords = [];
          });
          Get.snackbar("Error", res['message'] ?? "Failed to fetch data");
        }
      } else {
        Get.snackbar("Error", "Server error: ${response.statusCode}");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch data");
    } finally {
      setState(() => isLoading = false);
    }
  }
  Future<void> downloadExcel() async {
    if (filteredRecords.isEmpty) {
      Get.snackbar("No Data", "No attendance data to export");
      return;
    }

    final excel = Excel.createExcel();
    final sheet = excel['Attendance'];

    // 🟢 HEADER ROW
    sheet.appendRow([
      TextCellValue("ID"),
      TextCellValue("UID"),
      TextCellValue("Name"),
      TextCellValue("Department"),
      TextCellValue("Office"),
      TextCellValue("Status"),
      TextCellValue("Punch In"),
      TextCellValue("Punch Out"),
      TextCellValue("Shift Start"),
      TextCellValue("Shift End"),
      TextCellValue("Late"),
      TextCellValue("Total Break (min)"),
      TextCellValue("Working Minutes"),
      TextCellValue("Date"),
    ]);

    // 🔵 DATA ROWS (🔥 FIXED)
    for (var row in filteredRecords) {
      sheet.appendRow([
        TextCellValue(row['id']?.toString() ?? ''),
        TextCellValue(row['uid']?.toString() ?? ''),
        TextCellValue(row['name']?.toString() ?? ''),
        TextCellValue(row['department']?.toString() ?? ''),
        TextCellValue(row['office_name']?.toString() ?? ''),
        TextCellValue(row['status']?.toString() ?? ''),
        TextCellValue(row['punch_in_time']?.toString() ?? ''),
        TextCellValue(row['punch_out_time']?.toString() ?? ''),
        TextCellValue(row['shift_start']?.toString() ?? ''),
        TextCellValue(row['shift_end']?.toString() ?? ''),
        TextCellValue(row['late']?.toString() ?? ''),
        TextCellValue(row['total_break_minutes']?.toString() ?? ''),
        TextCellValue(row['working_minutes']?.toString() ?? ''),
        TextCellValue(row['created_at']?.toString() ?? ''),
      ]);

    }

    final directory = await getApplicationDocumentsDirectory();
    final filePath =
        "${directory.path}/attendance_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx";

    final fileBytes = excel.encode();
    final file = File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes!);

    await Share.shareXFiles(
      [XFile(filePath)],
      text: "Attendance Report",
    );
  }




  Map<String, String> addressCache = {};
  Future<String> getAddressFromLatLng(double lat, double lng) async {
    final key = "$lat,$lng";

    // ✅ cache check
    if (addressCache.containsKey(key)) {
      return addressCache[key]!;
    }

    try {
      String address;

      if (kIsWeb) {
        // 🌐 WEB → Google Geocoding API
        const googleApiKey = "AIzaSyBF7OlUqnsWTXRMiwtwEk9ieQ4YkzIhq18";

        final url =
            "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$googleApiKey";

        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['status'] == 'OK') {
            address = data['results'][0]['formatted_address'];
          } else {
            address = "Address not found";
          }
        } else {
          address = "Address not found";
        }
      } else {
        // 📱 ANDROID / IOS → Native geocoding
        List<Placemark> placemarks =
        await placemarkFromCoordinates(lat, lng);

        final place = placemarks.first;
        address =
        "${place.name}, ${place.street}, ${place.subLocality}, "
            "${place.locality}, ${place.administrativeArea} "
            "${place.postalCode}";
      }

      addressCache[key] = address;
      return address;
    } catch (e) {
      return "Address not found";
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Attendance"),
        actions: [
          IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () async {
                await pickDate(isFrom: true);
                await pickDate(isFrom: false);
                fetchAttendance();
              }),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: downloadExcel,
          ),

          // 🔍 Search
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Get.defaultDialog(
                title: "Search Employee",
                content: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: "Enter employee name",
                  ),
                  onChanged: filterByName,
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : attendanceRecords.isEmpty
          ? const Center(child: Text("No attendance records found"))
          : ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.mouse,
            PointerDeviceKind.touch,
            PointerDeviceKind.trackpad,
          },
        ),
        child: Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints:
              const BoxConstraints(minWidth: 2600), // 👈 VERY IMPORTANT
              child: Scrollbar(
                controller: _verticalController,
                thumbVisibility: true,
                trackVisibility: true,
                interactive: true,
                child: SingleChildScrollView(
                  controller: _verticalController,
                  scrollDirection: Axis.vertical,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: DataTable(
                    headingRowColor:
                    MaterialStateColor.resolveWith(
                            (states) => Colors.grey.shade200),
                    border: TableBorder.all(
                        color: Colors.grey.shade400, width: 1),
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text("Attendance ID")),
                      DataColumn(label: Text("UID")),
                      DataColumn(label: Text("Name")),
                      DataColumn(label: Text("Department")),
                      DataColumn(label: Text("Office Name")),
                      DataColumn(label: Text("Status")),
                      DataColumn(label: Text("Punch In")),
                      DataColumn(label: Text("Punch In Address")),
                      DataColumn(label: Text("Punch Out")),
                      DataColumn(label: Text("Punch Out Address")),
                      DataColumn(label: Text("Shift Start")),
                      DataColumn(label: Text("Shift End")),
                      DataColumn(label: Text("Punch In Image")),
                      DataColumn(label: Text("Punch Out Image")),
                      DataColumn(label: Text("Punch In Remark")),
                      DataColumn(label: Text("Punch Out Remark")),
                      DataColumn(label: Text("Total Break")),
                      DataColumn(label: Text("Late Mark")),
                      DataColumn(label: Text("Total Working Minutes")),
                      DataColumn(label: Text("Date")),
                    ],
                    rows: filteredRecords.map((data) {
                      DateTime? parse(dynamic v) {
                        if (v == null) return null;
                        try {
                          return DateTime.parse(v.toString());
                        } catch (_) {
                          return null;
                        }
                      }

                      return DataRow(cells: [
                        DataCell(Text(data['id'] ?? '-')),
                        DataCell(Text(data['uid'] ?? '-')),
                        DataCell(Text(data['name'] ?? '-')),
                        DataCell(Text(data['department'] ?? '-')),
                        DataCell(Text(data['office_name'] ?? '-')),
                        DataCell(Text(data['status'] ?? '-')),
                        DataCell(Text(data['punch_in_time'] ?? '-')),
                        DataCell( Builder( builder: (context) { final lat = double.tryParse(data['punch_in_lat']?.toString() ?? ''); final lng = double.tryParse(data['punch_in_lng']?.toString() ?? ''); if (lat == null || lng == null) { return const Text("-"); } return FutureBuilder<String>( future: getAddressFromLatLng(lat, lng), builder: (context, snapshot) { if (snapshot.connectionState == ConnectionState.waiting) { return const Text("Loading..."); } return Text( snapshot.data ?? "Address not found", maxLines: 2, overflow: TextOverflow.ellipsis, ); }, ); }, ), ),
                        DataCell(Text(data['punch_out_time'] ?? '-')),
                        DataCell( Builder( builder: (context) { final lat = double.tryParse(data['punch_out_lat']?.toString() ?? ''); final lng = double.tryParse(data['punch_out_lng']?.toString() ?? ''); if (lat == null || lng == null) { return const Text("-"); } return FutureBuilder<String>( future: getAddressFromLatLng(lat, lng), builder: (context, snapshot) { if (snapshot.connectionState == ConnectionState.waiting) { return const Text("Loading..."); } return Text( snapshot.data ?? "Address not found", maxLines: 2, overflow: TextOverflow.ellipsis, ); }, ); }, ), ),
                        DataCell(Text(data['shift_start'] ?? '-')),
                        DataCell(Text(data['shift_end'] ?? '-')),
                        DataCell(
                          data['punch_in_image'] != null &&
                              data['punch_in_image'].toString().isNotEmpty
                              ? InkWell(
                            onTap: () {
                              _showImageDialog(
                                context,
                                data['punch_in_image'],
                              );
                            },
                            child: Image.network(
                              data['punch_in_image'],
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image),
                            ),
                          )
                              : const Icon(Icons.image_not_supported),
                        ),
                        DataCell(
                          data['punch_out_image'] != null &&
                              data['punch_out_image'].toString().isNotEmpty
                              ? InkWell(
                            onTap: () {
                              _showImageDialog(
                                context,
                                data['punch_out_image'],
                              );
                            },
                            child: Image.network(
                              data['punch_out_image'],
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image),
                            ),
                          )
                              : const Icon(Icons.image_not_supported),
                        ),
                        DataCell(Text(data['punch_in_remark'] ?? '-')),
                        DataCell(Text(data['punch_out_remark'] ?? '-')),
                        DataCell(Text(data['total_break_minutes'] ?? '-')),
                        DataCell(Text(data['late'] ?? '-')),
                        DataCell(Text(data['total_working_minutes'] ?? '-')),
                        DataCell(Text(data['created_at'] ?? '-')),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),


    );
  }
}
