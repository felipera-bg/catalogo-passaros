import 'package:flutter/material.dart';
import '../models/captura.dart';
import '../models/especie.dart';
import 'captura_card.dart';

enum SortOption {
  tituloAsc('Título A→Z'),
  tituloDesc('Título Z→A'),
  dataDesc('Data mais recente'),
  dataAsc('Data mais antiga');

  final String label;
  const SortOption(this.label);
}

class CapturaListView extends StatefulWidget {
  final List<Captura> capturas;
  final List<Especie> especies;
  final String currentUserId;

  const CapturaListView({
    super.key,
    required this.capturas,
    required this.especies,
    required this.currentUserId,
  });

  @override
  State<CapturaListView> createState() => _CapturaListViewState();
}

class _CapturaListViewState extends State<CapturaListView> {
  SortOption _sortOption = SortOption.dataDesc;
  final Set<String> _selectedEspecies = {};

  List<Captura> get _filtered {
    var result = widget.capturas;

    if (_selectedEspecies.isNotEmpty) {
      result = result
          .where((c) => c.especiesId.any(_selectedEspecies.contains))
          .toList();
    }

    final sorted = List<Captura>.from(result);
    switch (_sortOption) {
      case SortOption.tituloAsc:
        sorted.sort((a, b) => a.titulo.compareTo(b.titulo));
      case SortOption.tituloDesc:
        sorted.sort((a, b) => b.titulo.compareTo(a.titulo));
      case SortOption.dataAsc:
        sorted.sort((a, b) => a.dataFoto.compareTo(b.dataFoto));
      case SortOption.dataDesc:
        sorted.sort((a, b) => b.dataFoto.compareTo(a.dataFoto));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      children: [
        _buildControls(),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Nenhuma captura encontrada.'))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => CapturaCard(
                    captura: filtered[i],
                    especies: widget.especies,
                    currentUserId: widget.currentUserId,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Ordenar: '),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<SortOption>(
                  value: _sortOption,
                  isExpanded: true,
                  items: SortOption.values
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
          const Divider(height: 12),
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

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.7,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                      Flexible(
                        child: SingleChildScrollView(
                          child: filtered.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text('Nenhuma espécie encontrada'),
                                  ),
                                )
                              : Wrap(
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
                        ),
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
              ),
            ),
          );
        },
      ),
    );
  }
}
