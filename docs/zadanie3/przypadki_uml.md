# Diagramy przypadków użycia (UML) — Grimoire MtG

## Diagram 1: Aktor — Michał Nowak (Competitive Player)

```mermaid
graph LR
    Michal["👤 Michał\n(Competitive Player)"]

    subgraph Grimoire["🎮 System: Grimoire MtG"]

        %% RZĄD 1
        subgraph _
            UC01(("Zarejestruj /\nZaloguj"))
            UC02(("Dodaj kartę"))
            UC03(("Skanuj kartę"))
            UC04(("Nowy deck"))
        end

        %% RZĄD 2
        subgraph _
            UC05(("Kolekcja"))
            UC06(("Decki"))
            UC07(("Edytuj"))
            UC08(("Filtruj"))
        end

        %% RZĄD 3
        subgraph _
            UC09(("Statystyki"))
            UC10(("Legalność"))
            UC11(("Eksport"))
            UC12(("Sync"))
        end
    end

    Scryfall[("🌐 Scryfall")]
    MLKit[("📷 ML Kit")]

    %% Aktor → pierwszy rząd (mniej linii!)
    Michal --- UC01
    Michal --- UC02
    Michal --- UC03
    Michal --- UC04

    %% poziomy układ (hack)
    UC01 --- UC02 --- UC03 --- UC04
    UC05 --- UC06 --- UC07 --- UC08
    UC09 --- UC10 --- UC11 --- UC12

    %% logika
    UC02 --- Scryfall
    UC03 --- MLKit
    UC03 --- Scryfall
    UC10 --- Scryfall
```

---

## Diagram 2: Aktor — Tomasz Wiśniewski (Collector)

```mermaid
graph LR
    Tomasz["👤 Tomasz\n(Collector)"]

    subgraph Grimoire["🎮 System: Grimoire MtG"]

        subgraph _
            UC01(("Logowanie"))
            UC03(("Skan"))
            UC05(("Kolekcja"))
            UC08(("Filtr"))
        end

        subgraph _
            UC13(("Notatki"))
            UC14(("Usuń"))
            UC15(("Wartość"))
            UC16(("Sortuj"))
        end
        subgraph _
            Scryfall[("🌐 Scryfall")]
            MLKit[("📷 ML Kit")]
        end
    end



    Tomasz --- UC01
    Tomasz --- UC03
    Tomasz --- UC05
    Tomasz --- UC08

    %% poziomy układ
    UC01 --- UC03 --- UC05 --- UC08
    UC13 --- UC14 --- UC15 --- UC16

    UC03 --- MLKit
    UC03 --- Scryfall
    UC15 --- Scryfall
```

---

## Diagram 3: Pełny diagram systemu — wszyscy aktorzy

```mermaid
graph LR
    Michal["👤 Michał"]
    Tomasz["👤 Tomasz"]

    subgraph Grimoire

        subgraph _
            UC01(("Login"))
            UC02(("Dodaj"))
            UC03(("Skan"))
            UC04(("Nowy deck"))
            UC05(("Kolekcja"))
        end

        subgraph _
            UC06(("Decki"))
            UC07(("Edytuj"))
            UC08(("Filtr"))
            UC09(("Staty"))
            UC10(("Legal"))
        end

        subgraph _
            UC11(("Export"))
            UC12(("Sync"))
            UC13(("Notatki"))
            UC14(("Usuń"))
            UC15(("Wartość"))
        end
    end

    Scryfall[("🌐 Scryfall")]
    MLKit[("📷 ML Kit")]

    Michal --- UC01
    Michal --- UC02
    Michal --- UC03
    Michal --- UC04

    Tomasz --- UC01
    Tomasz --- UC03
    Tomasz --- UC05
    Tomasz --- UC08

    %% wymuszenie poziomów
    UC01 --- UC02 --- UC03 --- UC04 --- UC05
    UC06 --- UC07 --- UC08 --- UC09 --- UC10
    UC11 --- UC12 --- UC13 --- UC14 --- UC15

    UC02 --- Scryfall
    UC03 --- MLKit
    UC03 --- Scryfall
    UC10 --- Scryfall
    UC15 --- Scryfall
```