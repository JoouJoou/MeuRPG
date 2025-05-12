import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'firebase_options.dart'; // Gerado automaticamente depois

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MeuRPGApp());
}

class MeuRPGApp extends StatelessWidget {
  const MeuRPGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu RPG',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
