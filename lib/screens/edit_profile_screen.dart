import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _controller = TextEditingController();
  String? error;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _controller.text = user?.username ?? '';
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) return;

    final newUsername = _controller.text.trim();

    // ❌ Username rỗng
    if (newUsername.isEmpty) {
      setState(() => error = "Username cannot be empty");
      return;
    }

    try {
      // 🔥 check username có tồn tại chưa
      final existing = await auth.getUserByUsername(newUsername);

      if (existing != null && existing.id != user.id) {
        setState(() => error = "Username already exists");
        return;
      }

      final updatedUser = user.copyWith(username: newUsername);

      await auth.updateUser(updatedUser);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Updated successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      print("UPDATE ERROR: $e");
      setState(() => error = "Update failed");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Username",
              ),
            ),

            const SizedBox(height: 20),

            if (error != null)
              Text(
                error!,
                style: const TextStyle(color: Colors.red),
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}