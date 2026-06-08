import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/especie.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../screens/minhas_capturas_screen.dart';
import '../screens/capturas_globais_screen.dart';
import '../screens/form_captura_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Especie>>(
      stream: FirestoreService.getEspecies(),
      builder: (context, snap) {
        final especies = snap.data ?? [];
        final user = FirebaseAuth.instance.currentUser!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Catálogo de Pássaros'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Sair',
                onPressed: _confirmSignOut,
              ),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              MinhasCapturasScreen(userId: user.uid, especies: especies),
              CapturasGlobaisScreen(especies: especies),
            ],
          ),
          floatingActionButton: _selectedIndex == 0
              ? FloatingActionButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FormCapturaScreen(
                        userId: user.uid,
                        especies: especies,
                      ),
                    ),
                  ),
                  tooltip: 'Nova Captura',
                  child: const Icon(Icons.add),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Minhas Capturas',
              ),
              NavigationDestination(
                icon: Icon(Icons.public_outlined),
                selectedIcon: Icon(Icons.public),
                label: 'Capturas Globais',
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirm == true) await AuthService.signOut();
  }
}
