import 'package:flutter/material.dart';
import 'screens/cvscanner_screen.dart'; // Asegúrate de que esta importación sea correcta
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // La ruta inicial será '/' (CsvScannerScreen)
      routes: {
        '/':
            (context) =>
                CsvScannerScreen(), // Asegúrate de que CsvScannerScreen esté correctamente importado
        '/home': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/scanFile':
            (context) =>
                Scaffold(body: Center(child: Text('Escanear desde archivo'))),
        '/scanCamera':
            (context) =>
                Scaffold(body: Center(child: Text('Escanear desde cámara'))),
        '/previousScans':
            (context) =>
                Scaffold(body: Center(child: Text('Hojas de vida anteriores'))),
      },
    );
  }
}
