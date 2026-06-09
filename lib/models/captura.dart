import 'package:cloud_firestore/cloud_firestore.dart';

class Captura {
  final String id;
  final String titulo;
  final DateTime dataFoto;
  final String urlImagem;
  final String usuarioId;
  final List<String> especiesId;
  final String? usuarioNome;
  final String? usuarioFoto;

  const Captura({
    required this.id,
    required this.titulo,
    required this.dataFoto,
    required this.urlImagem,
    required this.usuarioId,
    required this.especiesId,
    this.usuarioNome,
    this.usuarioFoto,
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
      usuarioNome: data['usuario_nome'] as String?,
      usuarioFoto: data['usuario_foto'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'data_foto': Timestamp.fromDate(dataFoto),
      'url_imagem': urlImagem,
      'usuario_id': usuarioId,
      'especies_id': especiesId,
      if (usuarioNome != null) 'usuario_nome': usuarioNome,
      if (usuarioFoto != null) 'usuario_foto': usuarioFoto,
    };
  }
}
