import 'package:flutter/material.dart';
import '../controller/branch_controller.dart';

class AddBranchScreen extends StatefulWidget {
  final String cid;

  const AddBranchScreen({super.key, required this.cid});

  @override
  State<AddBranchScreen> createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends State<AddBranchScreen> {
  final BranchController controller = BranchController();

  final nameCtrl = TextEditingController();
  final distanceCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final longCtrl = TextEditingController();

  bool isLoading = false;

  void saveBranch() async {
    setState(() => isLoading = true);

    final success = await controller.addBranch(
      branchName: nameCtrl.text.trim(),
      distance: distanceCtrl.text.trim(),
      cid: widget.cid,
      lat: latCtrl.text.trim(),
      long: longCtrl.text.trim(),
    );

    setState(() => isLoading = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add branch")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(  backgroundColor: Colors.blue,title: const Text("Add Kiosk",style: TextStyle(color: Colors.white),)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Branch Name"),
            ),
            TextField(
              controller: distanceCtrl,
              decoration: const InputDecoration(labelText: "Distance"),
            ),
            TextField(
              controller: latCtrl,
              decoration: const InputDecoration(labelText: "Latitude"),
            ),
            TextField(
              controller: longCtrl,
              decoration: const InputDecoration(labelText: "Longitude"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : saveBranch,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}
