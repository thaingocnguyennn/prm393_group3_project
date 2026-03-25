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

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _controller = TextEditingController();

  String? error;

  @override
  void initState() {
    super.initState();

    // lấy username hiện tại
    final user = context.read<AuthProvider>().currentUser;
    _controller.text = user?.username ?? '';
  }

  // validate username
  String? _validateUsername(String? value) {

    if (value == null || value.trim().isEmpty) {
      return "Username cannot be empty";
    }

    if (value.length < 3) {
      return "Username must be at least 3 characters";
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return "Only letters, numbers and _ allowed";
    }

    return null;
  }

  Future<void> _save() async {

    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) return;

    final newUsername = _controller.text.trim();

    try {

      // kiểm tra username đã tồn tại chưa
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
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            children: [

              /// Username input
              TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                ),
                validator: _validateUsername,
              ),

              const SizedBox(height: 20),

              if (error != null)
                Text(
                  error!,
                  style: const TextStyle(color: Colors.red),
                ),

              const SizedBox(height: 20),

              /// Save button
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
      ),
    );
  }
}