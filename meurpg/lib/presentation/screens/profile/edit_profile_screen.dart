import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _bioController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBio();
  }

  Future<void> _loadBio() async {
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['bio'] != null) {
        _bioController.text = data['bio'];
      }
    }
  }

  Future<void> _saveBio() async {
    setState(() {
      isSaving = true;
    });

    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'bio': _bioController.text.trim(),
      }, SetOptions(merge: true));
    }

    setState(() {
      isSaving = false;
    });

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Bio')),
      body:
          isSaving
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _bioController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Biografia',
                        border: OutlineInputBorder(),
                        hintText: 'Escreva algo sobre você...',
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveBio,
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
              ),
    );
  }
}
