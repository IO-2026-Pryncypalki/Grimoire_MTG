import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'text_scanner.dart';

class MobileTextScanner implements TextScanner {
  @override
  Future<String> scanText(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final textRecognizer = TextRecognizer();

    final result = await textRecognizer.processImage(inputImage);

    textRecognizer.close();
    return result.text;
  }
} 

TextScanner getScanner() => MobileTextScanner();