# Opis projektu — Grimoire MtG

## Zastosowane zasady SOLID

### S — Single Responsibility Principle (Zasada jednej odpowiedzialności)

Każda klasa w systemie ma jedną, wyraźnie określoną odpowiedzialność:

- **SessionManager** — odpowiada wyłącznie za zarządzanie sesjami i autoryzację przez Google OAuth2: wymianę authorization code na dane użytkownika, tworzenie/wyszukiwanie konta oraz zarządzanie tokenami sesji. Nie zajmuje się logiką biznesową kart ani decków.
- **ScannerService** — odpowiada wyłącznie za przetwarzanie skanu karty (orkiestrację OCR → identyfikacja). Nie przechowuje wyników ani nie zarządza kolekcją.
- **Collection** — odpowiada za zarządzanie zbiorem wpisów kolekcji użytkownika (dodawanie, usuwanie, wycena). Nie zajmuje się budową decków ani sesjami.
- **CollectionEntry** — odpowiada za przechowywanie informacji o posiadaniu konkretnego egzemplarza karty: ilość, stan fizyczny (NM/GD/LP) i notatki użytkownika. Oddziela dane obiektywne karty (Card) od danych subiektywnych, zależnych od użytkownika.
- **Card** — przechowuje wyłącznie obiektywne dane karty ze Scryfall (nazwa, edycja, cena, obrazek). Nie zawiera informacji o posiadaniu ani stanie egzemplarza.
- **Deck** — odpowiada za skład talii i jej walidację. Nie odpowiada za logikę kolekcji ani skanowania.
- **ScryfallAdapter** — odpowiada wyłącznie za komunikację z zewnętrznym API Scryfall.

Dzięki temu zmiana np. sposobu komunikacji z API Scryfall nie wymaga modyfikacji klasy `Collection` ani `Deck` — zmienia się jedynie adapter.

### O — Open/Closed Principle (Zasada otwarte–zamknięte)

System jest otwarty na rozszerzenia, ale zamknięty na modyfikacje, dzięki zastosowaniu interfejsów:

- **ICardProvider** — interfejs dostawcy danych o kartach. Obecnie implementuje go `ScryfallAdapter`, ale w przyszłości można dodać np. `LocalDatabaseProvider` (cache offline) lub adapter do innego API (np. MTGJson) bez zmiany klas `Deck`, `Collection` czy `ScannerService`, które zależą od tego interfejsu.
- **IDeckValidator** — interfejs walidatora talii. `FormatValidator` obsługuje różne formaty (Standard, Modern, Commander) na podstawie zestawu reguł (`formatRules`). Dodanie nowego formatu (np. Pioneer, Pauper) wymaga jedynie rozszerzenia mapy reguł, bez modyfikacji interfejsu ani klasy `Deck`.

### L — Liskov Substitution Principle (Zasada podstawienia Liskov)

Każda implementacja interfejsu może być użyta zamiennie z inną, bez wpływu na poprawność systemu:

- `ScryfallAdapter` i hipotetyczny `LocalCacheProvider` mogą być używane wymiennie wszędzie, gdzie oczekiwany jest `ICardProvider` — `Deck.searchNewCards()` i `Collection.refreshPrices()` działają poprawnie niezależnie od wybranej implementacji.
- `FormatValidator` implementuje `IDeckValidator` i może być w przyszłości zastąpiony wyspecjalizowaną implementacją (np. `CustomFormatValidator` dla niestandardowych reguł) — `Deck.validate()` działa poprawnie z każdą klasą spełniającą kontrakt interfejsu.

### I — Interface Segregation Principle (Zasada segregacji interfejsów)

Interfejsy w systemie są celowo wąskie i skupione na jednym obszarze:

- **ICardProvider** definiuje trzy metody związane z pobieraniem danych o kartach (`searchCard`, `getCardDetails`, `getPrice`). Nie wymusza implementacji logiki walidacji, skanowania czy zarządzania kolekcją.
- **IDeckValidator** definiuje jedną metodę `isValid(Deck, String format)`. Nie zmusza walidatorów do implementacji wyszukiwania kart czy zarządzania sesją.

Klasa `ScannerService` nie implementuje `ICardProvider`, choć korzysta z niego — skanowanie i dostarczanie danych kart to dwa odrębne obszary odpowiedzialności.

### D — Dependency Inversion Principle (Zasada odwrócenia zależności)

Klasy wysokiego poziomu zależą od abstrakcji, nie od konkretnych implementacji:

- **Deck** zależy od `ICardProvider` (do wyszukiwania kart) i `IDeckValidator` (do walidacji), nie od `ScryfallAdapter` czy `FormatValidator` bezpośrednio. Dzięki temu dostawcę danych i reguły walidacji można podmieniać niezależnie.
- **Collection** zależy od `ICardProvider` przy odświeżaniu cen (`refreshPrices`), co pozwala na wstrzyknięcie dowolnego źródła danych cenowych.
- **ScannerService** przyjmuje `ICardProvider` jako parametr metody `processScan`, co umożliwia testowanie z mockiem zamiast rzeczywistego API.

---

## Zastosowane wzorce projektowe

### 1. Adapter (wzorzec strukturalny)

**Gdzie:** `ScryfallAdapter`, `GoogleMLKitAdapter`

**Uzasadnienie:** System korzysta z dwóch zewnętrznych serwisów — Scryfall API (dane o kartach i cenach) oraz Google ML Kit (rozpoznawanie tekstu ze zdjęć). Ich interfejsy nie odpowiadają bezpośrednio potrzebom systemu:

- API Scryfall zwraca dane w swoim własnym formacie JSON z dziesiątkami pól — `ScryfallAdapter` mapuje je na obiekty `Card` rozumiane przez resztę systemu i udostępnia je przez interfejs `ICardProvider`.
- Google ML Kit operuje na niskopoziomowych obiektach obrazu i zwraca surowy tekst — `GoogleMLKitAdapter` opakowuje to w prostą metodę `recognizeText()` używaną przez `ScannerService`.

Gdyby w przyszłości Scryfall został zastąpiony innym API (np. MTGJson), wystarczy napisać nowy adapter implementujący `ICardProvider`, bez zmian w logice kolekcji, decków czy skanera.

### 2. Strategy (wzorzec behawioralny)

**Gdzie:** `IDeckValidator` z implementacją `FormatValidator`

**Uzasadnienie:** Zasady budowania talii różnią się fundamentalnie w zależności od formatu turniejowego:

- **Commander** wymaga dokładnie 100 kart, z jednym legendarnym stworzeniem jako dowódcą, bez powtórzeń (poza basic landami).
- **Standard** ogranicza się do 60+ kart z maksymalnie 4 kopiami tej samej karty i rotującym zbiorem legalnych edycji.
- **Modern** ma inny zbiór legalnych edycji i własną listę kart zakazanych.

Zamiast umieszczać rozgałęzienia `if/switch` wewnątrz klasy `Deck`, reguły walidacji są wydzielone za interfejs `IDeckValidator`. Klasa `FormatValidator` przechowuje mapę reguł per format (`formatRules`) i na podstawie przekazanego argumentu `format` dobiera odpowiedni zestaw zasad. Deck wywołuje `validate(validator)`, a konkretna logika walidacji jest ukryta za interfejsem. Dodanie nowego formatu (np. Pioneer, Pauper) sprowadza się do rozszerzenia mapy reguł w `FormatValidator`, bez modyfikacji klasy `Deck` ani interfejsu `IDeckValidator`.
