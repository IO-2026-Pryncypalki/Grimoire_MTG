import '../models/card.dart';
import '../models/card_search_result.dart';
import '../models/collection.dart';
import '../models/deck.dart';
import '../models/scan.dart';
import '../models/sync_status.dart';
import '../models/user.dart';
import 'api_client.dart';

class GrimoireApi {
  GrimoireApi(this._client);

  final ApiClient _client;

  Future<UserProfile> getMe() async {
    final json = await _client.get('/api/user/me');
    return UserProfile.fromJson(json);
  }

  Future<UserProfile> updateUsername(String username) async {
    await _client.patch('/api/user/me', body: {'username': username});
    return getMe();
  }

  Future<void> deleteAccount() async {
    await _client.delete('/api/user/me');
  }

  Future<void> logout({String? refreshToken}) async {
    await _client.post(
      '/api/auth/logout',
      body: refreshToken != null ? {'refreshToken': refreshToken} : null,
    );
  }

  Future<CardSearchResult> searchCards(String cardName) async {
    final json = await _client.post('/api/cards/search', body: {'cardName': cardName});
    return CardSearchResult.fromJson(json);
  }

  Future<ScanResponse> scanCard(String plaintext) async {
    final json = await _client.post('/api/cards/scan', body: {'plaintext': plaintext});
    return ScanResponse.fromJson(json);
  }

  Future<CardDetailDto> getCardDetails(String scryfallId) async {
    final json = await _client.get('/api/cards/$scryfallId');
    return CardDetailDto.fromJson(json);
  }

  Future<CollectionResponse> getCollection([CollectionFilters? filters]) async {
    final json = await _client.get(
      '/api/collection',
      query: filters?.toQueryParams(),
    );
    return CollectionResponse.fromJson(json);
  }

  Future<void> addToCollection({
    required String scryfallId,
    int quantity = 1,
    String condition = 'NM',
    bool isFoil = false,
  }) async {
    await _client.post('/api/collection', body: {
      'scryfallId': scryfallId,
      'quantity': quantity,
      'condition': condition,
      'isFoil': isFoil,
    });
  }

