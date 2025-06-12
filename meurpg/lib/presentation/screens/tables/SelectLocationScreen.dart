import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({super.key});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  LatLng? _pickedLocation;
  bool _permissionGranted = false;
  LatLng _initialLocation = LatLng(-23.5505, -46.6333);
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _checarPermissoes();
  }

  Future<void> _checarPermissoes() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _permissionGranted = true;
        _initialLocation = LatLng(pos.latitude, pos.longitude);
        _mapController.move(_initialLocation, 15);
      });
    } else {
      setState(() {
        _permissionGranted = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permissão de localização negada. Ative nas configurações.',
          ),
        ),
      );
    }
  }

  void _onTap(TapPosition tapPosition, LatLng latlng) {
    setState(() => _pickedLocation = latlng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecione a Localização'),
        backgroundColor: const Color(0xFF3CA8CF),
      ),
      body:
          _permissionGranted
              ? FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: _initialLocation,
                  zoom: 15,
                  onTap: _onTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.meurpg',
                  ),
                  if (_pickedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _pickedLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            size: 40,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                ],
              )
              : const Center(child: CircularProgressIndicator()),
      floatingActionButton:
          _pickedLocation != null
              ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.pop(context, _pickedLocation);
                },
                label: const Text('Confirmar'),
                icon: const Icon(Icons.check),
                backgroundColor: const Color(0xFF3CA8CF),
              )
              : null,
    );
  }
}
