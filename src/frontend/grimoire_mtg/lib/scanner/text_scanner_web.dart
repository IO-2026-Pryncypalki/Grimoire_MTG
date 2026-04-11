import 'text_scanner.dart';

class WebTextScanner implements TextScanner {
  @override
  Future<String> scanText(String path) async {
    return "ML Kit nie działa na webie 😄";
  }
}
TextScanner getScanner() => WebTextScanner();