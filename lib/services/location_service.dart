import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final String? error;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.error,
  });

  bool get hasError => error != null;
  bool get hasAddress => address != null && address!.isNotEmpty;
}

class LocationService {
  /// Verifica e solicita permissão de localização
  /// Retorna true se a permissão foi concedida, false caso contrário
  Future<bool> requestLocationPermission() async {
    try {
      // 1. Verifica se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      // 2. Verifica permissões
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      print('Erro ao solicitar permissão de localização: $e');
      return false;
    }
  }

  /// Obtém a localização atual (coordenadas e endereço)
  /// Retorna LocationData com coordenadas e endereço formatado
  Future<LocationData> getCurrentLocation() async {
    try {
      // 1. Verifica se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationData(
          latitude: 0,
          longitude: 0,
          error: 'Serviço de localização desabilitado',
        );
      }

      // 2. Verifica permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationData(
            latitude: 0,
            longitude: 0,
            error: 'Permissão de localização negada',
          );
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return LocationData(
          latitude: 0,
          longitude: 0,
          error: 'Permissão de localização negada permanentemente',
        );
      }

      // 3. Pega a posição atual
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      // 4. Tenta converter lat/long em endereço (Geocoding)
      // Nota: Na web, o geocoding pode não funcionar corretamente
      String? address;
      
      // Na web, pula o geocoding pois pode causar erros
      if (kIsWeb) {
        // Na web, apenas retorna coordenadas sem tentar geocoding
        print('Geocoding desabilitado na web - retornando apenas coordenadas');
      } else {
        try {
          // Tenta fazer geocoding com timeout para evitar travamentos
          List<Placemark> marks = await placemarkFromCoordinates(
            pos.latitude, 
            pos.longitude,
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('Timeout ao obter endereço via geocoding');
              return <Placemark>[];
            },
          );
        
        if (marks.isNotEmpty) {
          Placemark p = marks.first;
          
          // Formata o endereço, tratando valores null de forma segura
          String thoroughfare = '';
          String subThoroughfare = '';
          String subLocality = '';
          String subAdministrativeArea = '';
          String administrativeArea = '';
          String locality = '';
          String country = '';
          String postalCode = '';
          
          // Acessa cada campo de forma segura
          try {
            thoroughfare = p.thoroughfare ?? '';
          } catch (_) {}
          
          try {
            subThoroughfare = p.subThoroughfare ?? '';
          } catch (_) {}
          
          try {
            subLocality = p.subLocality ?? '';
          } catch (_) {}
          
          try {
            subAdministrativeArea = p.subAdministrativeArea ?? '';
          } catch (_) {}
          
          try {
            administrativeArea = p.administrativeArea ?? '';
          } catch (_) {}
          
          try {
            locality = p.locality ?? '';
          } catch (_) {}
          
          try {
            country = p.country ?? '';
          } catch (_) {}
          
          try {
            postalCode = p.postalCode ?? '';
          } catch (_) {}

          // Monta o endereço formatado com múltiplas tentativas
          List<String> addressParts = [];
          
          // Rua e número
          if (thoroughfare.isNotEmpty) {
            if (subThoroughfare.isNotEmpty) {
              addressParts.add("$thoroughfare Q $subThoroughfare");
            } else {
              addressParts.add(thoroughfare);
            }
          }
          
          // Bairro ou sublocalidade
          if (subLocality.isNotEmpty) {
            addressParts.add(subLocality);
          } else if (locality.isNotEmpty) {
            addressParts.add(locality);
          }
          
          // Cidade ou área administrativa
          if (subAdministrativeArea.isNotEmpty) {
            addressParts.add(subAdministrativeArea);
          } else if (administrativeArea.isNotEmpty) {
            addressParts.add(administrativeArea);
          }
          
          // País (opcional, só adiciona se não houver outros dados)
          if (addressParts.isEmpty && country.isNotEmpty) {
            addressParts.add(country);
          }
          
          // CEP (opcional)
          if (postalCode.isNotEmpty && addressParts.isNotEmpty) {
            addressParts.add("CEP: $postalCode");
          }

          if (addressParts.isNotEmpty) {
            address = addressParts.join('\n');
          }
        }
        } catch (e, stackTrace) {
          // Captura qualquer erro do geocoding
          print('Erro ao obter endereço via geocoding: $e');
          print('Stack trace: $stackTrace');
          // Continua sem endereço, mas retorna as coordenadas
          // O erro é silencioso porque as coordenadas já estão disponíveis
        }
      }

      return LocationData(
        latitude: pos.latitude,
        longitude: pos.longitude,
        address: address,
      );
    } catch (e) {
      return LocationData(
        latitude: 0,
        longitude: 0,
        error: 'Erro ao obter localização: $e',
      );
    }
  }

  Future<String> getFormattedAddress() async {
    try {
      // 1. Verifica se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return 'Serviço de localização desabilitado';
      }

      // 2. Verifica permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'Permissão de localização negada';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return 'Permissão de localização negada permanentemente';
      }

      // 3. Pega a posição atual
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      // 4. Converte lat/long em endereço (Geocoding)
      // Nota: Na web, o geocoding pode não funcionar corretamente
      if (kIsWeb) {
        // Na web, retorna apenas coordenadas sem tentar geocoding
        return 'Coordenadas GPS\nLat: ${pos.latitude.toStringAsFixed(6)}\nLng: ${pos.longitude.toStringAsFixed(6)}';
      }
      
      List<Placemark> marks = [];
      try {
        marks = await placemarkFromCoordinates(
          pos.latitude, 
          pos.longitude,
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('Timeout ao obter endereço via geocoding');
            return <Placemark>[];
          },
        );
      } catch (e, stackTrace) {
        // Se o geocoding falhar, retorna apenas coordenadas
        print('Erro ao obter endereço via geocoding: $e');
        print('Stack trace: $stackTrace');
        return 'Coordenadas GPS\nLat: ${pos.latitude.toStringAsFixed(6)}\nLng: ${pos.longitude.toStringAsFixed(6)}';
      }
      
      if (marks.isEmpty) {
        return 'Endereço não encontrado\nLat: ${pos.latitude.toStringAsFixed(6)}\nLng: ${pos.longitude.toStringAsFixed(6)}';
      }
      
      Placemark p = marks.first;

      // 5. Formata o endereço, tratando valores null de forma segura
      String thoroughfare = '';
      String subThoroughfare = '';
      String subLocality = '';
      String subAdministrativeArea = '';
      String administrativeArea = '';
      String locality = '';
      String country = '';
      String postalCode = '';
      
      // Acessa cada campo de forma segura
      try {
        thoroughfare = p.thoroughfare ?? '';
      } catch (_) {}
      
      try {
        subThoroughfare = p.subThoroughfare ?? '';
      } catch (_) {}
      
      try {
        subLocality = p.subLocality ?? '';
      } catch (_) {}
      
      try {
        subAdministrativeArea = p.subAdministrativeArea ?? '';
      } catch (_) {}
      
      try {
        administrativeArea = p.administrativeArea ?? '';
      } catch (_) {}
      
      try {
        locality = p.locality ?? '';
      } catch (_) {}
      
      try {
        country = p.country ?? '';
      } catch (_) {}
      
      try {
        postalCode = p.postalCode ?? '';
      } catch (_) {}

      // Monta o endereço formatado com múltiplas tentativas
      List<String> addressParts = [];
      
      // Rua e número
      if (thoroughfare.isNotEmpty) {
        if (subThoroughfare.isNotEmpty) {
          addressParts.add("$thoroughfare Q $subThoroughfare");
        } else {
          addressParts.add(thoroughfare);
        }
      }
      
      // Bairro ou sublocalidade
      if (subLocality.isNotEmpty) {
        addressParts.add(subLocality);
      } else if (locality.isNotEmpty) {
        addressParts.add(locality);
      }
      
      // Cidade ou área administrativa
      if (subAdministrativeArea.isNotEmpty) {
        addressParts.add(subAdministrativeArea);
      } else if (administrativeArea.isNotEmpty) {
        addressParts.add(administrativeArea);
      }
      
      // País (opcional, só adiciona se não houver outros dados)
      if (addressParts.isEmpty && country.isNotEmpty) {
        addressParts.add(country);
      }
      
      // CEP (opcional)
      if (postalCode.isNotEmpty && addressParts.isNotEmpty) {
        addressParts.add("CEP: $postalCode");
      }

      // Se não conseguiu montar endereço, retorna coordenadas
      if (addressParts.isEmpty) {
        return 'Endereço não disponível\nLat: ${pos.latitude.toStringAsFixed(6)}\nLng: ${pos.longitude.toStringAsFixed(6)}';
      }

      return addressParts.join('\n');
    } catch (e) {
      return 'Erro ao obter localização: $e';
    }
  }
}