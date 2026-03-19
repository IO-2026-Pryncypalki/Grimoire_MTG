# Scenariusze przypadków użycia — Grimoire MtG

---

## UC-01: Logowanie do aplikacji

**Aktorzy:** Użytkownik (Michał — Competitive Player, Tomasz — Collector)

**Warunki początkowe:**
- Użytkownik posiada zarejestrowane konto w systemie Grimoire.
- Aplikacja mobilna lub webowa jest uruchomiona i dostępna.

**Warunki końcowe:**
- Użytkownik jest zalogowany i ma dostęp do swojej kolekcji oraz decków.
- Sesja użytkownika jest aktywna po stronie backendu.

**Scenariusz główny:**
1. Użytkownik otwiera aplikację Grimoire (mobilną lub webową).
2. System wyświetla ekran logowania z polami na adres e-mail i hasło.
3. Użytkownik wprowadza swój adres e-mail i hasło.
4. Użytkownik zatwierdza formularz przyciskiem „Zaloguj się".
5. System weryfikuje dane logowania poprzez backend (REST API).
6. System przekierowuje użytkownika do ekranu głównego z jego kolekcją.

**Scenariusz alternatywny — błędne dane logowania:**
- W kroku 5: system nie odnajduje konta lub hasło jest błędne.
- System wyświetla komunikat o błędzie „Nieprawidłowy adres e-mail lub hasło".
- Powrót do kroku 3.

**Scenariusz alternatywny — brak konta:**
- W kroku 3: użytkownik wybiera opcję „Zarejestruj się".
- System wyświetla formularz rejestracji (imię, e-mail, hasło).
- Użytkownik wypełnia formularz i zatwierdza.
- System tworzy nowe konto i automatycznie loguje użytkownika.

**Odnośniki do wymagań:** FR-01, SYS-01, SYS-02, NFR-04

---

## UC-02: Ręczne wyszukiwanie karty i dodanie do kolekcji

**Aktorzy:** Użytkownik (Michał — Competitive Player), Scryfall API (system zewnętrzny)

**Warunki początkowe:**
- Użytkownik jest zalogowany w aplikacji.
- Aplikacja posiada aktywne połączenie z internetem.
- Scryfall API jest dostępne.

**Warunki końcowe:**
- Wybrana karta (z określoną edycją) została dodana do kolekcji użytkownika w bazie danych.
- Kolekcja jest zaktualizowana i widoczna na wszystkich urządzeniach użytkownika.

**Scenariusz główny:**
1. Użytkownik przechodzi do sekcji „Wyszukaj kartę" w aplikacji.
2. Użytkownik wpisuje nazwę karty (lub jej fragment) w pole wyszukiwania.
3. System wysyła zapytanie do Scryfall API i pobiera listę pasujących kart.
4. System wyświetla listę wyników z miniaturami, nazwami i edycjami kart.
5. Użytkownik wybiera odpowiednią kartę z listy wyników.
6. System wyświetla szczegóły karty: ilustrację, opis, typ, koszt many, edycję, wycenę.
7. Użytkownik klika przycisk „Dodaj do kolekcji".
8. System dodaje kartę do kolekcji użytkownika i wyświetla potwierdzenie.

**Scenariusz alternatywny — brak wyników:**
- W kroku 3: Scryfall API nie zwraca żadnych wyników dla podanej frazy.
- System wyświetla komunikat „Nie znaleziono kart pasujących do wyszukiwania".
- Użytkownik może zmodyfikować zapytanie i powrócić do kroku 2.

**Scenariusz alternatywny — karta już w kolekcji:**
- W kroku 8: karta jest już w kolekcji użytkownika.
- System pyta, czy dodać kolejny egzemplarz lub anulować.
- Użytkownik podejmuje decyzję.

**Odnośniki do wymagań:** FR-02, FR-05, SYS-05, C-03, C-05, NFR-03

---

## UC-03: Skanowanie karty kamerą i dodanie do kolekcji

**Aktorzy:** Użytkownik mobilny (Michał — Competitive Player, Tomasz — Collector), Google ML Kit (system zewnętrzny), Scryfall API (system zewnętrzny)

**Warunki początkowe:**
- Użytkownik jest zalogowany w aplikacji mobilnej (Android).
- Aplikacja posiada uprawnienia dostępu do kamery urządzenia.
- Urządzenie posiada aktywne połączenie z internetem.
- Oświetlenie jest wystarczające do odczytu tekstu z karty.

