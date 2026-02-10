import 'package:flutter/material.dart';
import '../components/app_button.dart'; // Importando seu componente customizado

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  // Simulação de uma função de login/processamento
  void _handlePress() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2)); // Simula delay de rede
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Pro'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho estilizado via tema
            Text(
              'Área de Testes',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
            ),
            const SizedBox(height: 8),
            const Text('Valide aqui o comportamento dos seus componentes.'),
            const SizedBox(height: 32),

            // --- SEÇÃO DE INPUTS ---
            const Text('FORMULÁRIO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Nível de Acesso',
                prefixIcon: Icon(Icons.shield_outlined),
              ),
              items: const [
                DropdownMenuItem(value: '1', child: Text('Admin')),
                DropdownMenuItem(value: '2', child: Text('Editor')),
              ],
              onChanged: (value) {},
            ),

            const SizedBox(height: 32),

            // --- SEÇÃO DE BOTÕES CUSTOMIZADOS ---
            const Text('AÇÕES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            
            // Usando seu AppButton com loading dinâmico
            AppButton(
              label: 'SALVAR ALTERAÇÕES',
              isLoading: _isLoading,
              onPressed: _handlePress,
            ),
            
            const SizedBox(height: 12),
            
            // Usando seu AppButton na versão Outlined com Ícone
            AppButton(
              label: 'VOLTAR AO INÍCIO',
              isOutlined: true,
              icon: Icons.arrow_back,
              onPressed: () {
                print("Botão secundário clicado");
              },
            ),

            const SizedBox(height: 32),

            // --- CARD INFORMATIVO ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: colors.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'As cores e bordas desta tela mudam automaticamente ao ativar o Modo Escuro no sistema.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}