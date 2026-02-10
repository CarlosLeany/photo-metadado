import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';
import '../services/image_processor.dart';
import '../services/image_saver_service.dart';
import '../widgets/preview_action_buttons.dart';
import '../widgets/processing_overlay.dart';

class PreviewScreen extends StatefulWidget {
  final String imagePath;
  final String address;

  const PreviewScreen({
    super.key,
    required this.imagePath,
    required this.address,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  Uint8List? _originalImageBytes;
  Uint8List? _processedImageBytes;
  bool _isLoading = true; // Estado inicial: carregando
  bool _isProcessing = false; // Processando metadados
  bool _isSaving = false; // Salvando imagem
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Inicia o carregamento após a tela ser renderizada
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAndProcess());
  }

  /// Carrega a imagem e processa até finalizar completamente
  Future<void> _loadAndProcess() async {
    try {
      // 1. Carrega os bytes do arquivo
      Uint8List bytes;
      if (kIsWeb) {
        bytes = await XFile(widget.imagePath).readAsBytes();
      } else {
        final file = File(widget.imagePath);
        if (!await file.exists()) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          }
          return;
        }
        bytes = await file.readAsBytes();
      }

      // 2. Mostra a imagem original carregada
      if (mounted) {
        setState(() {
          _originalImageBytes = bytes;
          _isLoading = false; // Terminou de carregar
          _isProcessing = true; // Inicia processamento
        });
      }

      // 3. Processa em isolate separado (não trava a UI)
      final processed = await compute(
        ImageProcessor.drawMetadata,
        {
          'bytes': bytes,
          'address': widget.address,
        },
      );

      // 4. Atualiza com imagem processada (finalizada)
      if (mounted) {
        setState(() {
          _processedImageBytes = processed;
          _isProcessing = false; // Finalizou tudo
        });
      }
    } catch (e) {
      debugPrint("Erro ao processar imagem: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _isProcessing = false;
        });
        
        // Mostra mensagem de erro mais amigável
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('memory') || e.toString().contains('Memory')
                  ? 'Memória insuficiente. Tente uma foto menor.'
                  : 'Erro ao processar imagem: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _handleDiscard() {
    Navigator.pop(context);
  }

  Future<void> _handleConfirm() async {
    // Escolhe a imagem processada, se não houver, usa a original
    final imageToSave = _processedImageBytes ?? _originalImageBytes;
    
    if (imageToSave == null) return;

    try {
      setState(() {
        _isSaving = true; // Ativa o ProcessingOverlay com a mensagem "Salvando..."
      });

      // Chama o serviço atualizado
      final String savedPath = await ImageSaverService.saveImage(imageToSave);

      if (mounted) {
        setState(() => _isSaving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Foto salva na galeria com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        // Aguarda o usuário ver o feedback antes de fechar
        await Future.delayed(const Duration(milliseconds: 800));
        Navigator.pop(context, savedPath);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Confirmar Foto"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Exibição da Imagem
          Center(
            child: _hasError
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text(
                        "Erro ao carregar imagem",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  )
                : _isLoading || _originalImageBytes == null
                    ? const SizedBox.shrink() // Não mostra nada, apenas o overlay com texto
                    : Image.memory(
                        _processedImageBytes ?? _originalImageBytes!,
                        fit: BoxFit.contain,
                        gaplessPlayback: true, // Evita flicker ao trocar
                        // Cache width reduzido para celulares simples (800px max)
                        cacheWidth: _processedImageBytes != null ? null : 800,
                        filterQuality: FilterQuality.low, // Mais rápido para preview
                      ),
          ),

          // Overlay de Loading/Processamento/Salvamento
          if (_isLoading || _isProcessing || _isSaving)
            ProcessingOverlay(
              message: _isLoading 
                  ? "Carregando foto..." 
                  : _isProcessing
                      ? "Estampando metadados..."
                      : "Salvando foto...",
            ),
        ],
      ),
      bottomNavigationBar: _hasError || _isLoading || _isProcessing || _isSaving
          ? null
          : PreviewActionButtons(
              onDiscard: _handleDiscard,
              onConfirm: _handleConfirm,
              isLoading: false,
            ),
    );
  }
}