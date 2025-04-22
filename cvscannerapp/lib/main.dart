import 'package:flutter/material.dart';
import 'screens/file_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/scan_screen.dart';

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
        '/': (context) => LoginScreen(),
        '/home': (context) => ScanScreen(),
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
