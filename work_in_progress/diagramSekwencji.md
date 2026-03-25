---
title: UC-01 - Logowanie przez Google OAuth2
---
sequenceDiagram
    autonumber
    actor U as Uzytkownik
    participant UI as Interfejs
    participant G as Google OAuth2
    participant SM as SessionManager
    participant DB as Baza Danych
    participant S as Nowa Sesja

    U->>UI: Klika "Zaloguj przez Google"
    UI->>G: Przekierowanie do Google (Authorization Request)
    G->>U: Wyswietla ekran logowania Google
    U->>G: Loguje sie i wyraza zgode
    G-->>UI: Zwraca authorization code (redirect)

    UI->>SM: loginWithGoogle(authCode)
    activate SM

    SM->>G: exchangeGoogleToken(authCode)
    activate G
    G-->>SM: Zwraca access token + dane uzytkownika (email, name, googleId)
    deactivate G

    SM->>DB: findByGoogleId(googleId)
    activate DB

    alt Uzytkownik istnieje
        DB-->>SM: dane uzytkownika
    else Nowy uzytkownik
        DB-->>SM: brak wyniku
        SM->>DB: createUser(email, username, googleId)
        DB-->>SM: nowy uzytkownik utworzony
    end
    deactivate DB

    SM->>SM: createSession(userId, device)
    SM->>S: create
    SM-->>UI: zwraca SessionToken
    deactivate SM
    UI->>U: Wyswietla Dashboard

---
title: UC-02 - Reczne wyszukiwanie i dodawanie karty
---
sequenceDiagram
    autonumber
    actor U as Uzytkownik
    participant UI as Interfejs
    participant SM as SessionManager
    participant SA as ScryfallAdapter
    participant COL as Kolekcja

    Note over U, UI: Warunek: Uzytkownik jest zalogowany (posiada token)

    U->>UI: Wpisuje nazwe karty w wyszukiwarke
    UI->>SM: checkSession(token)
    SM-->>UI: session valid

    UI->>SA: searchCard(query)
    activate SA
    SA-->>UI: zwraca liste wynikow (miniatury, nazwy, edycje)
    deactivate SA

    alt Scenariusz Alternatywny: Brak wynikow
        UI->>U: Wyswietla "Nie znaleziono kart pasujacych do wyszukiwania"
    else Scenariusz Glowny: Znaleziono karty
        UI->>U: Wyswietla liste wynikow
        U->>UI: Wybiera konkretna karte

        UI->>SA: getCardDetails(scryfallId)
        activate SA
        SA-->>UI: zwraca szczegoly (obraz, opis, cena, edycja)
        deactivate SA

        UI->>U: Wyswietla pelne dane karty

        U->>UI: Klika "Dodaj do kolekcji"

        UI->>COL: getEntry(scryfallId)
        activate COL

        alt Scenariusz Alternatywny: Karta juz jest w kolekcji
            COL-->>UI: zwraca istniejacy CollectionEntry
            UI->>U: Pyta: "Karta jest juz w kolekcji. Dodac kolejny egzemplarz?"
            U->>UI: Wybiera "Tak"
            UI->>COL: entry.updateQuantity(+1)
            COL-->>UI: Sukces (zaktualizowano liczbe)
        else Karta nowa
            COL-->>UI: brak wpisu
            UI->>COL: addCard(card)
            Note right of COL: Tworzy nowy CollectionEntry (quantity=1)
            COL-->>UI: Sukces (dodano karte)
        end
        deactivate COL

        UI->>U: Wyswietla potwierdzenie dodania
    end

---
title: UC-03 - Skanowanie karty kamera i dodanie do kolekcji
---
sequenceDiagram
    autonumber
    actor U as Uzytkownik (Mobile)
    participant UI as Interfejs Skanera
    participant SM as SessionManager
    participant SS as ScannerService
    participant ML as GoogleMLKit (OCR)
    participant SA as ScryfallAdapter
    participant COL as Kolekcja

    Note over U, UI: Warunek: Uzytkownik zalogowany

    U->>UI: Otwiera skaner i robi zdjecie karty
    UI->>SM: checkSession(token)
    SM-->>UI: token OK

    UI->>SS: processScan(image, token)
    activate SS

    SS->>ML: recognizeText(image)
    activate ML

    alt Scenariusz Alternatywny: Zle oswietlenie
        ML-->>SS: Brak mozliwosci odczytu tekstu
        SS-->>UI: Blad (Niewyrazne zdjecie)
        UI->>U: Wyswietla komunikat: "Zrob ponowne zdjecie"
    else Sukces OCR
        ML-->>SS: Zwraca tekst (np. "Tarmogoyf")
        deactivate ML

        SS->>SA: searchCard("Tarmogoyf")
        activate SA

        alt Scenariusz Alternatywny: Nie znaleziono w Scryfall
            SA-->>SS: Brak wynikow
            SS-->>UI: Blad (Karta nieznana)
            UI->>U: Proponuje reczne wyszukiwanie (UC-02)
        else Znaleziono karte
            SA-->>SS: Zwraca dane karty (id, obraz, edycja)
            deactivate SA

            SS-->>UI: Wyswietla podglad karty
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

