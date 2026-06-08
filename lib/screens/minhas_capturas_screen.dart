import 'package:flutter/material.dart';
import '../models/captura.dart';
import '../models/especie.dart';
import '../services/firestore_service.dart';
import '../widgets/captura_list_view.dart';

class MinhasCapturasScreen extends StatelessWidget {
  final String userId;
  final List<Especie> especies;

  const MinhasCapturasScreen({
    super.key,
    required this.userId,
    required this.especies,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Captura>>(
      stream: FirestoreService.getMinhasCapturas(userId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erro: ${snap.error}'));
        }
        return CapturaListView(
          capturas: snap.data ?? [],
          especies: especies,
          currentUserId: userId,
        );
      },
    );
  }
}
