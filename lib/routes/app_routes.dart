import 'package:flutter/material.dart';
import 'package:flutter_template/screens/home_screen.dart'; // Exemplo de tela

class AppRoutes {
  // Nomes das rotas como constantes para evitar erros de digitação
  static const String home = '/';
  static const String login = '/login';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      
      // case login:
      //   return MaterialPageRoute(builder: (_) => const LoginScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Rota não encontrada: ${settings.name}')),
          ),
        );
    }
  }
}