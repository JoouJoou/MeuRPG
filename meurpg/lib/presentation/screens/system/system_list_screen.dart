/* -------------------------------------------------------------------------- */
/*  system_list_screen.dart                                                   */
/* -------------------------------------------------------------------------- */
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/models/user_model.dart';
import 'create_system.dart';

class SystemListScreen extends StatelessWidget {
  final UserModel user;
  const SystemListScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final uid = user.uid;

    /* 🔸 somente o filtro por ownerId – sem orderBy (evita índice composto) */
    final systemsStream =
        FirebaseFirestore.instance
            .collection('systems')
            .where('ownerId', isEqualTo: uid)
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Sistemas'),
        backgroundColor: Colors.red.shade700,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red.shade700,
        icon: const Icon(Icons.add),
        label: const Text('Novo Sistema'),
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreateSystemScreen(user: user)),
            ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: systemsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          /* 🔸 ordena localmente por createdAt desc se existir */
          docs.sort((a, b) {
            final ta = a['createdAt'];
            final tb = b['createdAt'];
            if (ta is Timestamp && tb is Timestamp) {
              return tb.compareTo(ta); // descendente
            }
            return 0;
          });

          if (docs.isEmpty) {
            return const Center(child: Text('Nenhum sistema criado ainda.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data()! as Map<String, dynamic>;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    data['name'] ?? 'Sem nome',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(data['description'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editSystem(context, doc),
                      ),
                      IconButton(
                        tooltip: 'Excluir',
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteSystem(context, doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /* --------------------------- editar --------------------------- */
  void _editSystem(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final nameCtrl = TextEditingController(text: data['name']);
    final descCtrl = TextEditingController(text: data['description']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Editar Sistema',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                  ),
                  onPressed: () async {
                    await doc.reference.update({
                      'name': nameCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sistema atualizado com sucesso'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  /* -------------------------- excluir -------------------------- */
  void _deleteSystem(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Excluir Sistema'),
            content: const Text('Tem certeza que deseja excluir este sistema?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('systems').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sistema excluído com sucesso')),
      );
    }
  }
}
