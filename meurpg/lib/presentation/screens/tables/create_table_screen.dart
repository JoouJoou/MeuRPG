import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '/models/user_model.dart';
import '/models/table_model.dart';
import '/models/system_model.dart';
import '../system/system_service.dart';

class CreateTableScreen extends StatefulWidget {
  final UserModel user;
  const CreateTableScreen({super.key, required this.user});

  @override
  State<CreateTableScreen> createState() => _CreateTableScreenState();
}

class _CreateTableScreenState extends State<CreateTableScreen> {
  /* ------------------------ CONTROLLERS E VARIÁVEIS BÁSICAS ------------------------ */
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxPlayersController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _zipController = TextEditingController();
  final _numberController = TextEditingController();

  /* ----------------------------- Sistemas dinâmicos ----------------------------- */
  late final Stream<List<SystemModel>> _systemsStream;
  String? _selectedSystemId;
  String? _selectedSystemName;

  bool _isPrivate = false;
  File? _imageFile;
  String? _imageUrl;
  LatLng? _selectedLocation;
  String selectedAvatar = 'avatar1.png';

  final _availableAvatars = [
    'avatar1.png',
    'avatar2.png',
    'avatar3.png',
    'avatar4.png',
  ];

  LatLng _initialMapCenter = LatLng(-23.5505, -46.6333);
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _systemsStream = SystemService().streamSystemsByUser(widget.user.uid);
  }

  /* -------------------------------------------------------------------------- */
  /*                       BUSCAR COORDENADAS PELO ENDEREÇO                     */
  /* -------------------------------------------------------------------------- */
  Future<void> _buscarLocalizacaoPorEndereco() async {
    if (_isFetchingLocation) return;
    _isFetchingLocation = true;

    final enderecoCompleto =
        '${_streetController.text}, ${_numberController.text}, '
        '${_cityController.text}, ${_stateController.text}, '
        '${_zipController.text}, ${_countryController.text}';

    try {
      final locations = await locationFromAddress(enderecoCompleto);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        setState(() {
          _selectedLocation = LatLng(loc.latitude, loc.longitude);
          _initialMapCenter = _selectedLocation!;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Localização encontrada com sucesso!')),
        );
        await _selectOnMap(); // abre mapa para confirmação
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Endereço não encontrado.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao buscar localização: $e')));
    } finally {
      _isFetchingLocation = false;
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                        SELEÇÃO E UPLOAD DE IMAGEM (IMGUR)                  */
  /* -------------------------------------------------------------------------- */
  Future<void> _pickImage() async {
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissão para acessar fotos negada.')),
      );
      return;
    }
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      _imageFile = File(picked.path);
      await _uploadImageToImgur(_imageFile!);
    }
  }

  Future<void> _uploadImageToImgur(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final response = await http.post(
      Uri.parse('https://api.imgur.com/3/image'),
      headers: {'Authorization': 'Client-ID b809f190b885e35'},
      body: {'image': base64Image},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _imageUrl = data['data']['link'];
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao enviar imagem para o Imgur.')),
      );
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                               SELECIONAR NO MAPA                           */
  /* -------------------------------------------------------------------------- */
  Future<void> _selectOnMap() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissão de localização negada.')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder:
          (_) => _MapDialog(
            initialCenter: _initialMapCenter,
            currentMarker: _selectedLocation,
            onConfirmed: (latlng, placemark) {
              setState(() {
                _selectedLocation = latlng;
                _streetController.text = placemark.street ?? '';
                _cityController.text =
                    placemark.locality?.isNotEmpty == true
                        ? placemark.locality!
                        : (placemark.subAdministrativeArea?.isNotEmpty == true
                            ? placemark.subAdministrativeArea!
                            : (placemark.administrativeArea ?? ''));
                _stateController.text = placemark.administrativeArea ?? '';
                _countryController.text = placemark.country ?? '';
                _zipController.text = placemark.postalCode ?? '';
              });
            },
          ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                           ESCOLHER AVATAR DA MESA                          */
  /* -------------------------------------------------------------------------- */
  Future<void> _selectAvatar() async {
    final chosen = await showDialog<String>(
      context: context,
      builder:
          (_) => SimpleDialog(
            title: const Text('Escolha seu avatar'),
            children:
                _availableAvatars
                    .map(
                      (a) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, a),
                        child: Row(
                          children: [
                            Image.asset('assets/images/$a', width: 40),
                            const SizedBox(width: 12),
                            Text(a.split('.').first),
                          ],
                        ),
                      ),
                    )
                    .toList(),
          ),
    );
    if (chosen != null) {
      setState(() => selectedAvatar = chosen);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() ||
        _imageUrl == null ||
        _selectedLocation == null ||
        _selectedSystemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha todos os campos obrigatórios e selecione imagem/local.',
          ),
        ),
      );
      return;
    }

    final id = const Uuid().v4();
    final joinCode = const Uuid().v4().substring(0, 6).toUpperCase();

    // 🔹 obtém o nome do sistema a partir do cache

    final newTable = TableModel(
      id: id,
      name: _nameController.text.trim(),
      systemId: _selectedSystemId!, // salva o ID
      systemName: _selectedSystemName ?? '',
      description: _descriptionController.text.trim(),
      imageUrl: _imageUrl!,
      maxPlayers: int.parse(_maxPlayersController.text.trim()),
      locationName:
          '${_streetController.text}, ${_numberController.text}, '
          '${_cityController.text}, ${_stateController.text}, '
          '${_countryController.text}',
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
      isPrivate: _isPrivate,
      creatorId: widget.user.uid,
      joinCode: joinCode,
      players: [widget.user.uid],
    );

    await FirebaseFirestore.instance
        .collection('tables')
        .doc(id)
        .set(newTable.toMap());

    Navigator.pop(context);
  }

  /* -------------------------------------------------------------------------- */
  /*                                    UI                                      */
  /* -------------------------------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Mesa'),
        backgroundColor: Colors.red.shade700,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                widget.user.username ?? 'Usuário',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          GestureDetector(
            onTap: _selectAvatar,
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/images/$selectedAvatar'),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /* --------------------------- Nome da mesa --------------------------- */
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome da Mesa'),
                  validator:
                      (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                ),
                /* --------------------- Dropdown de Sistemas (Dinâmico) -------------- */
                StreamBuilder<List<SystemModel>>(
                  stream: _systemsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: LinearProgressIndicator(),
                      );
                    }
                    final systems = snapshot.data ?? [];
                    if (systems.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Você ainda não criou nenhum sistema.\n'
                          'Crie um sistema primeiro para usá-lo aqui.',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Sistema (selecione)',
                      ),
                      value: _selectedSystemId,
                      items:
                          systems
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name),
                                ),
                              )
                              .toList(),
                      validator:
                          (v) => v == null ? 'Selecione um sistema' : null,
                      onChanged: (val) {
                        setState(() {
                          _selectedSystemId = val;
                          _selectedSystemName =
                              systems
                                  .firstWhere((s) => s.id == val)
                                  .name; // guarda o nome
                        });
                      },
                    );
                  },
                ),
                /* ------------------ Descrição, imagem, etc. ------------------ */
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  maxLines: 3,
                  validator:
                      (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 12),
                _imageWidget(),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Selecionar Imagem'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _maxPlayersController,
                  decoration: const InputDecoration(
                    labelText: 'Número Máximo de Jogadores',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Obrigatório';
                    final n = int.tryParse(v);
                    if (n == null || n <= 0) return 'Número inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Mesa Privada'),
                  value: _isPrivate,
                  onChanged: (v) => setState(() => _isPrivate = v),
                ),
                const SizedBox(height: 12),
                /* -------------------------- Endereço ------------------------- */
                const Text(
                  'Endereço da mesa:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextFormField(
                  controller: _streetController,
                  decoration: const InputDecoration(labelText: 'Rua'),
                ),
                TextFormField(
                  controller: _numberController,
                  decoration: const InputDecoration(labelText: 'Número'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'Cidade'),
                ),
                TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(labelText: 'Estado'),
                ),
                TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(labelText: 'País'),
                ),
                TextFormField(
                  controller: _zipController,
                  decoration: const InputDecoration(labelText: 'CEP'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _buscarLocalizacaoPorEndereco,
                  child: const Text('Buscar localização pelo endereço'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _selectOnMap,
                  child: const Text('Selecionar localização no mapa'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                  ),
                  onPressed: _submitForm,
                  child: const Text('Criar Mesa'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /* ------------------------- Widget auxiliar imagem ------------------------- */
  Widget _imageWidget() {
    if (_imageFile != null) {
      return Image.file(_imageFile!, height: 150);
    } else if (_imageUrl != null) {
      return Image.network(_imageUrl!, height: 150);
    } else {
      return Container(
        height: 150,
        color: Colors.grey.shade300,
        child: const Center(child: Text('Sem imagem')),
      );
    }
  }
}

/* ------------------ Diálogo customizado com mapa (privado) ------------------ */
class _MapDialog extends StatefulWidget {
  final LatLng initialCenter;
  final LatLng? currentMarker;
  final Function(LatLng, Placemark) onConfirmed;

  const _MapDialog({
    required this.initialCenter,
    required this.currentMarker,
    required this.onConfirmed,
  });

  @override
  State<_MapDialog> createState() => _MapDialogState();
}

class _MapDialogState extends State<_MapDialog> {
  LatLng? _tempLocation;

  @override
  void initState() {
    super.initState();
    _tempLocation = widget.currentMarker;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Toque no mapa para escolher localização'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: FlutterMap(
          options: MapOptions(
            center: widget.initialCenter,
            zoom: 13,
            onTap: (tapPos, latlng) => setState(() => _tempLocation = latlng),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.meurpg',
            ),
            if (_tempLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40,
                    height: 40,
                    point: _tempLocation!,
                    child: const Icon(
                      Icons.location_pin,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('Confirmar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            if (_tempLocation == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Selecione um local no mapa.')),
              );
              return;
            }
            final placemarks = await placemarkFromCoordinates(
              _tempLocation!.latitude,
              _tempLocation!.longitude,
            );
            Navigator.of(context).pop();
            widget.onConfirmed(_tempLocation!, placemarks.first);
          },
        ),
      ],
    );
  }
}
