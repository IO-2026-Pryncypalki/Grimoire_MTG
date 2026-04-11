import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // dla rootBundle
import 'package:path_provider/path_provider.dart'; // dla getTemporaryDirectory
import 'package:image_picker/image_picker.dart'; // dla aparatu
import 'scanner/text_scanner.dart'; // Twoja klasa skanera

// --- SERWIS APARATU ---
class CameraService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> takePhotoPath() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      return photo?.path;
    } catch (e) {
      debugPrint("Błąd aparatu: $e");
      return null;
    }
  }
}

// --- GŁÓWNA APLIKACJA ---
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR Scanner',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const ScannerScreen(),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final CameraService _cameraService = CameraService();
  final TextScanner _scanner = TextScanner();
  
  String _recognizedText = "Kliknij przycisk, aby zeskanować tekst";
  bool _isLoading = false;

  // 1. Logika pobierania z assetów (Twoja stara funkcja)
  Future<String> _getAssetFilePath() async {
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/test_image.jpg';
    final file = File(path);

    final data = await rootBundle.load('assets/2.jpg');
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    await file.writeAsBytes(bytes);
    return path;
  }

  // 2. Wspólna metoda przetwarzania obrazu
  Future<void> _processImage(String path) async {
    setState(() {
      _isLoading = true;
      _recognizedText = "Skanowanie...";
    });

    try {
      final result = await _scanner.scanText(path);
      setState(() {
        _recognizedText = result.isEmpty ? "Nie wykryto tekstu." : result;
      });
    } catch (e) {
      setState(() {
        _recognizedText = "Błąd skanowania: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 3. Akcja: Zdjęcie z aparatu
  Future<void> _handleCameraAction() async {
    final path = await _cameraService.takePhotoPath();
    if (path != null) {
      await _processImage(path);
    }
  }

  // 4. Akcja: Test z assetów
  Future<void> _handleAssetAction() async {
    try {
      final path = await _getAssetFilePath();
      await _processImage(path);
    } catch (e) {
      setState(() => _recognizedText = "Błąd pliku asset: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Scanner Pro'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Kontener na wynik
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: SingleChildScrollView(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : Text(
                        _recognizedText,
                        style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
                      ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Przyciski akcji
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleCameraAction,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Aparat'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleAssetAction,
                    icon: const Icon(Icons.image),
                    label: const Text('Test (Asset)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}