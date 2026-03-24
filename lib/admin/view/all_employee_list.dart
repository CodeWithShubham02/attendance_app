import 'dart:convert';
import 'dart:io';

import 'package:aws_s3_api/s3-2006-03-01.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import '../controller/user_controller.dart';
import '../model/user_model.dart';
import 'package:http/http.dart' as http;
class UsersTableScreen extends StatefulWidget {
  const UsersTableScreen({super.key});

  @override
  State<UsersTableScreen> createState() => _UsersTableScreenState();
}

class _UsersTableScreenState extends State<UsersTableScreen> {
  final UserController controller = UserController();
  bool isLoading = true;
  List<UserModel> users = [];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    users = await controller.fetchUsers();
    filteredUsers = users;

    branchList = users
        .map((e) => e.branchName)
        .toSet()
        .toList();

    setState(() => isLoading = false);
  }
  void editUser(UserModel user) {
    showDialog(
      context: context,
      builder: (context) {
        // Create controllers for all fields
        final uidController = TextEditingController(text: user.uid);
        final cidController = TextEditingController(text: user.cid);
        final userIdController = TextEditingController(text: user.userid);
        final passwordController = TextEditingController(text: user.password);
        final userTokenController = TextEditingController(text: user.userToken);
        final userImgController = TextEditingController(text: user.userImg);
        final imeiNoController = TextEditingController(text: user.imeiNo);
        final fullNameController = TextEditingController(text: user.fullName);
        final emailController = TextEditingController(text: user.userEmail);
        final phoneController = TextEditingController(text: user.userPhone);
        final genderController = TextEditingController(text: user.gender);
        final addressController = TextEditingController(text: user.fullAddress);
        final branchIdController = TextEditingController(text: user.branchId);
        final branchNameController = TextEditingController(text: user.branchName);
        final branchDistanceController =
        TextEditingController(text: user.branchDistance);
        final branchLatController = TextEditingController(text: user.branchLat);
        final branchLongController = TextEditingController(text: user.branchLong);
        final deptIdController = TextEditingController(text: user.departmentId);
        final deptNameController =
        TextEditingController(text: user.departmentName);
        final shiftIdController = TextEditingController(text: user.shiftId);
        final shiftStartController = TextEditingController(text: user.shiftStart);
        final shiftEndController = TextEditingController(text: user.shiftEnd);
        final joiningDateController =
        TextEditingController(text: user.dateOfJoining);
        final statusController = TextEditingController(text: user.status);
        final roleController = TextEditingController(text: user.role);
        final createdAtController = TextEditingController(text: user.createdAt);

        bool isUpdating = false;

        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text("Edit User"),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                        controller: fullNameController,
                        decoration: const InputDecoration(labelText: "Full Name")),
                    TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: "Email")),
                    TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: "Phone")),
                    TextField(
                        controller: statusController,
                        decoration: const InputDecoration(labelText: "Status")),
                    TextField(
                        controller: branchNameController,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: "Branch")),
                    TextField(
                        controller: branchDistanceController,

                        decoration: const InputDecoration(labelText: "Distance")),
                    TextField(
                        controller: branchLatController,

                        decoration: const InputDecoration(labelText: "Lat")),
                    TextField(
                        controller: branchLongController,

                        decoration: const InputDecoration(labelText: "Long")),

                    TextField(
                        controller: deptNameController,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: "Department")),
                    TextField(
                        controller: shiftStartController,
                        decoration: const InputDecoration(labelText: "Shift Start")),
                    TextField(
                        controller: shiftEndController,
                        decoration: const InputDecoration(labelText: "Shift End")),
                    TextField(
                        controller: imeiNoController,
                        decoration: const InputDecoration(labelText: "IMEI No")),
                    // Add more fields if needed
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () async {
                  setState(() => isUpdating = true);
                  bool success = await UserController().updateUser(
                    uid: uidController.text,
                    cid: cidController.text,
                    userid: userIdController.text,
                    password: passwordController.text,
                    userToken: userTokenController.text,
                    userImg: userImgController.text,
                    imeiNo: imeiNoController.text,
                    fullName: fullNameController.text,
                    userEmail: emailController.text,
                    userPhone: phoneController.text,
                    gender: genderController.text,
                    fullAddress: addressController.text,
                    branchId: branchIdController.text,
                    branchName: branchNameController.text,
                    branchDistance: branchDistanceController.text,
                    branchLat: branchLatController.text,
                    branchLong: branchLongController.text,
                    departmentId: deptIdController.text,
                    departmentName: deptNameController.text,
                    shiftId: shiftIdController.text,
                    shiftStart: shiftStartController.text,
                    shiftEnd: shiftEndController.text,
                    dateOfJoining: joiningDateController.text,
                    status: statusController.text,
                    role: roleController.text,
                    createdAt: createdAtController.text,
                  );

                  setState(() => isUpdating = false);

                  if (success) {
                    Navigator.pop(context);
                    await loadUsers(); // reload table
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("User updated successfully")));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Update failed")));
                  }
                },
                child: isUpdating
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Save"),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> downloadExcel() async {
    if (users.isEmpty) {
      Get.snackbar("No Data", "No attendance data to export");
      return;
    }

    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Users'];

    // Header Row
    sheetObject.appendRow([
      TextCellValue("UID"),
      TextCellValue("USERID"),
      TextCellValue("PASSWORD"),
      TextCellValue("FULL NAME"),
      TextCellValue("IMAGE"),
      TextCellValue("OFFICE NAME"),
      TextCellValue("IMEI"),
      TextCellValue("EMAIL"),
      TextCellValue("PHONE"),
      TextCellValue("GENDER"),
      TextCellValue("ADDRESS"),
      TextCellValue("DISTANCE"),
      TextCellValue("OFFICE LAT"),
      TextCellValue("OFFICE LONG"),
      TextCellValue("USER TYPE"),
      TextCellValue("SHIFT START"),
      TextCellValue("SHIFT END"),
      TextCellValue("JOINING DATE"),
      TextCellValue("STATUS"),
      TextCellValue("ROLE"),
      TextCellValue("CREADTED"),
      TextCellValue("UPDATED"),

    ]);

    // 🔵 DATA ROWS
