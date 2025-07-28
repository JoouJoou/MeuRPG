import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/models/user_model.dart';

class EditTableScreen extends StatefulWidget {
  final UserModel user;
  final DocumentSnapshot tableDoc;

  const EditTableScreen({
    super.key,
    required this.user,
    required this.tableDoc,
  });

  @override
  State<EditTableScreen> createState() => _EditTableScreenState();
}

class _EditTableScreenState extends State<EditTableScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _locCtrl;
  late final TextEditingController _maxCtrl;

  String? _systemId;
  String? _systemName;

  @override
  void initState() {
    super.initState();
    final data = widget.tableDoc.data()! as Map<String, dynamic>;
    _nameCtrl = TextEditingController(text: data['name']);
    _descCtrl = TextEditingController(text: data['description']);
    _locCtrl = TextEditingController(text: data['locationName']);
    _maxCtrl = TextEditingController(
      text: (data['maxPlayers'] ?? 0).toString(),
    );

    _systemId = data['systemId'];
    _systemName = data['systemName'] ?? data['system'] ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  /* ------------------------------------------------------------------ */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Mesa'),
        backgroundColor: Colors.red.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome da Mesa'),
              ),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              const SizedBox(height: 12),

              /* -------- dropdown de sistemas do usuário -------- */
              FutureBuilder<QuerySnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('systems')
                        .where('ownerId', isEqualTo: widget.user.uid)
                        .get(),
                builder: (c, snap) {
                  if (!snap.hasData) {
                    return const LinearProgressIndicator();
                  }
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const Text(
                      'Você não possui sistemas cadastrados.',
                      style: TextStyle(color: Colors.red),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Sistema (selecione)',
                    ),
                    value: _systemId,
                    items:
                        docs
                            .map(
                              (d) => DropdownMenuItem(
                                value: d.id,
                                child: Text(
                                  (d.data() as Map<String, dynamic>)['name'] ??
                                      'Sem nome',
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      setState(() {
                        _systemId = val;
                        _systemName =
                            (docs.firstWhere((e) => e.id == val).data()
                                as Map<String, dynamic>)['name'] ??
                            '';
                      });
                    },
                  );
                },
              ),

              const SizedBox(height: 12),
              TextField(
                controller: _locCtrl,
                decoration: const InputDecoration(labelText: 'Local'),
              ),
              TextField(
                controller: _maxCtrl,
                decoration: const InputDecoration(labelText: 'Número de Vagas'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Salvar Alterações'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    await widget.tableDoc.reference.update({
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'systemId': _systemId,
      'systemName': _systemName,
      'locationName': _locCtrl.text.trim(),
      'maxPlayers': int.tryParse(_maxCtrl.text) ?? 0,
    });
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesa atualizada com sucesso')),
      );
    }
  }
}
