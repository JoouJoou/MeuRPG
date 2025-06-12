import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/user_model.dart';
import 'package:rxdart/rxdart.dart';
import '../tables/table_details_screen.dart';

class MyTablesScreen extends StatelessWidget {
  final UserModel user;

  const MyTablesScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final userId = user.uid;

    final tablesStream =
        FirebaseFirestore.instance
            .collection('tables')
            .where('players', arrayContains: userId)
            .snapshots();

    final createdTablesStream =
        FirebaseFirestore.instance
            .collection('tables')
            .where('creatorId', isEqualTo: userId)
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Mesas'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder(
        stream: Rx.combineLatest2<
          QuerySnapshot,
          QuerySnapshot,
          List<QueryDocumentSnapshot>
        >(createdTablesStream, tablesStream, (createdSnapshot, joinedSnapshot) {
          final createdDocs = createdSnapshot.docs;
          final joinedDocs =
              joinedSnapshot.docs
                  .where((doc) => doc['creatorId'] != userId)
                  .toList();

          return [...createdDocs, ...joinedDocs];
        }),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data!;

          if (allDocs.isEmpty) {
            return const Center(
              child: Text('Você ainda não participa de nenhuma mesa.'),
            );
          }

          return ListView.builder(
            itemCount: allDocs.length,
            itemBuilder: (context, index) {
              final doc = allDocs[index];
              final creatorId = doc['creatorId'];

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
                            'Sistema: ${doc['system']}',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 6),
                          // Aqui vamos buscar o nome do mestre:
                          FutureBuilder<DocumentSnapshot>(
                            future:
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(creatorId)
                                    .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Text('Carregando mestre...');
                              }
                              if (!snapshot.hasData || !snapshot.data!.exists) {
                                return const Text('Mestre não encontrado');
                              }
                              final userData =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              final masterName =
                                  userData['username'] ?? 'Sem nome';
                              return Text(
                                'Mestre: $masterName',
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                foregroundColor: Colors.white,
                              ),
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
