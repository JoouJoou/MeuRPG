import 'package:cloud_firestore/cloud_firestore.dart';
import 'session_model.dart';

class SessionService {
  final _sessions = FirebaseFirestore.instance.collection('sessions');

  // Getter para permitir acesso direto à coleção
  CollectionReference get sessionsCollection => _sessions;

  Future<void> createSession(SessionModel session) async {
    final docRef = _sessions.doc(); // gera o ID
    final newSession = session.copyWith(id: docRef.id);

    await docRef.set(newSession.toMap());
  }

  Stream<List<SessionModel>> getSessionsByTable(String tableId) {
    return _sessions
        .where('tableId', isEqualTo: tableId)
        .orderBy('date')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => SessionModel.fromFirestore(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList(),
        );
  }

  Future<void> deleteSession(String sessionId) async {
    await _sessions.doc(sessionId).delete();
  }

  Future<void> updateSession(SessionModel session) async {
    await _sessions.doc(session.id).update(session.toMap());
  }
}