// 🔵 DATA ROWS
    for (var u in users) {
      sheetObject.appendRow([
        TextCellValue(u.uid ?? ""),
        TextCellValue(u.userid ?? ""),
        TextCellValue(u.password ?? ""),
        TextCellValue(u.fullName ?? ""),
        TextCellValue(u.userImg ?? ""),
        TextCellValue(u.branchName ?? ""),
        TextCellValue(u.imeiNo ?? ""),
        TextCellValue(u.userEmail ?? ""),
        TextCellValue(u.userPhone ?? ""),
        TextCellValue(u.gender ?? ""),
        TextCellValue(u.fullAddress ?? ""),
        TextCellValue(u.branchDistance ?? ""),
        TextCellValue(u.branchLat ?? ""),
        TextCellValue(u.branchLong ?? ""),
        TextCellValue(u.departmentName ?? ""),
        TextCellValue(u.shiftStart ?? ""),
        TextCellValue(u.shiftEnd ?? ""),
        TextCellValue(u.dateOfJoining ?? ""),
        TextCellValue(u.status ?? ""),
        TextCellValue(u.role ?? ""),
        TextCellValue(u.createdAt ?? ""),
        TextCellValue(u.updatedAt ?? ""),
      ]);
    }

    final fileBytes = excel.encode();
    if (fileBytes == null) return;

    final fileName =
        "USERS_LIST${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx";

    if (kIsWeb) {
      // 🌐 WEB DOWNLOAD
      final content = base64Encode(fileBytes);
      final anchor = html.AnchorElement(
        href:
        "data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$content",
      )
        ..setAttribute("download", fileName)
        ..click();

      Get.snackbar("Success", "Downloading Excel file...");
    } else {
      // 📱 ANDROID / IOS DOWNLOAD

      final directory = await getApplicationDocumentsDirectory();
      final filePath = "${directory.path}/$fileName";

      final file = File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: "USERS Report",
      );
    }
  }

  void deleteUser(UserModel user) {
    print("Delete userId: ${user.uid}");
    print("Delete userName: ${user.fullName}");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete User"),
          content: Text("Are you sure you want to delete ${user.fullName}?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // ❌ cancel
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // dialog close
                await callDeleteApi(user.uid); // ✅ API call
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }
  Future<void> callDeleteApi(String uid) async {
    try {
      final url = Uri.parse(
          "https://fms.bizipac.com/apinew/attendance/delete_user.php");

      final response = await http.post(
        url,
        body: {
          "uid": uid,
        },
      );

      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User deleted successfully")),
          );
          setState(() {
            loadUsers();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "Delete failed")),
          );
        }
      }
    } catch (e) {
      print("Delete Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    }
  }


  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  Set<String> selectedBranches = {};
  List<UserModel> filteredUsers = [];
  List<String> branchList = [];

  void applyBranchFilter() {
    setState(() {
      if (selectedBranches.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users
            .where((u) => selectedBranches.contains(u.branchName))
            .toList();
      }
    });
  }
  void showBranchFilter() {
    Set<String> tempSelected = Set.from(selectedBranches);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Filter by Branch"),
          content: SizedBox(
            width: 300,
            height: 400,
            child: ListView(
              children: branchList.map((branch) {
                return CheckboxListTile(
                  title: Text(branch),
                  value: tempSelected.contains(branch),
                  onChanged: (val) {
                    if (val == true) {
                      tempSelected.add(branch);
                    } else {
                      tempSelected.remove(branch);
                    }
                    setState(() {});
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                selectedBranches.clear();
                applyBranchFilter();
                Navigator.pop(context);
              },
              child: const Text("Clear"),
            ),
            ElevatedButton(
              onPressed: () {
                selectedBranches = tempSelected;
                applyBranchFilter();
                Navigator.pop(context);
              },
              child: const Text("Apply"),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.blue,
          iconTheme: IconThemeData(color: Colors.white),
          title: const Text("All Users",style: TextStyle(color: Colors.white),),
      actions: [
        IconButton(onPressed: (){
          //download the excel file
          downloadExcel();

        }, icon:Icon(Icons.download))
      ],),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        trackVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: Scrollbar(
            controller: _verticalController,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: _verticalController,
              scrollDirection: Axis.vertical,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width,
                ),
                child: DataTable(
                  columnSpacing: 20,
                  headingRowColor: MaterialStateProperty.all(
                    Colors.grey.shade300,
                  ),
                  border: TableBorder.all(
                    color: Colors.black54,
                    width: 1,
                  ),
                  columns:  [
                    DataColumn(label: Text("Action")),
                    DataColumn(label: Text("UID")),
                    DataColumn(label: Text("UserID")),
                    DataColumn(label: Text("Password")),
                DataColumn(
                  label: Row(
                    children: [
                      const Text("Office Name"),
                      IconButton(
                        icon: Icon(
                          Icons.filter_list,
                          size: 18,
                          color: selectedBranches.isNotEmpty
                              ? Colors.blue
                              : Colors.grey,
                        ),
                        onPressed: showBranchFilter,
                      ),
                    ],
                  ),
                ),
                    DataColumn(label: Text("Status")),
                    DataColumn(label: Text("Full Name")),
                    DataColumn(label: Text("Image")),
                    DataColumn(label: Text("IMEI")),

                    DataColumn(label: Text("Email")),
                    DataColumn(label: Text("Phone")),
                    DataColumn(label: Text("Gender")),
                    DataColumn(label: Text("Address")),
                    DataColumn(label: Text("Distance")),
                    DataColumn(label: Text("Lat")),
                    DataColumn(label: Text("Long")),
                    DataColumn(label: Text("User Type")),
                    DataColumn(label: Text("Shift Start")),
                    DataColumn(label: Text("Shift End")),
                    DataColumn(label: Text("Joining Date")),

                    DataColumn(label: Text("Role")),
                    DataColumn(label: Text("Created At")),
                    DataColumn(label: Text("Updated At")),
                  ],
                  rows: filteredUsers.map((u) {
                    return DataRow(cells: [
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => editUser(u),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteUser(u),
                          ),
                        ],
                      )),
                      DataCell(Text(u.uid)),
                     // DataCell(Text(u.cid)),
                      DataCell(Text(u.userid)),
                      DataCell(Text(u.password)),
                      DataCell(Text(u.branchName)),
                      DataCell(Text(
                        u.status,
                        style: TextStyle(
                          color: u.status.toLowerCase() == 'active'
                              ? Colors.green
                              : Colors.red,
                        ),
                      )),
                      DataCell(Text(u.fullName)),
                      //DataCell(Text(u.userToken)),
                      DataCell(
                        u.userImg != null &&
                            u.userImg.toString().isNotEmpty
                            ? Image.network(
                          u.userImg,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                        )
                            : const Icon(Icons.image_not_supported),
                      ),
                      DataCell(Text(u.imeiNo)),

                      DataCell(Text(u.userEmail)),
                      DataCell(Text(u.userPhone)),
                      DataCell(Text(u.gender)),
                      DataCell(Text(u.fullAddress)),
                      //DataCell(Text(u.branchId)),
                      DataCell(Text(u.branchDistance)),
                      DataCell(Text(u.branchLat)),
                      DataCell(Text(u.branchLong)),
                      //DataCell(Text(u.departmentId)),
                      DataCell(Text(u.departmentName)),
                      //DataCell(Text(u.shiftId)),
                      DataCell(Text(u.shiftStart)),
                      DataCell(Text(u.shiftEnd)),
                      DataCell(Text(u.dateOfJoining)),

                      DataCell(Text(u.role)),

                      DataCell(Text(u.createdAt)),
                      DataCell(Text(u.updatedAt)),
                    ]);
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
