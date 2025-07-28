import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '/models/user_model.dart';

class SearchTablesScreen extends StatefulWidget {
  final UserModel user;
  const SearchTablesScreen({super.key, required this.user});

  @override
  State<SearchTablesScreen> createState() => _SearchTablesScreenState();
}

class _SearchTablesScreenState extends State<SearchTablesScreen> {
  /* ------------------ filtros / busca ------------------ */
  String searchName = '';
  double maxDistanceKm = 50;
  int minVagas = 1;

  /* ------------------ localização / dados ------------------ */
  double? userLatitude;
  double? userLongitude;
  List<QueryDocumentSnapshot> allTables = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /* ------------------ carga inicial ------------------ */
  Future<void> _loadData() async {
    await _determinePosition();
    await _loadTables();
    setState(() {});
  }

  Future<void> _determinePosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever)
      return;

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    userLatitude = pos.latitude;
    userLongitude = pos.longitude;
  }

  Future<void> _loadTables() async {
    final snap =
        await FirebaseFirestore.instance
            .collection('tables')
            .where('isPrivate', isEqualTo: false)
            .get();
    allTables = snap.docs;
  }

  /* ------------------ util distância ------------------ */
  double _deg2rad(double d) => d * pi / 180;
  double _distanceKm(lat1, lon1, lat2, lon2) {
    const r = 6371;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  @override
  Widget build(BuildContext context) {
    /* ------------------ aplica filtros ------------------ */
    final filtered =
        allTables.where((doc) {
            final data = doc.data()! as Map<String, dynamic>;
            final players = List<String>.from(data['players'] ?? []);

            if (searchName.isNotEmpty &&
                !data['name'].toString().toLowerCase().contains(
                  searchName.toLowerCase(),
                ))
              return false;

            if (players.contains(widget.user.uid)) return false;

            final vagas = (data['maxPlayers'] ?? 0) - players.length;
            if (vagas < minVagas) return false;

            return true;
          }).toList()
          ..sort((a, b) {
            if (userLatitude == null || userLongitude == null) return 0;
            final aData = a.data()! as Map<String, dynamic>;
            final bData = b.data()! as Map<String, dynamic>;
            final da = _distanceKm(
              userLatitude!,
              userLongitude!,
              aData['latitude'] ?? 0,
              aData['longitude'] ?? 0,
            );
            final db = _distanceKm(
              userLatitude!,
              userLongitude!,
              bData['latitude'] ?? 0,
              bData['longitude'] ?? 0,
            );
            return da.compareTo(db);
          });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Mesas Públicas'),
        backgroundColor: Colors.red.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /* ---------------- busca por nome ---------------- */
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar pelo nome da mesa',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => searchName = v),
            ),
            const SizedBox(height: 10),

            /* ---------------- filtro vagas ---------------- */
            Row(
              children: [
                const Text('Vagas mínimas:'),
                const SizedBox(width: 10),
                DropdownButton<int>(
                  value: minVagas,
                  items: List.generate(
                    10,
                    (i) =>
                        DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                  ),
                  onChanged: (v) => setState(() => minVagas = v ?? 1),
                ),
              ],
            ),
            const SizedBox(height: 12),

            /* ---------------- lista ---------------- */
            Expanded(
              child:
                  filtered.isEmpty
                      ? const Center(child: Text('Nenhuma mesa encontrada.'))
                      : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final doc = filtered[i];
                          final data = doc.data()! as Map<String, dynamic>;
                          final players = List<String>.from(
                            data['players'] ?? [],
                          );
                          final vagas =
                              (data['maxPlayers'] ?? 0) - players.length;

                          double? distKm;
                          if (userLatitude != null && userLongitude != null) {
                            distKm = _distanceKm(
                              userLatitude!,
                              userLongitude!,
                              data['latitude'] ?? 0,
                              data['longitude'] ?? 0,
                            );
                          }

                          final sistema =
                              data['systemName'] ?? data['system'] ?? '-';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((data['imageUrl'] ?? '').isNotEmpty)
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: Image.network(
                                      data['imageUrl'],
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data['description'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Sistema: $sistema',
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Local: ${data['locationName'] ?? '-'}',
                                      ),
                                      if (distKm != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          'Distância: ${distKm.toStringAsFixed(1)} km',
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      Text(
                                        'Vagas disponíveis: $vagas',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.red.shade700,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () async {
                                            final tableId = doc.id;
                                            if (players.contains(
                                              widget.user.uid,
                                            )) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Você já está nessa mesa.',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            try {
                                              await FirebaseFirestore.instance
                                                  .collection('tables')
                                                  .doc(tableId)
                                                  .update({
                                                    'players':
                                                        FieldValue.arrayUnion([
                                                          widget.user.uid,
                                                        ]),
                                                  });
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Você entrou na mesa!',
                                                  ),
                                                ),
                                              );
                                              await _loadTables();
                                            } catch (e) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text('Erro: $e'),
                                                ),
                                              );
                                            }
                                          },
                                          child: const Text('Juntar-se à mesa'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
