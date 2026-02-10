import 'package:flutter/material.dart';
import 'package:flutter_template/screens/camera_screen.dart';
import 'package:flutter_template/main.dart' as main_app;

class AppRoutes {
  // Nomes das rotas como constantes para evitar erros de digitação
  static const String home = '/';
  static const String login = '/login';
  static const String camera = '/camera';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case camera:
        return MaterialPageRoute(
          builder: (_) => CameraScreen(cameras: main_app.cameras),
        );
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