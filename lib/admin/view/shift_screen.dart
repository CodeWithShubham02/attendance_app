import 'package:flutter/material.dart';
import '../controller/shift_controller.dart';
import '../model/shift_model.dart';

class ShiftScreen extends StatefulWidget {
  final String cid;
  const ShiftScreen({required this.cid});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  final ShiftController controller = ShiftController();
  List<ShiftModel> shifts = [];
  bool isLoading = true;

  final startCtrl = TextEditingController();
  final endCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadShifts();
  }

  Future<void> loadShifts() async {
    final data = await controller.fetchShifts(widget.cid);
    setState(() {
      shifts = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shifts"),
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: shifts.length,
        itemBuilder: (context, index) {
          final shift = shifts[index];
          return Card(
            child: ListTile(
              title: Text(
                  "${shift.shiftStart} - ${shift.shiftEnd}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditDialog(shift),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteShift(shift.shiftId),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddDialog() {
    startCtrl.clear();
    endCtrl.clear();

    showDialog(
      context: context,
      builder: (_) => _shiftDialog(
        title: "Add Shift",
        onSave: () async {
          final success = await controller.addShift(
            widget.cid,
            startCtrl.text,
            endCtrl.text,
          );
          if (success) {
            Navigator.pop(context);
            loadShifts();
          }
        },
      ),
    );
  }

  void _showEditDialog(ShiftModel shift) {
    startCtrl.text = shift.shiftStart;
    endCtrl.text = shift.shiftEnd;

    showDialog(
      context: context,
      builder: (_) => _shiftDialog(
        title: "Edit Shift",
        onSave: () async {
          final success = await controller.updateShift(
            shift.shiftId,
            startCtrl.text,
            endCtrl.text,
          );
          if (success) {
            Navigator.pop(context);
            loadShifts();
          }
        },
      ),
    );
  }

  Widget _shiftDialog(
      {required String title, required VoidCallback onSave}) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: startCtrl,
            decoration:
            const InputDecoration(labelText: "Start (HH:mm)"),
          ),
          TextField(
            controller: endCtrl,
            decoration:
            const InputDecoration(labelText: "End (HH:mm)"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(onPressed: onSave, child: const Text("Save")),
      ],
    );
  }

  void _deleteShift(String shiftId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Shift"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(
            child: const Text("No"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text("Yes"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await controller.deleteShift(shiftId);
      loadShifts();
    }
  }
}
