import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/geocoding_web_service.dart';
import '../screens/preview_screen.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isProcessing = false;
  bool _locationPermissionGranted = false;
  LocationData? _currentLocation;
  bool _isLoadingLocation = false;

  final LocationService _locationService = LocationService();
  final GeocodingWebService _geocodingWebService = GeocodingWebService();

  @override
  void initState() {
    super.initState();
    // Verifica se há câmeras disponíveis
    if (widget.cameras.isEmpty) {
      _initializeControllerFuture = Future.value();
      return;
    }
    
    // Inicializa a primeira câmera traseira disponível
    _controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
    
    // Verifica permissão de localização ao inicializar
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool granted = await _locationService.requestLocationPermission();
    if (mounted) {
      setState(() {
        _locationPermissionGranted = granted;
      });
      
      // Se a permissão foi concedida, busca a localização atual
      if (granted) {
        _updateLocation();
      }
    }
  }

  Future<void> _updateLocation() async {
    if (!_locationPermissionGranted) return;
    
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      LocationData location;
      
      // Na web, usa o serviço de geocoding web
      if (kIsWeb) {
        try {
          // Primeiro obtém as coordenadas
          Position pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
          
          // Depois busca o endereço usando as coordenadas (mais rápido)
          String address = await _geocodingWebService.getAddressFromCoordinates(
            pos.latitude,
            pos.longitude,
          );
          
          location = LocationData(
            latitude: pos.latitude,
            longitude: pos.longitude,
            address: address,
          );
        } catch (e) {
          // Se falhar, tenta obter pelo menos as coordenadas
          try {
            Position pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 5),
            );
            location = LocationData(
              latitude: pos.latitude,
              longitude: pos.longitude,
              error: 'Erro ao obter endereço: $e',
            );
          } catch (e2) {
            location = LocationData(
              latitude: 0,
              longitude: 0,
              error: 'Erro ao obter localização: $e2',
            );
          }
        }
      } else {
        // Em outras plataformas, usa o LocationService normal
        location = await _locationService.getCurrentLocation();
      }
      
      if (mounted) {
        setState(() {
          _currentLocation = location;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _currentLocation = LocationData(
            latitude: 0,
            longitude: 0,
            error: 'Erro ao atualizar localização: $e',
          );
        });
      }
    }
  }

  @override
  void dispose() {
    if (widget.cameras.isNotEmpty) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_isProcessing) return;

    try {
      _isProcessing = true;
      await _initializeControllerFuture;

      // 1. Tira a foto (O arquivo é salvo temporariamente no disco pelo plugin)
      final XFile rawImage = await _controller.takePicture();

      if (mounted) {
        _isProcessing = false;
        
        // 2. NAVEGA IMEDIATAMENTE passando apenas o PATH (String é leve)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PreviewScreen(
              imagePath: rawImage.path, // Passamos o caminho, não os bytes
              address: _currentLocation?.address ?? "Localização não disponível",
            ),
          ),
        );
      }
    } catch (e) {
      _isProcessing = false;
      debugPrint("Erro: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se não houver câmeras disponíveis, mostra mensagem de erro
    if (widget.cameras.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Câmera de Produção")),
        body: const Center(
          child: Text(
            'Nenhuma câmera disponível.\nVerifique as permissões do dispositivo.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text("Câmera de Produção")),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Erro ao inicializar câmera: ${snapshot.error}'),
              );
            }
            return Stack(
              children: [
                CameraPreview(_controller),
                // Indicador de status da localização (canto superior direito)
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: _locationPermissionGranted ? _updateLocation : _checkLocationPermission,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _locationPermissionGranted 
                            ? Colors.green.withOpacity(0.8)
                            : Colors.orange.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isLoadingLocation)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            Icon(
                              _locationPermissionGranted ? Icons.location_on : Icons.location_off,
                              color: Colors.white,
                              size: 16,
                            ),
                          const SizedBox(width: 4),
                          Text(
                            _locationPermissionGranted ? 'GPS Ativo' : 'GPS Inativo',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Preview de localização (canto inferior direito)
                if (_locationPermissionGranted && _currentLocation != null)
                  Positioned(
                    bottom: 80,
                    right: 12,
                    height: 150,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Localização Atual:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_currentLocation!.hasError)
                            Text(
                              _currentLocation!.error!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                              ),
                            )
                          else ...[
                            if (_currentLocation!.hasAddress)
                              Text(
                                _currentLocation!.address!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              'Lat: ${_currentLocation!.latitude.toStringAsFixed(6)}\nLng: ${_currentLocation!.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _isProcessing ? null : _takePicture,
        backgroundColor: Colors.yellow[700],
        child: const Icon(Icons.camera_alt, color: Colors.black),
      ),
    );
  }
}