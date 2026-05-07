import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Pobierz listę dostępnych kamer
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Wybierz pierwszą (zazwyczaj tylną) kamerę
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!.initialize();
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    // Pamiętaj o zamknięciu kontrolera, aby zwolnić zasoby
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();

      if (!mounted) return;

      // Tutaj możesz coś zrobić ze zdjęciem, np. przejść do nowego ekranu
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Zapisano zdjęcie: ${image.path}')),
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Podgląd kamery
          _buildCameraPreview(),

          // 2. Ramka skanera (Twój design)
          Center(
            child: Container(
              width: 250,
              height: 350,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),

          // 3. Przycisk robienia zdjęcia
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.large(
                onPressed: _takePicture,
                child: const Icon(Icons.camera_alt),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // CameraPreview dopasowuje się do dostępnej przestrzeni
          return Center(
            child: CameraPreview(_controller!),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
