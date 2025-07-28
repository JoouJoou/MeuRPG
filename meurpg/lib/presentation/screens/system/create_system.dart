import 'package:flutter/material.dart';
import '/models/system_model.dart';
import '/models/user_model.dart';
import 'system_service.dart';

class CreateSystemScreen extends StatefulWidget {
  final UserModel user;

  const CreateSystemScreen({super.key, required this.user});

  @override
  State<CreateSystemScreen> createState() => _CreateSystemScreenState();
}

class _CreateSystemScreenState extends State<CreateSystemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _service = SystemService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Sistema'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome do Sistema'),
                validator:
                    (v) =>
                        v == null || v.trim().isEmpty ? 'Informe o nome' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Salvar Sistema'),
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* ------------------------------- SALVAR ------------------------------------- */
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final newSystem = SystemModel(
        id: '', // gerado automaticamente
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        createdAt: DateTime.now(),
        ownerId: widget.user.uid,
      );

      await _service.createSystem(newSystem);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sistema criado com sucesso!')),
      );
    }
  }
}
