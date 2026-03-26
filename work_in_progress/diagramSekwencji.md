# Diagramy sekwencji — Grimoire MtG

## UC-01 — Logowanie przez Google OAuth2

```mermaid
sequenceDiagram
    autonumber
    actor U as Użytkownik
    participant UI as Interfejs
    participant G as Google OAuth2
    participant AS as AuthService
    participant UR as UserRepository
    participant SM as SessionManager
    participant S as Nowa Sesja

    U->>UI: Klika "Zaloguj przez Google"
    UI->>G: Przekierowanie do Google (Authorization Request)
    G->>U: Wyswietla ekran logowania Google
    U->>G: Loguje sie i wyraża zgode
    G-->>UI: Zwraca authorization code (redirect)

    UI->>AS: loginWithGoogle(authCode)
    activate AS

    AS->>G: exchangeGoogleToken(authCode)
    activate G
    G-->>AS: Zwraca access token + GoogleUserInfo (email, name, googleId)
    deactivate G

    AS->>UR: findOrCreateByGoogleId(googleUserInfo)
    activate UR

    alt Użytkownik istnieje
        UR-->>AS: istniejący User
    else Nowy użytkownik
        UR->>UR: tworzy nowego User
        UR-->>AS: nowy User
    end
    deactivate UR

    AS->>SM: createSession(userId, deviceType)
    activate SM
    SM->>S: create
    SM-->>AS: zwraca Session z tokenem
    deactivate SM

    AS-->>UI: zwraca Session
    deactivate AS
    UI->>U: Wyswietla Dashboard
```

## UC-02 — Ręczne wyszukiwanie i dodawanie karty

```mermaid
sequenceDiagram
    autonumber
    actor U as Użytkownik
    participant UI as Interfejs
    participant SM as SessionManager
    participant SA as ScryfallAdapter
    participant COL as Kolekcja

    Note over U, UI: Warunek: Użytkownik jest zalogowany (posiada token)

    U->>UI: Wpisuje nazwe karty w wyszukiwarke
    UI->>SM: checkSession(token)
    SM-->>UI: session valid

    UI->>SA: searchCard(query)
    activate SA
    SA-->>UI: Zwraca liste wynikow (miniatury, nazwy, edycje)
    deactivate SA

    alt Brak wynikow
        UI->>U: Wyświetla "Nie znaleziono kart pasujacych do wyszukiwania"
    else Znaleziono karty
        UI->>U: Wyświetla liste wynikow
        U->>UI: Wybiera konkretną karte

        UI->>SA: getCardDetails(scryfallId)
        activate SA
        SA-->>UI: Zwraca szczegóły (obraz, opis, cena, edycja)
        deactivate SA

        UI->>U: Wyświetla pełne dane karty

        U->>UI: Klika "Dodaj do kolekcji"

        UI->>COL: getEntry(scryfallId)
        activate COL

        alt Karta juz jest w kolekcji
            COL-->>UI: zwraca istniejący CollectionEntry
            UI->>U: Pyta: "Karta jest juz w kolekcji. Dodać kolejny egzemplarz?"
            U->>UI: Wybiera "Tak"
            UI->>COL: entry.updateQuantity(+1)
            COL-->>UI: Sukces (zaktualizowano liczbę)
        else Karta nowa
            COL-->>UI: Brak wpisu
            UI->>COL: addCard(card)
            Note right of COL: Tworzy nowy CollectionEntry (quantity=1)
            COL-->>UI: Sukces (dodano karte)
        end
        deactivate COL

        UI->>U: Wyświetla potwierdzenie dodania
    end
```

## UC-03 — Skanowanie karty kamerą/aparatem i dodanie do kolekcji

```mermaid
sequenceDiagram
    autonumber
    actor U as Użytkownik (Mobile)
    participant UI as Interfejs Skanera
    participant SM as SessionManager
    participant SS as ScannerService
    participant ML as GoogleMLKit (OCR)
    participant SA as ScryfallAdapter
    participant COL as Kolekcja

    Note over U, UI: Warunek: Użytkownik zalogowany

    U->>UI: Otwiera skaner i robi zdjęcie karty
    UI->>SM: checkSession(token)
    SM-->>UI: token OK

    UI->>SS: processScan(image, token)
    activate SS

    SS->>ML: recognizeText(image)
    activate ML

    alt Złe oświetlenie
        ML-->>SS: Brak możliwości odczytu tekstu
        SS-->>UI: Bład (Niewyraźne zdjęcie)
        UI->>U: Wyświetla komunikat: "Zrób ponowne zdjęcie"
    else Sukces OCR
        ML-->>SS: Zwraca tekst (np. "Tarmogoyf")
        deactivate ML

        SS->>SA: searchCard("Tarmogoyf")
        activate SA

        alt Nie znaleziono w Scryfall
            SA-->>SS: Brak wyników
            SS-->>UI: Bład (Karta nieznana)
            UI->>U: Proponuje ręczne wyszukiwanie (UC-02)
        else Znaleziono karte
            SA-->>SS: Zwraca dane karty (id, obraz, edycja)
            deactivate SA

            SS-->>UI: Wyświetla podglad karty
            deactivate SS

            U->>UI: Potwierdza i klika "Dodaj do kolekcji"
            UI->>COL: addCard(card)
            activate COL
            Note right of COL: Tworzy CollectionEntry (quantity=1)
            COL-->>UI: Potwierdzenie zapisu
            deactivate COL
            UI->>U: Wyswietla komunikat o sukcesie
        end
    end
```

