import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool showPassword = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("No user")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.person, size: 80),
            ),
            const SizedBox(height: 20),

            // 👤 Username
            Text(
              "Username: ${user.username}",
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 10),

            // 🔐 Password
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Password: ${showPassword ? user.password : "••••••"}",
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    showPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => showPassword = !showPassword);
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditProfileScreen(),
                  ),
                );
              },
              child: const Text("Edit Profile"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              },
              child: const Text("Change Password"),
            ),
          ],
        ),
      ),
    );
  }
}