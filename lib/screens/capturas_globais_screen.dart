import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/captura.dart';
import '../models/especie.dart';
import '../services/firestore_service.dart';
import 'detalhe_captura_screen.dart';

enum _SortOption {
  tituloAsc('Título A→Z'),
  tituloDesc('Título Z→A'),
  dataDesc('Data mais recente'),
  dataAsc('Data mais antiga');

  final String label;
  const _SortOption(this.label);
}

class CapturasGlobaisScreen extends StatefulWidget {
  final List<Especie> especies;

  const CapturasGlobaisScreen({super.key, required this.especies});

  @override
  State<CapturasGlobaisScreen> createState() => _CapturasGlobaisScreenState();
}

class _CapturasGlobaisScreenState extends State<CapturasGlobaisScreen> {
  _SortOption _sortOption = _SortOption.dataDesc;
  final Set<String> _selectedEspecies = {};

  List<Captura> _applyFilters(List<Captura> capturas) {
    var result = capturas;
    if (_selectedEspecies.isNotEmpty) {
      result = result
          .where((c) => c.especiesId.any(_selectedEspecies.contains))
          .toList();
    }
    final sorted = List<Captura>.from(result);
    switch (_sortOption) {
      case _SortOption.tituloAsc:
        sorted.sort((a, b) => a.titulo.compareTo(b.titulo));
      case _SortOption.tituloDesc:
        sorted.sort((a, b) => b.titulo.compareTo(a.titulo));
      case _SortOption.dataAsc:
        sorted.sort((a, b) => a.dataFoto.compareTo(b.dataFoto));
      case _SortOption.dataDesc:
        sorted.sort((a, b) => b.dataFoto.compareTo(a.dataFoto));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<List<Captura>>(
      stream: FirestoreService.getCapturas(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erro: ${snap.error}'));
        }
        final capturas = _applyFilters(snap.data ?? []);

        return Column(
          children: [
            _buildControls(context),
            Expanded(
              child: capturas.isEmpty
                  ? const Center(child: Text('Nenhuma captura encontrada.'))
                  : ListView.builder(
                      itemCount: capturas.length,
                      itemBuilder: (_, i) => _PostCard(
                        captura: capturas[i],
                        especies: widget.especies,
                        currentUserId: currentUserId,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Ordenar: '),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<_SortOption>(
                  value: _sortOption,
                  isExpanded: true,
                  items: _SortOption.values
                      .map(
                        (o) => DropdownMenuItem(
                          value: o,
                          child: Text(
                            o.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _sortOption = v);
                  },
                ),
              ),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    tooltip: 'Filtrar por espécie',
                    onPressed: widget.especies.isEmpty
                        ? null
                        : () => _showFilterSheet(context),
                  ),
                  if (_selectedEspecies.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const Divider(height: 4),
        ],
      ),
    );
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    String searchText = '';
    final tempSelected = Set<String>.from(_selectedEspecies);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final filtered = searchText.isEmpty
              ? widget.especies
              : widget.especies
                  .where((e) => e.nome
                      .toLowerCase()
                      .contains(searchText.toLowerCase()))
                  .toList();

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtrar por espécie',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Pesquisar espécie...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setSheetState(() => searchText = v),
                  ),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Nenhuma espécie encontrada'),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: filtered.map((e) {
                        final selected = tempSelected.contains(e.id);
                        return FilterChip(
                          label: Text(e.nome),
                          selected: selected,
                          onSelected: (v) => setSheetState(() {
                            if (v) {
                              tempSelected.add(e.id);
                            } else {
                              tempSelected.remove(e.id);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () =>
                            setSheetState(() => tempSelected.clear()),
                        child: const Text('Limpar'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _selectedEspecies.clear();
                            _selectedEspecies.addAll(tempSelected);
                          });
                        },
                        child: const Text('Aplicar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Captura captura;
  final List<Especie> especies;
  final String currentUserId;

  const _PostCard({
    required this.captura,
    required this.especies,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final especiesCaptura =
        especies.where((e) => captura.especiesId.contains(e.id)).toList();
    final dataFormatada =
        DateFormat('dd/MM/yyyy HH:mm').format(captura.dataFoto);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: const RoundedRectangleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetalheCapturaScreen(
              captura: captura,
              especies: especies,
              currentUserId: currentUserId,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Camada 1: imagem
            CachedNetworkImage(
              imageUrl: captura.urlImagem,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                height: 300,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, _, _) => Container(
                height: 300,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image,
                    size: 64, color: Colors.grey),
              ),
            ),

            // Camada 3: tags das espécies
            if (especiesCaptura.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: especiesCaptura
                      .map(
                        (e) => Chip(
                          label: Text(
                            e.nome,
                            style: const TextStyle(fontSize: 12),
                          ),
                          padding: EdgeInsets.zero,
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 6),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ),

            // Camada 4: titulo como legenda
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text(
                captura.titulo,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    dataFormatada,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
