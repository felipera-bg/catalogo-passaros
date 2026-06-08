import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/captura.dart';
import '../models/especie.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static Stream<List<Especie>> getEspecies() {
    return _db
        .collection('especies')
        .orderBy('nome')
        .snapshots()
        .map((snap) => snap.docs.map(Especie.fromFirestore).toList());
  }

  static Stream<List<Captura>> getMinhasCapturas(String userId) {
    return _db
        .collection('capturas')
        .where('usuario_id', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map(Captura.fromFirestore).toList());
  }

  static Stream<List<Captura>> getCapturas() {
    return _db
        .collection('capturas')
        .snapshots()
        .map((snap) => snap.docs.map(Captura.fromFirestore).toList());
  }

  static Future<void> addCaptura(Captura captura) {
    return _db.collection('capturas').add(captura.toMap());
  }

  static Future<void> updateCaptura(String id, Map<String, dynamic> data) {
    return _db.collection('capturas').doc(id).update(data);
  }

  static Future<void> deleteCaptura(String id) {
    return _db.collection('capturas').doc(id).delete();
  }
}
