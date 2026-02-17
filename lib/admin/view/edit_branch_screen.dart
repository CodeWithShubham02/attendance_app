import 'package:flutter/material.dart';
import '../controller/branch_controller.dart';
import '../model/branch_model.dart';

class EditBranchScreen extends StatefulWidget {
  final BranchModel branch;
  const EditBranchScreen({super.key, required this.branch});

  @override
  State<EditBranchScreen> createState() => _EditBranchScreenState();
}

class _EditBranchScreenState extends State<EditBranchScreen> {
  final controller = BranchController();

  late TextEditingController nameCtrl;
  late TextEditingController distCtrl;
  late TextEditingController latCtrl;
  late TextEditingController longCtrl;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.branch.branchName);
    distCtrl = TextEditingController(text: widget.branch.distance);
    latCtrl = TextEditingController(text: widget.branch.lat);
    longCtrl = TextEditingController(text: widget.branch.long);
  }

  void update() async {
    setState(() => isLoading = true);

    final ok = await controller.updateBranch({
      "id": widget.branch.id,
      "branch_name": nameCtrl.text,
      "distance": distCtrl.text,
      "branch_lat": latCtrl.text,
      "branch_long": longCtrl.text,
    });

    setState(() => isLoading = false);

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Update failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Branch")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Branch Name")),
            TextField(controller: distCtrl, decoration: const InputDecoration(labelText: "Distance")),
            TextField(controller: latCtrl, decoration: const InputDecoration(labelText: "Latitude")),
            TextField(controller: longCtrl, decoration: const InputDecoration(labelText: "Longitude")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : update,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }
}
