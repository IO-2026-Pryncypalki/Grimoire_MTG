# Opis projektu — Grimoire MtG

## Zastosowane zasady SOLID

### S — Single Responsibility Principle (Zasada jednej odpowiedzialności)

Każda klasa w systemie ma jedną, wyraźnie określoną odpowiedzialność:

- **AuthService** — odpowiada wyłącznie za proces logowania przez Google OAuth2: wymianę authorization code na dane użytkownika (`GoogleUserInfo`) i zainicjowanie sesji. Nie zarządza sesjami ani użytkownikami bezpośrednio — deleguje to do `SessionManager` i `UserRepository`.
- **SessionManager** — odpowiada wyłącznie za zarządzanie cyklem życia sesji: tworzenie, walidację i unieważnianie tokenów. Nie zajmuje się autoryzacją OAuth2 ani logiką biznesową kart.
- **UserRepository** — odpowiada za operacje na danych użytkowników: wyszukiwanie po `googleId` i tworzenie nowych kont. Nie zajmuje się sesjami ani autoryzacją.
- **ScannerService** — odpowiada wyłącznie za przetwarzanie skanu karty (orkiestrację OCR → identyfikacja). Nie przechowuje wyników ani nie zarządza kolekcją.
- **Collection** — odpowiada za zarządzanie zbiorem wpisów kolekcji użytkownika (dodawanie, usuwanie, wycena). Nie zajmuje się budową decków ani sesjami.
- **CollectionEntry** — odpowiada za przechowywanie informacji o posiadaniu konkretnego egzemplarza karty: ilość, stan fizyczny (NM/GD/LP) i notatki użytkownika. Oddziela dane obiektywne karty (`Card`) od danych subiektywnych, zależnych od użytkownika.
- **Card** — przechowuje wyłącznie obiektywne dane karty ze Scryfall (nazwa, edycja, cena, obrazek). Nie zawiera informacji o posiadaniu ani stanie egzemplarza.
- **Deck** — odpowiada za skład talii i jej walidację. Nie odpowiada za logikę kolekcji ani skanowania.
- **ScryfallAdapter** — odpowiada wyłącznie za komunikację HTTP z zewnętrznym API Scryfall.
- **JsonCacheProvider** — odpowiada wyłącznie za cache'owanie danych kart w pamięci i na dysku. Nie komunikuje się z żadnym API.
- **SmartAdapter** — odpowiada za orkiestrację: najpierw sprawdza cache (`JsonCacheProvider`), a w razie braku danych deleguje do `ScryfallAdapter`. Nie implementuje samodzielnie ani logiki cache'owania, ani komunikacji HTTP.

Dzięki takiemu podziałowi zmiana np. sposobu cache'owania (z pliku JSON na bazę danych) wymaga modyfikacji wyłącznie `JsonCacheProvider`, bez wpływu na `SmartAdapter`, `ScryfallAdapter` czy klasy biznesowe.

### O — Open/Closed Principle (Zasada otwarte–zamknięte)

System jest otwarty na rozszerzenia, ale zamknięty na modyfikacje, dzięki zastosowaniu interfejsów:

- **ICardProvider** — interfejs dostawcy danych o kartach. Implementuje go `SmartAdapter` (który wewnętrznie komponuje `ScryfallAdapter` i `JsonCacheProvider`) oraz sam `ScryfallAdapter`. W przyszłości można dodać np. adapter do innego API (MTGJson) — wystarczy nowa implementacja `ICardProvider`, bez zmiany klas `Deck`, `Collection` czy `ScannerService`.
- **IDeckValidator** — interfejs walidatora talii. `FormatValidator` obsługuje różne formaty (Standard, Modern, Commander) na podstawie zestawu reguł (`formatRules`). Dodanie nowego formatu (np. Pioneer, Pauper) wymaga jedynie rozszerzenia mapy reguł, bez modyfikacji interfejsu ani klasy `Deck`.

### L — Liskov Substitution Principle (Zasada podstawienia Liskov)

Każda implementacja interfejsu może być użyta zamiennie z inną, bez wpływu na poprawność systemu:

