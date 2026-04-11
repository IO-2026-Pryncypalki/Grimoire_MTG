import 'text_scanner_impl.dart'; // Importujemy plik z warunkowym eksportem

abstract class TextScanner {
  // Konstruktor fabryczny, który zwraca odpowiednią implementację
  factory TextScanner() => getScanner(); 

  Future<String> scanText(String path);
}