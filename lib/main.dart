import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'database_helper.dart';

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
          seedColor: Colors.indigo,
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

      final texto = recognizedText.text.trim();

      setState(() {
        _textoReconocido = texto.isEmpty
            ? 'No se encontró texto en la imagen.'
            : texto;
      });

      if (texto.isNotEmpty) {
        await DatabaseHelper.instance.insertScan(texto);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Escaneo guardado en la base de datos'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _textoReconocido = 'Error al reconocer el texto:\n$e';
      });
    } finally {
      await textRecognizer.close();

      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  void abrirHistorial() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HistoryPage(),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text(
        'UniScan OCR',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: abrirHistorial,
          icon: const Icon(Icons.history),
          tooltip: 'Historial',
        ),
      ],
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado
            Row(
              children: [
                const Icon(
                  Icons.document_scanner,
                  size: 42,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'UniScan OCR',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Reconocimiento de texto con ML Kit',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Botón
            ElevatedButton.icon(
              onPressed: _procesando ? null : seleccionarImagen,
              icon: const Icon(Icons.image),
              label: const Text(
                'Seleccionar imagen',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Vista pequeña de la imagen
            if (_imagen != null)
              SizedBox(
                height: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _imagen!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            if (_imagen != null)
              const SizedBox(height: 12),

            // Estado de procesamiento
            if (_procesando)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        'Analizando imagen...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

            // Texto reconocido
            if (!_procesando && _textoReconocido.isNotEmpty)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.text_snippet),
                          const SizedBox(width: 8),
                          const Text(
                            'Texto reconocido',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      const Divider(),

                      const SizedBox(height: 6),

                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _textoReconocido,
                            style: const TextStyle(
                              fontSize: 17,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Mensaje inicial
            if (!_procesando &&
                _textoReconocido.isEmpty &&
                _imagen == null)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.document_scanner_outlined,
                        size: 70,
                      ),
                      SizedBox(height: 15),
                      Text(
                        'Selecciona una imagen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'El texto reconocido aparecerá aquí.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _scans = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    cargarHistorial();
  }

  Future<void> cargarHistorial() async {
    final scans = await DatabaseHelper.instance.getScans();

    if (!mounted) return;

    setState(() {
      _scans = scans;
      _cargando = false;
    });
  }

  Future<void> eliminarScan(int id) async {
    await DatabaseHelper.instance.deleteScan(id);
    await cargarHistorial();
  }

  Future<void> eliminarTodo() async {
    await DatabaseHelper.instance.deleteAllScans();
    await cargarHistorial();
  }

  String formatearFecha(String fecha) {
    final date = DateTime.parse(fecha);

    final dia = date.day.toString().padLeft(2, '0');
    final mes = date.month.toString().padLeft(2, '0');
    final anio = date.year.toString();

    final hora = date.hour.toString().padLeft(2, '0');
    final minuto = date.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de escaneos'),
        actions: [
          if (_scans.isNotEmpty)
            IconButton(
              onPressed: eliminarTodo,
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Eliminar todo',
            ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _scans.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 70,
                      ),
                      SizedBox(height: 15),
                      Text(
                        'No hay escaneos guardados',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Los textos que reconozcas aparecerán aquí.',
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _scans.length,
                  itemBuilder: (context, index) {
                    final scan = _scans[index];

                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.text_snippet),
                        ),
                        title: Text(
                          scan['text'],
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            formatearFecha(
                              scan['created_at'],
                            ),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            eliminarScan(scan['id']);
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}