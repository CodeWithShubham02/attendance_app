import 'package:flutter/material.dart';
import '../controller/branch_controller.dart';
import '../model/branch_model.dart';
import 'branch_screen.dart';
import 'edit_branch_screen.dart';

class BranchListScreen extends StatefulWidget {
  final String cid;
  const BranchListScreen({super.key, required this.cid});

  @override
  State<BranchListScreen> createState() => _BranchListScreenState();
}

class _BranchListScreenState extends State<BranchListScreen> {
  final controller = BranchController();
  late Future<List<BranchModel>> future;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    future = controller.getBranches(widget.cid);
    setState(() {});
  }

  void delete(String id) async {
    final ok = await controller.deleteBranch(id);
    if (ok) refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor:Colors.blue,
          title: const Text("All Kiosk",style: TextStyle(color: Colors.white),)),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddBranchScreen(cid: widget.cid),
            ),
          );
          if (result == true) refresh();
        },
      ),
      body: FutureBuilder<List<BranchModel>>(
        future: future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.data!.isEmpty) {
            return const Center(child: Text("No branches"));
          }

          return ListView.builder(
            itemCount: snap.data!.length,
            itemBuilder: (context, i) {
              final b = snap.data![i];
              return Card(
                child: ListTile(
                  title: Text(b.branchName),
                  subtitle: Text("Distance: ${b.distance}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final res = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditBranchScreen(branch: b),
                            ),
                          );
                          if (res == true) refresh();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => delete(b.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
