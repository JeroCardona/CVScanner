import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login', // Ruta inicial
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/scanFile': (context) => Scaffold(body: Center(child: Text('Escanear desde archivo'))),
        '/scanCamera': (context) => Scaffold(body: Center(child: Text('Escanear desde cámara'))),
        '/previousScans': (context) => Scaffold(body: Center(child: Text('Hojas de vida anteriores'))),
      },
    );
  }
}