## UC-04 — Tworzenie nowego decku

```mermaid
sequenceDiagram
    autonumber
    actor U as Użytkownik
    participant UI as Interfejs
    participant SM as SessionManager
    participant D as DeckObject
    participant SA as ScryfallAdapter
    participant VAL as FormatValidator

    U->>UI: Wybiera "Utworz nowy deck"
    UI->>U: Wyświetla formularz

    U->>UI: Podaje nazwę i format

    alt Brak nazwy
        UI->>U: Komunikat błędu
    else Dane OK
        UI->>SM: checkSession(token)
        SM-->>UI: token OK

        Note right of D: Tworzenie obiektu Deck
        UI->>D: create(name, format)

        loop Dodawanie kart
            U->>UI: Szuka karty
            UI->>SA: searchCard(query)
            SA-->>UI: Lista wyników
            U->>UI: Dodaje wybraną kartę
            UI->>D: addCard(card, count)
        end

        U->>UI: Klika Zapisz

        UI->>D: validate(validator)
        activate D
        D->>VAL: isValid(deck, format)
        activate VAL
        VAL-->>D: true
        deactivate VAL
        D-->>UI: Wynik walidacji OK
        deactivate D

        UI->>U: Potwierdzenie zapisu
    end
```

## UC-05 — Przegladanie kolekcji z weryfikacją sesji

```mermaid
sequenceDiagram
    autonumber
    actor U as Użytkownik
    participant UI as Interfejs
    participant SM as SessionManager
    participant COL as Kolekcja

    U->>UI: Przechodzi do Moja Kolekcja
    UI->>SM: checkSession(token)
    activate SM

    alt Sesja wygasla
        SM-->>UI: false (session invalid)
        deactivate SM
        UI->>U: Przekierowanie do ekranu logowania (UC-01)
    else Sesja aktywna
        activate SM
        SM-->>UI: true (session valid)
        deactivate SM

        UI->>COL: getEntries()
        activate COL

        alt Kolekcja ma karty
            COL-->>UI: Lista obiektów CollectionEntry
            UI->>U: Wyświetla karty (z ilościa, stanem, notatkami)
        else Kolekcja pusta
            COL-->>UI: Pusta lista
            UI->>U: Wyświetla ekran zachęty (link do dodawania)
        end
        deactivate COL
    end
```

## UC-06 — Edycja istniejacego decku

```mermaid
sequenceDiagram
    autonumber
    actor U as Użytkownik
    participant UI as Interfejs
    participant SM as SessionManager
    participant D as DeckObject
    participant SA as ScryfallAdapter

    U->>UI: Wybiera deck do edycji

    UI->>+SM: checkSession(token)
    SM-->>-UI: Zwraca status sesji

    alt Sesja wygasla
        UI->>U: Przekierowanie do logowania
    else Sesja aktywna
        UI->>+D: load()
        D-->>-UI: Dane decku i statystyki

        UI->>U: Wyświetla tryb edycji

        loop Edycja kart
            U->>UI: Dodaje/Usuwa kartę
            UI->>+SA: searchCard(query)
            SA-->>-UI: Wyniki
            UI->>+D: updateContent()
            D-->>-UI: Odswieżone statystyki
            UI->>U: Pokazuje zmiany na żywo
        end

        alt Klika Zapisz
            UI->>+D: save()
            D-->>-UI: Sukces
            UI->>U: Potwierdzenie zapisu
        else Klika Anuluj
            UI->>U: Pyta o potwierdzenie
            U->>UI: Potwierdza
            UI->>D: discardChanges()
            UI->>U: Powrót do widoku listy
        end
    end
```

## UC-07 — Sprawdzenie wartosci kolekcji

```mermaid
sequenceDiagram
    autonumber
    actor U as Użytkownik (Tomasz)
    participant UI as Interfejs
    participant SM as SessionManager
    participant COL as Kolekcja
    participant SA as ScryfallAdapter

    U->>UI: Wybiera widok wyceny rynkowej

    UI->>+SM: checkSession(token)
    SM-->>-UI: Status sesji (valid)

    alt Brak połaczenia z internetem
        UI->>U: Ostrzeżenie: "Brak połaczenia - ceny z cache"
        UI->>+COL: getCachedPrices()
        COL-->>-UI: Ostatnio zapisane dane cenowe
    else Polaczenie aktywne
        UI->>+COL: getCardIds()
        COL-->>-UI: Lista ID kart w kolekcji

        UI->>+SA: getLatestPrices(ids)

        alt Bład API / Brak cen dla części kart
            SA-->>UI: Zwraca ceny + info o braku danych dla wybranych ID
        else Sukces
            SA-->>-UI: Kompletne dane cenowe
        end

        UI->>+COL: updateCache(prices)
        COL-->>-UI: OK
    end

    UI->>+COL: calculateTotalValue(prices)
    COL-->>-UI: Łaczna wartość i posortowana lista

    UI->>U: Wyświetla wartość łaczną i ceny przy kartach

    opt Filtrowanie i Szczegóły
        U->>UI: Filtruje po wartości (np. > 50$)
        UI->>U: Aktualizuje widok
        U->>UI: Klika karte
        UI->>U: Wyświetla historie cen i szczegóły
    end
```