import 'package:cloud_firestore/cloud_firestore.dart';

class Captura {
  final String id;
  final String titulo;
  final DateTime dataFoto;
  final String urlImagem;
  final String usuarioId;
  final List<String> especiesId;

  const Captura({
    required this.id,
    required this.titulo,
    required this.dataFoto,
    required this.urlImagem,
    required this.usuarioId,
    required this.especiesId,
  });

  factory Captura.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Captura(
      id: doc.id,
      titulo: data['titulo'] as String? ?? '',
      dataFoto: (data['data_foto'] as Timestamp).toDate(),
      urlImagem: data['url_imagem'] as String? ?? '',
      usuarioId: data['usuario_id'] as String? ?? '',
      especiesId: List<String>.from(data['especies_id'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'data_foto': Timestamp.fromDate(dataFoto),
      'url_imagem': urlImagem,
      'usuario_id': usuarioId,
      'especies_id': especiesId,
    };
  }
}
