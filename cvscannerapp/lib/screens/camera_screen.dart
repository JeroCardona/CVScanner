import 'dart:async';
import 'dart:convert'; 
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
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
  String? _docxPath;
  String _cameraStatus = 'Inicializando cámara...';
  bool _cameraInitialized = false;
  int _currentImageIndex = -1;
  
  @override
  void initState() {
    super.initState();
    _requestPermissions().then((_) => _initializeCamera());
  }
  
  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.storage,
    ].request();
    
    // Verificar si los permisos fueron concedidos
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
      
      _controller = CameraController(
        cameras![0],
        ResolutionPreset.high,
      );
      
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
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La cámara no está inicializada')),
      );
      return;
    }
    
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/cvscanner';
    await Directory(dirPath).create(recursive: true);
    
    try {
      final XFile file = await _controller!.takePicture();
      File imageFile = File(file.path);
      
      setState(() {
        _capturedImages.add(imageFile);
        _currentImageIndex = _capturedImages.length - 1;
      });
      
      _processImage(imageFile);
    } catch (e) {
      print('Error al tomar foto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al tomar foto: $e')),
      );
    }
  }
  
  Future<void> _processImage(File image) async {
    setState(() {
      _processing = true;
      _extractedTexts.add('Procesando...');
    });
    
    try {
      // Realizar OCR localmente
      String text = await FlutterTesseractOcr.extractText(
        image.path,
        language: 'spa', // Idioma español, cambia según necesidades
      );
      
      setState(() {
        _extractedTexts[_currentImageIndex] = text;
      });
    } catch (e) {
      setState(() {
        _extractedTexts[_currentImageIndex] = 'Error al procesar: $e';
      });
      print('Error OCR: $e');
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }
  
  Future<void> _uploadAllImages() async {
    if (_capturedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No hay imágenes para procesar')),
      );
      return;
    }
    
    setState(() {
      _processing = true;
    });
    
    try {
      // Combinar todos los textos extraídos
      String combinedText = _extractedTexts.join('\n\n--- Nueva página ---\n\n');
      
      // Enviar la primera imagen al servidor (como representación)
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:3000/api/resumes/upload'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', 
          _capturedImages[0].path,
        ),
      );
      
      // Añadir el texto combinado como un campo adicional
      request.fields['combinedText'] = combinedText;
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseData);
        
        // Descargar PDF y DOCX
        await _downloadFile(jsonResponse['resume']['pdfUrl'], 'pdf');
        await _downloadFile(jsonResponse['resume']['docxUrl'], 'docx');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Procesamiento exitoso')),
        );
      } else {
        throw Exception('Error al subir imágenes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al subir imágenes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir imágenes: $e')),
      );
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }
  
  Future<void> _downloadFile(String url, String type) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000$url'),
      );
      
      if (response.statusCode == 200) {
        final Directory extDir = await getApplicationDocumentsDirectory();
        final String dirPath = '${extDir.path}/CV';
        await Directory(dirPath).create(recursive: true);
        final String filePath = join(dirPath, 'resume_${DateTime.now().millisecondsSinceEpoch}.$type');
        
        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        if (type == 'pdf') {
          setState(() {
            _pdfPath = filePath;
          });
        } else if (type == 'docx') {
          setState(() {
            _docxPath = filePath;
          });
        }
        
        print('Archivo $type guardado en: $filePath');
      } else {
        throw Exception('Error al descargar archivo $type: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al descargar archivo $type: $e');
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
      _docxPath = null;
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
                  color: _currentImageIndex == index ? Colors.blue : Colors.grey,
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
                : CameraPreview(_controller!),
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    _processing
                        ? Center(child: CircularProgressIndicator())
                        : Text(_extractedTexts[_currentImageIndex]),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (_pdfPath != null)
                          ElevatedButton(
                            onPressed: () => _openFile(_pdfPath),
                            child: Text('Abrir PDF'),
                          ),
                        if (_docxPath != null)
                          ElevatedButton(
                            onPressed: () => _openFile(_docxPath),
                            child: Text('Abrir DOCX'),
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
                onPressed: _takePicture,
                icon: Icon(Icons.camera),
                label: Text('Tomar foto'),
              ),
              if (_capturedImages.length > 0)
                ElevatedButton.icon(
                  onPressed: _uploadAllImages,
                  icon: Icon(Icons.upload_file),
                  label: Text('Procesar CV'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}