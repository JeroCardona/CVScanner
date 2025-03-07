import 'package:flutter/material.dart';
import 'screens/cvscanner_screen.dart'; // Asegúrate de importar esta pantalla correctamente
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      '/':
          (context) =>
              CsvScannerScreen(), // Asegúrate de que CsvScannerScreen sea usada aquí
      '/home': (context) => HomeScreen(),
      '/login': (context) => LoginScreen(),
      '/register': (context) => RegisterScreen(),
    };
  }
}
