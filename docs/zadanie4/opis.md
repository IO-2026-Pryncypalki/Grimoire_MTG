S (Single Responsibility): Klasa ScryfallAdapter zajmuje się wyłącznie komunikacją z API i mapowaniem danych. 
Klasa Deck odpowiada tylko za logikę biznesową talii (statystyki, skład), nie wie nic o bazie danych.

O (Open/Closed): System jest otwarty na nowe formaty rozgrywki (np. Modern, Legacy). Wystarczy dodać 
nową klasę implementującą IDeckValidator bez modyfikowania głównego kodu deckbuildera.

D (Dependency Inversion): Klasy wysokiego poziomu (np. obsługa kolekcji) zależą od interfejsu ICardProvider, 
a nie bezpośrednio od klasy ScryfallAPI. Ułatwia to testowanie (Mockowanie) i zmianę dostawcy danych.

Wybrane Wzorce Projektowe
Wzorzec Adapter (Strukturalny):

Zastosowanie: ScryfallAdapter.

Uzasadnienie: API Scryfall ma swój własny format danych. Używamy adaptera, aby "przetłumaczyć" ich JSON na nasz wewnętrzny obiekt Card. Jeśli Scryfall zmieni API, naprawiamy tylko adapter, a reszta aplikacji (Flutter, baza danych) działa bez zmian.

Wzorzec Strategia (Behawioralny):

Zastosowanie: IDeckValidator (walidacja legalności decku).

Uzasadnienie: Każdy format MtG (Commander, Standard) ma inne zasady legalności (liczba kart, duplikaty). Używając wzorca Strategia, aplikacja dynamicznie wybiera odpowiedni algorytm walidacji w zależności od tego, jaki format wybrał użytkownik w UC-04.
