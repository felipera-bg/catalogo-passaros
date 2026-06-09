import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/captura.dart';
import '../models/especie.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'form_captura_screen.dart';

class DetalheCapturaScreen extends StatelessWidget {
  final Captura captura;
  final List<Especie> especies;
  final String currentUserId;

  const DetalheCapturaScreen({
    super.key,
    required this.captura,
    required this.especies,
    required this.currentUserId,
  });

  bool get _isOwner => captura.usuarioId == currentUserId;

  @override
  Widget build(BuildContext context) {
    final especiesCaptura = especies
        .where((e) => captura.especiesId.contains(e.id))
        .toList();
    final dataFormatada = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(captura.dataFoto);

    return Scaffold(
      appBar: AppBar(
        title: Text(captura.titulo),
        actions: _isOwner
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar',
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FormCapturaScreen(
                        userId: currentUserId,
                        especies: especies,
                        captura: captura,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Excluir',
                  onPressed: () => _confirmDelete(context),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl: captura.urlImagem,
              width: double.infinity,
              height: 280,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                height: 280,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, _, _) => Container(
                height: 280,
                color: Colors.grey[200],
                child: const Icon(
                  Icons.broken_image,
                  size: 64,
                  color: Colors.grey,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    captura.titulo,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 6),
                      Text(dataFormatada),
                    ],
                  ),
                  if (especiesCaptura.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Espécies',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: especiesCaptura
                          .map(
                            (e) => Chip(
                              label: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(e.nome),
                                  Text(
                                    e.nomeCientifico,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir captura'),
        content: const Text('Tem certeza que deseja excluir esta captura?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirestoreService.deleteCaptura(captura.id);
      await StorageService.deleteImageByUrl(captura.urlImagem);
      if (context.mounted) Navigator.pop(context);
    }
  }
}
