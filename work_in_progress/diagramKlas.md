# Diagram klas — Grimoire MtG

```mermaid
classDiagram

    class GoogleUserInfo {
        <<DTO>>
        +String googleId
        +String email
        +String name
    }

    class AuthService {
        -UserRepository userRepo
        -SessionManager sessionManager
        +loginWithGoogle(String authCode) Session
        -exchangeGoogleToken(String authCode) GoogleUserInfo
    }

    class Session {
        -string token
        -string deviceType
        -DateTime createdAt
        -DateTime expiresAt
        +getToken() string
        +getDeviceType() string
        +isValid() boolean
    }

    class SessionManager {
        -List~Session~ activeSessions
        +createSession(UUID userId, String deviceType) Session
        +checkSession(String token) boolean
        +logout(String token) void
        -getSessionByToken(String token) Session
        -invalidateSession(String token) void
    }

    class User {
        -UUID id
        -String email
        -String username
        -String googleId
        +getId() UUID
        +getEmail() String
        +getUsername() String
        +updateProfile()
    }

    class UserRepository {
        <<repository>>
        +findOrCreateByGoogleId(GoogleUserInfo info) User
        +findById(UUID id) User
    }

    class Card {
        -String scryfallId
        -String name
        -String setCode
        -Double currentPrice
        -String imageUrl
        +getScryfallId() String
        +getName() String
        +getSetCode() String
        +getCurrentPrice() Double
        +getImageUrl() String
    }

    class CollectionEntry {
        -Card card
        -int quantity
        -String condition
        -String notes
        +getCard() Card
        +getQuantity() int
        +getCondition() String
        +getNotes() String
        +updateQuantity(int delta) void
        +setCondition(String condition) void
        +setNotes(String notes) void
    }

    class Collection {
        -UUID userId
        -List~CollectionEntry~ entries
        +addCard(Card card) void
        +removeCard(String scryfallId) void
        +getEntry(String scryfallId) CollectionEntry
        +getEntries() List~CollectionEntry~
        +calculateTotalValue() Double
        +refreshPrices(ICardProvider provider) void
    }

    class Deck {
        -UUID id
        -String name
        -String format
        +getId() UUID
        +getName() String
        +getFormat() String
        +addCard(Card card, int count) void
        +removeCard(String scryfallId) void
        +validate(IDeckValidator validator) boolean
        +searchNewCards(String query, ICardProvider provider) List~Card~
    }

    class ICardProvider {
        <<interface>>
        +searchCard(String query) List~Card~
        +getCardDetails(String id) Card
        +getPrice(String scryfallId) Double
    }

    class JsonCacheProvider {
        -Map~String, Card~ memoryCache
        -String filePath
        -loadFromFile() void
        -saveToFile() void
        +getCard(String id) Card
        +isCachedMap(String id) boolean
        +isCachedFile(String id) boolean
    }

    class ScryfallAdapter {
        -HttpClient client
        +searchCard(String query) List~Card~
        +getCardDetails(String id) Card
        +getPrice(String scryfallId) Double
    }

    class SmartAdapter {
        -ScryfallAdapter scryfall
        -JsonCacheProvider cache
        +searchCard(String query) List~Card~
        +getCardDetails(String id) Card
        +getPrice(String scryfallId) Double
    }

    class IDeckValidator {
        <<interface>>
        +isValid(Deck deck, String format) boolean
    }

    class FormatValidator {
        -Map~String, Rules~ formatRules
        +isValid(Deck deck, String format) boolean
        -loadRules(String format) Rules
    }

    class ScannerService {
        <<service>>
        +processScan(Object image, ICardProvider provider) Card
    }

    class GoogleMLKitAdapter {
        +recognizeText(Object image) String
    }

    AuthService ..> GoogleUserInfo : tworzy z odpowiedzi Google
    AuthService --> UserRepository : korzysta z
    AuthService --> SessionManager : inicjuje sesje
    UserRepository ..> User : operuje na

    User "1" -- "0..*" Session : posiada
    SessionManager "1" -- "*" Session : zarzadza

    User "1" -- "1" Collection : posiada
    User "1" -- "*" Deck : tworzy

    Collection "1" -- "*" CollectionEntry : zawiera
    CollectionEntry "1" -- "1" Card : odnosi sie do
    Deck "1" -- "*" Card : zawiera

    SmartAdapter ..|> ICardProvider : implementuje
    SmartAdapter --> ScryfallAdapter : deleguje zapytania
    SmartAdapter --> JsonCacheProvider : sprawdza cache
    ScryfallAdapter ..|> ICardProvider : implementuje

    GoogleMLKitAdapter ..|> ScannerService : dostarcza OCR
    FormatValidator ..|> IDeckValidator : implementuje

    Collection ..> ICardProvider : pobiera ceny
    Deck ..> ICardProvider : szuka kart
    Deck ..> IDeckValidator : sprawdza zasady
    ScannerService ..> ICardProvider : identyfikuje karte po OCR
```