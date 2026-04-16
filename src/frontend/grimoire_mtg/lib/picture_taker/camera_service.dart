import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  // Funkcja do robienia zdjęcia aparatem
  Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800, // Opcjonalna optymalizacja rozmiaru
        maxHeight: 1800,
        imageQuality: 85, // Kompresja (0-100)
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      print("Błąd podczas robienia zdjęcia: $e");
      return null;
    }
  }

  // Funkcja do wybierania zdjęcia z galerii
  Future<File?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    return image != null ? File(image.path) : null;
  }
}