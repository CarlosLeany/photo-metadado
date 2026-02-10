import 'dart:html' as html;
import 'dart:typed_data';
import 'package:intl/intl.dart';

/// Implementação web para download de imagens
Future<String> downloadImageWeb(Uint8List imageBytes) async {
  // Gera nome do arquivo com timestamp
  final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  final fileName = 'foto_$timestamp.jpg';

  // Cria um Blob com os bytes da imagem
  final blob = html.Blob([imageBytes], 'image/jpeg');
  
  // Cria uma URL temporária para o blob
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  // Cria um elemento <a> para download
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  
  // Limpa a URL temporária após um delay
  Future.delayed(const Duration(milliseconds: 100), () {
    html.Url.revokeObjectUrl(url);
  });

  return fileName;
}
