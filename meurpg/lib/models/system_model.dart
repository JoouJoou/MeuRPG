import 'package:cloud_firestore/cloud_firestore.dart';

class SystemModel {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final String ownerId;

  SystemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.ownerId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'createdAt': Timestamp.fromDate(createdAt),
    'ownerId': ownerId,
  };

  factory SystemModel.fromMap(String docId, Map<String, dynamic> map) {
    final created = map['createdAt'];
    return SystemModel(
      id: map['id'] ?? docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      ownerId: map['ownerId'] ?? '',
    );
  }
}
