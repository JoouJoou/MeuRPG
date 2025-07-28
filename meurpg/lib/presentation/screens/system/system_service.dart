import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/system_model.dart';

class SystemService {
  final _collection = FirebaseFirestore.instance.collection('systems');

  Future<void> createSystem(SystemModel system) async {
    final docRef = _collection.doc();
    final sysWithId = SystemModel(
      id: docRef.id,
      name: system.name,
      description: system.description,
      createdAt: system.createdAt,
      ownerId: system.ownerId,
    );
    await docRef.set(sysWithId.toMap());
  }

  Stream<List<SystemModel>> streamSystemsByUser(String userId) {
    return _collection
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => SystemModel.fromMap(d.id, d.data()))
                  .toList(),
        );
  }

  /* ------------------------------- DELETAR -------------------------------- */
  Future<void> deleteSystem(String id) => _collection.doc(id).delete();
}
