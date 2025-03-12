import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';

class FileScreen extends StatefulWidget {
  @override
  _FileScanScreenState createState() => _FileScanScreenState();
}

class _FileScanScreenState extends State<FileScreen> {
  List<File> _selectedImages = [];
  List<String> _extractedTexts = [];
  bool _processing = false;
  String? _pdfPath;
  String? _jsonPath;
  int _currentImageIndex = -1;
  final _textRecognizer = TextRecognizer();

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedImages =
              result.paths
                  .where((path) => path != null)
                  .map((path) => File(path!))
                  .toList();
          _extractedTexts = List.filled(
            _selectedImages.length,
            'Pendiente de procesar',
          );
          _currentImageIndex = 0;
        });

        // Procesar la primera imagen inmediatamente
        if (_selectedImages.isNotEmpty) {
          _processImage(_selectedImages[0], 0);
        }
      }
    } catch (e) {
      print('Error al seleccionar imágenes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imágenes: $e')),
      );
    }
  }

  Future<void> _processImage(File image, int index) async {
    setState(() {
      _processing = true;
      _extractedTexts[index] = 'Procesando...';
    });

    try {
      // Usar ML Kit para reconocimiento de texto
      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      String extractedText = recognizedText.text;

      setState(() {
        _extractedTexts[index] = extractedText;
      });
    } catch (e) {
      setState(() {
        _extractedTexts[index] = 'Error al procesar: $e';
      });
      print('Error en reconocimiento de texto: $e');
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }

  Future<void> _processAllImages() async {
    for (int i = 0; i < _selectedImages.length; i++) {
      if (_extractedTexts[i] == 'Pendiente de procesar') {
        await _processImage(_selectedImages[i], i);
      }
    }
  }

  Future<void> _generateDocuments() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No hay imágenes para procesar')));
      return;
    }

    // Procesar todas las imágenes primero si no se han procesado
    await _processAllImages();

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
        'imagenesPaths': _selectedImages.map((file) => file.path).toList(),
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
      for (int i = 0; i < _selectedImages.length; i++) {
        final imageBytes = await _selectedImages[i].readAsBytes();
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
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Archivos guardados correctamente')),
      );
    } catch (e) {
      print('Error al generar documentos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar documentos: $e')),
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

  Widget _buildImagePreview() {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _currentImageIndex = index;
                if (_extractedTexts[index] == 'Pendiente de procesar') {
                  _processImage(_selectedImages[index], index);
                }
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
                _selectedImages[index],
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
    return Scaffold(
      appBar: AppBar(title: Text('Escanear desde archivo')),
      body:
          _selectedImages.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 100, color: Colors.grey),
                    SizedBox(height: 20),
                    Text('No hay imágenes seleccionadas'),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: Icon(Icons.file_upload),
                      label: Text('Seleccionar imágenes'),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  Expanded(
                    flex: 1,
                    child:
                        _currentImageIndex >= 0
                            ? Image.file(_selectedImages[_currentImageIndex])
                            : Container(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: _buildImagePreview(),
                  ),
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Texto extraído (Página ${_currentImageIndex + 1}/${_selectedImages.length}):',
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
      bottomNavigationBar:
          _selectedImages.isEmpty
              ? null
              : BottomAppBar(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: Icon(Icons.add_photo_alternate),
                        label: Text('Cambiar imágenes'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _generateDocuments,
                        icon: Icon(Icons.save),
                        label: Text('Procesar y guardar'),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
