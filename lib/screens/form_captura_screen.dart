import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/captura.dart';
import '../models/especie.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class FormCapturaScreen extends StatefulWidget {
  final String userId;
  final List<Especie> especies;
  final Captura? captura;

  const FormCapturaScreen({
    super.key,
    required this.userId,
    required this.especies,
    this.captura,
  });

  @override
  State<FormCapturaScreen> createState() => _FormCapturaScreenState();
}

class _FormCapturaScreenState extends State<FormCapturaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloController;
  late DateTime _dataFoto;
  late Set<String> _selectedEspecies;
  File? _imageFile;
  bool _loading = false;
  String _especieSearch = '';

  bool get _isEditing => widget.captura != null;

  @override
  void initState() {
    super.initState();
    _tituloController =
        TextEditingController(text: widget.captura?.titulo ?? '');
    _dataFoto = widget.captura?.dataFoto ?? DateTime.now();
    _selectedEspecies = Set.from(widget.captura?.especiesId ?? []);
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dataFoto,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataFoto),
    );

    final time = pickedTime ?? TimeOfDay.fromDateTime(_dataFoto);
    setState(() => _dataFoto = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          time.hour,
          time.minute,
        ));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEditing && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma imagem.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isEditing) {
        String? newUrl;
        if (_imageFile != null) {
          newUrl =
              await StorageService.uploadImage(_imageFile!, widget.userId);
        }

        await FirestoreService.updateCaptura(widget.captura!.id, {
          'titulo': _tituloController.text.trim(),
          'data_foto': Timestamp.fromDate(_dataFoto),
          'especies_id': _selectedEspecies.toList(),
          'url_imagem': ?newUrl,
        });

        if (newUrl != null) {
          await StorageService.deleteImageByUrl(widget.captura!.urlImagem);
        }
      } else {
        final user = FirebaseAuth.instance.currentUser;
        final url =
            await StorageService.uploadImage(_imageFile!, widget.userId);
        await FirestoreService.addCaptura(
          Captura(
            id: '',
            titulo: _tituloController.text.trim(),
            dataFoto: _dataFoto,
            urlImagem: url,
            usuarioId: widget.userId,
            especiesId: _selectedEspecies.toList(),
            usuarioNome: user?.email?.split('@')[0],
            usuarioFoto: user?.photoURL,
          ),
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Captura' : 'Nova Captura'),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Salvar',
              onPressed: _save,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildImagePicker(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe um título' : null,
              ),
              const SizedBox(height: 8),
              _buildDateField(),
              const SizedBox(height: 16),
              _buildEspeciesSelector(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    Widget imageContent;

    if (_imageFile != null) {
      imageContent = Image.file(_imageFile!, fit: BoxFit.cover);
    } else if (_isEditing) {
      imageContent = CachedNetworkImage(
        imageUrl: widget.captura!.urlImagem,
        fit: BoxFit.cover,
        placeholder: (_, _) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (_, _, _) =>
            const Center(child: Icon(Icons.broken_image)),
      );
    } else {
      imageContent = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'Toque para adicionar uma foto',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    }

    return Column(
      children: [
        GestureDetector(
          onTap: _showImageSourceSheet,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageContent,
            ),
          ),
        ),
        if (_isEditing)
          TextButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Trocar imagem'),
            onPressed: _showImageSourceSheet,
          ),
      ],
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Data e hora da foto',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(DateFormat('dd/MM/yyyy HH:mm').format(_dataFoto)),
      ),
    );
  }

  Widget _buildEspeciesSelector() {
    final filtered = _especieSearch.isEmpty
        ? widget.especies
        : widget.especies
            .where((e) => e.nome
                .toLowerCase()
                .contains(_especieSearch.toLowerCase()))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Espécies',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (widget.especies.isNotEmpty)
          TextField(
            decoration: const InputDecoration(
              hintText: 'Pesquisar espécie...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _especieSearch = v),
          ),
        const SizedBox(height: 8),
        widget.especies.isEmpty
            ? const Text(
                'Nenhuma espécie disponível',
                style: TextStyle(color: Colors.grey),
              )
            : filtered.isEmpty
                ? const Text(
                    'Nenhuma espécie encontrada',
                    style: TextStyle(color: Colors.grey),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: filtered.map((e) {
                      final selected = _selectedEspecies.contains(e.id);
                      return FilterChip(
                        label: Text(e.nome),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _selectedEspecies.add(e.id);
                          } else {
                            _selectedEspecies.remove(e.id);
                          }
                        }),
                      );
                    }).toList(),
                  ),
      ],
    );
  }
}