  Future<void> updateCollectionEntry({
    required String scryfallId,
    required String condition,
    required bool isFoil,
    int? delta,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (delta != null) body['delta'] = delta;
    if (notes != null) body['notes'] = notes;
    await _client.patch(
      '/api/collection/$scryfallId',
      query: {
        'condition': condition,
        'isFoil': isFoil.toString(),
      },
      body: body,
    );
  }

  Future<void> transferCondition({
    required String scryfallId,
    required String fromCondition,
    required String toCondition,
    required bool isFoil,
    int quantity = 1,
  }) async {
    await _client.patch(
      '/api/collection/$scryfallId/transfer',
      body: {
        'fromCondition': fromCondition,
        'toCondition': toCondition,
        'isFoil': isFoil,
        'quantity': quantity,
      },
    );
  }

  Future<void> removeFromCollection({
    required String scryfallId,
    String? condition,
    bool? isFoil,
  }) async {
    final query = <String, String>{};
    if (condition != null) query['condition'] = condition;
    if (isFoil != null) query['isFoil'] = isFoil.toString();
    await _client.delete('/api/collection/$scryfallId', query: query);
  }

  Future<Map<String, dynamic>> refreshPrices() async {
    return _client.post('/api/collection/refresh-prices');
  }

  Future<List<CollectionEntryAssignmentDto>> getCollectionEntryAssignments(
    String entryId,
  ) async {
    final json = await _client.get('/api/collection/entries/$entryId/assignments');
    final list = json['assignments'] as List<dynamic>? ?? [];
    return list
        .map((e) => CollectionEntryAssignmentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SyncStatus> getSyncStatus() async {
    final json = await _client.get('/api/sync/status');
    return SyncStatus.fromJson(json);
  }

  Future<List<DeckListItem>> listDecks() async {
    final json = await _client.get('/api/decks');
    return (json['decks'] as List<dynamic>)
        .map((e) => DeckListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DeckDetails> getDeck(String deckId) async {
    final json = await _client.get('/api/decks/$deckId');
    return DeckDetails.fromJson(json);
  }

  Future<DeckListItem> createDeck({
    required String name,
    String format = 'Custom',
    String? description,
  }) async {
    final json = await _client.post('/api/decks', body: {
      'name': name,
      'format': format,
      if (description != null) 'description': description,
    });
    return DeckListItem.fromJson(json['deck'] as Map<String, dynamic>);
  }

  Future<DeckListItem> updateDeck(
    String deckId, {
    String? name,
    String? format,
    String? description,
    bool? isValid,
    String? lastValidatedAt,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (format != null) body['format'] = format;
    if (description != null) body['description'] = description;
    if (isValid != null) body['isValid'] = isValid;
    if (lastValidatedAt != null) body['lastValidatedAt'] = lastValidatedAt;
    final json = await _client.patch('/api/decks/$deckId', body: body);
    return DeckListItem.fromJson(json['deck'] as Map<String, dynamic>);
  }

  Future<void> deleteDeck(String deckId) async {
    await _client.delete('/api/decks/$deckId');
  }

  Future<DeckCardItem> addCardToDeck({
    required String deckId,
    required String scryfallId,
    int quantity = 1,
    String board = 'main',
    List<Map<String, dynamic>>? assignments,
  }) async {
    final json = await _client.post('/api/decks/$deckId/cards', body: {
      'scryfallId': scryfallId,
      'quantity': quantity,
      'board': board,
      if (assignments != null) 'assignments': assignments,
    });
    return DeckCardItem.fromJson(json['card'] as Map<String, dynamic>);
  }

  Future<void> removeCardFromDeck({
    required String deckId,
    required String scryfallId,
    String board = 'main',
    int quantity = 1,
  }) async {
    await _client.delete(
      '/api/decks/$deckId/cards/$scryfallId',
      query: {'board': board, 'quantity': quantity.toString()},
    );
  }

  Future<CardAvailabilityDto> getCardAvailability(String scryfallId) async {
    final json = await _client.get(
      '/api/decks/card-availability',
      query: {'scryfallId': scryfallId},
    );
    return CardAvailabilityDto.fromJson(json);
  }

  Future<List<CollectionOptionDto>> getCollectionOptions({
    required String deckId,
    required String deckCardId,
  }) async {
    final json = await _client.get(
      '/api/decks/$deckId/cards/$deckCardId/collection-options',
    );
    return (json['options'] as List<dynamic>)
        .map((e) => CollectionOptionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AssignDeckByNameSummary> assignDeckFromCollectionByName(String deckId) async {
    final json = await _client.post('/api/decks/$deckId/assign-from-collection-by-name');
    return AssignDeckByNameSummary.fromJson(json);
  }

  Future<ImportDeckListResultDto> importDeckList({
    required String deckId,
    required String text,
    required String mode,
  }) async {
    final json = await _client.post('/api/decks/$deckId/import-list', body: {
      'text': text,
      'mode': mode,
    });
    return ImportDeckListResultDto.fromJson(json['result'] as Map<String, dynamic>);
  }

  Future<Map<String, String>> getSymbology() async {
    final json = await _client.get('/api/symbology');
    final list = json['symbols'] as List<dynamic>? ?? [];
    return {
      for (final e in list)
        e['symbol'] as String: e['svgUri'] as String,
    };
  }

  Future<String> exportDeckList(String deckId) async {
    final json = await _client.get('/api/decks/$deckId/export-list');
    return json['text'] as String;
  }

  Future<FillStatusDto> assignToDeck({
    required String deckId,
    required String deckCardId,
    required String collectionEntryId,
    required int quantity,
    String? preferredSourceDeckId,
  }) async {
    final json = await _client.post(
      '/api/decks/$deckId/cards/$deckCardId/assignments',
      body: {
        'collectionEntryId': collectionEntryId,
        'quantity': quantity,
        'preferredSourceDeckId': preferredSourceDeckId,
      },
    );
    return FillStatusDto.fromJson(json['fillStatus'] as Map<String, dynamic>);
  }

  Future<FillStatusDto> updateAssignment({
    required String deckId,
    required String deckCardId,
    required String assignmentId,
    required int quantity,
  }) async {
    final json = await _client.patch(
      '/api/decks/$deckId/cards/$deckCardId/assignments/$assignmentId',
      body: {'quantity': quantity},
    );
    return FillStatusDto.fromJson(json['fillStatus'] as Map<String, dynamic>);
  }

  Future<FillStatusDto> removeAssignment({
    required String deckId,
    required String deckCardId,
    required String assignmentId,
  }) async {
    final json = await _client.delete(
      '/api/decks/$deckId/cards/$deckCardId/assignments/$assignmentId',
    );
    return FillStatusDto.fromJson(json['fillStatus'] as Map<String, dynamic>);
  }
}
