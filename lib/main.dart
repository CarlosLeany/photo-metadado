import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/theme/app_theme.dart';
import 'routes/app_routes.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o formato de data para português (necessário para web)
  await initializeDateFormatting('pt_BR', null);
  
  // Inicializa as câmeras disponíveis
  try {
    cameras = await availableCameras();
  } catch (e) {
    print('Erro ao inicializar câmeras: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Pro Template',
      debugShowCheckedModeBanner: false,
      
      // Tema
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // Navegação Centralizada
      initialRoute: AppRoutes.camera,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}