- `SmartAdapter` i `ScryfallAdapter` oba implementują `ICardProvider` i mogą być używane zamiennie wszędzie tam, gdzie oczekiwany jest ten interfejs — `Deck.searchNewCards()`, `Collection.refreshPrices()` i `ScannerService.processScan()` działają poprawnie niezależnie od wybranej implementacji. Różnica jest jedynie w wydajności (cache vs bezpośrednie zapytania HTTP).
- `FormatValidator` implementuje `IDeckValidator` i może być w przyszłości zastąpiony wyspecjalizowaną implementacją (np. `CustomFormatValidator` dla niestandardowych reguł) — `Deck.validate()` działa poprawnie z każdą klasą spełniającą kontrakt interfejsu.

### I — Interface Segregation Principle (Zasada segregacji interfejsów)

Interfejsy w systemie są celowo wąskie i skupione na jednym obszarze:

- **ICardProvider** definiuje trzy metody związane z pobieraniem danych o kartach (`searchCard`, `getCardDetails`, `getPrice`). Nie wymusza implementacji logiki walidacji, skanowania czy zarządzania kolekcją.
- **IDeckValidator** definiuje jedną metodę `isValid(Deck, String format)`. Nie zmusza walidatorów do implementacji wyszukiwania kart czy zarządzania sesją.

`JsonCacheProvider` celowo **nie** implementuje `ICardProvider` — jego API (`getCard`, `isCachedMap`, `isCachedFile`) jest inne, bo pełni inną rolę (cache, nie dostawca). Orkiestracją zajmuje się `SmartAdapter`, który implementuje `ICardProvider` i korzysta z obu klas wewnętrznie.

### D — Dependency Inversion Principle (Zasada odwrócenia zależności)

Klasy wysokiego poziomu zależą od abstrakcji, nie od konkretnych implementacji:

- **Deck** zależy od `ICardProvider` (do wyszukiwania kart) i `IDeckValidator` (do walidacji), nie od `SmartAdapter` czy `FormatValidator` bezpośrednio. Dzięki temu dostawcę danych i reguły walidacji można podmieniać niezależnie.
- **Collection** zależy od `ICardProvider` przy odświeżaniu cen (`refreshPrices`), co pozwala na wstrzyknięcie dowolnego źródła danych cenowych.
- **ScannerService** przyjmuje `ICardProvider` jako parametr metody `processScan`, co umożliwia testowanie z mockiem zamiast rzeczywistego API.
- **AuthService** zależy od `UserRepository` i `SessionManager` przez pola prywatne, co umożliwia ich podmianę (np. w testach jednostkowych).

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

### 3. Proxy (wzorzec strukturalny)

**Gdzie:** `SmartAdapter` jako caching proxy dla `ScryfallAdapter`

**Uzasadnienie:** Scryfall API narzuca limity zapytań (zalecany interwał 50–100ms między requestami) i każde zapytanie HTTP wprowadza opóźnienie. Jednocześnie dane kart zmieniają się stosunkowo rzadko — metadane (nazwa, edycja, obrazek) są stałe, a ceny aktualizują się co najwyżej raz dziennie.

`SmartAdapter` implementuje ten sam interfejs `ICardProvider` co `ScryfallAdapter`, więc z perspektywy reszty systemu (`Deck`, `Collection`, `ScannerService`) jest przezroczysty — klasy klienckie nie wiedzą, czy dane pochodzą z cache'u czy z sieci. Wewnętrznie `SmartAdapter` przy każdym zapytaniu najpierw sprawdza `JsonCacheProvider` (pamięć → plik). Jeśli dane są w cache'u, zwraca je natychmiast; jeśli nie — deleguje do `ScryfallAdapter`, a wynik zapisuje w cache'u na przyszłość.

Dzięki temu logika cache'owania jest wydzielona z adaptera HTTP i z klas biznesowych. Podmiana strategii cache'owania (np. z pliku JSON na Redis) wymaga zmiany jedynie `JsonCacheProvider`, a podmiana źródła danych (np. z Scryfall na MTGJson) wymaga zmiany jedynie `ScryfallAdapter` — `SmartAdapter` orkiestruje oba bez zmian.