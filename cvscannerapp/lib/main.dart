import 'package:flutter/material.dart';
import 'routes.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      initialRoute: '/',  // Página de inicio
      routes: AppRoutes.getRoutes(),  // Llama a las rutas definidas
    );
  }
}
