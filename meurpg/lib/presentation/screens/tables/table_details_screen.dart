/* -------------------------------------------------------------------------- */
/*  table_details_screen.dart                                                 */
/* -------------------------------------------------------------------------- */
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '/models/user_model.dart';
import '../sessions/session_create_screen.dart';
import '../sessions/scheduled_sessions_screen.dart';
import 'edit_table_screen.dart'; //  ⬅️ NOVO

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
    tableSnapshot = await tableSnapshot.reference.get();
    setState(() {});
  }

  /* ====================================================================== */
  /*                                BUILD                                   */
  /* ====================================================================== */
  @override
  Widget build(BuildContext context) {
    final data = tableSnapshot.data()! as Map<String, dynamic>;
    final isCreator = widget.user.uid == data['creatorId'];

    final players = List<String>.from(data['players'] ?? []);
    final vagas = (data['maxPlayers'] ?? 0) - players.length;

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
                  _buildInfoRow(
                    'Sistema:',
                    data['systemName'] ?? data['system'] ?? 'Desconhecido',
                  ),
                  _buildInfoRow(
                    'Local:',
                    data['locationName'] ?? 'Não definido',
                  ),
                  _buildInfoRow('Vagas:', vagas.toString()),
                  _buildJoinCodeRow(data['joinCode']),
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

  /* ====================================================================== */
  /*                              WIDGETS AUX                               */
  /* ====================================================================== */
  Widget _buildInfoRow(String title, String value) => Padding(
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

  Widget _buildJoinCodeRow(String joinCode) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 16),
    child: Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'Código de entrada: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                  text: joinCode,
                  style: const TextStyle(fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy),
          tooltip: 'Copiar código',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: joinCode));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Código copiado')));
          },
        ),
      ],
    ),
  );

  /* ====================================================================== */
  /*                          AÇÕES DO CRIADOR                              */
  /* ====================================================================== */
  Widget _buildCreatorActions(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Divider(),
      ElevatedButton.icon(
        icon: const Icon(Icons.edit),
        label: const Text('Editar Informações da Mesa'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => EditTableScreen(
                    user: widget.user,
                    tableDoc: tableSnapshot,
                  ),
            ),
          );
          _refreshTableData(); // recarrega depois da edição
        },
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

  /* ====================================================================== */
  /*                         AÇÕES DO MEMBRO                                */
  /* ====================================================================== */
  Widget _buildMemberActions(BuildContext context) => Column(
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

  /* ====================================================================== */
  /*                         EXCLUIR MESA                                   */
  /* ====================================================================== */
  void _deleteTable(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Deletar Mesa'),
            content: const Text('Tem certeza que deseja deletar esta mesa?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Deletar'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await tableSnapshot.reference.delete();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mesa deletada com sucesso')),
        );
      }
    }
  }

  /* ====================================================================== */
  /*                  LISTA / REMOVER JOGADORES (inalterado)                */
  /* ====================================================================== */
  void _showPlayersSheet(BuildContext context) {
    final data = tableSnapshot.data()! as Map<String, dynamic>;
    final players = List<String>.from(data['players'] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => DraggableScrollableSheet(
            expand: false,
            builder:
                (context, scrollController) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Jogadores da Mesa',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: players.length,
                          itemBuilder: (context, i) {
                            final id = players[i];
                            return FutureBuilder<DocumentSnapshot>(
                              future:
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(id)
                                      .get(),
                              builder: (c, snap) {
                                if (!snap.hasData) {
                                  return const ListTile(
                                    title: Text('Carregando...'),
                                  );
                                }
                                final userData =
                                    snap.data!.data() as Map<String, dynamic>;
                                final name = userData['username'] ?? 'Sem nome';
                                return ListTile(
                                  title: Text(name),
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
                                              title: const Text(
                                                'Expulsar Jogador',
                                              ),
                                              content: Text(
                                                'Deseja expulsar "$name" da mesa?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('Cancelar'),
                                                ),
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text('Expulsar'),
                                                ),
                                              ],
                                            ),
                                      );
                                      if (confirm == true) {
                                        await tableSnapshot.reference.update({
                                          'players': FieldValue.arrayRemove([
                                            id,
                                          ]),
                                        });
                                        Navigator.pop(context);
                                        _showPlayersSheet(context);
                                        await _refreshTableData();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('$name foi expulso.'),
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
                ),
          ),
    );
  }

  /* ====================================================================== */
  /*                             SAIR DA MESA                               */
  /* ====================================================================== */
  void _leaveTable(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Sair da Mesa'),
            content: const Text('Tem certeza que deseja sair desta mesa?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sair'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await tableSnapshot.reference.update({
        'players': FieldValue.arrayRemove([widget.user.uid]),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Você saiu da mesa.')));
      }
    }
  }
}
