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
  File? _imageFile;
  String _extractedText = '';
  bool _processing = false;
  String? _pdfPath;
  String? _docxPath;
  String _cameraStatus = 'Inicializando cámara...';
  bool _cameraInitialized = false;
  
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
      
      setState(() {
        _imageFile = File(file.path);
      });
      
      _processImage(File(file.path));
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
      _extractedText = 'Procesando...';
    });
    
    try {
      // Realizar OCR localmente
      String text = await FlutterTesseractOcr.extractText(
        image.path,
        language: 'spa', // Idioma español, cambia según necesidades
      );
      
      setState(() {
        _extractedText = text;
      });
      
      // Enviar al servidor para procesar y crear PDF/DOCX
      await _uploadImage(image, text);
    } catch (e) {
      setState(() {
        _extractedText = 'Error al procesar: $e';
      });
      print('Error OCR: $e');
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }
  
  Future<void> _uploadImage(File image, String text) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:3000/api/resumes/upload'), // Usa tu IP local o dominio
      );
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', 
          image.path,
        ),
      );
      
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
        throw Exception('Error al subir imagen: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al subir imagen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir imagen: $e')),
      );
    }
  }
  
  Future<void> _downloadFile(String url, String type) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000$url'), // Usa tu IP local o dominio
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
      appBar: AppBar(title: Text('CV Scanner')),
      body: Column(
        children: [
          Expanded(
            flex: _imageFile != null ? 1 : 2,
            child: _imageFile != null
                ? Image.file(_imageFile!)
                : CameraPreview(_controller!),
          ),
          if (_imageFile != null)
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Texto extraído:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    _processing
                        ? Center(child: CircularProgressIndicator())
                        : Text(_extractedText),
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
                    SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _imageFile = null;
                            _extractedText = '';
                            _pdfPath = null;
                            _docxPath = null;
                          });
                        },
                        child: Text('Tomar otra foto'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _imageFile == null
          ? FloatingActionButton(
              onPressed: _takePicture,
              child: Icon(Icons.camera),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}