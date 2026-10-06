import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() {
  runApp(const UniScanApp());
}

class UniScanApp extends StatelessWidget {
  const UniScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UniScan OCR',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _imagen;
  String _textoReconocido = '';
  bool _procesando = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> seleccionarImagen() async {
    final XFile? imagenSeleccionada = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (imagenSeleccionada == null) {
      return;
    }

    setState(() {
      _imagen = File(imagenSeleccionada.path);
      _textoReconocido = '';
    });

    await reconocerTexto();
  }

  Future<void> reconocerTexto() async {
    if (_imagen == null) return;

    setState(() {
      _procesando = true;
    });

    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    try {
      final inputImage = InputImage.fromFile(_imagen!);

      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      setState(() {
        _textoReconocido = recognizedText.text;

        if (_textoReconocido.isEmpty) {
          _textoReconocido = 'No se encontró texto en la imagen.';
        }
      });
    } catch (e) {
      setState(() {
        _textoReconocido = 'Error al reconocer el texto: $e';
      });
    } finally {
      await textRecognizer.close();

      setState(() {
        _procesando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniScan OCR'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _procesando ? null : seleccionarImagen,
              icon: const Icon(Icons.image),
              label: const Text('Seleccionar imagen'),
            ),

            const SizedBox(height: 20),

            if (_imagen != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _imagen!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 20),

            if (_procesando)
              const CircularProgressIndicator(),

            if (!_procesando && _textoReconocido.isNotEmpty)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _textoReconocido,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}