**Warunki końcowe:**
- Zidentyfikowana karta została dodana do kolekcji użytkownika.
- W przypadku błędnego rozpoznania — użytkownik mógł ręcznie poprawić lub odrzucić wynik.

**Scenariusz główny:**
1. Użytkownik przechodzi do sekcji „Skanuj kartę" w aplikacji mobilnej.
2. System uruchamia podgląd kamery z ramką naprowadzającą na kartę.
3. Użytkownik umieszcza kartę w kadrze i wykonuje zdjęcie (lub system wykonuje je automatycznie po ustabilizowaniu).
4. System przekazuje zdjęcie do Google ML Kit, który odczytuje tekst z karty (OCR).
5. System ekstrahuje nazwę karty z rozpoznanego tekstu i wysyła zapytanie do Scryfall API.
6. System wyświetla znalezioną kartę z prośbą o potwierdzenie: ilustracja, nazwa, edycja.
7. Użytkownik potwierdza poprawność rozpoznania i klika „Dodaj do kolekcji".
8. System dodaje kartę do kolekcji i wyświetla potwierdzenie.

**Scenariusz alternatywny — błędne rozpoznanie:**
- W kroku 6: system rozpoznał kartę błędnie lub nie odnalazł jej w Scryfall.
- System informuje o problemie i oferuje opcję ręcznego wyszukania karty (przejście do UC-02).
- Użytkownik wyszukuje kartę ręcznie i dodaje ją do kolekcji.

**Scenariusz alternatywny — złe oświetlenie / niewyraźne zdjęcie:**
- W kroku 4: ML Kit nie jest w stanie odczytać tekstu ze zdjęcia.
- System informuje o błędzie i prosi o ponowne zdjęcie w lepszych warunkach.
- Powrót do kroku 2.

**Odnośniki do wymagań:** FR-03, FR-10, SYS-06, C-02, C-04, NFR-01, NFR-02

---

## UC-04: Tworzenie nowego decku

**Aktorzy:** Użytkownik (Michał — Competitive Player)

**Warunki początkowe:**
- Użytkownik jest zalogowany w aplikacji (mobilnej lub webowej).
- Użytkownik posiada co najmniej jedną kartę w kolekcji lub ma dostęp do wyszukiwarki Scryfall.

**Warunki końcowe:**
- Nowy deck został zapisany w systemie z nadaną nazwą i przypisanymi kartami.
- Deck jest widoczny na liście decków użytkownika na wszystkich urządzeniach.

**Scenariusz główny:**
1. Użytkownik przechodzi do sekcji „Moje decki" i klika „Utwórz nowy deck".
2. System wyświetla formularz tworzenia decku: pole nazwy, opcjonalny format (Standard, Modern, Commander).
3. Użytkownik wpisuje nazwę decku i wybiera format, a następnie zatwierdza.
4. System tworzy pusty deck i otwiera widok deckbuildera.
5. Użytkownik wyszukuje karty z własnej kolekcji lub przez wyszukiwarkę Scryfall.
6. Użytkownik dodaje karty do decku (kliknięciem lub przeciągnięciem), określając liczbę egzemplarzy.
7. Użytkownik opcjonalnie przegląda statystyki decku (mana curve, rozkład kolorów).
8. Użytkownik klika „Zapisz deck".
9. System zapisuje deck w bazie danych i wyświetla potwierdzenie.

**Scenariusz alternatywny — brak nazwy decku:**
- W kroku 3: użytkownik nie wypełnił pola nazwy.
- System wyświetla komunikat walidacyjny „Podaj nazwę decku".
- Powrót do kroku 3.

**Odnośniki do wymagań:** FR-04, FR-06, FR-14, SYS-05

---

## UC-05: Przeglądanie i filtrowanie kolekcji

**Aktorzy:** Użytkownik (Michał — Competitive Player, Tomasz — Collector)

**Warunki początkowe:**
- Użytkownik jest zalogowany w aplikacji (mobilnej lub webowej).
- Kolekcja użytkownika zawiera co najmniej jedną kartę.

**Warunki końcowe:**
- Użytkownik widzi listę kart w kolekcji (ewentualnie przefiltrowaną / posortowaną).
- Żadne dane kolekcji nie zostają zmodyfikowane.

