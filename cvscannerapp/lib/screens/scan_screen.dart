import 'package:flutter/material.dart';
import 'login_screen.dart';

class ScanScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 50),
                      Image.asset(
                        'assets/images/logo_cvscanner.png',
                        height: 50,
                      ),
                      SizedBox(height: 50),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/scanCamera');
                        },
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: EdgeInsets.all(30),
                          child: Center(
                            child: Image.asset(
                              'assets/images/logo_camera.png',
                              height: 80,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/scanFile');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 20), // Desplaza la imagen hacia la derecha
                              Image.asset(
                                'assets/images/carpeta.png',
                                height: 24,
                              ),
                              SizedBox(width: 15), // Espaciado entre la imagen y el texto
                              Expanded(
                                child: Text(
                                  'Escanear desde archivo existente',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      _buildFileItem('Resume 1', '1/02/2025'),
                      SizedBox(height: 15),
                      _buildFileItem('Resume 2', '10/02/2025'),
                      SizedBox(height: 15),
                      _buildFileItem('Resume 3', '29/01/2025'),
                      SizedBox(height: 15),
                      _buildFileItem('Resume 4', '25/01/2025'),
                      SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Logo Magneto en la parte inferior izquierda
                          Image.asset(
                            'assets/images/logo_magneto.png',
                            height: 40,
                          ),
                          // Botón de salir en la parte inferior derecha
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            icon: Icon(Icons.logout, color: Colors.black),
                            label: Text(
                              'Salir',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileItem(String title, String date) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Image.asset('assets/images/files.png', height: 24),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(date, style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}