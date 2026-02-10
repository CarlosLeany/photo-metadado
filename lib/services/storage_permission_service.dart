import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class StoragePermissionService {
  /// Solicita permissão de armazenamento no Android
  /// Retorna true se a permissão foi concedida
  static Future<bool> requestStoragePermission() async {
    if (kIsWeb) {
      return true; // Web não precisa de permissão
    }

    try {
      // Verifica o status atual da permissão
      PermissionStatus status;
      
      
      // Para Android 13+ usa READ_MEDIA_IMAGES
      // Para Android 10-12 usa WRITE_EXTERNAL_STORAGE
      if (await Permission.photos.isGranted) {
        return true;
      }

      // Solicita a permissão apropriada
      if (await Permission.photos.isDenied) {
        status = await Permission.photos.request();
      } else {
        // Tenta photos primeiro (Android 13+)
        status = await Permission.photos.request();
        
        // Se não funcionar, tenta storage (Android 10-12)
        if (status.isDenied) {
          status = await Permission.storage.request();
        }
      }

      return status.isGranted;
    } catch (e) {
      debugPrint('Erro ao solicitar permissão de armazenamento: $e');
      return false;
    }
  }

  /// Verifica se tem permissão de armazenamento
  static Future<bool> hasStoragePermission() async {
    if (kIsWeb) return true;
    
    return await Permission.photos.isGranted || 
           await Permission.storage.isGranted;
  }
}
