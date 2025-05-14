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
        '/': (context) => LoginScreen(),
        '/home': (context) => ScanScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/scanFile':
            (context) =>
                Scaffold(body: Center(child: Text('Escanear desde archivos'))),
        '/scanCamera': (context) => CameraScreen(),
        '/previousScans':
            (context) =>
                Scaffold(body: Center(child: Text('Hojas de vida anteriores'))),
      },
    );
  }
}
