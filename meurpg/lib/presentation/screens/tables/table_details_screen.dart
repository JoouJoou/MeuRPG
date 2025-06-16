import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/user_model.dart';
import '../sessions/scheduled_sessions_screen.dart';
import '../sessions/session_create_screen.dart';

class TableDetailsScreen extends StatefulWidget {
  final UserModel user;
  final DocumentSnapshot tableDoc;

  const TableDetailsScreen({
    super.key,
    required this.user,
    required this.tableDoc,
  });

  @override
  State<TableDetailsScreen> createState() => _TableDetailsScreenState();
}

class _TableDetailsScreenState extends State<TableDetailsScreen> {
  late DocumentSnapshot tableSnapshot;

  @override
  void initState() {
    super.initState();
    tableSnapshot = widget.tableDoc;
  }

  Future<void> _refreshTableData() async {
    final updatedSnapshot = await tableSnapshot.reference.get();
    setState(() {
      tableSnapshot = updatedSnapshot;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = tableSnapshot.data() as Map<String, dynamic>;
    final isCreator = widget.user.uid == data['creatorId'];

    final List<dynamic> players = data['players'] ?? [];
    final int maxPlayers = data['maxPlayers'] ?? 0;
    final int vagas = maxPlayers - players.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(data['name']),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions:
            isCreator
                ? [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteTable(context),
                  ),
                ]
                : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              data['imageUrl'],
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    'Descrição:',
                    data['description'] ?? 'Sem descrição',
                  ),
                  _buildInfoRow('Sistema:', data['system'] ?? 'Desconhecido'),
                  _buildInfoRow(
                    'Local:',
                    data['locationName'] ?? 'Não definido',
                  ),
                  _buildInfoRow('Vagas:', vagas.toString()),
                  const SizedBox(height: 16),
                  isCreator
                      ? _buildCreatorActions(context)
                      : _buildMemberActions(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          text: '$title ',
          style: const TextStyle(fontWeight: FontWeight.bold),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatorActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        ElevatedButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text('Editar Informações da Mesa'),
          onPressed: () => _showEditTableSheet(context),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.group),
          label: const Text('Ver / Expulsar Jogadores'),
          onPressed: () => _showPlayersSheet(context),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.event),
          label: const Text('Agendar Sessão'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => SessionCreateScreen(
                      user: widget.user,
                      tableId: tableSnapshot.id,
                    ),
              ),
            );
          },
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.calendar_today),
          label: const Text('Ver Sessões Marcadas'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => ScheduledSessionsScreen(
                      user: widget.user,
                      tableId: tableSnapshot.id,
                      creatorId: tableSnapshot['creatorId'],
                    ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMemberActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        ElevatedButton.icon(
          icon: const Icon(Icons.event),
          label: const Text('Ver Sessões Agendadas'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => ScheduledSessionsScreen(
                      user: widget.user,
                      tableId: tableSnapshot.id,
                      creatorId: tableSnapshot['creatorId'],
                    ),
              ),
            );
          },
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.exit_to_app),
          label: const Text('Sair da Mesa'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade800,
            foregroundColor: Colors.white,
          ),
          onPressed: () => _leaveTable(context),
        ),
      ],
    );
  }

  void _showEditTableSheet(BuildContext context) {
    final data = tableSnapshot.data() as Map<String, dynamic>;

    final nameController = TextEditingController(text: data['name']);
    final descController = TextEditingController(text: data['description']);
    final systemController = TextEditingController(text: data['system']);
    final locationController = TextEditingController(
      text: data['locationName'],
    );
    final maxPlayersController = TextEditingController(
      text: (data['maxPlayers'] ?? 0).toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Editar Informações da Mesa',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome da Mesa'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                TextField(
                  controller: systemController,
                  decoration: const InputDecoration(labelText: 'Sistema'),
                ),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Local'),
                ),
                TextField(
                  controller: maxPlayersController,
                  decoration: const InputDecoration(
                    labelText: 'Número de Vagas',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar Alterações'),
                  onPressed: () async {
                    await tableSnapshot.reference.update({
                      'name': nameController.text.trim(),
                      'description': descController.text.trim(),
                      'system': systemController.text.trim(),
                      'locationName': locationController.text.trim(),
                      'maxPlayers':
                          int.tryParse(maxPlayersController.text) ?? 0,
                    });

                    Navigator.pop(context);
                    await _refreshTableData();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mesa atualizada com sucesso'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteTable(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Deletar Mesa'),
            content: const Text('Tem certeza que deseja deletar esta mesa?'),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text('Deletar'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await tableSnapshot.reference.delete();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesa deletada com sucesso')),
      );
    }
  }

  void _showPlayersSheet(BuildContext context) {
    final data = tableSnapshot.data() as Map<String, dynamic>;
    final List<dynamic> players = data['players'] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Jogadores da Mesa',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        final playerId = players[index];
                        return FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(playerId)
                                  .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const ListTile(
                                title: Text('Carregando...'),
                              );
                            }

                            final playerData =
                                snapshot.data!.data() as Map<String, dynamic>;
                            final playerName =
                                playerData['username'] ?? 'Sem nome';

                            return ListTile(
                              title: Text(playerName),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (_) => AlertDialog(
                                          title: const Text('Expulsar Jogador'),
                                          content: Text(
                                            'Deseja expulsar "$playerName" da mesa?',
                                          ),
                                          actions: [
                                            TextButton(
                                              child: const Text('Cancelar'),
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                            ),
                                            TextButton(
                                              child: const Text('Expulsar'),
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                            ),
                                          ],
                                        ),
                                  );

                                  if (confirm == true) {
                                    await tableSnapshot.reference.update({
                                      'players': FieldValue.arrayRemove([
                                        playerId,
                                      ]),
                                    });

                                    Navigator.pop(context);
                                    _showPlayersSheet(context);
                                    await _refreshTableData();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '$playerName foi expulso.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _leaveTable(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Sair da Mesa'),
            content: const Text('Tem certeza que deseja sair desta mesa?'),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text('Sair'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await tableSnapshot.reference.update({
        'players': FieldValue.arrayRemove([widget.user.uid]),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Você saiu da mesa.')));
    }
  }
}
