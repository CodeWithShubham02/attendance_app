import 'package:flutter/material.dart';
import 'package:joizone/user/model/client_form_report_model.dart';
import '../controller/form_reports_controller.dart';

class AllFormReportScreen extends StatefulWidget {
  const AllFormReportScreen({super.key});

  @override
  State<AllFormReportScreen> createState() => _AllFormReportScreenState();
}

class _AllFormReportScreenState extends State<AllFormReportScreen> {

  late Future<List<ClientFormReportModel>> reportsFuture;

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    reportsFuture = ReportController.fetchReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Client Form Reports")),
      body: FutureBuilder<List<ClientFormReportModel>>(
        future: reportsFuture,
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No reports found"));
          }

          final reports = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(10),
            child: Card(
              elevation: 4,
              child: Scrollbar(
                controller: _verticalController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _verticalController,
                  child: Scrollbar(
                    controller: _horizontalController,
                    thumbVisibility: true,
                    notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.horizontal,
                    child: SingleChildScrollView(
                      controller: _horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 16,
                        headingRowHeight: 48,
                        dataRowHeight: 70,
                        headingRowColor: MaterialStateProperty.all(
                          Colors.grey.shade200,
                        ),
                        columns: const [
                          DataColumn(label: Text("Action")),
                          DataColumn(label: Text("UID")),
                          DataColumn(label: Text("User ID")),
                          DataColumn(label: Text("User Name")),
                          DataColumn(label: Text("City Name")),
                          DataColumn(label: Text("Report Date")),
                          DataColumn(label: Text("Report Time")),
                          DataColumn(label: Text("Application No")),
                          DataColumn(label: Text("Relation")),
                          DataColumn(label: Text("Variant")),
                          DataColumn(label: Text("Status")),
                          DataColumn(label: Text("Remarks")),
                          DataColumn(label: Text("Contact No")),
                          DataColumn(label: Text("Images")),
                          DataColumn(label: Text("GPS Location")),
                          DataColumn(label: Text("Kiosk Name")),
                          DataColumn(label: Text("Created At")),
                        ],
                        rows: reports.map<DataRow>((report) {
                          return DataRow(
                            cells: [

                              // Action
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.settings),
                                  onPressed: () {
                                    debugPrint(report.uid.toString());
                                  },
                                ),
                              ),

                              DataCell(Text(report.uid.toString())),
                              DataCell(Text(report.userId)),
                              DataCell(Text(report.userName)),
                              DataCell(Text(report.cityName)),
                              DataCell(Text(report.reportDate)),
                              DataCell(Text(report.reportTime)),
                              DataCell(Text(report.applicationNo)),
                              DataCell(Text(report.relation)),
                              DataCell(Text(report.variant)),

                              // Status Color
                              DataCell(
                                Text(
                                  report.status,
                                  style: TextStyle(
                                    color: report.status.toLowerCase() == "approved"
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              DataCell(Text(report.remarks)),
                              DataCell(Text(report.contactNo)),

                              // 🔥 Multiple Images
                              DataCell(
                                report.imageUrls.isNotEmpty
                                    ? SizedBox(
                                  width: 150,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: report.imageUrls.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Image.network(
                                            report.imageUrls[index],
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                                    : const Icon(Icons.image_not_supported),
                              ),

                              DataCell(Text(report.gpsLocation)),
                              DataCell(Text(report.kioskName)),
                              DataCell(Text(report.createdAt)),
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
        },
      ),
    );
  }
}
