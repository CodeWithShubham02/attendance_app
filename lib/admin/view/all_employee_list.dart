import 'package:flutter/material.dart';
import '../controller/user_controller.dart';
import '../model/user_model.dart';

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


  void deleteUser(UserModel user) {
    print("Delete user: ${user.fullName}");
    // TODO: Call delete API and refresh table
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users List")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
            child: DataTable(
              headingRowColor:
              MaterialStateProperty.all(Colors.grey.shade300),
              border: TableBorder.all(
                color: Colors.black54,
                width: 1,
              ),
              columns: const [
                DataColumn(label: Text("Action")),
                DataColumn(label: Text("UID")),
                DataColumn(label: Text("CID")),
                DataColumn(label: Text("UserID")),
                DataColumn(label: Text("Password")),
                DataColumn(label: Text("Token")),
                DataColumn(label: Text("Image")),
                DataColumn(label: Text("IMEI")),
                DataColumn(label: Text("Full Name")),
                DataColumn(label: Text("Email")),
                DataColumn(label: Text("Phone")),
                DataColumn(label: Text("Gender")),
                DataColumn(label: Text("Address")),
                DataColumn(label: Text("Branch ID")),
                DataColumn(label: Text("Branch Name")),
                DataColumn(label: Text("Distance")),
                DataColumn(label: Text("Lat")),
                DataColumn(label: Text("Long")),
                DataColumn(label: Text("Dept ID")),
                DataColumn(label: Text("Dept Name")),
                DataColumn(label: Text("Shift ID")),
                DataColumn(label: Text("Shift Start")),
                DataColumn(label: Text("Shift End")),
                DataColumn(label: Text("Joining Date")),
                DataColumn(label: Text("Status")),
                DataColumn(label: Text("Role")),
                DataColumn(label: Text("Created At")),
                DataColumn(label: Text("Updated At")),
              ],
              rows: users.map((u) {
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
                  DataCell(Text(u.cid)),
                  DataCell(Text(u.userid)),
                  DataCell(Text(u.password)),
                  DataCell(Text(u.userToken)),
                  //DataCell(Text(u.userImg)),
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
                  DataCell(Text(u.fullName)),
                  DataCell(Text(u.userEmail)),
                  DataCell(Text(u.userPhone)),
                  DataCell(Text(u.gender)),
                  DataCell(Text(u.fullAddress)),
                  DataCell(Text(u.branchId)),
                  DataCell(Text(u.branchName)),
                  DataCell(Text(u.branchDistance)),
                  DataCell(Text(u.branchLat)),
                  DataCell(Text(u.branchLong)),
                  DataCell(Text(u.departmentId)),
                  DataCell(Text(u.departmentName)),
                  DataCell(Text(u.shiftId)),
                  DataCell(Text(u.shiftStart)),
                  DataCell(Text(u.shiftEnd)),
                  DataCell(Text(u.dateOfJoining)),
                  DataCell(Text(
                    u.status,
                    style: TextStyle(
                      color: u.status.toLowerCase() == 'active'
                          ? Colors.green
                          : Colors.red,
                    ),
                  )),
                  DataCell(Text(u.role)),
                  DataCell(Text(u.createdAt)),
                  DataCell(Text(u.updatedAt)),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
