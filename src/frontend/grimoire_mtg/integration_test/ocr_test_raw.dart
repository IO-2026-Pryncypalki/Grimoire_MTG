import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:grimoire_mtg/scanner/text_scanner.dart'; // Zmień na Twój import

String extractExpectedName(String filePath) {
  final fileName = filePath.split('/').last;

  return fileName
      .replaceAll('_final.png', '')
      .replaceAll('_', ' ')
      .toLowerCase()
      .trim();
}

bool fuzzyMatch(String recognized, String expected) {
  final r = recognized.toLowerCase().trim();
  final e = expected.toLowerCase().trim();

  if (r.isEmpty) return false;

  final dist = levenshtein(r, e);
  final threshold = (e.length * 0.4).round();

  return dist <= threshold;
}

int levenshtein(String s, String t) {
  final dp = List.generate(
    s.length + 1,
    (_) => List<int>.filled(t.length + 1, 0),
  );

  for (int i = 0; i <= s.length; i++) dp[i][0] = i;
  for (int j = 0; j <= t.length; j++) dp[0][j] = j;

  for (int i = 1; i <= s.length; i++) {
    for (int j = 1; j <= t.length; j++) {
      final cost = s[i - 1] == t[j - 1] ? 0 : 1;

      dp[i][j] = [
        dp[i - 1][j] + 1,
        dp[i][j - 1] + 1,
        dp[i - 1][j - 1] + cost,
      ].reduce((a, b) => a < b ? a : b);
    }
  }

  return dp[s.length][t.length];
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('OCR Accuracy Tests - assets/raw', () {
    final ocrService = TextScanner(); // Twoja klasa OCR

    testWidgets('Sprawdź wszystkie obrazy z losowym tłem', (tester) async {
      // 1. Pobierz listę plików z manifestu assetów
      final AssetManifest assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final List<String> imagePaths = assetManifest
          .listAssets()
          .where((String key) => key.startsWith('assets/raw/'))
          .toList();

      if (imagePaths.isEmpty) {
        fail("Nie znaleziono żadnych obrazów w assets/raw/");
      }

      int passed = 0;
      int total = imagePaths.length;
      List<String> failures = [];

      for (String assetPath in imagePaths) {
        print('Testowanie: $assetPath');

        // 2. ML Kit potrzebuje ścieżki do pliku na dysku, 
        // więc musimy skopiować asset do folderu tymczasowego
        final File file = await _copyAssetToFile(assetPath);

        try {
          // 3. Wywołaj rozpoznawanie tekstu
          final stopwatch = Stopwatch()..start();
          final String resultText = await ocrService.scanText(file.path);
          stopwatch.stop();
          final time_elapsed = stopwatch.elapsedMilliseconds/1000;
          // 4. Logika porównania: nazwa pliku vs pierwsza linijka
          // assets/final/napis.jpg -> oczekiwany tekst: "napis"
          String expectedText = extractExpectedName(assetPath);
          
          // Pobranie pierwszej linii i oczyszczenie z białych znaków
          String firstLine = resultText.split('\n').first.trim();

          if ( fuzzyMatch(firstLine.toLowerCase(), expectedText.toLowerCase()) ) {
            passed++;
            print('✅ SUKCES: Oczekiwano "$expectedText", otrzymano "$firstLine"');
          } else {
            failures.add('❌ BŁĄD w $assetPath: Oczekiwano "$expectedText", ale OCR wykrył "$firstLine"');
            print(failures.last);
          }
          print('Czas skanowania: "$time_elapsed"');
        } catch (e) {
          failures.add('💥 CRASH w $assetPath: $e');
        }
      }

      // 5. Podsumowanie wyników
      print('\n=== PODSUMOWANIE ===');
      print('Wynik: $passed / $total (${(passed / total * 100).toStringAsFixed(1)}%)');
      
      if (failures.isNotEmpty) {
        print('\nSzczegóły błędów:');
        failures.forEach(print);
      }

      expect(passed, greaterThanOrEqualTo(total * 0.70), reason: 'Nie rozpoznano więcej niż 30% obrazów.');
    });
  });
}

/// Pomocnicza funkcja kopiująca asset do pliku tymczasowego
Future<File> _copyAssetToFile(String assetPath) async {
  final byteData = await rootBundle.load(assetPath);
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/${assetPath.split('/').last}');
  await file.writeAsBytes(byteData.buffer.asUint8List());
  return file;
}