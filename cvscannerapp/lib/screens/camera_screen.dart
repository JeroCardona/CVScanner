import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CameraScreen extends StatefulWidget {
  final String? ownerDocument;

  const CameraScreen({Key? key, this.ownerDocument}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  List<File> _capturedImages = [];
  List<String> _extractedTexts = [];
  bool _processing = false;
  String? _pdfPath;
  String? _jsonPath;
  String _cameraStatus = 'Inicializando cámara...';
  bool _cameraInitialized = false;
  int _currentImageIndex = -1;
  final _textRecognizer = TextRecognizer();

  @override
  void initState() {
    super.initState();
    _requestPermissions().then((_) => _initializeCamera());
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses =
        await [Permission.camera, Permission.storage].request();

    if (statuses[Permission.camera] != PermissionStatus.granted) {
      setState(() {
        _cameraStatus = 'Permiso de cámara denegado';
      });
    }

    if (statuses[Permission.storage] != PermissionStatus.granted) {
      setState(() {
        _cameraStatus += '\nPermiso de almacenamiento denegado';
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();

      if (cameras == null || cameras!.isEmpty) {
        setState(() {
          _cameraStatus = 'No hay cámaras disponibles';
        });
        return;
      }

      _controller = CameraController(cameras![0], ResolutionPreset.high);

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _cameraInitialized = true;
          _cameraStatus = 'Cámara lista';
        });
      }
    } catch (e) {
      setState(() {
        _cameraStatus = 'Error al inicializar la cámara: $e';
      });
      print('Error de inicialización de cámara: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
    }

    Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      ScaffoldMessenger.of(
      context,
      ).showSnackBar(SnackBar(content: Text('La cámara no está inicializada')));
      return;
    }

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/cvscanner';
    await Directory(dirPath).create(recursive: true);

    try {
      final XFile file = await _controller!.takePicture();
      File imageFile = File(file.path);

      // Guardar la imagen en una ubicación permanente
      final String fileName =
        'cvscanner_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String permanentPath = join(dirPath, fileName);

      File permanentFile = await imageFile.copy(permanentPath);

      setState(() {
        _capturedImages.add(permanentFile);
        _currentImageIndex = _capturedImages.length - 1;
      });

      _processImage(permanentFile);
    } catch (e) {
      print('Error al tomar foto: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al tomar foto: $e')));
    }
  }

  Future<void> _processImage(File image) async {
    setState(() {
      _processing = true;
      _extractedTexts.add('Procesando...');
    });

    try {
      // Usar ML Kit para reconocimiento de texto
      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      String extractedText = recognizedText.text;

      setState(() {
        _extractedTexts[_currentImageIndex] = extractedText;
      });
    } catch (e) {
      setState(() {
        _extractedTexts[_currentImageIndex] = 'Error al procesar: $e';
      });
      print('Error en reconocimiento de texto: $e');
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }

Future<void> _sendToBackend() async {
  if (_capturedImages.isEmpty || _extractedTexts.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No hay texto o imágenes para enviar')),
    );
    return;
  }

  if (widget.ownerDocument == null || widget.ownerDocument!.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se especificó la cédula del dueño del CV')),
    );
    return;
  }

  setState(() {
    _processing = true;
  });

  try {
    // Combinar los textos extraídos
    String combinedText = _extractedTexts.join(
      '\n\n--- Nueva página ---\n\n',
    );

    // Crear solicitud multipart
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://${dotenv.env['ip']}/api/resumes/upload'),
    );

    // Agregar imagen principal (solo la primera)
    request.files.add(
      await http.MultipartFile.fromPath('image', _capturedImages[0].path),
    );

    // Enviar la cédula del dueño y el texto
    request.fields['ownerDocument'] = widget.ownerDocument!;
    request.fields['combinedText'] = combinedText;

    // Enviar
    var response = await request.send();

    if (response.statusCode == 200 || response.statusCode == 201) {
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CV guardado exitosamente en la base de datos')),
      );

      // Limpiar estado después de guardar
      setState(() {
        _capturedImages.clear();
        _extractedTexts.clear();
        _currentImageIndex = -1;
        _pdfPath = null;
        _jsonPath = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar: ${response.statusCode}')),
      );
    }
  } catch (e) {
    print('Error al enviar al servidor: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al enviar al servidor: $e')),
    );
  } finally {
    setState(() {
      _processing = false;
    });
  }
}


  Future<void> _processAndSaveDocuments() async {
    if (_capturedImages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No hay imágenes para procesar')));
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      // Combinar todos los textos extraídos
      String combinedText = _extractedTexts.join(
        '\n\n--- Nueva página ---\n\n',
      );

      // Crear directorio para guardar archivos
      final Directory extDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${extDir.path}/CV';
      await Directory(dirPath).create(recursive: true);

      // Generar nombres de archivo con timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Crear y guardar archivo JSON
      final jsonPath = join(dirPath, 'cv_data_$timestamp.json');
      final Map<String, dynamic> jsonData = {
        'fecha': DateTime.now().toIso8601String(),
        'textoExtraido': _extractedTexts,
        'imagenesPaths': _capturedImages.map((file) => file.path).toList(),
        'textoCompleto': combinedText,
      };

      final File jsonFile = File(jsonPath);
      await jsonFile.writeAsString(json.encode(jsonData));

      // Generar PDF localmente
      final pdfPath = join(dirPath, 'cv_$timestamp.pdf');
      final pdf = pw.Document();

      // Añadir texto extraído al PDF
       pdf.addPage(
         pw.MultiPage(
           build: (pw.Context context) {
             return [
               pw.Header(level: 0, child: pw.Text('CV Escaneado')),
               pw.Paragraph(text: combinedText),
             ];
           },
         ),
       );

      // Añadir imágenes al PDF
      for (int i = 0; i < _capturedImages.length; i++) {
        final imageBytes = await _capturedImages[i].readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Center(child: pw.Image(image));
            },
          ),
        );
      }

      // Guardar PDF
      final File pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(await pdf.save());

      setState(() {
        _pdfPath = pdfPath;
        _jsonPath = jsonPath;
        _currentImageIndex = _capturedImages.length - 1; // Mantener la vista actual
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Archivos guardados correctamente')),
      );
    } catch (e) {
      print('Error al procesar documentos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar documentos: $e')),
      );
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }

  void _openFile(String? path) {
    if (path != null) {
      OpenFile.open(path);
    }
  }

  void _resetCapture() {
    setState(() {
      _capturedImages = [];
      _extractedTexts = [];
      _currentImageIndex = -1;
      _pdfPath = null;
      _jsonPath = null;
    });
  }

  Widget _buildCapturedImagesPreview() {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _capturedImages.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _currentImageIndex = index;
              });
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      _currentImageIndex == index ? Colors.blue : Colors.grey,
                  width: 2,
                ),
              ),
              child: Image.file(
                _capturedImages[index],
                width: 80,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text('CV Scanner')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(_cameraStatus, textAlign: TextAlign.center),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeCamera,
                child: Text('Reintentar inicializar cámara'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('CV Scanner'),
        actions: [
          if (_capturedImages.isNotEmpty)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _resetCapture,
              tooltip: 'Reiniciar captura',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: _currentImageIndex >= 0 ? 1 : 2,
            child: _currentImageIndex >= 0
                ? Image.file(_capturedImages[_currentImageIndex])
                : CameraPreview(_controller!), // Mostrar la vista previa de la cámara
          ),
          if (_capturedImages.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: _buildCapturedImagesPreview(),
            ),
          if (_currentImageIndex >= 0)
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Texto extraído (Página ${_currentImageIndex + 1}/${_capturedImages.length}):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    _processing
                        ? Center(child: CircularProgressIndicator())
                        : Text(_extractedTexts[_currentImageIndex]),
                    SizedBox(height: 16),
                    // Modificar el botón de Generar PDF en el Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _currentImageIndex = -1; // Mostrar la cámara
                            });
                            _takePicture();
                          },
                          child: Text('Añadir otra foto'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await _processAndSaveDocuments();
                            if (_pdfPath != null) {
                              _openFile(_pdfPath); // Abrir el PDF automáticamente después de generarlo
                            }
                            await _sendToBackend();
                          },
                          child: Text('Generar PDF'),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (_pdfPath != null)
                          ElevatedButton(
                            onPressed: () => _openFile(_pdfPath),
                            child: Text('Abrir PDF'),
                          ),
                        if (_jsonPath != null)
                          ElevatedButton(
                            onPressed: () => _openFile(_jsonPath),
                            child: Text('Abrir JSON'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _takePicture, // Llamar a _takePicture en lugar de solo cambiar el índice
                icon: Icon(Icons.camera),
                label: Text('Tomar otra foto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}