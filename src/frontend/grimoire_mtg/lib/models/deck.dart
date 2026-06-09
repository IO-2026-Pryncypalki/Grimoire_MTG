const deckFormats = [
  'Standard',
  'Pioneer',
  'Modern',
  'Legacy',
  'Vintage',
  'Commander',
  'Pauper',
  'Draft',
  'Sealed',
  'Oathbreaker',
  'Custom',
];

const deckBoards = ['main', 'sideboard', 'commander'];

class FormatWarningDto {
  FormatWarningDto({required this.status, required this.message});

  final String status;
  final String message;

  factory FormatWarningDto.fromJson(Map<String, dynamic> json) =>
      FormatWarningDto(
        status: json['status'] as String,
        message: json['message'] as String,
      );
}

class AssignmentDto {
  AssignmentDto({
    required this.id,
    required this.collectionEntryId,
    required this.quantity,
    required this.condition,
    required this.isFoil,
  });

  final String id;
  final String collectionEntryId;
  final int quantity;
  final String condition;
  final bool isFoil;

  factory AssignmentDto.fromJson(Map<String, dynamic> json) => AssignmentDto(
        id: json['id'] as String,
        collectionEntryId: json['collectionEntryId'] as String,
        quantity: json['quantity'] as int,
        condition: json['condition'] as String,
        isFoil: json['isFoil'] as bool? ?? false,
      );
}

class FillStatusDto {
  FillStatusDto({
    required this.quantity,
    required this.filledQty,
    required this.unfilledQty,
    required this.assignments,
  });

  final int quantity;
  final int filledQty;
  final int unfilledQty;
  final List<AssignmentDto> assignments;

