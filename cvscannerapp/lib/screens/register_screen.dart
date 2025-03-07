import 'package:flutter/material.dart';
import 'home_screen.dart'; // Asegúrate de tener esta pantalla creada

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Focus nodes for each input field
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  @override
  void dispose() {
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _register(BuildContext context) {
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String phone = _phoneController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    // Verificar si todos los campos están llenos
    if (firstName.isEmpty ||
        lastName.isEmpty ||
        phone.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showErrorSnackBar(context, 'Por favor, completa todos los campos');
    }
    // Verificar si las contraseñas coinciden
    else if (password != confirmPassword) {
      _showErrorSnackBar(context, 'Las contraseñas no coinciden');
    }
    // Verificar si la contraseña tiene menos de 8 caracteres
    else if (password.length < 8) {
      _showErrorSnackBar(
        context,
        'La contraseña debe tener al menos 8 caracteres',
      );
    } else {
      // Si todo está bien, navegar a la pantalla principal
      _navigateToHome(context);
    }
  }

  // Método para mostrar el SnackBar de error
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red, // Fondo rojo para indicar error
        behavior:
            SnackBarBehavior.floating, // Para que se muestre flotando arriba
        duration: Duration(seconds: 3), // Duración del SnackBar
      ),
    );
  }

  // Método para navegar a la pantalla de inicio (HomeScreen)
  void _navigateToHome(BuildContext context) {
    Navigator.of(context).push(_createRoute());
  }

  // Animación de transición al ir a la pantalla de inicio
  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registro')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Registro',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Campo para el nombre
            TextField(
              controller: _firstNameController,
              focusNode: _firstNameFocus, // Establecer el FocusNode aquí
              decoration: InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            // Campo para el apellido
            TextField(
              controller: _lastNameController,
              focusNode: _lastNameFocus, // Establecer el FocusNode aquí
              decoration: InputDecoration(
                labelText: 'Apellido',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            // Campo para el celular
            TextField(
              controller: _phoneController,
              focusNode: _phoneFocus, // Establecer el FocusNode aquí
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Celular',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            // Campo para el correo electrónico
            TextField(
              controller: _emailController,
              focusNode: _emailFocus, // Establecer el FocusNode aquí
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            // Campo para la contraseña
            TextField(
              controller: _passwordController,
              focusNode: _passwordFocus, // Establecer el FocusNode aquí
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            // Campo para confirmar la contraseña
            TextField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocus, // Establecer el FocusNode aquí
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmar contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            // Botón de registro
            ElevatedButton(
              onPressed: () => _register(context),
              child: Text('Registrar', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