**Scenariusz główny:**
1. Użytkownik przechodzi do sekcji „Moja kolekcja".
2. System pobiera z backendu listę kart kolekcji i wyświetla je w widoku siatki lub listy.
3. Użytkownik opcjonalnie klika ikonę filtrowania.
4. System wyświetla panel filtrów: kolor, typ, koszt many (CMC), edycja.
5. Użytkownik ustawia wybrane filtry i zatwierdza.
6. System aktualizuje widok kolekcji, pokazując tylko karty spełniające kryteria.
7. Użytkownik może opcjonalnie zmienić sposób sortowania (nazwa, wartość, edycja).
8. Użytkownik przegląda przefiltrowaną kolekcję; kliknięcie karty otwiera jej szczegóły.

**Scenariusz alternatywny — kolekcja pusta:**
- W kroku 2: kolekcja nie zawiera żadnych kart.
- System wyświetla ekran zachęcający do dodania pierwszej karty z odnośnikiem do UC-02 lub UC-03.

**Odnośniki do wymagań:** FR-05, FR-07, FR-15, NFR-03, NFR-05, NFR-06

---

## UC-06: Edycja istniejącego decku

**Aktorzy:** Użytkownik (Michał — Competitive Player)

**Warunki początkowe:**
- Użytkownik jest zalogowany w aplikacji.
- W systemie istnieje co najmniej jeden deck należący do użytkownika.

**Warunki końcowe:**
- Zmiany w składzie decku zostały zapisane w bazie danych.
- Zaktualizowany deck jest widoczny na wszystkich urządzeniach użytkownika.

**Scenariusz główny:**
1. Użytkownik przechodzi do sekcji „Moje decki" i wybiera deck do edycji.
2. System wyświetla zawartość decku: listę kart z liczbą egzemplarzy i statystyki.
3. Użytkownik klika „Edytuj deck".
4. System przechodzi do trybu edycji deckbuildera.
5. Użytkownik dodaje nowe karty (wyszukiwanie z kolekcji lub Scryfall) lub usuwa istniejące.
6. System na bieżąco aktualizuje statystyki decku (liczba kart, mana curve).
7. Użytkownik klika „Zapisz zmiany".
8. System zapisuje zaktualizowany deck i wyświetla potwierdzenie.

**Scenariusz alternatywny — porzucenie zmian:**
- W kroku 7: użytkownik klika „Anuluj" zamiast „Zapisz zmiany".
- System pyta o potwierdzenie porzucenia zmian.
- Jeśli użytkownik potwierdzi — deck wraca do poprzedniego stanu.

**Odnośniki do wymagań:** FR-09, FR-14, FR-06

---

## UC-07: Sprawdzenie wartości kolekcji

**Aktorzy:** Użytkownik (Tomasz — Collector), Scryfall API (system zewnętrzny)

**Warunki początkowe:**
- Użytkownik jest zalogowany w aplikacji mobilnej lub webowej.
- Kolekcja użytkownika zawiera co najmniej jedną kartę.
- Aplikacja posiada aktywne połączenie z internetem.

**Warunki końcowe:**
- Użytkownik widzi aktualną wycenę rynkową kart w kolekcji oraz łączną wartość.
- Dane wyceny zostały pobrane z Scryfall API.

**Scenariusz główny:**
1. Użytkownik przechodzi do sekcji „Moja kolekcja" i wybiera widok wyceny.
2. System pobiera aktualne ceny rynkowe kart z Scryfall API.
3. System wyświetla kolekcję posortowaną wg wartości rynkowej (malejąco), z ceną przy każdej karcie.
4. System wyświetla łączną szacunkową wartość kolekcji na górze ekranu.
5. Użytkownik może filtrować kolekcję po wartości (np. powyżej określonej kwoty).
6. Użytkownik klika wybraną kartę, aby zobaczyć historię cen lub więcej szczegółów.

**Scenariusz alternatywny — brak danych cen dla karty:**
- W kroku 2: Scryfall API nie zwraca danych cenowych dla wybranych kart (np. bardzo stare edycje).
- System wyświetla „brak danych" przy tych kartach; pozostałe karty są wyceniane normalnie.

**Scenariusz alternatywny — brak połączenia z internetem:**
- W kroku 2: aplikacja nie może połączyć się z Scryfall API.
- System wyświetla ostrzeżenie „Brak połączenia — ceny mogą być nieaktualne" i prezentuje ostatnio pobrane dane (jeśli dostępne w cache).

**Odnośniki do wymagań:** FR-16, FR-15, C-03, C-05