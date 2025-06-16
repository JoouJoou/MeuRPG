import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '/models/user_model.dart';

class SearchTablesScreen extends StatefulWidget {
  final UserModel user;
  const SearchTablesScreen({super.key, required this.user});

  @override
  State<SearchTablesScreen> createState() => _SearchTablesScreenState();
}

class _SearchTablesScreenState extends State<SearchTablesScreen> {
  String searchName = '';
  String? selectedSystem;
  double? userLatitude;
  double? userLongitude;
  double maxDistanceKm = 50;
  int minVagas = 1;

  List<QueryDocumentSnapshot> allTables = [];

  final List<String> systems = [
    'Dungeons and Dragons',
    'Tormenta20',
    'Pathfinder',
    'F&M',
    'Storyteller',
    'Call of Cthulhu',
    'GURPS',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _determinePosition();
    await _loadTables();
    setState(() {});
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Serviço de localização desabilitado.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Permissão de localização negada');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Permissão de localização negada para sempre.');
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      userLatitude = position.latitude;
      userLongitude = position.longitude;
    });
  }

  Future<void> _loadTables() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('tables')
            .where('isPrivate', isEqualTo: false)
            .get();

    setState(() {
      allTables = snapshot.docs;
    });
  }

  double calculateDistanceKm(lat1, lon1, lat2, lon2) {
    const earthRadiusKm = 6371;

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double deg) => deg * pi / 180;

  @override
  Widget build(BuildContext context) {
    List<QueryDocumentSnapshot> filteredTables =
        allTables.where((doc) {
          final data = doc.data()! as Map<String, dynamic>;
          final players = List<String>.from(data['players'] ?? []);

          if (searchName.isNotEmpty &&
              !data['name'].toString().toLowerCase().contains(
                searchName.toLowerCase(),
              )) {
            return false;
          }

          if (players.contains(widget.user.uid)) {
            return false;
          }

          if (selectedSystem != null &&
              selectedSystem!.isNotEmpty &&
              data['system'] != selectedSystem) {
            return false;
          }

          final maxPlayers = (data['maxPlayers'] ?? 0) as int;
          final vagas = maxPlayers - players.length;
          if (vagas < minVagas) {
            return false;
          }

          return true;
        }).toList();

    if (userLatitude != null && userLongitude != null) {
      filteredTables.sort((a, b) {
        final dataA = a.data()! as Map<String, dynamic>;
        final dataB = b.data()! as Map<String, dynamic>;
        double distA = calculateDistanceKm(
          userLatitude!,
          userLongitude!,
          (dataA['latitude'] ?? 0),
          (dataA['longitude'] ?? 0),
        );
        double distB = calculateDistanceKm(
          userLatitude!,
          userLongitude!,
          (dataB['latitude'] ?? 0),
          (dataB['longitude'] ?? 0),
        );
        return distA.compareTo(distB);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Mesas Públicas'),
        backgroundColor: Colors.red.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar pelo nome da mesa',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchName = value;
                });
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Filtrar por sistema',
              ),
              items: [
                const DropdownMenuItem(value: '', child: Text('Todos')),
                ...systems.map(
                  (sys) => DropdownMenuItem(value: sys, child: Text(sys)),
                ),
              ],
              value: selectedSystem ?? '',
              onChanged: (value) {
                setState(() {
                  selectedSystem = (value == '') ? null : value;
                });
              },
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                const Text('Vagas mínimas:'),
                const SizedBox(width: 10),
                DropdownButton<int>(
                  value: minVagas,
                  items:
                      List.generate(10, (index) => index + 1)
                          .map(
                            (v) =>
                                DropdownMenuItem(value: v, child: Text('$v')),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      minVagas = value ?? 1;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child:
                  filteredTables.isEmpty
                      ? const Center(child: Text('Nenhuma mesa encontrada.'))
                      : ListView.builder(
                        itemCount: filteredTables.length,
                        itemBuilder: (context, index) {
                          final doc = filteredTables[index];
                          final data = doc.data()! as Map<String, dynamic>;
                          final players = List<String>.from(
                            data['players'] ?? [],
                          );
                          final maxPlayers = (data['maxPlayers'] ?? 0) as int;
                          final vagas = maxPlayers - players.length;

                          double? distKm;
                          if (userLatitude != null && userLongitude != null) {
                            distKm = calculateDistanceKm(
                              userLatitude!,
                              userLongitude!,
                              (data['latitude'] ?? 0),
                              (data['longitude'] ?? 0),
                            );
                          }

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
                                        data['name'] ?? 'Nome não disponível',
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
                                        'Sistema: ${data['system'] ?? '-'}',
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
                                            final currentPlayers =
                                                List<String>.from(
                                                  data['players'] ?? [],
                                                );

                                            if (currentPlayers.contains(
                                              widget.user.uid,
                                            )) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
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
                                                SnackBar(
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
                                                  content: Text(
                                                    'Erro ao entrar na mesa: $e',
                                                  ),
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