  factory FillStatusDto.fromJson(Map<String, dynamic> json) => FillStatusDto(
        quantity: json['quantity'] as int,
        filledQty: json['filledQty'] as int,
        unfilledQty: json['unfilledQty'] as int,
        assignments: (json['assignments'] as List<dynamic>?)
                ?.map((e) => AssignmentDto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class DeckListItem {
  DeckListItem({
    required this.id,
    required this.name,
    required this.format,
    this.description,
    this.isValid,
    this.lastValidatedAt,
    this.isFormatValid = false,
    this.isFullyAssigned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String format;
  final String? description;
  final bool? isValid;
  final String? lastValidatedAt;
  final bool isFormatValid;
  final bool isFullyAssigned;
  final String createdAt;
  final String updatedAt;

  factory DeckListItem.fromJson(Map<String, dynamic> json) => DeckListItem(
        id: json['id'] as String,
        name: json['name'] as String,
        format: json['format'] as String,
        description: json['description'] as String?,
        isValid: json['isValid'] as bool?,
        lastValidatedAt: json['lastValidatedAt'] as String?,
        isFormatValid: json['isFormatValid'] as bool? ?? false,
        isFullyAssigned: json['isFullyAssigned'] as bool? ?? false,
        createdAt: json['createdAt'] as String,
        updatedAt: json['updatedAt'] as String,
      );
}

class DeckCardItem {
  DeckCardItem({
    required this.id,
    required this.scryfallId,
    required this.quantity,
    required this.board,
    this.name,
    this.setCode,
    this.typeLine,
    this.imageUrl,
    this.imageUrlHiRes,
    this.inCollection = false,
    required this.fillStatus,
    this.formatWarning,
  });

  final String id;
  final String scryfallId;
  final int quantity;
  final String board;
  final String? name;
  final String? setCode;
  final String? typeLine;
  final String? imageUrl;
  final String? imageUrlHiRes;
  final bool inCollection;
  final FillStatusDto fillStatus;
  final FormatWarningDto? formatWarning;

  factory DeckCardItem.fromJson(Map<String, dynamic> json) => DeckCardItem(
        id: json['id'] as String,
        scryfallId: json['scryfallId'] as String,
        quantity: json['quantity'] as int,
        board: json['board'] as String? ?? 'main',
        name: json['name'] as String?,
        setCode: json['setCode'] as String?,
        typeLine: json['typeLine'] as String?,
        imageUrl: json['imageUrl'] as String?,
        imageUrlHiRes: json['imageUrlHiRes'] as String?,
        inCollection: json['inCollection'] as bool? ?? false,
        fillStatus: FillStatusDto.fromJson(
          json['fillStatus'] as Map<String, dynamic>,
        ),
        formatWarning: json['formatWarning'] != null
            ? FormatWarningDto.fromJson(
                json['formatWarning'] as Map<String, dynamic>,
              )
            : null,
      );
}

class DeckDetails extends DeckListItem {
  DeckDetails({
    required super.id,
    required super.name,
    required super.format,
    super.description,
    super.isValid,
    super.lastValidatedAt,
    super.isFormatValid,
    super.isFullyAssigned,
    required super.createdAt,
    required super.updatedAt,
    required this.cards,
  });

  final List<DeckCardItem> cards;

  factory DeckDetails.fromJson(Map<String, dynamic> json) {
    final deck = json['deck'] as Map<String, dynamic>? ?? json;
    return DeckDetails(
      id: deck['id'] as String,
      name: deck['name'] as String,
      format: deck['format'] as String,
      description: deck['description'] as String?,
      isValid: deck['isValid'] as bool?,
      lastValidatedAt: deck['lastValidatedAt'] as String?,
      isFormatValid: deck['isFormatValid'] as bool? ?? false,
      isFullyAssigned: deck['isFullyAssigned'] as bool? ?? false,
      createdAt: deck['createdAt'] as String,
      updatedAt: deck['updatedAt'] as String,
      cards: (deck['cards'] as List<dynamic>?)
              ?.map((e) => DeckCardItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class AssignmentTransferSourceDto {
  AssignmentTransferSourceDto({
    required this.deckId,
    required this.deckName,
    required this.quantity,
  });

  final String deckId;
  final String deckName;
  final int quantity;

  factory AssignmentTransferSourceDto.fromJson(Map<String, dynamic> json) =>
      AssignmentTransferSourceDto(
        deckId: json['deckId'] as String,
        deckName: json['deckName'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 0,
      );
}

class CollectionOptionDto {
  CollectionOptionDto({
    required this.collectionEntryId,
    required this.condition,
    required this.isFoil,
    required this.entryQuantity,
    required this.assignedTotal,
    required this.assignedOnSlot,
    required this.assignedElsewhere,
    required this.availableToAssign,
    required this.assignableToSlot,
    required this.scryfallId,
    required this.transferSources,
    this.setCode,
    this.name,
    this.isExactPrinting = true,
  });

  final String collectionEntryId;
  final String condition;
  final bool isFoil;
  final int entryQuantity;
  final int assignedTotal;
  final int assignedOnSlot;
  final int assignedElsewhere;
  final int availableToAssign;
  final int assignableToSlot;
  final String scryfallId;
  final String? setCode;
  final String? name;
  final bool isExactPrinting;
  final List<AssignmentTransferSourceDto> transferSources;

  factory CollectionOptionDto.fromJson(Map<String, dynamic> json) =>
      CollectionOptionDto(
        collectionEntryId: json['collectionEntryId'] as String,
        condition: json['condition'] as String,
        isFoil: json['isFoil'] as bool? ?? false,
        entryQuantity: json['entryQuantity'] as int,
        assignedTotal: json['assignedTotal'] as int,
        assignedOnSlot: json['assignedOnSlot'] as int? ?? 0,
        assignedElsewhere: json['assignedElsewhere'] as int? ?? 0,
        availableToAssign: json['availableToAssign'] as int,
        assignableToSlot: json['assignableToSlot'] as int? ??
            json['availableToAssign'] as int,
        scryfallId: json['scryfallId'] as String,
        setCode: json['setCode'] as String?,
        name: json['name'] as String?,
        isExactPrinting: json['isExactPrinting'] as bool? ?? true,
        transferSources: (json['transferSources'] as List<dynamic>? ?? [])
            .map((e) => AssignmentTransferSourceDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AssignDeckByNameSummary {
  AssignDeckByNameSummary({
    required this.assignedSlots,
    required this.assignedCopies,
    required this.skippedNoCollection,
    required this.skippedNoName,
  });

  final int assignedSlots;
  final int assignedCopies;
  final int skippedNoCollection;
  final int skippedNoName;

  factory AssignDeckByNameSummary.fromJson(Map<String, dynamic> json) =>
      AssignDeckByNameSummary(
        assignedSlots: json['assignedSlots'] as int? ?? 0,
        assignedCopies: json['assignedCopies'] as int? ?? 0,
        skippedNoCollection: json['skippedNoCollection'] as int? ?? 0,
        skippedNoName: json['skippedNoName'] as int? ?? 0,
      );
}

class CardAvailabilityDto {
  CardAvailabilityDto({
    required this.ownedQty,
    required this.inDecksQty,
    required this.availableToAdd,
    required this.decksUsing,
  });

  final int ownedQty;
  final int inDecksQty;
  final int availableToAdd;
  final List<DeckUsingCardDto> decksUsing;

  bool get enforceCollectionLimit => ownedQty > 0;

  factory CardAvailabilityDto.fromJson(Map<String, dynamic> json) =>
      CardAvailabilityDto(
        ownedQty: json['ownedQty'] as int? ?? 0,
        inDecksQty: json['inDecksQty'] as int? ?? 0,
        availableToAdd: json['availableToAdd'] as int? ?? 0,
        decksUsing: (json['decksUsing'] as List<dynamic>? ?? [])
            .map((e) => DeckUsingCardDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DeckUsingCardDto {
  DeckUsingCardDto({
    required this.deckId,
    required this.deckName,
    required this.deckCardId,
    required this.quantity,
  });

  final String deckId;
  final String deckName;
  final String deckCardId;
  final int quantity;

  factory DeckUsingCardDto.fromJson(Map<String, dynamic> json) =>
      DeckUsingCardDto(
        deckId: json['deckId'] as String,
        deckName: json['deckName'] as String,
        deckCardId: json['deckCardId'] as String,
        quantity: json['quantity'] as int,
      );
}

class ImportedDeckListItemDto {
  ImportedDeckListItemDto({
    required this.name,
    required this.scryfallId,
    required this.quantity,
    required this.board,
  });

  final String name;
  final String scryfallId;
  final int quantity;
  final String board;

  factory ImportedDeckListItemDto.fromJson(Map<String, dynamic> json) =>
      ImportedDeckListItemDto(
        name: json['name'] as String,
        scryfallId: json['scryfallId'] as String,
        quantity: json['quantity'] as int,
        board: json['board'] as String,
      );
}

class ImportDeckListFailureDto {
  ImportDeckListFailureDto({
    required this.name,
    required this.reason,
    this.line,
  });

  final String name;
  final String reason;
  final int? line;

  factory ImportDeckListFailureDto.fromJson(Map<String, dynamic> json) =>
      ImportDeckListFailureDto(
        name: json['name'] as String,
        reason: json['reason'] as String,
        line: json['line'] as int?,
      );
}

class ImportDeckListResultDto {
  ImportDeckListResultDto({
    required this.mode,
    required this.imported,
    required this.failed,
    required this.clearedExisting,
  });

  final String mode;
  final List<ImportedDeckListItemDto> imported;
  final List<ImportDeckListFailureDto> failed;
  final bool clearedExisting;

  factory ImportDeckListResultDto.fromJson(Map<String, dynamic> json) =>
      ImportDeckListResultDto(
        mode: json['mode'] as String,
        imported: (json['imported'] as List<dynamic>? ?? [])
            .map((e) => ImportedDeckListItemDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        failed: (json['failed'] as List<dynamic>? ?? [])
            .map((e) => ImportDeckListFailureDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        clearedExisting: json['clearedExisting'] as bool? ?? false,
      );
}
