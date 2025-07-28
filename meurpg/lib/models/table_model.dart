class TableModel {
  final String id;
  final String name;
  final String systemId; // 🔹 novo campo
  final String systemName; // 🔹 mantém o nome para exibição (opcional)
  final String description;
  final String imageUrl;
  final int maxPlayers;
  final String locationName;
  final double latitude;
  final double longitude;
  final bool isPrivate;
  final String creatorId;
  final String joinCode;
  final List<String> players;

  TableModel({
    required this.id,
    required this.name,
    required this.systemId,
    required this.systemName,
    required this.description,
    required this.imageUrl,
    required this.maxPlayers,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.isPrivate,
    required this.creatorId,
    required this.joinCode,
    required this.players,
  });

  /* ---------------------------- Serialização ---------------------------- */
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'systemId': systemId, // grava o id
      'systemName': systemName, // grava o nome p/ evitar 2ª consulta
      'description': description,
      'imageUrl': imageUrl,
      'maxPlayers': maxPlayers,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'isPrivate': isPrivate,
      'creatorId': creatorId,
      'joinCode': joinCode,
      'players': players,
    };
  }

  /* --------------------------- Desserialização --------------------------- */
  factory TableModel.fromMap(Map<String, dynamic> map) {
    return TableModel(
      id: map['id'],
      name: map['name'],
      // se ainda não houver systemId (documentos antigos) usa uma string vazia
      systemId: map['systemId'] ?? '',
      // se não existir systemName, usa o antigo campo system
      systemName: map['systemName'] ?? map['system'] ?? '',
      description: map['description'],
      imageUrl: map['imageUrl'],
      maxPlayers: map['maxPlayers'],
      locationName: map['locationName'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      isPrivate: map['isPrivate'],
      creatorId: map['creatorId'],
      joinCode: map['joinCode'],
      players: List<String>.from(map['players']),
    );
  }
}
