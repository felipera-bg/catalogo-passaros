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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
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
            ],
          ),
          if (widget.especies.isNotEmpty) ...[
            const Text('Filtrar por espécie:'),
            const SizedBox(height: 4),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: widget.especies.map((e) {
                  final selected = _selectedEspecies.contains(e.id);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(e.nome),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        if (v) {
                          _selectedEspecies.add(e.id);
                        } else {
                          _selectedEspecies.remove(e.id);
                        }
                      }),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const Divider(height: 12),
        ],
      ),
    );
  }
}
