import 'package:flutter/material.dart';
import 'screens/cvscanner_screen.dart'; // Asegúrate de que esta importación sea correcta
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/camera_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => CsvScannerScreen(),
        '/home': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/scanFile':
            (context) =>
                Scaffold(body: Center(child: Text('Escanear desde archivo'))),
        '/scanCamera': (context) => CameraScreen(),
        '/previousScans':
            (context) =>
                Scaffold(body: Center(child: Text('Hojas de vida anteriores'))),
      },
    );
  }
}
