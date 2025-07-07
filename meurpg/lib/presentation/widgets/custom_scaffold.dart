import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth/login_screen.dart';
import '/models/user_model.dart';

class CustomScaffold extends StatelessWidget {
  final UserModel user;
  final String selectedAvatar;
  final VoidCallback onAvatarTap;
  final VoidCallback onSettingsTap;
  final Widget body;

  const CustomScaffold({
    super.key,
    required this.user,
    required this.selectedAvatar,
    required this.onAvatarTap,
    required this.onSettingsTap,
    required this.body,
  });

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.red.shade700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage(
                      'assets/images/$selectedAvatar',
                    ),
                    radius: 30,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Meu Perfil'),
              onTap: onSettingsTap,
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair da conta'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        title: Builder(
          builder:
              (context) => InkWell(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: const Text(
                  'MeuRPG',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
        ),
        actions: [
          InkWell(
            onTap: onSettingsTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(
                child: Text(
                  user.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          InkWell(
            onTap: onAvatarTap,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                backgroundImage: AssetImage('assets/images/$selectedAvatar'),
              ),
            ),
          ),
        ],
      ),
      body: body,
    );
  }
}
