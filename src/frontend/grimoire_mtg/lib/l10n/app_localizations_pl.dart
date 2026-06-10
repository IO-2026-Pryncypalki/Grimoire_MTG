// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get navSearch => 'Szukaj';

  @override
  String get navCollection => 'Kolekcja';

  @override
  String get navDecks => 'Talie';

  @override
  String get navProfile => 'Profil';

  @override
  String get navScanner => 'Skaner';

  @override
  String get commonCancel => 'Anuluj';

  @override
  String get commonDelete => 'Usuń';

  @override
  String get commonOK => 'OK';

  @override
  String get commonSave => 'Zapisz';

  @override
  String get commonApply => 'Zastosuj';

  @override
  String get commonClear => 'Wyczyść';

  @override
  String get commonRetry => 'Spróbuj ponownie';

  @override
  String get commonReplace => 'Zastąp';

  @override
  String get commonTransfer => 'Przenieś';

  @override
  String get commonFill => 'Uzupełnij';

  @override
  String get commonAdd => 'Dodaj';

  @override
  String get errorAppStartup => 'Błąd uruchomienia aplikacji';

  @override
  String get errorSessionExpired => 'Sesja wygasła. Zaloguj się ponownie.';

  @override
  String errorServer(int statusCode) {
    return 'Błąd serwera ($statusCode).';
  }

  @override
  String get errorScryfallRateLimit => 'Limit Scryfall — spróbuj za chwilę.';

  @override
  String get errorNoConnection =>
      'Brak połączenia z serwerem. Sprawdź sieć i spróbuj ponownie.';

  @override
  String get errorLoadCollection => 'Nie udało się wczytać kolekcji';

  @override
  String get errorLoadDecks => 'Nie udało się wczytać talii';

  @override
  String get errorNoLoginTokens => 'Brak tokenów po logowaniu.';

  @override
  String get loginTagline => 'Zarządzaj kolekcją i taliami Magic';

  @override
  String get loginGoogle => 'Zaloguj przez Google';

  @override
  String get profileTitle => 'Profil Użytkownika';

  @override
  String get profileUsername => 'Nazwa użytkownika';

  @override
  String profileJoined(String date) {
    return 'Dołączono: $date';
  }

  @override
  String get profileDecks => 'Talie';

  @override
  String get profileUniqueCards => 'Unikalne karty';

  @override
  String get profilePhysicalCards => 'Fizyczne karty';

  @override
  String get profileEditName => 'Edytuj nazwę';

  @override
  String get profileSaveName => 'Zapisz nazwę';

  @override
  String get profileLogout => 'Wyloguj';

  @override
  String get profileDeleteAccount => 'Usuń konto';

  @override
  String get profileUpdated => 'Profil zaktualizowany';

  @override
  String get profileDeleteConfirm => 'Usunąć konto?';

  @override
  String get profileDeleteConfirmBody => 'Tej operacji nie można cofnąć.';

  @override
  String get profileLanguage => 'Język';

  @override
  String get collectionTitle => 'Moja Kolekcja';

  @override
  String get collectionEmpty => 'Kolekcja jest pusta';

  @override
  String collectionValueSummary(String value, int count) {
    return 'Wartość: $value • $count wpisów';
  }

  @override
  String get collectionRefreshPrices => 'Odśwież ceny';

  @override
  String cardsUpdated(int updated, int total) {
    return 'Zaktualizowano $updated/$total kart';
  }

  @override
  String get collectionFiltersTitle => 'Filtry kolekcji';

  @override
  String get collectionFilterColor => 'Kolor (R, U, G, B, W)';

  @override
  String get collectionFilterType => 'Typ (Creature, Instant, ...)';

  @override
  String get collectionFilterEdition => 'Edycja / set';

  @override
  String get collectionFilterCmc => 'CMC';

  @override
  String collectionFilterSummaryColor(String value) {
    return 'kolor: $value';
  }

  @override
  String collectionFilterSummaryType(String value) {
    return 'typ: $value';
  }

  @override
  String collectionFilterSummaryEdition(String value) {
    return 'edycja: $value';
  }

  @override
  String collectionFilterSummaryCmc(int value) {
    return 'CMC: $value';
  }

  @override
  String get decksTitle => 'Moje Talie';

  @override
  String get decksEmpty => 'Brak talii — utwórz pierwszą';

  @override
  String get decksNewDeck => 'Nowa talia';

  @override
  String get deckNew => 'Nowa Talia';

  @override
  String get deckSave => 'ZAPISZ';

  @override
  String get deckName => 'Nazwa talii';

  @override
  String get deckDescription => 'Opis (opcjonalnie)';

  @override
  String get deckDeleteConfirm => 'Usunąć talię?';

  @override
  String get deckRemoveConfirm => 'Usunąć z talii?';

  @override
  String deckRemoveAllCopies(int quantity, String name) {
    return 'Usunąć wszystkie $quantity kopie: $name?';
  }

  @override
  String deckRemoveCard(String name) {
    return 'Usunąć kartę: $name?';
  }

  @override
  String get deckRemoveFromDeck => 'Usuń z talii';

  @override
  String get deckCardDetails => 'Szczegóły karty';

  @override
  String get deckEmptyCards => 'Brak kart w talii';

  @override
  String get deckValidationTitle => 'Walidacja talii';

  @override
  String get deckFormatNoIssues => 'Format: bez uwag.';

  @override
  String get deckFormatIssues => 'Format:';

  @override
  String get deckAssignmentsAll => 'Przypisania: wszystkie kopie z kolekcji.';

  @override
  String get deckAssignmentsEmpty => 'Przypisania: brak kart w talii.';

  @override
  String get deckAssignmentsIssues => 'Przypisania:';

  @override
  String get deckFillFromCollection => 'Uzupełnij z kolekcji?';

  @override
  String deckFillFromCollectionBody(int unfilled) {
    return 'Przypisać kopie z kolekcji do $unfilled brakujących slotów (dopasowanie po nazwie karty)?';
  }

  @override
  String get deckFillFromCollectionTooltip => 'Uzupełnij z kolekcji';

  @override
  String get deckExportList => 'Eksportuj listę';

  @override
  String get deckImportList => 'Import z listy';

  @override
  String get deckAddCard => 'Dodaj kartę';

  @override
  String get deckValidate => 'Waliduj';

  @override
  String get deckExportEmpty => 'Talia jest pusta — skopiowano pustą listę';

  @override
  String get deckExportCopied => 'Skopiowano listę talii do schowka';

  @override
  String deckAssignedSummary(int copies, int slots, String skipped) {
    return 'Przypisano $copies kopii do $slots pozycji$skipped';
  }

  @override
  String deckAssignedSkipped(int count) {
    return ' • $count bez kopii';
  }

  @override
  String get deckNoAvailableCopies =>
      'Brak dostępnych kopii — wszystkie są już przypisane w innych taliach';

  @override
  String get deckTransferCopies => 'Przenieść kopie?';

  @override
  String deckTransferCopiesBody(int count, String sources) {
    return 'Ten wpis ma $count kopii przypisanych w innej talii.\n\nPrzypisywanie tutaj usunie je stamtąd:\n$sources';
  }

  @override
  String deckTransferSource(int quantity, String deckName) {
    return '$quantity× z talii „$deckName”';
  }

  @override
  String get deckTransferPickSource => 'Wybierz talię, z której zabrać kopie:';

  @override
  String get deckAssignCopies => 'Przypisz kopie';

  @override
  String get deckAssignFromCollection => 'Przypisz kopie z kolekcji';

  @override
  String deckOptionFree(int available, int assignable, String version) {
    return 'Wolne: $available • do slotu: $assignable • $version';
  }

  @override
  String deckOptionTransfer(int assignable, int elsewhere, String version) {
    return 'Przenieś do $assignable • $elsewhere w innej talii • $version';
  }

  @override
  String deckOptionSlot(int assignable, String version) {
    return 'Do slotu: $assignable • $version';
  }

  @override
  String deckOptionOtherVersion(String setCode) {
    return '$setCode • inna wersja';
  }

  @override
  String get deckFormatOk => 'Format OK';

  @override
  String get deckFormatWarnings => 'Format: uwagi';

  @override
  String get deckFormatValidTooltip => 'Talia spełnia wymagania formatu';

  @override
  String get deckAssigned => 'Przypisane';

  @override
  String get deckNotAssigned => 'Brak przypisań';

  @override
  String get deckAllCopiesAssigned => 'Wszystkie kopie przypisane z kolekcji';

  @override
  String get deckListAllAssigned => 'Wszystkie kopie z kolekcji przypisane';

  @override
  String get deckListMissingAssignments => 'Brak pełnych przypisań';

  @override
  String get deckViewList => 'Lista';

  @override
  String get deckViewGrid => 'Siatka';

  @override
  String get deckViewStack => 'Stos';

  @override
  String deckViewTooltip(String mode) {
    return 'Widok: $mode';
  }

  @override
  String get deckBoardMain => 'Główna';

  @override
  String get deckBoardEmpty => '0 kart';

  @override
  String deckBoardSummary(
    int positions,
    int copies,
    int filled,
    int copiesTotal,
  ) {
    return '$positions poz. • $copies kopii • $filled/$copiesTotal przypisane';
  }

  @override
  String deckValidatorMainMin60(int count) {
    return 'Main deck wymaga min. 60 kart (masz $count).';
  }

  @override
  String deckValidatorCommanderMin100(int count) {
    return 'Commander wymaga 100 kart (masz $count).';
  }

  @override
  String deckValidatorLegalityWarnings(int count) {
    return '$count kart z ostrzeżeniem legalności.';
  }

  @override
  String deckValidatorUnfilledPositions(int positions, int copies) {
    return '$positions pozycji w kolekcji bez pełnego przypisania ($copies kopii).';
  }

  @override
  String deckValidatorNotInCollection(int count) {
    return '$count pozycji bez karty w kolekcji.';
  }

  @override
  String deckValidatorCopyLimit(int max, int actual) {
    return 'Karta przekracza limit $max kopii ($max dozwolone, $actual w decku).';
  }

  @override
  String get cardSearchTitle => 'Szukaj kart';

  @override
  String get cardSearchHint => 'Nazwa karty...';

  @override
  String cardSearchNotFound(String query) {
    return 'Nie znaleziono kart dla „$query”';
  }

  @override
  String get cardSearchDidYouMean => 'Czy chodziło Ci o:';

  @override
  String get cardSearchMinChars =>
      'Wpisz co najmniej 2 znaki, aby szukać w Scryfall';

  @override
  String get cardSearchMinCharsShort => 'Wpisz co najmniej 2 znaki';

  @override
  String get cardSearchAutocomplete => 'Pokazano wyniki dla podobnych nazw';

  @override
  String get cardSearchNoResults => 'Nie znaleziono kart dla aktywnych filtrów';

  @override
  String get searchFiltersLabel => 'Filtry';

  @override
  String searchFiltersActive(int count) {
    return 'Filtry ($count)';
  }

  @override
  String get searchFilterClear => 'Wyczyść filtry';

  @override
  String get searchFilterColors => 'Kolory';

  @override
  String get searchFilterType => 'Typ';

  @override
  String get searchFilterTypeAny => 'Dowolny typ';

  @override
  String get searchFilterTypeCreature => 'Stworzenie';

  @override
  String get searchFilterTypeInstant => 'Błyskawica';

  @override
  String get searchFilterTypeSorcery => 'Czary';

  @override
  String get searchFilterTypeEnchantment => 'Zaczarowanie';

  @override
  String get searchFilterTypeArtifact => 'Artefakt';

  @override
  String get searchFilterTypePlaneswalker => 'Płanetowładca';

  @override
  String get searchFilterTypeLand => 'Ląd';

  @override
  String get searchFilterRarity => 'Rzadkość';

  @override
  String get searchFilterCmc => 'CMC';

  @override
  String get searchFilterExactColors => 'dokładnie';

  @override
  String get cardDefaultName => 'Karta';

  @override
  String cardPowerToughness(String value) {
    return 'Siła/Wytrzymałość: $value';
  }

  @override
  String cardRarity(String value) {
    return 'Rzadkość: $value';
  }

  @override
  String get cardColors => 'Kolory';

  @override
  String get cardColorIdentity => 'Tożsamość';

  @override
  String get cardOpenScryfall => 'Otwórz w Scryfall';

  @override
  String get cardAddToCollection => 'Dodano do kolekcji';

  @override
  String get cardCreateDeckFirst => 'Najpierw utwórz talię';

  @override
  String get cardAddToDeck => 'Dodano do talii';

  @override
  String get cardSelectDeck => 'Wybierz talię';

  @override
  String get cardCollectionButton => 'Kolekcja';

  @override
  String get cardDeckButton => 'Talia';

  @override
  String get addToCollectionTitle => 'Dodaj do kolekcji';

  @override
  String get addToCollectionQuantity => 'Ilość:';

  @override
  String get addToDeckTitle => 'Dodaj do talii';

  @override
  String get addToDeckQuantity => 'Ilość w talii:';

  @override
  String get addToDeckAssignFromCollection => 'Przypisz z kolekcji';

  @override
  String addToDeckAvailableCopies(int count) {
    return 'Dostępne kopie: $count';
  }

  @override
  String get addToDeckExceedsQuantity =>
      'Przypisane kopie przekraczają ilość w talii';

  @override
  String get addToDeckExceedsOwnedQuantity =>
      'Wszystkie posiadane kopie tej karty są już w innych taliach';

  @override
  String addToDeckAvailableToAdd(int count) {
    return 'Można dodać do talii: $count';
  }

  @override
  String addToDeckAllCopiesInDecks(int owned) {
    return 'Wszystkie $owned posiadane kopie są już w taliach';
  }

  @override
  String addToDeckUsedInDeck(int quantity, String deckName) {
    return '$quantity× w $deckName';
  }

  @override
  String get deckBoardZone => 'Strefa';

  @override
  String deckAssignedCount(int assigned, int total) {
    return 'Przypisane: $assigned / $total';
  }

  @override
  String get addCardToDeckTitle => 'Dodaj kartę do talii';

  @override
  String get addCardToDeckTabCollection => 'Kolekcja';

  @override
  String get addCardToDeckTabSearch => 'Szukaj';

  @override
  String get addCardToDeckEmptyCollection =>
      'Kolekcja jest pusta.\nUżyj zakładki Szukaj, aby dodać karty spoza kolekcji.';

  @override
  String get addCardToDeckSearchHint => 'Szukaj po nazwie...';

  @override
  String get addCardToDeckFilters => 'Filtry kolekcji';

  @override
  String get addCardToDeckNoFilterMatch => 'Brak kart pasujących do filtrów';

  @override
  String get collectionEntryDeleteConfirm => 'Usunąć wpis?';

  @override
  String get collectionEntryDelete => 'Usuń wpis';

  @override
  String get collectionEntryChangeCondition => 'Zmień stan';

  @override
  String get collectionEntryQuantityToMove => 'Ilość do przeniesienia:';

  @override
  String get collectionEntrySaveNotes => 'Zapisz notatki';

  @override
  String get collectionYourCollection => 'Twoja kolekcja';

  @override
  String get collectionConditionChanged => 'Zmieniono stan';

  @override
  String get collectionNotes => 'Notatki';

  @override
  String get collectionEntryDeckUsage => 'Użycie w taliach';

  @override
  String collectionEntryUnassigned(int count) {
    return '$count× nieprzypisane';
  }

  @override
  String get collectionNotInCollection => 'Brak w kolekcji';

  @override
  String fillStatusAssigned(int filled, int total) {
    return 'Przypisano $filled/$total kopii';
  }

  @override
  String fillStatusMissing(int count) {
    return '$count brak';
  }

  @override
  String get importTitle => 'Import z listy';

  @override
  String get importAction => 'IMPORT';

  @override
  String get importReplaceConfirm => 'Zastąpić talię?';

  @override
  String get importReplaceBody =>
      'Wszystkie karty i przypisania w tej talii zostaną usunięte przed importem.';

  @override
  String get importMerge => 'Dodaj do talii';

  @override
  String get importReplace => 'Zastąp talię';

  @override
  String get importHint =>
      'Wklej listę w formacie „1 Nazwa karty”, z opcjonalnymi sekcjami // Commander, // Sideboard lub // Oathbreaker.';

  @override
  String get importPasteRequired => 'Wklej listę kart do importu';

  @override
  String get importRecognizing => 'Rozpoznawanie kart…';

  @override
  String get importComplete => 'Import zakończony';

  @override
  String importImportedCount(int count) {
    return 'Zaimportowano $count pozycji.';
  }

  @override
  String get importClearedExisting =>
      'Poprzednia zawartość talii została usunięta.';

  @override
  String importUnrecognized(int count) {
    return 'Nierozpoznane karty ($count):';
  }

  @override
  String importUnrecognizedLine(int line) {
    return ' (linia $line)';
  }

  @override
  String importAndMore(int count) {
    return '… i $count więcej';
  }

  @override
  String get scanNoText => 'Nie wykryto tekstu na karcie';

  @override
  String scanError(String error) {
    return 'Błąd skanowania: $error';
  }

  @override
  String get scanTitle => 'Skan';

  @override
  String get scanNotRecognized => 'Nie rozpoznano karty';

  @override
  String get scanSearchManually => 'Wyszukaj ręcznie';

  @override
  String get scanSelectVariant => 'Wybierz wariant';

  @override
  String get scanFilterHint => 'Filtruj po kodzie edycji, numerze lub roku…';

  @override
  String get scanCreateDeckInTab => 'Utwórz talię w zakładce Talie';

  @override
  String get scanAddedToCollectionAndDeck => 'Dodano do kolekcji i talii';
}
