import 'package:flutter/material.dart';

import '../controller/attendance_detail_controller.dart';
import '../model/attendance_detail_model.dart';

class UserAttendanceDetailScreen extends StatefulWidget {
  const UserAttendanceDetailScreen({super.key});

  @override
  State<UserAttendanceDetailScreen> createState() =>
      _UserAttendanceDetailScreenState();
}

class _UserAttendanceDetailScreenState
    extends State<UserAttendanceDetailScreen> {

  final uidController = TextEditingController();
  final dateController = TextEditingController();

  AttendanceMultiModel? attendance;
  bool isLoading = false;

  Future<void> searchAttendance() async {
    setState(() => isLoading = true);

    final result = await AttendanceMultiService.fetchAttendance(
      uidController.text,
      dateController.text,
    );

    setState(() {
      attendance = result;
      isLoading = false;
    });
  }

  void openSearchDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Search Attendance"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: uidController,
              decoration: const InputDecoration(labelText: "Enter UID"),
            ),
            TextField(
              controller: dateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Select Date",
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );

                if (pickedDate != null) {
                  String formattedDate =
                      "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";

                  setState(() {
                    dateController.text = formattedDate;
                  });
                }
              },
            ),

          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              searchAttendance();
            },
            child: const Text("Search"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Details"),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: openSearchDialog,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : attendance == null
          ? const Center(child: Text("Search User Attendance"))
          : Column(
        children: [

          // 🔥 SUMMARY CARD
          Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              title: Text(
                "Total Punches: ${attendance!.totalPunches}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle:
              Text("Net Working: ${attendance!.netWorkingHours}"),
            ),
          ),

          // 🔥 LIST OF PUNCHES
          Expanded(
            child: ListView.builder(
              itemCount: attendance!.punches.length,
              itemBuilder: (context, index) {
                final punch = attendance!.punches[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [

                        Text("Punch ${index + 1}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),

                        const SizedBox(height: 8),

                        Text("Punch In: ${punch.punchIn}"),
                        Text("Remark: ${punch.punchInRemark}"),

                        if (punch.punchInImage.isNotEmpty)
                          Image.network(
                            "${punch.punchInImage}",
                            height: 120,
                          ),

                        const Divider(),

                        Text("Punch Out: ${punch.punchOut}"),
                        Text("Remark: ${punch.punchOutRemark}"),

                        if (punch.punchOutImage.isNotEmpty)
                          Image.network(
                            "${punch.punchOutImage}",
                            height: 120,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
