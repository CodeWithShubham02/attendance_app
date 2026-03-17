import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controller/attendance_by_kiosk_controller.dart';
import '../controller/attendance_controller.dart';

class OfficeAttendanceScreen extends StatefulWidget {
  final String officeName;

  const OfficeAttendanceScreen({
    super.key,
    required this.officeName,
  });

  @override
  State<OfficeAttendanceScreen> createState() =>
      _OfficeAttendanceScreenState();
}

class _OfficeAttendanceScreenState extends State<OfficeAttendanceScreen> {
  bool isLoading = false;
  bool isSearching = false;

  DateTimeRange? selectedRange;

  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> attendanceRecords = [];
  List<Map<String, dynamic>> filteredRecords = [];

  /// 📅 PICK DATE RANGE
  Future<void> pickDateRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: selectedRange,
    );

    if (picked != null) {
      setState(() {
        selectedRange = picked;
        isLoading = true;
        attendanceRecords.clear();
        filteredRecords.clear();
      });

      await fetchAttendance(picked);
    }
  }

  /// 🌐 FETCH ATTENDANCE
  Future<void> fetchAttendance(DateTimeRange range) async {
    try {
      final from = DateFormat('yyyy-MM-dd').format(range.start);
      final to = DateFormat('yyyy-MM-dd').format(range.end);

      attendanceRecords = await AttendanceController.fetchAttendance(
        officeName: widget.officeName,
        fromDate: from,
        toDate: to,
      );

      filteredRecords = List.from(attendanceRecords);
    } catch (e) {
      debugPrint("Attendance error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// 🔍 FILTER BY NAME
  void filterByName(String query) {
    if (query.isEmpty) {
      filteredRecords = List.from(attendanceRecords);
    } else {
      filteredRecords = attendanceRecords.where((r) {
        final name = (r['name'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    }
    setState(() {});
  }

  /// ⏱ FORMAT TIME
  String formatTime(String? time) {
    if (time == null || time.isEmpty) return "-";
    return time;
  }

  /// 🖼 IMAGE VIEWER
  void showImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
  String formatTime12(String? time) {
    if (time == null || time.isEmpty || time == "-") return "-";

    try {
      final dt = DateTime.parse(time);
      int hour = dt.hour;
      String period = hour >= 12 ? "PM" : "AM";

      hour = hour % 12;
      if (hour == 0) hour = 12;

      return "${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period";
    } catch (e) {
      return "-";
    }
  }
  /// 📊 ATTENDANCE TABLE
  Widget buildAttendanceTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 18,
        headingRowColor:
        MaterialStateProperty.all(Colors.blue.shade50),
        border: TableBorder.all(
          color: Colors.grey,
          width: 1,
        ),
        columns: const [
          DataColumn(label: Text("Name")),
          DataColumn(label: Text("User Type")),
          DataColumn(label: Text("Status")),
          DataColumn(label: Text("Shift")),
          DataColumn(label: Text("Punch In")),
          DataColumn(label: Text("Punch Out")),
          DataColumn(label: Text("In Img")),
          DataColumn(label: Text("Out Img")),
        ],
        rows: filteredRecords.map((r) {
          return DataRow(cells: [
            DataCell(Text(r['name'] ?? "-")),
            DataCell(Text(r['department'] ?? "-")),
            DataCell(
              Text(
                r['status'] ?? "-",
                style: TextStyle(
                  color: r['status'] == 'Present'
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataCell(
              Text("${r['shiftStart']} - ${r['shiftEnd']}"),
            ),
            DataCell(Text(formatTime(r['punchIn']?['time']))),
            DataCell(Text(formatTime(r['punchOut']?['time']))),
            DataCell(
              r['punchIn']?['image'] != null
                  ? IconButton(
                icon: const Icon(Icons.image),
                onPressed: () =>
                    showImage(r['punchIn']['image']),
              )
                  : const Text("-"),
            ),
            DataCell(
              r['punchOut']?['image'] != null
                  ? IconButton(
                icon: const Icon(Icons.image),
                onPressed: () =>
                    showImage(r['punchOut']['image']),
              )
                  : const Text("-"),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(
          color: Colors.white, // 🔥 icon color
        ),
        title: isSearching
            ? TextField(
          controller: searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Search employee...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: filterByName,
        )
            : Text("Attendance - ${widget.officeName}",style: TextStyle(color: Colors.white),),
        actions: [
          IconButton(
            icon: Icon(
              isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (isSearching) {
                  searchController.clear();
                  filteredRecords =
                      List.from(attendanceRecords);
                }
                isSearching = !isSearching;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// 📅 DATE RANGE PICKER
            ElevatedButton.icon(
              onPressed: pickDateRange,
              icon: const Icon(Icons.date_range),
              label: Text(
                selectedRange == null
                    ? "Select Date Range"
                    : "${DateFormat('dd MMM').format(selectedRange!.start)}"
                    " - "
                    "${DateFormat('dd MMM').format(selectedRange!.end)}",
              ),
            ),

            const SizedBox(height: 12),

            /// ⏳ LOADING
            if (isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )

            /// 📭 EMPTY
            else if (filteredRecords.isEmpty)
              const Expanded(
                child: Center(child: Text("No attendance found")),
              )

            /// 📊 TABLE
            else
              Expanded(
                child: buildAttendanceTable(),
              ),
          ],
        ),
      ),
    );
  }
}
