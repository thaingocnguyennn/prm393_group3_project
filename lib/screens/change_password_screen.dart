import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/database_helper.dart'; // 👈 thêm dòng này
import '../utils/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final oldPass = TextEditingController();
  final newPass = TextEditingController();

  String? error;
  bool isLoading = false;

  Future<void> _change() async {
    setState(() {
      error = null;
    });

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) return;

    // ✅ Validate input
    if (oldPass.text.trim().isEmpty ||
        newPass.text.trim().isEmpty) {
      setState(() => error = "Please fill all fields");
      return;
    }

    if (newPass.text.trim().length < 4) {
      setState(() => error = "Password must be at least 4 characters");
      return;
    }

    setState(() => isLoading = true);

    try {
      // ✅ Lấy dữ liệu mới nhất từ DB (fix lỗi sai password)
      final db = DatabaseHelper();
      final freshUser =
      await db.getUserByUsername(user.username);

      if (freshUser == null ||
          oldPass.text.trim() != freshUser.password.trim()) {
        setState(() {
          error = "Wrong old password";
          isLoading = false;
        });
        return;
      }

      // ✅ Update password
      await auth.changePassword(newPass.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password changed successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        error = "Something went wrong";
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    oldPass.dispose();
    newPass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: oldPass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Old Password",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "New Password",
              ),
            ),
            const SizedBox(height: 20),

            if (error != null)
              Text(
                error!,
                style: const TextStyle(color: Colors.red),
              ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _change,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Change Password"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}