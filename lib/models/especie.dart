import 'package:cloud_firestore/cloud_firestore.dart';

class Especie {
  final String id;
  final String nome;
  final String nomeCientifico;

  const Especie({
    required this.id,
    required this.nome,
    required this.nomeCientifico,
  });

  factory Especie.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Especie(
      id: doc.id,
      nome: data['nome'] as String? ?? '',
      nomeCientifico: data['nome_cientifico'] as String? ?? '',
    );
  }
}
