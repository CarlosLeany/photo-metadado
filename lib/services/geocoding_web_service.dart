import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class GeocodingWebService {
  /// Obtém endereço usando coordenadas já disponíveis (mais rápido)
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      // Consulta a API do OpenStreetMap (Nominatim) com timeout
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1');

      final response = await http.get(url, headers: {
        'User-Agent': 'MeuAppDeObras/1.0',
        'Accept-Charset': 'utf-8',
      }).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Timeout ao buscar endereço');
        },
      );

      if (response.statusCode == 200) {
        // Garante que o encoding é UTF-8 para acentos
        final utf8Body = utf8.decode(response.bodyBytes);
        final data = json.decode(utf8Body);
        final addr = data['address'];

        // Monta a string tratando valores null
        String rua = addr['road'] ?? '';
        String numero = addr['house_number'] ?? '';
        String bairro = addr['suburb'] ?? addr['neighbourhood'] ?? '';
        String cidade = addr['city'] ?? addr['town'] ?? addr['municipality'] ?? '';
        String estado = addr['state'] ?? '';

        List<String> parts = [];
        if (rua.isNotEmpty) {
          if (numero.isNotEmpty) {
            parts.add("$rua Q $numero");
          } else {
            parts.add(rua);
          }
        }
        if (bairro.isNotEmpty) parts.add(bairro);
        if (cidade.isNotEmpty) parts.add(cidade);
        if (estado.isNotEmpty) parts.add(estado);

        return parts.isEmpty ? 'Endereço não encontrado' : parts.join('\n');
      } else {
        return "Erro ao buscar endereço";
      }
    } catch (e) {
      print('Erro no geocoding web: $e');
      return "Erro ao buscar endereço";
    }
  }

  /// Método legado - mantido para compatibilidade
  Future<String> getAddressFromWeb() async {
    // Pega a posição (Funciona no Chrome/Safari/Edge)
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5),
    );

    return getAddressFromCoordinates(position.latitude, position.longitude);
  }
}