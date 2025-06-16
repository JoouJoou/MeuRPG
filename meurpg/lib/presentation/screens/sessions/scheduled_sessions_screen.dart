import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'session_model.dart';
import 'session_service.dart';
import 'session_edit_screen.dart';
import '/models/user_model.dart';

class ScheduledSessionsScreen extends StatelessWidget {
  final String tableId;
  final UserModel user;
  final String creatorId;

  const ScheduledSessionsScreen({
    super.key,
    required this.tableId,
    required this.user,
    required this.creatorId,
  });

  @override
  Widget build(BuildContext context) {
    final _service = SessionService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessões Agendadas'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<SessionModel>>(
        stream: _service.getSessionsByTable(tableId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar sessões.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = snapshot.data ?? [];

          if (sessions.isEmpty) {
            return const Center(child: Text('Nenhuma sessão agendada.'));
          }

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final formattedDate = DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(session.date);

              return ListTile(
                title: Text(session.title),
                subtitle: Text('${session.description}\n$formattedDate'),
                isThreeLine: true,
                leading: const Icon(Icons.event),

                // Exibe o menu apenas se o usuário for o criador da mesa
                trailing:
                    user.uid == creatorId
                        ? PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          SessionEditScreen(session: session),
                                ),
                              );
                            } else if (value == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('Confirmar exclusão'),
                                      content: const Text(
                                        'Tem certeza que deseja excluir esta sessão?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: const Text('Excluir'),
                                        ),
                                      ],
                                    ),
                              );

                              if (confirm == true) {
                                await _service.deleteSession(session.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sessão excluída'),
                                  ),
                                );
                              }
                            }
                          },
                          itemBuilder:
                              (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Editar'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Excluir'),
                                ),
                              ],
                        )
                        : null,
              );
            },
          );
        },
      ),
    );
  }
}
