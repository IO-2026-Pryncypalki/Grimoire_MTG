# Dokumentacja API backendu — Grimoire MTG

Backend REST API dla aplikacji do zarządzania kolekcją kart Magic: The Gathering i taliami (deckami).

**Bazowy URL:** `http://localhost:3000` (domyślnie)  
**Prefiks API:** `/api`

---

## Spis treści

1. [Autentykacja](#autentykacja)
2. [Typy wspólne](#typy-wspólne)
3. [Endpointy — Auth](#endpointy--auth)
4. [Endpointy — User](#endpointy--user)
5. [Endpointy — Cards](#endpointy--cards)
6. [Endpointy — Collection](#endpointy--collection)
7. [Endpointy — Decks](#endpointy--decks)
8. [Endpointy — Sync](#endpointy--sync)
9. [Flow — wersja mobilna (skanowanie)](#flow--wersja-mobilna-skanowanie)
10. [Flow — wersja webowa (wyszukiwanie)](#flow--wersja-webowa-wyszukiwanie)
11. [Flow — wspólne funkcjonalności](#flow--wspólne-funkcjonalności)
12. [Funkcjonalności dodatkowe](#funkcjonalności-dodatkowe)
13. [Kody błędów i limity](#kody-błędów-i-limity)

---

## Autentykacja

Większość endpointów wymaga zalogowanego użytkownika (middleware `requireJwt`).

### Sposoby przekazywania tokena

| Platforma | Mechanizm |
|-----------|-----------|
| **Web** | Cookie `accessToken` (ustawiane po logowaniu Google OAuth) |
| **Mobile / narzędzia dev** | Nagłówek `Authorization: Bearer <accessToken>` |

Cookie `refreshToken` jest **httpOnly** — dostępny tylko dla serwera (rotacja sesji).

### Cykl życia sesji

```
Logowanie Google → cookies (access + refresh) → requesty z JWT
       ↓ (access wygasa ~15 min)
POST /api/auth/refresh → nowe cookies
       ↓ (refresh wygasa ~14 dni)
POST /api/auth/logout lub ponowne logowanie
```

**401 Unauthorized** — brak tokena, wygasły access token lub nieprawidłowy JWT. Frontend powinien wtedy wywołać `/api/auth/refresh` (web) lub przekierowaćells użytkownika do logowania.

---

## Typy wspólne

### CardDto (podstawowa karta)

```json
{
  "scryfallId": "uuid",
  "name": "Lightning Bolt",
  "setCode": "M21",
  "setName": "Core Set 2021",
  "collectorNumber": "234",
  "lang": "en",
  "imageUrl": "https://...",
  "price": 1.25
}
```

### CardDetailDto (szczegóły karty)

Rozszerza `CardDto` o:

```json
{
  "manaCost": "{R}",
  "cmc": 1,
  "typeLine": "Instant",
  "oracleText": "Lightning Bolt deals 3 damage...",
  "power": null,
  "toughness": null,
  "rarity": "common",
  "colors": ["R"],
  "colorIdentity": ["R"],
  "priceUsd": 1.25,
  "priceUsdFoil": 2.50,
  "priceEur": 1.10,
  "priceEurFoil": 2.20,
  "scryfallUri": "https://scryfall.com/card/..."
}
```

### CardCondition (stan fizycznej karty)

Dozwolone wartości: `M`, `NM`, `GD`, `LP`, `MP`, `HP`, `DMG`

| Skrót | Znaczenie |
|-------|-----------|
| M | Mint |
| NM | Near Mint (domyślny) |
| GD | Good |
| LP | Light Played |
| MP | Moderately Played |
| HP | Heavily Played |
| DMG | Damaged |

### DeckFormat

`Standard`, `Pioneer`, `Modern`, `Legacy`, `Vintage`, `Commander`, `Pauper`, `Draft`, `Sealed`, `Oathbreaker`, `Custom`

### DeckBoard

`main` (domyślny), `sideboard`, `commander`

### FormatWarningDto

Ostrzeżenie o legalności karty w formacie decku (z Scryfall):

```json
{
  "status": "not_legal",
  "message": "Karta nie jest legalna w formacie Modern"
}
```

Statusy: `not_legal`, `restricted`, `banned`. Dla formatów `Draft`, `Sealed`, `Custom` ostrzeżenia nie są sprawdzane.

### DeckCardFillStatus

Status przypisania fizycznych kopii z kolekcji do slotu w decku:

```json
{
  "quantity": 4,
  "filledQty": 2,
  "unfilledQty": 2,
  "assignments": [
    {
      "id": "uuid",
      "collectionEntryId": "uuid",
      "quantity": 2,
      "condition": "NM",
      "isFoil": false
    }
  ]
}
```

---

## Endpointy — Auth

### `GET /api/auth/google`

Rozpoczyna logowanie przez Google OAuth 2.0. Przekierowuje użytkownika na stronę Google.

**Auth:** nie wymagana  
**Response:** redirect 302 do Google

---

### `GET /api/auth/google/callback`

Callback OAuth po autoryzacji Google.

**Auth:** nie wymagana (obsługiwane przez Passport)  
**Response:** redirect 302 na `{FE_BASE_URL}/` (strona Flutter Web) z ustawionymi cookies:

| Cookie | httpOnly | TTL (domyślnie) |
|--------|----------|-----------------|
| `accessToken` | false | 15 min |
| `refreshToken` | true | 14 dni |

Tworzy sesję w bazie (`device`: `web` lub `mobile` na podstawie User-Agent).

**Błędy:** `401` — autentykacja Google nie powiodła się; `500` — błąd serwera.

---

### `POST /api/auth/refresh`

Odświeża access token i rotuje refresh token.

**Auth:** cookie `refreshToken` (wymagany)  
**Body:** brak

**Response 200:**
```json
{ "message": "Token refreshed" }
```
Ustawia nowe cookies `accessToken` i `refreshToken`.

**Błędy:** `401` — brak/wygasły/nieprawidłowy refresh token.

---

### `POST /api/auth/logout`

Wylogowuje użytkownika — czyści cookies i usuwa sesję z bazy.

**Auth:** opcjonalna (działa nawet bez tokena)  
**Body:** brak

**Response 200:**
```json
{ "message": "Pomyślnie wylogowano" }
```

---

## Endpointy — User

### `GET /api/user/me`

Pobiera profil zalogowanego użytkownika ze statystykami.

**Auth:** wymagana

**Response 200:**
```json
{
  "username": "Jan Kowalski",
  "email": "jan@example.com",
  "stats": {
    "deckCount": 5,
    "uniqueCardsCount": 120,
    "totalPhysicalCards": 340,
    "joinedAt": "15.03.2024"
  }
}
```

---

### `PATCH /api/user/me`

Aktualizuje profil użytkownika.

**Auth:** wymagana

**Body:**
```json
{
  "username": "Nowa nazwa"
}
```

**Response 200:**
```json
{
  "message": "Profile updated",
  "user": { /* obiekt Sequelize User */ }
}
```

---

### `DELETE /api/user/me`

Usuwa konto użytkownika i czyści cookies sesji.

**Auth:** wymagana

**Response 200:**
```json
{
  "message": "Account deleted successfully, but we hope you will be back."
}
```

---

## Endpointy — Cards

Wszystkie endpointy wymagają autentykacji. Dane kart pochodzą ze Scryfall (z cache w lokalnej bazie).

### `POST /api/cards/search`

Wyszukuje karty po nazwie — **głównie dla wersji webowej**.

**Body:**
```json
{
  "cardName": "Lightning Bolt"
}
```

| Pole | Typ | Wymagane | Opis |
|------|-----|----------|------|
| `cardName` | string | tak | Fragment lub pełna nazwa karty |

**Response 200:**
```json
{
  "cards": [ /* CardDto[] */ ],
  "total": 42
}
```

Wyniki łączą dane ze Scryfall (`unique=prints`) z kartami już zapisanymi lokalnie.

**Błędy:** `400` — brak `cardName`; `429` — limit Scryfall; `500` — błąd wyszukiwania.

---

### `POST /api/cards/scan`

Rozpoznaje kartę z tekstu OCR — **głównie dla wersji mobilnej**.

**Body:**
```json
{
  "plaintext": "Lightning Bolt\nInstant\nM21 • EN\n234/274\n..."
}
```

| Pole | Typ | Wymagane | Opis |
|------|-----|----------|------|
| `plaintext` | string | tak | Surowy tekst z OCR skanera |

**Response 200:**
```json
{
  "resolution": "unique",
  "parsed": {
    "name": "Lightning Bolt",
    "set": "M21",
    "collectorNumber": "234/274"
  },
  "cards": [ /* CardDto[] */ ],
  "total": 1
}
```

| `resolution` | Znaczenie |
|--------------|-----------|
| `unique` | Jedno jednoznaczne dopasowanie — można od razu dodać |
| `ambiguous` | Wiele wariantów (języki, foil, ramki) — użytkownik wybiera |
| `none` | Brak dopasowania — użytkownik może wyszukać ręcznie |

**Błędy:** `400` — brak `plaintext`; `429` — limit Scryfall; `500` — błąd skanowania.

---

### `GET /api/cards/:scryfallId`

Pobiera pełne szczegóły karty.

**Params:** `scryfallId` — UUID Scryfall

**Response 200:** `CardDetailDto`

**Błędy:** `400` — nieprawidłowy UUID; `404` — karta nie istnieje; `429` — limit Scryfall.

---

## Endpointy — Collection

### `GET /api/collection`

Pobiera kolekcję użytkownika z opcjonalnymi filtrami.

**Query params (opcjonalne):**

| Param | Typ | Opis |
|-------|-----|------|
| `color` | string | Kolor many (np. `R`, `U`) |
| `type` | string | Fragment type line (np. `Creature`) |
| `edition` / `setCode` | string | Kod lub nazwa edycji |
| `cmc` | number | Converted mana cost |

**Response 200:**
```json
{
  "entries": [
    {
      "scryfallId": "uuid",
      "name": "Lightning Bolt",
      "setCode": "M21",
      "imageUrl": "https://...",
      "price": 1.25,
      "quantity": 4,
      "condition": "NM",
      "isFoil": false,
      "notes": "Z turnieju FNM"
    }
  ],
  "totalValue": 125.50
}
```

> **Uwaga implementacyjna:** odpowiedź nie zawiera `collectionEntryId` (UUID wpisu w bazie). Identyfikator ten jest potrzebny do przypisywania fizycznych kopii do decków — można go uzyskać przez `GET /api/decks/:id/cards/:deckCardId/collection-options`.

---

### `POST /api/collection`

Dodaje kartę do kolekcji (lub zwiększa ilość istniejącego wpisu o tym samym `scryfallId + condition + isFoil`).

**Body:**
```json
{
  "scryfallId": "uuid",
  "quantity": 2,
  "condition": "NM",
  "isFoil": false
}
```

| Pole | Typ | Wymagane | Domyślnie |
|------|-----|----------|-----------|
| `scryfallId` | UUID | tak | — |
| `quantity` | int ≥ 1 | nie | `1` |
| `condition` | CardCondition | nie | `NM` |
| `isFoil` | boolean | nie | `false` |

**Response 201:**
```json
{
  "message": "Card added to collection",
  "entry": {
    "scryfallId": "uuid",
    "quantity": 2,
    "condition": "NM",
    "isFoil": false
  }
}
```

Karta jest automatycznie pobierana ze Scryfall i zapisywana w lokalnej bazie (`ensureCardInDb`).

**Błędy:** `400` — walidacja; `404` — karta nie istnieje w Scryfall; `429` — limit Scryfall.

---

### `POST /api/collection/refresh-prices`

Odświeża ceny wszystkich kart w kolekcji użytkownika ze Scryfall.

**Body:** brak

**Response 200:**
```json
{
  "message": "Prices refreshed successfully",
  "totalCards": 120,
  "updatedCards": 118,
  "failedCards": 2,
  "failedIds": ["uuid-1", "uuid-2"]
}
```

---

### `PATCH /api/collection/:scryfallId`

Aktualizuje ilość (delta) lub notatki wpisu w kolekcji.

**Params:** `scryfallId` — UUID karty

**Query params (identyfikują konkretny wpis):**

| Param | Opis |
|-------|------|
| `condition` | Stan karty (np. `NM`) |
| `isFoil` | `true` / `false` |

**Body (co najmniej jedno pole):**
```json
{
  "delta": -1,
  "notes": "Sprzedane 2 szt."
}
```

| Pole | Typ | Opis |
|------|-----|------|
| `delta` | int | Zmiana ilości (+/-). Przy zejściu do 0 wpis jest usuwany |
| `notes` | string \| null | Notatki użytkownika |

**Response 200:**
```json
{ "message": "Entry updated" }
```

**Błędy:** `404` — wpis nie istnieje; `400` — np. ujemna ilość.

---

### `PATCH /api/collection/:scryfallId/transfer`

Przenosi określoną liczbę kopii między stanami (condition) tej samej karty.

**Body:**
```json
{
  "fromCondition": "NM",
  "toCondition": "LP",
  "isFoil": false,
  "quantity": 2
}
```

| Pole | Typ | Wymagane | Domyślnie |
|------|-----|----------|-----------|
| `fromCondition` | CardCondition | tak | — |
| `toCondition` | CardCondition | tak | — |
| `isFoil` | boolean | nie | `false` |
| `quantity` | int | nie | `1` |

**Response 200:**
```json
{ "message": "Condition transferred" }
```

---

### `DELETE /api/collection/:scryfallId`

Usuwa wpis (lub wszystkie wpisy danej karty) z kolekcji.

**Query params:** `condition`, `isFoil` (opcjonalne — bez nich usuwa wszystkie warianty danej karty)

**Response 200:**
```json
{ "message": "Entry removed" }
```

---

## Endpointy — Decks

### `GET /api/decks`

Lista decków użytkownika.

**Response 200:**
```json
{
  "decks": [
    {
      "id": "uuid",
      "name": "Mono Red Burn",
      "format": "Modern",
      "description": null,
      "isValid": null,
      "lastValidatedAt": null,
      "createdAt": "2024-03-15T10:00:00.000Z",
      "updatedAt": "2024-03-20T14:30:00.000Z"
    }
  ]
}
```

---

### `POST /api/decks`

Tworzy nowy deck.

**Body:**
```json
{
  "name": "Mono Red Burn",
  "format": "Modern",
  "description": "Turn 3 kill"
}
```

| Pole | Typ | Wymagane | Domyślnie |
|------|-----|----------|-----------|
| `name` | string | tak | — |
| `format` | DeckFormat | nie | `Custom` |
| `description` | string \| null | nie | `null` |

**Response 201:**
```json
{
  "message": "Deck created",
  "deck": { /* DeckListItem */ }
}
```

---

### `GET /api/decks/:id`

Szczegóły decku z listą kart, statusem wypełnienia i ostrzeżeniami formatu.

**Response 200:**
```json
{
  "deck": {
    "id": "uuid",
    "name": "Mono Red Burn",
    "format": "Modern",
    "description": null,
    "isValid": true,
    "lastValidatedAt": "2024-03-20T12:00:00.000Z",
    "createdAt": "...",
    "updatedAt": "...",
    "cards": [
      {
        "id": "deck-card-uuid",
        "scryfallId": "uuid",
        "quantity": 4,
        "board": "main",
        "name": "Lightning Bolt",
        "setCode": "M21",
        "imageUrl": "https://...",
        "fillStatus": {
          "quantity": 4,
          "filledQty": 2,
          "unfilledQty": 2,
          "assignments": [ /* ... */ ]
        },
        "formatWarning": null
      }
    ]
  }
}
```

---

### `PATCH /api/decks/:id`

Aktualizuje metadane decku.

**Body (co najmniej jedno pole):**
```json
{
  "name": "Nowa nazwa",
  "format": "Legacy",
  "description": "Opis",
  "isValid": true,
  "lastValidatedAt": "2024-03-20T12:00:00.000Z"
}
```

Pola `isValid` i `lastValidatedAt` służą do zapisu wyniku walidacji decku po stronie klienta.

**Response 200:**
```json
{
  "message": "Deck updated",
  "deck": { /* DeckListItem */ }
}
```

---

### `DELETE /api/decks/:id`

Usuwa deck wraz z kartami i przypisaniami.

**Response 200:**
```json
{ "message": "Deck removed" }
```

---

### `POST /api/decks/:id/cards`

Dodaje kartę do decku.

**Body:**
```json
{
  "scryfallId": "uuid",
  "quantity": 4,
  "board": "main",
  "assignments": [
    { "collectionEntryId": "uuid", "quantity": 2 }
  ]
}
```

| Pole | Typ | Wymagane | Domyślnie |
|------|-----|----------|-----------|
| `scryfallId` | UUID | tak | — |
| `quantity` | int ≥ 1 | nie | `1` |
| `board` | DeckBoard | nie | `main` |
| `assignments` | array | nie | `[]` |

**Response 201:**
```json
{
  "message": "Card added to deck",
  "card": { /* DeckCardItem */ },
  "formatWarning": null
}
```

Jeśli karta już istnieje w danym `board`, ilość jest sumowana.

**Błędy:** `400` — walidacja / przekroczenie slotów przy assignments; `404` — deck/karta nie istnieje; `429` — limit Scryfall.

---

### `DELETE /api/decks/:id/cards/:scryfallId`

Usuwa kartę z decku lub zmniejsza ilość.

**Query params:**

| Param | Domyślnie | Opis |
|-------|-----------|------|
| `board` | `main` | Tablica decku |
| `quantity` | `1` | Ile kopii usunąć |

**Response 200:**
```json
{ "message": "Card removed from deck" }
```
lub (gdy ilość > 1):
```json
{
  "message": "Card quantity updated",
  "card": { /* DeckCardItem */ }
}
```

**Błędy:** `400` — nie można zmniejszyć poniżej przypisanej ilości (`Cannot reduce deck card below assigned quantity`).

---

### `GET /api/decks/:id/cards/:deckCardId/collection-options`

Zwraca wpisy z kolekcji pasujące do karty w decku — do przypisywania fizycznych kopii.

**Response 200:**
```json
{
  "options": [
    {
      "collectionEntryId": "uuid",
      "condition": "NM",
      "isFoil": false,
      "entryQuantity": 4,
      "assignedTotal": 2,
      "availableToAssign": 2
    }
  ]
}
```

---

### `POST /api/decks/:id/cards/:deckCardId/assignments`

Przypisuje fizyczne kopie z kolekcji do slotu w decku.

**Body:**
```json
{
  "collectionEntryId": "uuid",
  "quantity": 2
}
```

**Response 201:**
```json
{
  "message": "Collection entry assigned to deck card",
  "fillStatus": { /* DeckCardFillStatus */ }
}
```

Jeśli przypisanie dla tego `collectionEntryId` już istnieje, ilości są sumowane.

---

### `PATCH /api/decks/:id/cards/:deckCardId/assignments/:assignmentId`

Aktualizuje ilość istniejącego przypisania.

**Body:**
```json
{ "quantity": 3 }
```

**Response 200:**
```json
{
  "message": "Assignment updated",
  "fillStatus": { /* DeckCardFillStatus */ }
}
```

---

### `DELETE /api/decks/:id/cards/:deckCardId/assignments/:assignmentId`

Usuwa przypisanie fizycznych kopii.

**Response 200:**
```json
{
  "message": "Assignment removed",
  "fillStatus": { /* DeckCardFillStatus */ }
}
```

---

## Endpointy — Sync

Endpointy do wykrywania zmian w kolekcji i taliach użytkownika (cross-device sync, polling).

### `GET /api/sync/status`

Zwraca znaczniki czasu ostatniej modyfikacji kolekcji i talii zalogowanego użytkownika.

**Auth:** wymagany (`requireJwt`)

**Response 200:**
```json
{
  "collectionUpdatedAt": "2026-06-03T12:00:00.000Z",
  "decksUpdatedAt": "2026-06-03T12:05:00.000Z",
  "syncToken": "2026-06-03T12:05:00.000Z"
}
```

| Pole | Opis |
|------|------|
| `collectionUpdatedAt` | `MAX(collection_entries.updated_at)` dla użytkownika (epoch ISO jeśli brak wpisów) |
| `decksUpdatedAt` | `MAX(decks.updated_at)` dla użytkownika (epoch ISO jeśli brak talii) |
| `syncToken` | Późniejszy z dwóch powyższych timestampów (porównanie leksykograficzne ISO) |

**Użycie w kliencie:** poll co ~5 s w tle aplikacji. Gdy `syncToken` się zmieni:

- jeśli zmieniło się `collectionUpdatedAt` → odśwież `GET /api/collection`
- jeśli zmieniło się `decksUpdatedAt` → odśwież `GET /api/decks` (oraz otwarty `GET /api/decks/:id` jeśli dotyczy)

Mutacje decków (karty, assignments) aktualizują `decks.updated_at` rodzica. Mutacje kolekcji aktualizują `collection_entries.updated_at`.

---

## Flow — wersja mobilna (skanowanie)

### 1. Logowanie

```
Użytkownik → GET /api/auth/google (WebView / przeglądarka systemowa)
         → Google OAuth
         → GET /api/auth/google/callback
         → cookies ustawione, redirect na FE
```

Aplikacja mobilna powinna przechwytywać cookies lub używać `Authorization: Bearer` po otrzymaniu tokena.

### 2. Skanowanie karty

```
Kamera + OCR → plaintext
           → POST /api/cards/scan { plaintext }
           → sprawdź resolution:
```

| resolution | Akcja UI |
|------------|----------|
| `unique` | Pokaż kartę, przyciski „Dodaj do kolekcji” / „Dodaj do decku” |
| `ambiguous` | Lista `cards[]` — użytkownik wybiera wariant (język, foil, ramka) |
| `none` | Komunikat + opcja ręcznego wyszukiwania (`POST /api/cards/search`) |

Opcjonalnie: `GET /api/cards/:scryfallId` — pełne szczegóły przed dodaniem.

### 3a. Dodanie tylko do kolekcji

```
POST /api/collection
{
  "scryfallId": "...",
  "quantity": 1,
  "condition": "NM",
  "isFoil": false
}
```

### 3b. Dodanie do kolekcji i decku (sekwencja zalecana)

```
1. POST /api/collection          → karta w kolekcji
2. POST /api/decks/:deckId/cards → karta w decku (bez assignments)
   { "scryfallId": "...", "quantity": 4, "board": "main" }
3. GET /api/decks/:deckId/cards/:deckCardId/collection-options
4. POST /api/decks/:deckId/cards/:deckCardId/assignments
   { "collectionEntryId": "...", "quantity": 4 }
```

Alternatywa — dodanie do decku z assignments w jednym kroku (wymaga `collectionEntryId` z kroku 3, więc karta musi być już w kolekcji):

```
POST /api/decks/:deckId/cards
{
  "scryfallId": "...",
  "quantity": 4,
  "assignments": [{ "collectionEntryId": "...", "quantity": 4 }]
}
```

### 4. Wybór decku przy skanowaniu

Przed krokiem 3b pobierz listę decków:

```
GET /api/decks → użytkownik wybiera deck z listy
```

---

## Flow — wersja webowa (wyszukiwanie)

### 1. Logowanie

Identyczne jak mobile — redirect OAuth, cookies w przeglądarce.

### 2. Wyszukiwanie karty

```
Użytkownik wpisuje nazwę
→ POST /api/cards/search { "cardName": "bolt" }
→ wyświetl cards[] (miniatura, nazwa, edycja, cena)
→ klik na kartę → GET /api/cards/:scryfallId (szczegóły)
```

### 3. Dodanie do kolekcji

```
Formularz: quantity, condition, isFoil
→ POST /api/collection
```

### 4. Dodanie do decku

```
GET /api/decks → wybór decku
→ POST /api/decks/:id/cards { scryfallId, quantity, board }
→ opcjonalnie: przypisanie kopii z kolekcji (assignments flow)
```

Można też najpierw dodać do kolekcji, potem z widoku decku przypisać fizyczne kopie.

---

## Flow — wspólne funkcjonalności

### Przegląd kolekcji

```
GET /api/collection
GET /api/collection?color=R&type=Instant&edition=M21
```

Wyświetl `entries[]` + `totalValue`.

### Edycja szczegółów karty w kolekcji

```
Zmiana ilości:  PATCH /api/collection/:scryfallId?condition=NM&isFoil=false
                { "delta": 1 }

Notatki:        PATCH /api/collection/:scryfallId?condition=NM&isFoil=false
                { "notes": "..." }

Zmiana stanu:   PATCH /api/collection/:scryfallId/transfer
                { "fromCondition": "NM", "toCondition": "LP", "quantity": 1 }

Usunięcie:      DELETE /api/collection/:scryfallId?condition=NM&isFoil=false
```

### Przegląd decków

```
GET /api/decks           → lista
GET /api/decks/:id       → szczegóły z kartami, fillStatus, formatWarning
```

### Tworzenie i edycja decków

```
POST /api/decks          → nowy deck
PATCH /api/decks/:id     → zmiana nazwy, formatu, opisu
DELETE /api/decks/:id    → usunięcie
```

### Dodawanie kart do decków

```
POST /api/decks/:id/cards
DELETE /api/decks/:id/cards/:scryfallId?board=main&quantity=1
```

### Uzupełnianie decków kartami z kolekcji (assignments)

```
GET  .../collection-options  → jakie kopie są dostępne
POST .../assignments         → przypisz
PATCH .../assignments/:id    → zmień ilość
DELETE .../assignments/:id   → usuń przypisanie
```

`fillStatus.unfilledQty > 0` sygnalizuje w UI, że slot decku nie ma przypisanych wszystkich fizycznych kopii.

### Profil użytkownika

```
GET /api/user/me     → dane + statystyki
PATCH /api/user/me   → zmiana username
```

### Synchronizacja między urządzeniami (live sync)

```
Co ~5 s (aplikacja na pierwszym planie):
GET /api/sync/status → porównaj syncToken z poprzednią wartością
  → zmiana collectionUpdatedAt → GET /api/collection
  → zmiana decksUpdatedAt      → GET /api/decks (+ otwarty deck)
```

Po każdej lokalnej mutacji klient odświeża odpowiedni store natychmiast (nie czeka na poll). Konflikty: last-write-wins po stronie serwera.

### Odświeżanie sesji (web)

```
(access token wygasa)
→ POST /api/auth/refresh (automatycznie z cookie refreshToken)
→ kontynuuj requesty
```

---

## Funkcjonalności dodatkowe

Poniższe funkcje istnieją w backendzie, ale nie były wymienione w prompcie:

| Funkcja | Endpoint | Opis |
|---------|----------|------|
| **Odświeżanie cen** | `POST /api/collection/refresh-prices` | Pobiera aktualne ceny ze Scryfall dla całej kolekcji |
| **Ostrzeżenia formatu** | zwracane przy dodawaniu/wyświetlaniu kart w decku | Informacja czy karta jest legalna w formacie decku (Scryfall legalities) |
| **Walidacja decku** | `PATCH /api/decks/:id` (`isValid`, `lastValidatedAt`) | Klient zapisuje wynik walidacji (min. kart, max kopii — logika w `FormatValidator`) |
| **Tablice decku** | `board`: `main`, `sideboard`, `commander` | Obsługa sideboardu i strefy commandera |
| **Transfer stanu** | `PATCH /api/collection/:scryfallId/transfer` | Przenoszenie kopii między stanami bez utraty karty |
| **Foil vs non-foil** | `isFoil` w kolekcji i assignments | Osobne wpisy i ceny dla foil |
| **Usunięcie konta** | `DELETE /api/user/me` | Trwałe usunięcie użytkownika |
| **Wylogowanie** | `POST /api/auth/logout` | Unieważnienie sesji |
| **Filtry kolekcji** | query params w `GET /api/collection` | Filtrowanie po kolorze, typie, edycji, CMC |
| **Wartość kolekcji** | `totalValue` w `GET /api/collection` | Suma cen × ilości |
| **Wykrywanie urządzenia** | przy logowaniu OAuth | Sesja oznaczana jako `web` lub `mobile` |

### Formaty z walidacją legalności (Scryfall)

`Standard`, `Pioneer`, `Modern`, `Legacy`, `Vintage`, `Commander`, `Pauper`, `Oathbreaker`

Formaty bez sprawdzania legalności: `Draft`, `Sealed`, `Custom`

### Reguły walidacji decku (FormatValidator)

| Format | Min kart | Max kopii (non-basic) |
|--------|----------|----------------------|
| Standard | 60 | 4 |
| Commander | 100 | 1 (basic lands bez limitu) |

Walidacja po stronie serwera jest dostępna jako klasa domenowa; endpoint nie wykonuje jej automatycznie — klient powinien wywołać logikę i zapisać wynik przez `PATCH /api/decks/:id`.

---

## Kody błędów i limity

### Typowe kody HTTP

| Kod | Znaczenie |
|-----|-----------|
| `200` | Sukces |
| `201` | Utworzono |
| `302` | Redirect (OAuth) |
| `400` | Błąd walidacji / logiki biznesowej |
| `401` | Brak autentykacji / wygasła sesja |
| `404` | Nie znaleziono (deck, karta, wpis) |
| `429` | Przekroczony limit Scryfall |
| `500` | Błąd serwera |

### Limit Scryfall

Backend respektuje limit ~10 req/s do Scryfall (wewnętrzny throttle 100 ms między requestami). Przy `429` frontend powinien wyświetlić komunikat i spróbować ponownie później.

### Identyfikacja wpisów kolekcji

Klucz wpisu w kolekcji to para: `(scryfallId, condition, isFoil)`.  
Do operacji assignments wymagany jest dodatkowo `collectionEntryId` (UUID z bazy) — dostępny przez endpoint `collection-options`.

---

## Diagram — pełny flow dodawania karty (mobile + web)

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Mobile OCR │     │  Web Search      │     │  Card Details   │
│  POST /scan │     │  POST /search    │     │  GET /cards/:id │
└──────┬──────┘     └────────┬─────────┘     └────────┬────────┘
       │                     │                          │
       └─────────────────────┴──────────────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │  POST /api/collection  │ (opcjonalnie)
                    └────────────┬───────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │ POST /api/decks/:id/   │ (opcjonalnie)
                    │        cards           │
                    └────────────┬───────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │ GET .../collection-    │ (opcjonalnie)
                    │     options            │
                    └────────────┬───────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │ POST .../assignments   │ (opcjonalnie)
                    └────────────────────────┘
```

---

## Zmienne środowiskowe (backend)

| Zmienna | Opis |
|---------|------|
| `PORT` | Port serwera (domyślnie 3000) |
| `JWT_ACCESS_SECRET` | Sekret access tokena |
| `JWT_REFRESH_SECRET` | Sekret refresh tokena |
| `JWT_ACCESS_EXPIRES_IN` | TTL access tokena |
| `JWT_REFRESH_EXPIRES_IN` | TTL refresh tokena |
| `ACCESS_TOKEN_EXPIRY_MIN` | TTL cookie access (minuty) |
| `REFRESH_TOKEN_EXPIRY_DAYS` | TTL cookie refresh (dni) |
| `FE_BASE_URL` | URL frontendu (redirect po OAuth) |
| `NODE_ENV` | `production` włącza `secure` cookies |
