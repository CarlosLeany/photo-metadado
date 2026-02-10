import 'package:flutter/material.dart';

/// Widget separado para o overlay de processamento
class ProcessingOverlay extends StatelessWidget {
  final String message;

  const ProcessingOverlay({
    super.key,
    this.message = "Processando...",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
