import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:open_file/open_file.dart';

class CameraScreen extends StatefulWidget {
  final String? ownerDocument;

  const CameraScreen({Key? key, this.ownerDocument}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final List<File> _capturedImages = [];
  final List<String> _extractedTexts = [];
  final _textRecognizer = TextRecognizer();
  bool _processing = false;
  String? _formattedResult;
  int _currentImageIndex = -1;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No hay cámaras disponibles')),
        );
        return;
      }

      _controller = CameraController(cameras[0], ResolutionPreset.high);
      await _controller!.initialize();

      if (mounted) setState(() {});
    } catch (e) {
      print('Error al inicializar la cámara: $e');
    }
  }

  Future<void> _takePictureAndProcess() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() => _processing = true);

    try {
      final XFile file = await _controller!.takePicture();
      final File imageFile = File(file.path);

      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final extractedText = recognizedText.text;

      if (extractedText.trim().isNotEmpty) {
        setState(() {
          _capturedImages.add(imageFile);
          _extractedTexts.add(extractedText);
          _currentImageIndex = _capturedImages.length - 1;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se detectó texto en esta imagen.')),
        );
      }
    } catch (e) {
      print("Error al procesar imagen: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al tomar o procesar la imagen')),
      );
    } finally {
      setState(() => _processing = false);
    }
  }

  Future<void> _processAllAndSendToAI() async {
    if (_extractedTexts.isEmpty) return;

    setState(() => _processing = true);

    try {
      final combinedText = _extractedTexts.join(
        '\n\n--- Página siguiente ---\n\n',
      );

      final uri = Uri.parse('http://${dotenv.env['ip']}/api/resumes/upload');
      final request = http.MultipartRequest('POST', uri);

      request.fields['combinedText'] = combinedText;
      request.fields['ownerDocument'] = widget.ownerDocument ?? 'sin_cedula';

      if (_capturedImages.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            _capturedImages.first.path,
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final jsonResponse = json.decode(responseBody);
        final resumeId = jsonResponse['resume']['id'];

        final downloadUrl =
            'http://${dotenv.env['ip']}/api/resumes/download/$resumeId';

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('CV generado'),
            content: Text('Puedes descargar tu archivo generado.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cerrar'),
              ),
              TextButton(
                onPressed: () async {
                  final launched = await OpenFile.open(downloadUrl);
                  if (launched.type == ResultType.noAppToOpen) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No se pudo abrir el archivo')),
                    );
                  }
                },
                child: Text('Descargar .docx'),
              ),
            ],
          ),
        );
      } else {
        throw Exception('Error: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      print('Error al enviar a la IA: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar texto al backend')),
      );
    } finally {
      setState(() => _processing = false);
    }
  }

  void _resetCapture() {
    setState(() {
      _capturedImages.clear();
      _extractedTexts.clear();
      _currentImageIndex = -1;
      _formattedResult = null;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Definir el color azul oscuro para todos los botones
    final Color darkBlueColor = Color(0xFF0D47A1); // Azul oscuro
    final Color textColor = Colors.white; // Texto blanco

    return Scaffold(
      appBar: AppBar(
        title: Text('Scanner de CV'),
        actions: [
          if (_capturedImages.isNotEmpty)
            IconButton(
              onPressed: _resetCapture,
              icon: Icon(Icons.refresh),
              tooltip: 'Reiniciar',
            ),
        ],
      ),
      body: _controller == null || !_controller!.value.isInitialized
          ? Center(child: Text('Cargando cámara...'))
          : Column(
        children: [
          if (_currentImageIndex == -1)
            Expanded(child: CameraPreview(_controller!))
          else
            Expanded(
              child: Image.file(_capturedImages[_currentImageIndex]),
            ),
          if (_capturedImages.isNotEmpty)
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _capturedImages.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () {
                    setState(() => _currentImageIndex = index);
                  },
                  child: Container(
                    margin: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _currentImageIndex == index
                            ? Colors.blue
                            : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Image.file(
                      _capturedImages[index],
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          if (_currentImageIndex != -1 && !_processing)
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(8),
                child: Text(
                  _extractedTexts[_currentImageIndex],
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          if (_processing) LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: [
                if (_capturedImages.isEmpty)
                  ElevatedButton.icon(
                    onPressed: _takePictureAndProcess,
                    icon: Icon(Icons.camera_alt, color: textColor),
                    label: Text('Tomar foto', style: TextStyle(color: textColor)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkBlueColor,
                    ),
                  ),
                if (_capturedImages.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _takePictureAndProcess,
                    icon: Icon(Icons.add_photo_alternate, color: textColor),
                    label: Text('Añadir otra foto', style: TextStyle(color: textColor)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkBlueColor,
                    ),
                  ),
                if (_capturedImages.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _processAllAndSendToAI,
                    icon: Icon(Icons.check, color: textColor),
                    label: Text('Procesar CV completo', style: TextStyle(color: textColor)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkBlueColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}