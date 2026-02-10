import 'dart:typed_data';

/// Stub para plataformas não-web
/// Este arquivo nunca será usado, mas é necessário para compilação
Future<String> downloadImageWeb(Uint8List imageBytes) {
  throw UnsupportedError('Download na web não suportado nesta plataforma');
}
