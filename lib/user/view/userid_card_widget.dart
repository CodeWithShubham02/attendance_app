import 'package:flutter/material.dart';
import 'package:joizone/admin/model/user_model.dart';

class UserIdCardDialog extends StatelessWidget {
  final UserModel user;

  const UserIdCardDialog({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// 🔴 Header
            const Text(
              "ID CARD",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 12),

            /// 🖼 Profile Image
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(user.userImg),
              onBackgroundImageError: (_, __) {},
            ),

            const SizedBox(height: 10),

            /// 👤 Name
            Text(
              user.fullName ?? "No Name",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            /// 🆔 User ID
            Text(
              "ID: ${user.userid ?? '-'}",
              style: const TextStyle(color: Colors.white70),
            ),

            const Divider(color: Colors.white),

            /// 📋 Details

            infoRow("Mobile", user.userPhone),
            infoRow("Email", user.userEmail),
            infoRow("Role", user.role),
            infoRow("Address", user.fullAddress),

            const SizedBox(height: 10),

            /// ❌ Close Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      ),
    );
  }

  Widget infoRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Flexible(
            child: Text(
              value ?? "-",
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}