import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'scan_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';



class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _documentController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _documentController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (_documentController.text.isEmpty || _passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      _showSnackBar('Por favor, completa todos los campos');
      return;
    }

    if (_passwordController.text.length < 8) {
      _showSnackBar('La contraseña debe tener al menos 8 caracteres');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Las contraseñas no coinciden');
      return;
    }

    final url = Uri.parse('http://${dotenv.env['ip']}/api/users');

    final body = {
      "document": _documentController.text.trim(),
      "password": _passwordController.text,
      "confirmPassword": _confirmPasswordController.text,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      _showSnackBar('Usuario registrado exitosamente', Colors.green);
      _navigateToHome(context);
    } else {
      final data = jsonDecode(response.body);
      _showSnackBar(data['message'] ?? 'Error al registrar usuario');
    }
  }

  void _showSnackBar(String message, [Color color = Colors.red]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    Navigator.of(context).push(_createRoute());
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => ScanScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset("assets/images/logo_cvscanner.png", height: 50),
                    SizedBox(height: 10),
                    Text(
                      "¡Regístrate!",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text("Por favor, ingresa tus datos para crear tu cuenta"),
                    SizedBox(height: 20),
                    TextField(
                      controller: _documentController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Documento',
                        filled: true,
                        fillColor: Colors.grey[300],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        filled: true,
                        fillColor: Colors.grey[300],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900], // Azul oscuro
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      child: Text(
                        'Registrarse',
                        style: TextStyle(fontSize: 18, color: Colors.white), // Letra blanca
                      ),
                    ),
                    SizedBox(height: 30),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Image.asset("assets/images/logo_magneto.png", height: 50),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}