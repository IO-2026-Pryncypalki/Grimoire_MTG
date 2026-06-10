import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
  ];

  /// No description provided for @navSearch.
  ///
  /// In pl, this message translates to:
  /// **'Szukaj'**
  String get navSearch;

  /// No description provided for @navCollection.
  ///
  /// In pl, this message translates to:
  /// **'Kolekcja'**
  String get navCollection;

  /// No description provided for @navDecks.
  ///
  /// In pl, this message translates to:
  /// **'Talie'**
  String get navDecks;

  /// No description provided for @navProfile.
  ///
  /// In pl, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @navScanner.
  ///
  /// In pl, this message translates to:
  /// **'Skaner'**
  String get navScanner;

  /// No description provided for @commonCancel.
  ///
  /// In pl, this message translates to:
  /// **'Anuluj'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In pl, this message translates to:
  /// **'Usuń'**
  String get commonDelete;

  /// No description provided for @commonOK.
  ///
  /// In pl, this message translates to:
  /// **'OK'**
  String get commonOK;

  /// No description provided for @commonSave.
  ///
  /// In pl, this message translates to:
  /// **'Zapisz'**
  String get commonSave;

  /// No description provided for @commonApply.
  ///
  /// In pl, this message translates to:
  /// **'Zastosuj'**
  String get commonApply;

  /// No description provided for @commonClear.
  ///
  /// In pl, this message translates to:
  /// **'Wyczyść'**
  String get commonClear;

  /// No description provided for @commonRetry.
  ///
  /// In pl, this message translates to:
  /// **'Spróbuj ponownie'**
  String get commonRetry;

  /// No description provided for @commonReplace.
  ///
  /// In pl, this message translates to:
  /// **'Zastąp'**
  String get commonReplace;

  /// No description provided for @commonTransfer.
  ///
  /// In pl, this message translates to:
  /// **'Przenieś'**
  String get commonTransfer;

  /// No description provided for @commonFill.
  ///
  /// In pl, this message translates to:
  /// **'Uzupełnij'**
  String get commonFill;

  /// No description provided for @commonAdd.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj'**
  String get commonAdd;

  /// No description provided for @errorAppStartup.
  ///
  /// In pl, this message translates to:
  /// **'Błąd uruchomienia aplikacji'**
  String get errorAppStartup;

  /// No description provided for @errorSessionExpired.
  ///
  /// In pl, this message translates to:
  /// **'Sesja wygasła. Zaloguj się ponownie.'**
  String get errorSessionExpired;

  /// No description provided for @errorServer.
  ///
  /// In pl, this message translates to:
  /// **'Błąd serwera ({statusCode}).'**
  String errorServer(int statusCode);

  /// No description provided for @errorScryfallRateLimit.
  ///
  /// In pl, this message translates to:
  /// **'Limit Scryfall — spróbuj za chwilę.'**
  String get errorScryfallRateLimit;

  /// No description provided for @errorNoConnection.
  ///
  /// In pl, this message translates to:
  /// **'Brak połączenia z serwerem. Sprawdź sieć i spróbuj ponownie.'**
  String get errorNoConnection;

  /// No description provided for @errorLoadCollection.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wczytać kolekcji'**
  String get errorLoadCollection;

  /// No description provided for @errorLoadDecks.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wczytać talii'**
  String get errorLoadDecks;

  /// No description provided for @errorNoLoginTokens.
  ///
  /// In pl, this message translates to:
  /// **'Brak tokenów po logowaniu.'**
  String get errorNoLoginTokens;

  /// No description provided for @loginTagline.
  ///
  /// In pl, this message translates to:
  /// **'Zarządzaj kolekcją i taliami Magic'**
  String get loginTagline;

  /// No description provided for @loginGoogle.
  ///
  /// In pl, this message translates to:
  /// **'Zaloguj przez Google'**
  String get loginGoogle;

  /// No description provided for @profileTitle.
  ///
  /// In pl, this message translates to:
  /// **'Profil Użytkownika'**
  String get profileTitle;

  /// No description provided for @profileUsername.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa użytkownika'**
  String get profileUsername;

  /// No description provided for @profileJoined.
  ///
  /// In pl, this message translates to:
  /// **'Dołączono: {date}'**
  String profileJoined(String date);

  /// No description provided for @profileDecks.
  ///
  /// In pl, this message translates to:
  /// **'Talie'**
  String get profileDecks;

  /// No description provided for @profileUniqueCards.
  ///
  /// In pl, this message translates to:
  /// **'Unikalne karty'**
  String get profileUniqueCards;

  /// No description provided for @profilePhysicalCards.
  ///
  /// In pl, this message translates to:
  /// **'Fizyczne karty'**
  String get profilePhysicalCards;

  /// No description provided for @profileEditName.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj nazwę'**
  String get profileEditName;

  /// No description provided for @profileSaveName.
  ///
  /// In pl, this message translates to:
  /// **'Zapisz nazwę'**
  String get profileSaveName;

  /// No description provided for @profileLogout.
  ///
  /// In pl, this message translates to:
  /// **'Wyloguj'**
  String get profileLogout;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In pl, this message translates to:
  /// **'Usuń konto'**
  String get profileDeleteAccount;

  /// No description provided for @profileUpdated.
  ///
  /// In pl, this message translates to:
  /// **'Profil zaktualizowany'**
  String get profileUpdated;

  /// No description provided for @profileDeleteConfirm.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć konto?'**
  String get profileDeleteConfirm;

  /// No description provided for @profileDeleteConfirmBody.
  ///
  /// In pl, this message translates to:
  /// **'Tej operacji nie można cofnąć.'**
  String get profileDeleteConfirmBody;

  /// No description provided for @profileLanguage.
  ///
  /// In pl, this message translates to:
  /// **'Język'**
  String get profileLanguage;

  /// No description provided for @collectionTitle.
  ///
  /// In pl, this message translates to:
  /// **'Moja Kolekcja'**
  String get collectionTitle;

  /// No description provided for @collectionEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Kolekcja jest pusta'**
  String get collectionEmpty;

  /// No description provided for @collectionValueSummary.
  ///
  /// In pl, this message translates to:
  /// **'Wartość: {value} • {count} wpisów'**
  String collectionValueSummary(String value, int count);

  /// No description provided for @collectionRefreshPrices.
  ///
  /// In pl, this message translates to:
  /// **'Odśwież ceny'**
  String get collectionRefreshPrices;

  /// No description provided for @cardsUpdated.
  ///
  /// In pl, this message translates to:
  /// **'Zaktualizowano {updated}/{total} kart'**
  String cardsUpdated(int updated, int total);

  /// No description provided for @collectionFiltersTitle.
  ///
  /// In pl, this message translates to:
  /// **'Filtry kolekcji'**
  String get collectionFiltersTitle;

  /// No description provided for @collectionFilterColor.
  ///
  /// In pl, this message translates to:
  /// **'Kolor (R, U, G, B, W)'**
  String get collectionFilterColor;

  /// No description provided for @collectionFilterType.
  ///
  /// In pl, this message translates to:
  /// **'Typ (Creature, Instant, ...)'**
  String get collectionFilterType;

  /// No description provided for @collectionFilterEdition.
  ///
  /// In pl, this message translates to:
  /// **'Edycja / set'**
  String get collectionFilterEdition;

  /// No description provided for @collectionFilterCmc.
  ///
  /// In pl, this message translates to:
  /// **'CMC'**
  String get collectionFilterCmc;

  /// No description provided for @collectionFilterSummaryColor.
  ///
  /// In pl, this message translates to:
  /// **'kolor: {value}'**
  String collectionFilterSummaryColor(String value);

  /// No description provided for @collectionFilterSummaryType.
  ///
  /// In pl, this message translates to:
  /// **'typ: {value}'**
  String collectionFilterSummaryType(String value);

  /// No description provided for @collectionFilterSummaryEdition.
  ///
  /// In pl, this message translates to:
  /// **'edycja: {value}'**
  String collectionFilterSummaryEdition(String value);

  /// No description provided for @collectionFilterSummaryCmc.
  ///
  /// In pl, this message translates to:
  /// **'CMC: {value}'**
  String collectionFilterSummaryCmc(int value);

  /// No description provided for @decksTitle.
  ///
  /// In pl, this message translates to:
  /// **'Moje Talie'**
  String get decksTitle;

  /// No description provided for @decksEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Brak talii — utwórz pierwszą'**
  String get decksEmpty;

  /// No description provided for @decksNewDeck.
  ///
  /// In pl, this message translates to:
  /// **'Nowa talia'**
  String get decksNewDeck;

  /// No description provided for @deckNew.
  ///
  /// In pl, this message translates to:
  /// **'Nowa Talia'**
  String get deckNew;

  /// No description provided for @deckSave.
  ///
  /// In pl, this message translates to:
  /// **'ZAPISZ'**
  String get deckSave;

  /// No description provided for @deckName.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa talii'**
  String get deckName;

  /// No description provided for @deckDescription.
  ///
  /// In pl, this message translates to:
  /// **'Opis (opcjonalnie)'**
  String get deckDescription;

  /// No description provided for @deckDeleteConfirm.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć talię?'**
  String get deckDeleteConfirm;

  /// No description provided for @deckRemoveConfirm.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć z talii?'**
  String get deckRemoveConfirm;

  /// No description provided for @deckRemoveAllCopies.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć wszystkie {quantity} kopie: {name}?'**
  String deckRemoveAllCopies(int quantity, String name);

  /// No description provided for @deckRemoveCard.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć kartę: {name}?'**
  String deckRemoveCard(String name);

  /// No description provided for @deckRemoveFromDeck.
  ///
  /// In pl, this message translates to:
  /// **'Usuń z talii'**
  String get deckRemoveFromDeck;

  /// No description provided for @deckCardDetails.
  ///
  /// In pl, this message translates to:
  /// **'Szczegóły karty'**
  String get deckCardDetails;

  /// No description provided for @deckEmptyCards.
  ///
  /// In pl, this message translates to:
  /// **'Brak kart w talii'**
  String get deckEmptyCards;

  /// No description provided for @deckValidationTitle.
  ///
  /// In pl, this message translates to:
  /// **'Walidacja talii'**
  String get deckValidationTitle;

  /// No description provided for @deckFormatNoIssues.
  ///
  /// In pl, this message translates to:
  /// **'Format: bez uwag.'**
  String get deckFormatNoIssues;

  /// No description provided for @deckFormatIssues.
  ///
  /// In pl, this message translates to:
  /// **'Format:'**
  String get deckFormatIssues;

  /// No description provided for @deckAssignmentsAll.
  ///
  /// In pl, this message translates to:
  /// **'Przypisania: wszystkie kopie z kolekcji.'**
  String get deckAssignmentsAll;

  /// No description provided for @deckAssignmentsEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Przypisania: brak kart w talii.'**
  String get deckAssignmentsEmpty;

  /// No description provided for @deckAssignmentsIssues.
  ///
  /// In pl, this message translates to:
  /// **'Przypisania:'**
  String get deckAssignmentsIssues;

  /// No description provided for @deckFillFromCollection.
  ///
  /// In pl, this message translates to:
  /// **'Uzupełnij z kolekcji?'**
  String get deckFillFromCollection;

  /// No description provided for @deckFillFromCollectionBody.
  ///
  /// In pl, this message translates to:
  /// **'Przypisać kopie z kolekcji do {unfilled} brakujących slotów (dopasowanie po nazwie karty)?'**
  String deckFillFromCollectionBody(int unfilled);

  /// No description provided for @deckFillFromCollectionTooltip.
  ///
  /// In pl, this message translates to:
  /// **'Uzupełnij z kolekcji'**
  String get deckFillFromCollectionTooltip;

  /// No description provided for @deckExportList.
  ///
  /// In pl, this message translates to:
  /// **'Eksportuj listę'**
  String get deckExportList;

  /// No description provided for @deckImportList.
  ///
  /// In pl, this message translates to:
  /// **'Import z listy'**
  String get deckImportList;

  /// No description provided for @deckAddCard.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj kartę'**
  String get deckAddCard;

  /// No description provided for @deckValidate.
  ///
  /// In pl, this message translates to:
  /// **'Waliduj'**
  String get deckValidate;

  /// No description provided for @deckExportEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Talia jest pusta — skopiowano pustą listę'**
  String get deckExportEmpty;

  /// No description provided for @deckExportCopied.
  ///
  /// In pl, this message translates to:
  /// **'Skopiowano listę talii do schowka'**
  String get deckExportCopied;

  /// No description provided for @deckAssignedSummary.
  ///
  /// In pl, this message translates to:
  /// **'Przypisano {copies} kopii do {slots} pozycji{skipped}'**
  String deckAssignedSummary(int copies, int slots, String skipped);

  /// No description provided for @deckAssignedSkipped.
  ///
  /// In pl, this message translates to:
  /// **' • {count} bez kopii'**
  String deckAssignedSkipped(int count);

  /// No description provided for @deckNoAvailableCopies.
  ///
  /// In pl, this message translates to:
  /// **'Brak dostępnych kopii — wszystkie są już przypisane w innych taliach'**
  String get deckNoAvailableCopies;

  /// No description provided for @deckTransferCopies.
  ///
  /// In pl, this message translates to:
  /// **'Przenieść kopie?'**
  String get deckTransferCopies;

  /// No description provided for @deckTransferCopiesBody.
  ///
  /// In pl, this message translates to:
  /// **'Ten wpis ma {count} kopii przypisanych w innej talii.\n\nPrzypisywanie tutaj usunie je stamtąd:\n{sources}'**
  String deckTransferCopiesBody(int count, String sources);

  /// No description provided for @deckTransferSource.
  ///
  /// In pl, this message translates to:
  /// **'{quantity}× z talii „{deckName}”'**
  String deckTransferSource(int quantity, String deckName);

  /// No description provided for @deckTransferPickSource.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz talię, z której zabrać kopie:'**
  String get deckTransferPickSource;

  /// No description provided for @deckAssignCopies.
  ///
  /// In pl, this message translates to:
  /// **'Przypisz kopie'**
  String get deckAssignCopies;

  /// No description provided for @deckAssignFromCollection.
  ///
  /// In pl, this message translates to:
  /// **'Przypisz kopie z kolekcji'**
  String get deckAssignFromCollection;

  /// No description provided for @deckOptionFree.
  ///
  /// In pl, this message translates to:
  /// **'Wolne: {available} • do slotu: {assignable} • {version}'**
  String deckOptionFree(int available, int assignable, String version);

  /// No description provided for @deckOptionTransfer.
  ///
  /// In pl, this message translates to:
  /// **'Przenieś do {assignable} • {elsewhere} w innej talii • {version}'**
  String deckOptionTransfer(int assignable, int elsewhere, String version);

  /// No description provided for @deckOptionSlot.
  ///
  /// In pl, this message translates to:
  /// **'Do slotu: {assignable} • {version}'**
  String deckOptionSlot(int assignable, String version);

  /// No description provided for @deckOptionOtherVersion.
  ///
  /// In pl, this message translates to:
  /// **'{setCode} • inna wersja'**
  String deckOptionOtherVersion(String setCode);

  /// No description provided for @deckFormatOk.
  ///
  /// In pl, this message translates to:
  /// **'Format OK'**
  String get deckFormatOk;

  /// No description provided for @deckFormatWarnings.
  ///
  /// In pl, this message translates to:
  /// **'Format: uwagi'**
  String get deckFormatWarnings;

  /// No description provided for @deckFormatValidTooltip.
  ///
  /// In pl, this message translates to:
  /// **'Talia spełnia wymagania formatu'**
  String get deckFormatValidTooltip;

  /// No description provided for @deckAssigned.
  ///
  /// In pl, this message translates to:
  /// **'Przypisane'**
  String get deckAssigned;

  /// No description provided for @deckNotAssigned.
  ///
  /// In pl, this message translates to:
  /// **'Brak przypisań'**
  String get deckNotAssigned;

  /// No description provided for @deckAllCopiesAssigned.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie kopie przypisane z kolekcji'**
  String get deckAllCopiesAssigned;

  /// No description provided for @deckListAllAssigned.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie kopie z kolekcji przypisane'**
  String get deckListAllAssigned;

  /// No description provided for @deckListMissingAssignments.
  ///
  /// In pl, this message translates to:
  /// **'Brak pełnych przypisań'**
  String get deckListMissingAssignments;

  /// No description provided for @deckViewList.
  ///
  /// In pl, this message translates to:
  /// **'Lista'**
  String get deckViewList;

  /// No description provided for @deckViewGrid.
  ///
  /// In pl, this message translates to:
  /// **'Siatka'**
  String get deckViewGrid;

  /// No description provided for @deckViewStack.
  ///
  /// In pl, this message translates to:
  /// **'Stos'**
  String get deckViewStack;

  /// No description provided for @deckViewTooltip.
  ///
  /// In pl, this message translates to:
  /// **'Widok: {mode}'**
  String deckViewTooltip(String mode);

  /// No description provided for @deckBoardMain.
  ///
  /// In pl, this message translates to:
  /// **'Główna'**
  String get deckBoardMain;

  /// No description provided for @deckBoardEmpty.
  ///
  /// In pl, this message translates to:
  /// **'0 kart'**
  String get deckBoardEmpty;

  /// No description provided for @deckBoardSummary.
  ///
  /// In pl, this message translates to:
  /// **'{positions} poz. • {copies} kopii • {filled}/{copiesTotal} przypisane'**
  String deckBoardSummary(
    int positions,
    int copies,
    int filled,
    int copiesTotal,
  );

  /// No description provided for @deckValidatorMainMin60.
  ///
  /// In pl, this message translates to:
  /// **'Main deck wymaga min. 60 kart (masz {count}).'**
  String deckValidatorMainMin60(int count);

  /// No description provided for @deckValidatorCommanderMin100.
  ///
  /// In pl, this message translates to:
  /// **'Commander wymaga 100 kart (masz {count}).'**
  String deckValidatorCommanderMin100(int count);

  /// No description provided for @deckValidatorLegalityWarnings.
  ///
  /// In pl, this message translates to:
  /// **'{count} kart z ostrzeżeniem legalności.'**
  String deckValidatorLegalityWarnings(int count);

  /// No description provided for @deckValidatorUnfilledPositions.
  ///
  /// In pl, this message translates to:
  /// **'{positions} pozycji w kolekcji bez pełnego przypisania ({copies} kopii).'**
  String deckValidatorUnfilledPositions(int positions, int copies);

  /// No description provided for @deckValidatorNotInCollection.
  ///
  /// In pl, this message translates to:
  /// **'{count} pozycji bez karty w kolekcji.'**
  String deckValidatorNotInCollection(int count);

  /// No description provided for @deckValidatorCopyLimit.
  ///
  /// In pl, this message translates to:
  /// **'Karta przekracza limit {max} kopii ({max} dozwolone, {actual} w decku).'**
  String deckValidatorCopyLimit(int max, int actual);

  /// No description provided for @cardSearchTitle.
  ///
  /// In pl, this message translates to:
  /// **'Szukaj kart'**
  String get cardSearchTitle;

  /// No description provided for @cardSearchHint.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa karty...'**
  String get cardSearchHint;

  /// No description provided for @cardSearchNotFound.
  ///
  /// In pl, this message translates to:
  /// **'Nie znaleziono kart dla „{query}”'**
  String cardSearchNotFound(String query);

  /// No description provided for @cardSearchDidYouMean.
  ///
  /// In pl, this message translates to:
  /// **'Czy chodziło Ci o:'**
  String get cardSearchDidYouMean;

  /// No description provided for @cardSearchMinChars.
  ///
  /// In pl, this message translates to:
  /// **'Wpisz co najmniej 2 znaki, aby szukać w Scryfall'**
  String get cardSearchMinChars;

  /// No description provided for @cardSearchMinCharsShort.
  ///
  /// In pl, this message translates to:
  /// **'Wpisz co najmniej 2 znaki'**
  String get cardSearchMinCharsShort;

  /// No description provided for @cardSearchAutocomplete.
  ///
  /// In pl, this message translates to:
  /// **'Pokazano wyniki dla podobnych nazw'**
  String get cardSearchAutocomplete;

  /// No description provided for @cardSearchNoResults.
  ///
  /// In pl, this message translates to:
  /// **'Nie znaleziono kart dla aktywnych filtrów'**
  String get cardSearchNoResults;

  /// No description provided for @searchFiltersLabel.
  ///
  /// In pl, this message translates to:
  /// **'Filtry'**
  String get searchFiltersLabel;

  /// No description provided for @searchFiltersActive.
  ///
  /// In pl, this message translates to:
  /// **'Filtry ({count})'**
  String searchFiltersActive(int count);

  /// No description provided for @searchFilterClear.
  ///
  /// In pl, this message translates to:
  /// **'Wyczyść filtry'**
  String get searchFilterClear;

  /// No description provided for @searchFilterColors.
  ///
  /// In pl, this message translates to:
  /// **'Kolory'**
  String get searchFilterColors;

  /// No description provided for @searchFilterType.
  ///
  /// In pl, this message translates to:
  /// **'Typ'**
  String get searchFilterType;

  /// No description provided for @searchFilterTypeAny.
  ///
  /// In pl, this message translates to:
  /// **'Dowolny typ'**
  String get searchFilterTypeAny;

  /// No description provided for @searchFilterTypeCreature.
  ///
  /// In pl, this message translates to:
  /// **'Stworzenie'**
  String get searchFilterTypeCreature;

  /// No description provided for @searchFilterTypeInstant.
  ///
  /// In pl, this message translates to:
  /// **'Błyskawica'**
  String get searchFilterTypeInstant;

  /// No description provided for @searchFilterTypeSorcery.
  ///
  /// In pl, this message translates to:
  /// **'Czary'**
  String get searchFilterTypeSorcery;

  /// No description provided for @searchFilterTypeEnchantment.
  ///
  /// In pl, this message translates to:
  /// **'Zaczarowanie'**
  String get searchFilterTypeEnchantment;

  /// No description provided for @searchFilterTypeArtifact.
  ///
  /// In pl, this message translates to:
  /// **'Artefakt'**
  String get searchFilterTypeArtifact;

  /// No description provided for @searchFilterTypePlaneswalker.
  ///
  /// In pl, this message translates to:
  /// **'Płanetowładca'**
  String get searchFilterTypePlaneswalker;

  /// No description provided for @searchFilterTypeLand.
  ///
  /// In pl, this message translates to:
  /// **'Ląd'**
  String get searchFilterTypeLand;

  /// No description provided for @searchFilterRarity.
  ///
  /// In pl, this message translates to:
  /// **'Rzadkość'**
  String get searchFilterRarity;

  /// No description provided for @searchFilterCmc.
  ///
  /// In pl, this message translates to:
  /// **'CMC'**
  String get searchFilterCmc;

  /// No description provided for @searchFilterExactColors.
  ///
  /// In pl, this message translates to:
  /// **'dokładnie'**
  String get searchFilterExactColors;

  /// No description provided for @cardDefaultName.
  ///
  /// In pl, this message translates to:
  /// **'Karta'**
  String get cardDefaultName;

  /// No description provided for @cardPowerToughness.
  ///
  /// In pl, this message translates to:
  /// **'Siła/Wytrzymałość: {value}'**
  String cardPowerToughness(String value);

  /// No description provided for @cardRarity.
  ///
  /// In pl, this message translates to:
  /// **'Rzadkość: {value}'**
  String cardRarity(String value);

  /// No description provided for @cardColors.
  ///
  /// In pl, this message translates to:
  /// **'Kolory'**
  String get cardColors;

  /// No description provided for @cardColorIdentity.
  ///
  /// In pl, this message translates to:
  /// **'Tożsamość'**
  String get cardColorIdentity;

  /// No description provided for @cardOpenScryfall.
  ///
  /// In pl, this message translates to:
  /// **'Otwórz w Scryfall'**
  String get cardOpenScryfall;

  /// No description provided for @cardAddToCollection.
  ///
  /// In pl, this message translates to:
  /// **'Dodano do kolekcji'**
  String get cardAddToCollection;

  /// No description provided for @cardCreateDeckFirst.
  ///
  /// In pl, this message translates to:
  /// **'Najpierw utwórz talię'**
  String get cardCreateDeckFirst;

  /// No description provided for @cardAddToDeck.
  ///
  /// In pl, this message translates to:
  /// **'Dodano do talii'**
  String get cardAddToDeck;

  /// No description provided for @cardSelectDeck.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz talię'**
  String get cardSelectDeck;

  /// No description provided for @cardCollectionButton.
  ///
  /// In pl, this message translates to:
  /// **'Kolekcja'**
  String get cardCollectionButton;

  /// No description provided for @cardDeckButton.
  ///
  /// In pl, this message translates to:
  /// **'Talia'**
  String get cardDeckButton;

  /// No description provided for @addToCollectionTitle.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj do kolekcji'**
  String get addToCollectionTitle;

  /// No description provided for @addToCollectionQuantity.
  ///
  /// In pl, this message translates to:
  /// **'Ilość:'**
  String get addToCollectionQuantity;

  /// No description provided for @addToDeckTitle.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj do talii'**
  String get addToDeckTitle;

  /// No description provided for @addToDeckQuantity.
  ///
  /// In pl, this message translates to:
  /// **'Ilość w talii:'**
  String get addToDeckQuantity;

  /// No description provided for @addToDeckAssignFromCollection.
  ///
  /// In pl, this message translates to:
  /// **'Przypisz z kolekcji'**
  String get addToDeckAssignFromCollection;

  /// No description provided for @addToDeckAvailableCopies.
  ///
  /// In pl, this message translates to:
  /// **'Dostępne kopie: {count}'**
  String addToDeckAvailableCopies(int count);

  /// No description provided for @addToDeckExceedsQuantity.
  ///
  /// In pl, this message translates to:
  /// **'Przypisane kopie przekraczają ilość w talii'**
  String get addToDeckExceedsQuantity;

  /// No description provided for @addToDeckExceedsOwnedQuantity.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie posiadane kopie tej karty są już w innych taliach'**
  String get addToDeckExceedsOwnedQuantity;

  /// No description provided for @addToDeckAvailableToAdd.
  ///
  /// In pl, this message translates to:
  /// **'Można dodać do talii: {count}'**
  String addToDeckAvailableToAdd(int count);

  /// No description provided for @addToDeckAllCopiesInDecks.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie {owned} posiadane kopie są już w taliach'**
  String addToDeckAllCopiesInDecks(int owned);

  /// No description provided for @addToDeckUsedInDeck.
  ///
  /// In pl, this message translates to:
  /// **'{quantity}× w {deckName}'**
  String addToDeckUsedInDeck(int quantity, String deckName);

  /// No description provided for @deckBoardZone.
  ///
  /// In pl, this message translates to:
  /// **'Strefa'**
  String get deckBoardZone;

  /// No description provided for @deckAssignedCount.
  ///
  /// In pl, this message translates to:
  /// **'Przypisane: {assigned} / {total}'**
  String deckAssignedCount(int assigned, int total);

  /// No description provided for @addCardToDeckTitle.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj kartę do talii'**
  String get addCardToDeckTitle;

  /// No description provided for @addCardToDeckTabCollection.
  ///
  /// In pl, this message translates to:
  /// **'Kolekcja'**
  String get addCardToDeckTabCollection;

  /// No description provided for @addCardToDeckTabSearch.
  ///
  /// In pl, this message translates to:
  /// **'Szukaj'**
  String get addCardToDeckTabSearch;

  /// No description provided for @addCardToDeckEmptyCollection.
  ///
  /// In pl, this message translates to:
  /// **'Kolekcja jest pusta.\nUżyj zakładki Szukaj, aby dodać karty spoza kolekcji.'**
  String get addCardToDeckEmptyCollection;

  /// No description provided for @addCardToDeckSearchHint.
  ///
  /// In pl, this message translates to:
  /// **'Szukaj po nazwie...'**
  String get addCardToDeckSearchHint;

  /// No description provided for @addCardToDeckFilters.
  ///
  /// In pl, this message translates to:
  /// **'Filtry kolekcji'**
  String get addCardToDeckFilters;

  /// No description provided for @addCardToDeckNoFilterMatch.
  ///
  /// In pl, this message translates to:
  /// **'Brak kart pasujących do filtrów'**
  String get addCardToDeckNoFilterMatch;

  /// No description provided for @collectionEntryDeleteConfirm.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć wpis?'**
  String get collectionEntryDeleteConfirm;

  /// No description provided for @collectionEntryDelete.
  ///
  /// In pl, this message translates to:
  /// **'Usuń wpis'**
  String get collectionEntryDelete;

  /// No description provided for @collectionEntryChangeCondition.
  ///
  /// In pl, this message translates to:
  /// **'Zmień stan'**
  String get collectionEntryChangeCondition;

  /// No description provided for @collectionEntryQuantityToMove.
  ///
  /// In pl, this message translates to:
  /// **'Ilość do przeniesienia:'**
  String get collectionEntryQuantityToMove;

  /// No description provided for @collectionEntrySaveNotes.
  ///
  /// In pl, this message translates to:
  /// **'Zapisz notatki'**
  String get collectionEntrySaveNotes;

  /// No description provided for @collectionYourCollection.
  ///
  /// In pl, this message translates to:
  /// **'Twoja kolekcja'**
  String get collectionYourCollection;

  /// No description provided for @collectionConditionChanged.
  ///
  /// In pl, this message translates to:
  /// **'Zmieniono stan'**
  String get collectionConditionChanged;

  /// No description provided for @collectionNotes.
  ///
  /// In pl, this message translates to:
  /// **'Notatki'**
  String get collectionNotes;

  /// No description provided for @collectionEntryDeckUsage.
  ///
  /// In pl, this message translates to:
  /// **'Użycie w taliach'**
  String get collectionEntryDeckUsage;

  /// No description provided for @collectionEntryUnassigned.
  ///
  /// In pl, this message translates to:
  /// **'{count}× nieprzypisane'**
  String collectionEntryUnassigned(int count);

  /// No description provided for @collectionNotInCollection.
  ///
  /// In pl, this message translates to:
  /// **'Brak w kolekcji'**
  String get collectionNotInCollection;

  /// No description provided for @fillStatusAssigned.
  ///
  /// In pl, this message translates to:
  /// **'Przypisano {filled}/{total} kopii'**
  String fillStatusAssigned(int filled, int total);

  /// No description provided for @fillStatusMissing.
  ///
  /// In pl, this message translates to:
  /// **'{count} brak'**
  String fillStatusMissing(int count);

  /// No description provided for @importTitle.
  ///
  /// In pl, this message translates to:
  /// **'Import z listy'**
  String get importTitle;

  /// No description provided for @importAction.
  ///
  /// In pl, this message translates to:
  /// **'IMPORT'**
  String get importAction;

  /// No description provided for @importReplaceConfirm.
  ///
  /// In pl, this message translates to:
  /// **'Zastąpić talię?'**
  String get importReplaceConfirm;

  /// No description provided for @importReplaceBody.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie karty i przypisania w tej talii zostaną usunięte przed importem.'**
  String get importReplaceBody;

  /// No description provided for @importMerge.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj do talii'**
  String get importMerge;

  /// No description provided for @importReplace.
  ///
  /// In pl, this message translates to:
  /// **'Zastąp talię'**
  String get importReplace;

  /// No description provided for @importHint.
  ///
  /// In pl, this message translates to:
  /// **'Wklej listę w formacie „1 Nazwa karty”, z opcjonalnymi sekcjami // Commander, // Sideboard lub // Oathbreaker.'**
  String get importHint;

  /// No description provided for @importPasteRequired.
  ///
  /// In pl, this message translates to:
  /// **'Wklej listę kart do importu'**
  String get importPasteRequired;

  /// No description provided for @importRecognizing.
  ///
  /// In pl, this message translates to:
  /// **'Rozpoznawanie kart…'**
  String get importRecognizing;

  /// No description provided for @importComplete.
  ///
  /// In pl, this message translates to:
  /// **'Import zakończony'**
  String get importComplete;

  /// No description provided for @importImportedCount.
  ///
  /// In pl, this message translates to:
  /// **'Zaimportowano {count} pozycji.'**
  String importImportedCount(int count);

  /// No description provided for @importClearedExisting.
  ///
  /// In pl, this message translates to:
  /// **'Poprzednia zawartość talii została usunięta.'**
  String get importClearedExisting;

  /// No description provided for @importUnrecognized.
  ///
  /// In pl, this message translates to:
  /// **'Nierozpoznane karty ({count}):'**
  String importUnrecognized(int count);

  /// No description provided for @importUnrecognizedLine.
  ///
  /// In pl, this message translates to:
  /// **' (linia {line})'**
  String importUnrecognizedLine(int line);

  /// No description provided for @importAndMore.
  ///
  /// In pl, this message translates to:
  /// **'… i {count} więcej'**
  String importAndMore(int count);

  /// No description provided for @scanNoText.
  ///
  /// In pl, this message translates to:
  /// **'Nie wykryto tekstu na karcie'**
  String get scanNoText;

  /// No description provided for @scanError.
  ///
  /// In pl, this message translates to:
  /// **'Błąd skanowania: {error}'**
  String scanError(String error);

  /// No description provided for @scanTitle.
  ///
  /// In pl, this message translates to:
  /// **'Skan'**
  String get scanTitle;

  /// No description provided for @scanNotRecognized.
  ///
  /// In pl, this message translates to:
  /// **'Nie rozpoznano karty'**
  String get scanNotRecognized;

  /// No description provided for @scanSearchManually.
  ///
  /// In pl, this message translates to:
  /// **'Wyszukaj ręcznie'**
  String get scanSearchManually;

  /// No description provided for @scanSelectVariant.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz wariant'**
  String get scanSelectVariant;

  /// No description provided for @scanFilterHint.
  ///
  /// In pl, this message translates to:
  /// **'Filtruj po kodzie edycji, numerze lub roku…'**
  String get scanFilterHint;

  /// No description provided for @scanCreateDeckInTab.
  ///
  /// In pl, this message translates to:
  /// **'Utwórz talię w zakładce Talie'**
  String get scanCreateDeckInTab;

  /// No description provided for @scanAddedToCollectionAndDeck.
  ///
  /// In pl, this message translates to:
  /// **'Dodano do kolekcji i talii'**
  String get scanAddedToCollectionAndDeck;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
