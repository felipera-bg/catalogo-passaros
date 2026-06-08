import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/captura.dart';
import '../models/especie.dart';
import '../services/firestore_service.dart';
import '../widgets/captura_list_view.dart';

class CapturasGlobaisScreen extends StatelessWidget {
  final List<Especie> especies;

  const CapturasGlobaisScreen({super.key, required this.especies});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<List<Captura>>(
      stream: FirestoreService.getCapturas(),
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
