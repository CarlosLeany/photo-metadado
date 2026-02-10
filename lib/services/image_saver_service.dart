import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart'; // Pacote moderno para galeria

// Import condicional para web
import 'image_saver_service_stub.dart'
    if (dart.library.html) 'image_saver_service_web.dart' as web_helper;

class ImageSaverService {
  /// Salva a imagem processada no dispositivo (Galeria no Mobile / Download na Web)
  static Future<String> saveImage(Uint8List imageBytes) async {
    try {
      // 1. Lógica para WEB
      if (kIsWeb) {
        return await web_helper.downloadImageWeb(imageBytes);
      }

      // 2. Lógica para MOBILE (Android e iOS)
      
      // Criar um arquivo temporário primeiro (necessário para o Gal salvar)
      final tempDir = await getTemporaryDirectory();
      final String fileName = 'Stamp_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String fullPath = '${tempDir.path}/$fileName';
      
      final file = File(fullPath);
      await file.writeAsBytes(imageBytes);

      // Solicita permissão e salva na galeria de uma vez
      // O Gal cuida das permissões do Android 13+ e iOS automaticamente
      await Gal.putImage(fullPath);

      // Opcional: Deletar o arquivo temporário após salvar na galeria
      try { await file.delete(); } catch (_) {}

      debugPrint('Foto enviada para a Galeria com sucesso');
      
      // No mobile, retornamos um nome amigável ou o caminho da galeria
      return "Galeria/Fotos"; 
      
    } catch (e) {
      debugPrint('Erro ao salvar imagem: $e');
      rethrow;
    }
  }

  /// Alias para manter compatibilidade com suas chamadas antigas
  static Future<String> saveToGallery(Uint8List imageBytes) async {
    return await saveImage(imageBytes);
  }
}