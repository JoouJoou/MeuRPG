class TableModel {
  final String id;
  final String name;
  final String system;
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
    required this.system,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'system': system,
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

  factory TableModel.fromMap(Map<String, dynamic> map) {
    return TableModel(
      id: map['id'],
      name: map['name'],
      system: map['system'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      maxPlayers: map['maxPlayers'],
      locationName: map['locationName'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      isPrivate: map['isPrivate'],
      creatorId: map['creatorId'],
      joinCode: map['joinCode'],
      players: map['players'],
    );
  }
}
