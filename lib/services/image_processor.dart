import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

class ImageProcessor {
  /// Processa a imagem e adiciona metadados de forma otimizada
  /// Esta função deve ser chamada com compute() para rodar em isolate
  static Uint8List drawMetadata(Map<String, dynamic> data) {
    final Uint8List imageBytes = data['bytes'] as Uint8List;
    final String address = data['address'] as String;

    // 1. Decodifica com limite de tamanho para evitar travamentos
    img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) throw Exception('Erro ao decodificar imagem');

    // 2. Redimensiona IMEDIATAMENTE para liberar RAM e melhorar performance
    // Usa 800px como máximo para celulares simples (menos memória, mais rápido)
    img.Image processedImage;
    const int maxSize = 800; // Reduzido para celulares simples
    
    if (originalImage.width > maxSize || originalImage.height > maxSize) {
      // Mantém aspect ratio
      double ratio = originalImage.width / originalImage.height;
      int newWidth = maxSize;
      int newHeight = (maxSize / ratio).round();
      
      if (newHeight > maxSize) {
        newHeight = maxSize;
        newWidth = (maxSize * ratio).round();
      }
      
      processedImage = img.copyResize(
        originalImage,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear, // Mais rápido que cubic
      );
      
      // Libera memória da imagem original
      originalImage = null;
    } else {
      processedImage = originalImage;
    }

    // 3. Adiciona texto com metadados
    final timestamp = DateFormat("dd/MM/yyyy HH:mm:ss").format(DateTime.now());
    final fullText = "$timestamp\n$address";
    
    _drawTextDirectly(processedImage, fullText);

      // 4. Codifica em JPG com qualidade otimizada para celulares simples (65% - menor arquivo)
      final encoded = img.encodeJpg(processedImage, quality: 65);
      
      return Uint8List.fromList(encoded);
  }
  
  /// Cria um thumbnail rápido da imagem para preview
  static Uint8List? createThumbnail(Uint8List imageBytes, {int maxSize = 400}) {
    try {
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return null;
      
      if (image.width <= maxSize && image.height <= maxSize) {
        return imageBytes; // Já é pequena o suficiente
      }
      
      double ratio = image.width / image.height;
      int thumbWidth = maxSize;
      int thumbHeight = (maxSize / ratio).round();
      
      if (thumbHeight > maxSize) {
        thumbHeight = maxSize;
        thumbWidth = (maxSize * ratio).round();
      }
      
      final thumbnail = img.copyResize(
        image,
        width: thumbWidth,
        height: thumbHeight,
        interpolation: img.Interpolation.linear,
      );
      
      return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 60));
    } catch (e) {
      return null;
    }
  }

  static void _drawTextDirectly(img.Image image, String text) {
    final font = img.arial24;
    const lineHeight = 30;
    const padding = 15;
    
    final cleanText = _replaceAccents(text);
    final lines = cleanText.split('\n').where((l) => l.isNotEmpty).toList();
    
    final lineWidths = lines.map((l) => _measureTextWidth(l, font)).toList();
    final maxWidth = lineWidths.reduce((a, b) => a > b ? a : b);
    
    final bgWidth = maxWidth + (padding * 2);
    final bgHeight = (lines.length * lineHeight) + padding;
    
    // Posicionamento no canto inferior direito
    final bgX = image.width - bgWidth - 20;
    final bgY = image.height - bgHeight - 20;

    // Fundo semi-transparente
    img.fillRect(
      image,
      radius: 10,
      x1: bgX.toInt(), y1: bgY.toInt(),
      x2: (bgX + bgWidth).toInt(), y2: (bgY + bgHeight).toInt(),
      color: img.ColorRgba8(0, 0, 0, 150),
    );

    int currentY = bgY.toInt() + 10;
    for (int i = 0; i < lines.length; i++) {
      final lineX = (bgX + bgWidth - padding - lineWidths[i]).toInt();
      img.drawString(image, lines[i], font: font, x: lineX, y: currentY, color: img.ColorRgb8(255, 255, 255));
      currentY += lineHeight;
    }
  }

  static int _measureTextWidth(String text, img.BitmapFont font) {
    int width = 0;
    for (var char in text.runes) {
      if (font.characters.containsKey(char)) {
        width += font.characters[char]!.xAdvance;
      }
    }
    return width;
  }

  static String _replaceAccents(String text) {
    return text.replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i').replaceAll('ó', 'o').replaceAll('ú', 'u')
               .replaceAll('ã', 'a').replaceAll('õ', 'o').replaceAll('ç', 'c')
               .replaceAll('Á', 'A').replaceAll('É', 'E').replaceAll('Í', 'I').replaceAll('Ó', 'O').replaceAll('Ú', 'U');
  }
}