// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navSearch => 'Search';

  @override
  String get navCollection => 'Collection';

  @override
  String get navDecks => 'Decks';

  @override
  String get navProfile => 'Profile';

  @override
  String get navScanner => 'Scanner';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonOK => 'OK';

  @override
  String get commonSave => 'Save';

  @override
  String get commonApply => 'Apply';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonReplace => 'Replace';

  @override
  String get commonTransfer => 'Transfer';

  @override
  String get commonFill => 'Fill';

  @override
  String get commonAdd => 'Add';

  @override
  String get errorAppStartup => 'Application startup error';

  @override
  String get errorSessionExpired => 'Session expired. Please sign in again.';

  @override
  String errorServer(int statusCode) {
    return 'Server error ($statusCode).';
  }

  @override
  String get errorScryfallRateLimit =>
      'Scryfall rate limit — try again shortly.';

  @override
  String get errorNoConnection =>
      'Cannot reach the server. Check your network and try again.';

  @override
  String get errorLoadCollection => 'Failed to load collection';

  @override
  String get errorLoadDecks => 'Failed to load decks';

  @override
  String get errorNoLoginTokens => 'No tokens after sign-in.';

  @override
  String get loginTagline => 'Manage your Magic collection and decks';

  @override
  String get loginGoogle => 'Sign in with Google';

  @override
  String get profileTitle => 'User Profile';

  @override
  String get profileUsername => 'Username';

  @override
  String profileJoined(String date) {
    return 'Joined: $date';
  }

  @override
  String get profileDecks => 'Decks';

  @override
  String get profileUniqueCards => 'Unique cards';

  @override
  String get profilePhysicalCards => 'Physical cards';

  @override
  String get profileEditName => 'Edit name';

  @override
  String get profileSaveName => 'Save name';

  @override
  String get profileLogout => 'Sign out';

  @override
  String get profileDeleteAccount => 'Delete account';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get profileDeleteConfirm => 'Delete account?';

  @override
  String get profileDeleteConfirmBody => 'This action cannot be undone.';

  @override
  String get profileLanguage => 'Language';

  @override
  String get collectionTitle => 'My Collection';

  @override
  String get collectionEmpty => 'Collection is empty';

  @override
  String collectionValueSummary(String value, int count) {
    return 'Value: $value • $count entries';
  }

  @override
  String get collectionRefreshPrices => 'Refresh prices';

  @override
  String cardsUpdated(int updated, int total) {
    return 'Updated $updated/$total cards';
  }

  @override
  String get collectionFiltersTitle => 'Collection filters';

  @override
  String get collectionFilterColor => 'Color (R, U, G, B, W)';

  @override
  String get collectionFilterType => 'Type (Creature, Instant, ...)';

  @override
  String get collectionFilterEdition => 'Edition / set';

  @override
  String get collectionFilterCmc => 'CMC';

  @override
  String collectionFilterSummaryColor(String value) {
    return 'color: $value';
  }

  @override
  String collectionFilterSummaryType(String value) {
    return 'type: $value';
  }

  @override
  String collectionFilterSummaryEdition(String value) {
    return 'edition: $value';
  }

  @override
  String collectionFilterSummaryCmc(int value) {
    return 'CMC: $value';
  }

  @override
  String get decksTitle => 'My Decks';

  @override
  String get decksEmpty => 'No decks yet — create your first';

  @override
  String get decksNewDeck => 'New deck';

  @override
  String get deckNew => 'New Deck';

  @override
  String get deckSave => 'SAVE';

  @override
  String get deckName => 'Deck name';

  @override
  String get deckDescription => 'Description (optional)';

  @override
  String get deckDeleteConfirm => 'Delete deck?';

  @override
  String get deckRemoveConfirm => 'Remove from deck?';

  @override
  String deckRemoveAllCopies(int quantity, String name) {
    return 'Remove all $quantity copies: $name?';
  }

  @override
  String deckRemoveCard(String name) {
    return 'Remove card: $name?';
  }

  @override
  String get deckRemoveFromDeck => 'Remove from deck';

  @override
  String get deckCardDetails => 'Card details';

  @override
  String get deckEmptyCards => 'No cards in deck';

  @override
  String get deckValidationTitle => 'Deck validation';

  @override
  String get deckFormatNoIssues => 'Format: no issues.';

  @override
  String get deckFormatIssues => 'Format:';

  @override
  String get deckAssignmentsAll => 'Assignments: all copies from collection.';

  @override
  String get deckAssignmentsEmpty => 'Assignments: no cards in deck.';

  @override
  String get deckAssignmentsIssues => 'Assignments:';

  @override
  String get deckFillFromCollection => 'Fill from collection?';

  @override
  String deckFillFromCollectionBody(int unfilled) {
    return 'Assign copies from collection to $unfilled missing slots (match by card name)?';
  }

  @override
  String get deckFillFromCollectionTooltip => 'Fill from collection';

  @override
  String get deckExportList => 'Export list';

  @override
  String get deckImportList => 'Import from list';

  @override
  String get deckAddCard => 'Add card';

  @override
  String get deckValidate => 'Validate';

  @override
  String get deckExportEmpty => 'Deck is empty — copied empty list';

  @override
  String get deckExportCopied => 'Deck list copied to clipboard';

  @override
  String deckAssignedSummary(int copies, int slots, String skipped) {
    return 'Assigned $copies copies to $slots slots$skipped';
  }

  @override
  String deckAssignedSkipped(int count) {
    return ' • $count without copies';
  }

  @override
  String get deckNoAvailableCopies =>
      'No available copies — all are already assigned in other decks';

  @override
  String get deckTransferCopies => 'Transfer copies?';

  @override
  String deckTransferCopiesBody(int count, String sources) {
    return 'This entry has $count copies assigned in another deck.\n\nAssigning here will remove them from there:\n$sources';
  }

  @override
  String deckTransferSource(int quantity, String deckName) {
    return '$quantity× from deck \"$deckName\"';
  }

  @override
  String get deckTransferPickSource =>
      'Select which deck to remove copies from:';

  @override
  String get deckAssignCopies => 'Assign copies';

  @override
  String get deckAssignFromCollection => 'Assign copies from collection';

  @override
  String deckOptionFree(int available, int assignable, String version) {
    return 'Free: $available • for slot: $assignable • $version';
  }

  @override
  String deckOptionTransfer(int assignable, int elsewhere, String version) {
    return 'Transfer $assignable • $elsewhere in another deck • $version';
  }

  @override
  String deckOptionSlot(int assignable, String version) {
    return 'For slot: $assignable • $version';
  }

  @override
  String deckOptionOtherVersion(String setCode) {
    return '$setCode • other printing';
  }

  @override
  String get deckFormatOk => 'Format OK';

  @override
  String get deckFormatWarnings => 'Format: issues';

  @override
  String get deckFormatValidTooltip => 'Deck meets format requirements';

  @override
  String get deckAssigned => 'Assigned';

  @override
  String get deckNotAssigned => 'Not assigned';

  @override
  String get deckAllCopiesAssigned => 'All copies assigned from collection';

  @override
  String get deckListAllAssigned => 'All copies from collection assigned';

  @override
  String get deckListMissingAssignments => 'Missing full assignments';

  @override
  String get deckViewList => 'List';

  @override
  String get deckViewGrid => 'Grid';

  @override
  String get deckViewStack => 'Stack';

  @override
  String deckViewTooltip(String mode) {
    return 'View: $mode';
  }

  @override
  String get deckBoardMain => 'Main';

  @override
  String get deckBoardEmpty => '0 cards';

  @override
  String deckBoardSummary(
    int positions,
    int copies,
    int filled,
    int copiesTotal,
  ) {
    return '$positions pos. • $copies copies • $filled/$copiesTotal assigned';
  }

  @override
  String deckValidatorMainMin60(int count) {
    return 'Main deck requires at least 60 cards (you have $count).';
  }

  @override
  String deckValidatorCommanderMin100(int count) {
    return 'Commander requires 100 cards (you have $count).';
  }

  @override
  String deckValidatorLegalityWarnings(int count) {
    return '$count cards with legality warnings.';
  }

  @override
  String deckValidatorUnfilledPositions(int positions, int copies) {
    return '$positions collection entries without full assignment ($copies copies).';
  }

  @override
  String deckValidatorNotInCollection(int count) {
    return '$count entries without a card in collection.';
  }

  @override
  String deckValidatorCopyLimit(int max, int actual) {
    return 'Card exceeds $max copy limit ($max allowed, $actual in deck).';
  }

  @override
  String get cardSearchTitle => 'Search cards';

  @override
  String get cardSearchHint => 'Card name...';

  @override
  String cardSearchNotFound(String query) {
    return 'No cards found for \"$query\"';
  }

  @override
  String get cardSearchDidYouMean => 'Did you mean:';

  @override
  String get cardSearchMinChars =>
      'Enter at least 2 characters to search Scryfall';

  @override
  String get cardSearchMinCharsShort => 'Enter at least 2 characters';

  @override
  String get cardSearchAutocomplete => 'Showing results for similar names';

  @override
  String get cardSearchNoResults => 'No cards found for current filters';

  @override
  String get searchFiltersLabel => 'Filters';

  @override
  String searchFiltersActive(int count) {
    return 'Filters ($count)';
  }

  @override
  String get searchFilterClear => 'Clear filters';

  @override
  String get searchFilterColors => 'Colors';

  @override
  String get searchFilterType => 'Type';

  @override
  String get searchFilterTypeAny => 'Any type';

  @override
  String get searchFilterTypeCreature => 'Creature';

  @override
  String get searchFilterTypeInstant => 'Instant';

  @override
  String get searchFilterTypeSorcery => 'Sorcery';

  @override
  String get searchFilterTypeEnchantment => 'Enchantment';

  @override
  String get searchFilterTypeArtifact => 'Artifact';

  @override
  String get searchFilterTypePlaneswalker => 'Planeswalker';

  @override
  String get searchFilterTypeLand => 'Land';

  @override
  String get searchFilterRarity => 'Rarity';

  @override
  String get searchFilterCmc => 'CMC';

  @override
  String get searchFilterExactColors => 'exact';

  @override
  String get cardDefaultName => 'Card';

  @override
  String cardPowerToughness(String value) {
    return 'Power/Toughness: $value';
  }

  @override
  String cardRarity(String value) {
    return 'Rarity: $value';
  }

  @override
  String get cardColors => 'Colors';

  @override
  String get cardColorIdentity => 'Color identity';

  @override
  String get cardOpenScryfall => 'Open in Scryfall';

  @override
  String get cardAddToCollection => 'Added to collection';

  @override
  String get cardCreateDeckFirst => 'Create a deck first';

  @override
  String get cardAddToDeck => 'Added to deck';

  @override
  String get cardSelectDeck => 'Select deck';

  @override
  String get cardCollectionButton => 'Collection';

  @override
  String get cardDeckButton => 'Deck';

  @override
  String get addToCollectionTitle => 'Add to collection';

  @override
  String get addToCollectionQuantity => 'Quantity:';

  @override
  String get addToDeckTitle => 'Add to deck';

  @override
  String get addToDeckQuantity => 'Quantity in deck:';

  @override
  String get addToDeckAssignFromCollection => 'Assign from collection';

  @override
  String addToDeckAvailableCopies(int count) {
    return 'Available copies: $count';
  }

  @override
  String get addToDeckExceedsQuantity =>
      'Assigned copies exceed quantity in deck';

  @override
  String get addToDeckExceedsOwnedQuantity =>
      'All owned copies of this card are already in other decks';

  @override
  String addToDeckAvailableToAdd(int count) {
    return 'Can add to decks: $count';
  }

  @override
  String addToDeckAllCopiesInDecks(int owned) {
    return 'All $owned owned copies are already in decks';
  }

  @override
  String addToDeckUsedInDeck(int quantity, String deckName) {
    return '$quantity× in $deckName';
  }

  @override
  String get deckBoardZone => 'Zone';

  @override
  String deckAssignedCount(int assigned, int total) {
    return 'Assigned: $assigned / $total';
  }

  @override
  String get addCardToDeckTitle => 'Add card to deck';

  @override
  String get addCardToDeckTabCollection => 'Collection';

  @override
  String get addCardToDeckTabSearch => 'Search';

  @override
  String get addCardToDeckEmptyCollection =>
      'Collection is empty.\nUse the Search tab to add cards not in your collection.';

  @override
  String get addCardToDeckSearchHint => 'Search by name...';

  @override
  String get addCardToDeckFilters => 'Collection filters';

  @override
  String get addCardToDeckNoFilterMatch => 'No cards match filters';

  @override
  String get collectionEntryDeleteConfirm => 'Delete entry?';

  @override
  String get collectionEntryDelete => 'Delete entry';

  @override
  String get collectionEntryChangeCondition => 'Change condition';

  @override
  String get collectionEntryQuantityToMove => 'Quantity to move:';

  @override
  String get collectionEntrySaveNotes => 'Save notes';

  @override
  String get collectionYourCollection => 'Your collection';

  @override
  String get collectionConditionChanged => 'Condition changed';

  @override
  String get collectionNotes => 'Notes';

  @override
  String get collectionEntryDeckUsage => 'Deck usage';

  @override
  String collectionEntryUnassigned(int count) {
    return '$count× unassigned';
  }

  @override
  String get collectionNotInCollection => 'Not in collection';

  @override
  String fillStatusAssigned(int filled, int total) {
    return 'Assigned $filled/$total copies';
  }

  @override
  String fillStatusMissing(int count) {
    return '$count missing';
  }

  @override
  String get importTitle => 'Import from list';

  @override
  String get importAction => 'IMPORT';

  @override
  String get importReplaceConfirm => 'Replace deck?';

  @override
  String get importReplaceBody =>
      'All cards and assignments in this deck will be removed before import.';

  @override
  String get importMerge => 'Add to deck';

  @override
  String get importReplace => 'Replace deck';

  @override
  String get importHint =>
      'Paste a list in the format \"1 Card Name\", with optional // Commander, // Sideboard or // Oathbreaker sections.';

  @override
  String get importPasteRequired => 'Paste a card list to import';

  @override
  String get importRecognizing => 'Recognizing cards…';

  @override
  String get importComplete => 'Import complete';

  @override
  String importImportedCount(int count) {
    return 'Imported $count entries.';
  }

  @override
  String get importClearedExisting => 'Previous deck contents were removed.';

  @override
  String importUnrecognized(int count) {
    return 'Unrecognized cards ($count):';
  }

  @override
  String importUnrecognizedLine(int line) {
    return ' (line $line)';
  }

  @override
  String importAndMore(int count) {
    return '… and $count more';
  }

  @override
  String get scanNoText => 'No text detected on card';

  @override
  String scanError(String error) {
    return 'Scan error: $error';
  }

  @override
  String get scanTitle => 'Scan';

  @override
  String get scanNotRecognized => 'Card not recognized';

  @override
  String get scanSearchManually => 'Search manually';

  @override
  String get scanSelectVariant => 'Select printing';

  @override
  String get scanCreateDeckInTab => 'Create a deck in the Decks tab';

  @override
  String get scanAddedToCollectionAndDeck => 'Added to collection and deck';
}
