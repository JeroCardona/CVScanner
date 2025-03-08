import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/camera_screen.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp( 
      debugShowCheckedModeBanner: false,
      initialRoute: '/login', 
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/scanFile': (context) => Scaffold(body: Center(child: Text('Escanear desde archivoddddddd'))),
        '/scanCamera': (context) => CameraScreen(), 
        '/previousScans': (context) => Scaffold(body: Center(child: Text('Hojas de vida anteriores'))),
      },
    );
  }
}