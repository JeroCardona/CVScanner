import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Importación de pantallas
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/file_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        // Pantalla inicial
        '/': (context) => LoginScreen(),

        // Rutas principales
        '/home': (context) => ScanScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),

        // Pantalla para escanear desde archivo
        '/scanFile': (context) => 
            Scaffold(body: Center(child: Text('Escanear desde archivo'))),

        // Pantalla para escanear desde cámara (recibe argumentos)
        '/scanCamera': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>?;
          return CameraScreen(ownerDocument: args?['ownerDocument']);
        },

        // Escaneos anteriores
        '/previousScans': (context) =>
            Scaffold(body: Center(child: Text('Hojas de vida anteriores'))),
      },
    );
  }
}
