import 'package:flutter/material.dart';

/// Widget separado para os botões de ação da preview screen
/// Corrige o problema de layout com largura infinita
class PreviewActionButtons extends StatelessWidget {
  final VoidCallback onDiscard;
  final VoidCallback onConfirm;
  final bool isLoading;

  const PreviewActionButtons({
    super.key,
    required this.onDiscard,
    required this.onConfirm,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Botão Descartar
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              child: TextButton(
                onPressed: isLoading ? null : onDiscard,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Descartar",
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Botão Confirmar
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              child: ElevatedButton(
                onPressed: isLoading ? null : onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(0, 48), // Altura mínima fixa
                ),
                child: const Text(
                  "Confirmar",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
