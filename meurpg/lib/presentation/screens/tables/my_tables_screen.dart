import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '/models/user_model.dart';
import '../tables/table_details_screen.dart';

class MyTablesScreen extends StatelessWidget {
  final UserModel user;
  const MyTablesScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final uid = user.uid;

    /* ------------------------- streams de mesas ------------------------- */
    final joinedTables$ =
        FirebaseFirestore.instance
            .collection('tables')
            .where('players', arrayContains: uid)
            .snapshots();

    final createdTables$ =
        FirebaseFirestore.instance
            .collection('tables')
            .where('creatorId', isEqualTo: uid)
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Mesas'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<List<QueryDocumentSnapshot>>(
        stream: Rx.combineLatest2<
          QuerySnapshot,
          QuerySnapshot,
          List<QueryDocumentSnapshot>
        >(createdTables$, joinedTables$, (created, joined) {
          final createdDocs = created.docs;
          final joinedDocs =
              joined.docs.where((d) => d['creatorId'] != uid).toList();
          return [...createdDocs, ...joinedDocs];
        }),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!;
          if (docs.isEmpty) {
            return const Center(
              child: Text('Você ainda não participa de nenhuma mesa.'),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final creatorId = doc['creatorId'];
              final systemLabel =
                  doc['systemName'] ?? doc['system'] ?? 'Desconhecido';

              return Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.network(
                        doc['imageUrl'],
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc['name'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            doc['description'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sistema: $systemLabel',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 6),
                          /* -------- nome do mestre -------- */
                          FutureBuilder<DocumentSnapshot>(
                            future:
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(creatorId)
                                    .get(),
                            builder: (context, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Text('Carregando mestre…');
                              }
                              if (!snap.hasData || !snap.data!.exists) {
                                return const Text('Mestre não encontrado');
                              }
                              final data =
                                  snap.data!.data() as Map<String, dynamic>;
                              final master = data['username'] ?? 'Sem nome';
                              return Text(
                                'Mestre: $master',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => TableDetailsScreen(
                                          user: user,
                                          tableDoc: doc,
                                        ),
                                  ),
                                );
                              },
                              child: const Text('Ver Mesa'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