---
title: UC-04 - Tworzenie nowego decku
---
sequenceDiagram
    autonumber
    actor U as Uzytkownik
    participant UI as Interfejs
    participant SM as SessionManager
    participant D as DeckObject
    participant SA as ScryfallAdapter
    participant VAL as FormatValidator

    U->>UI: Wybiera Utworz nowy deck
    UI->>U: Wyswietla formularz

    U->>UI: Podaje nazwe i format

    alt Brak nazwy
        UI->>U: Komunikat bledu
    else Dane OK
        UI->>SM: checkSession(token)
        SM-->>UI: token OK

        Note right of D: Tworzenie obiektu Deck
        UI->>D: create(name, format)

        loop Dodawanie kart
            U->>UI: Szuka karty
            UI->>SA: searchCard(query)
            SA-->>UI: lista wynikow
            U->>UI: Dodaje wybrana karte
            UI->>D: addCard(card, count)
        end

        U->>UI: Klika Zapisz

        UI->>D: validate(validator)
        activate D
        D->>VAL: isValid(deck, format)
        activate VAL
        VAL-->>D: true
        deactivate VAL
        D-->>UI: wynik walidacji OK
        deactivate D

        UI->>U: Potwierdzenie zapisu
    end

---
title: UC-05 - Przegladanie kolekcji z weryfikacja sesji
---
sequenceDiagram
    autonumber
    actor U as Uzytkownik
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
            COL-->>UI: lista obiektow CollectionEntry
            UI->>U: Wyswietla karty (z iloscia, stanem, notatkami)
        else Kolekcja pusta
            COL-->>UI: pusta lista
            UI->>U: Wyswietla ekran zachety (link do dodawania)
        end
        deactivate COL
    end

---
title: UC-06 - Edycja istniejacego decku
---
sequenceDiagram
    autonumber
    actor U as Uzytkownik
    participant UI as Interfejs
    participant SM as SessionManager
    participant D as DeckObject
    participant SA as ScryfallAdapter

    U->>UI: Wybiera deck do edycji

    UI->>+SM: checkSession(token)
    SM-->>-UI: zwraca status sesji

    alt Sesja wygasla
        UI->>U: Przekierowanie do logowania
    else Sesja aktywna
        UI->>+D: load()
        D-->>-UI: dane decku i statystyki

        UI->>U: Wyswietla tryb edycji

        loop Edycja kart
            U->>UI: Dodaje/Usuwa karte
            UI->>+SA: searchCard(query)
            SA-->>-UI: wyniki
            UI->>+D: updateContent()
            D-->>-UI: odswiezone statystyki
            UI->>U: Pokazuje zmiany na zywo
        end

        alt Klika Zapisz
            UI->>+D: save()
            D-->>-UI: Sukces
            UI->>U: Potwierdzenie zapisu
        else Klika Anuluj
            UI->>U: Pyta o potwierdzenie
            U->>UI: Potwierdza
            UI->>D: discardChanges()
            UI->>U: Powrot do widoku listy
        end
    end

---
title: UC-07 - Sprawdzenie wartosci kolekcji
---
sequenceDiagram
    autonumber
    actor U as Uzytkownik (Tomasz)
    participant UI as Interfejs
    participant SM as SessionManager
    participant COL as Kolekcja
    participant SA as ScryfallAdapter

    U->>UI: Wybiera widok wyceny rynkowej

    UI->>+SM: checkSession(token)
    SM-->>-UI: status sesji (valid)

    alt Brak polaczenia z internetem
        UI->>U: Ostrzezenie: "Brak polaczenia - ceny z cache"
        UI->>+COL: getCachedPrices()
        COL-->>-UI: ostatnio zapisane dane cenowe
    else Polaczenie aktywne
        UI->>+COL: getCardIds()
        COL-->>-UI: lista ID kart w kolekcji

        UI->>+SA: getLatestPrices(ids)

        alt Blad API / Brak cen dla czesci kart
            SA-->>UI: zwraca ceny + info o braku danych dla wybranych ID
        else Sukces
            SA-->>-UI: kompletne dane cenowe
        end

        UI->>+COL: updateCache(prices)
        COL-->>-UI: OK
    end

    UI->>+COL: calculateTotalValue(prices)
    COL-->>-UI: laczna wartosc i posortowana lista

    UI->>U: Wyswietla wartosc laczna i ceny przy kartach

    opt Filtrowanie i Szczegoly
        U->>UI: Filtruje po wartosci (np. > 50$)
        UI->>U: Aktualizuje widok
        U->>UI: Klika karte
        UI->>U: Wyswietla historie cen i szczegoly
    end
