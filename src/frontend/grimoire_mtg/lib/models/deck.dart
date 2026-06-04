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
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String format;
  final String? description;
  final bool? isValid;
  final String? lastValidatedAt;
  final String createdAt;
  final String updatedAt;

  factory DeckListItem.fromJson(Map<String, dynamic> json) => DeckListItem(
        id: json['id'] as String,
        name: json['name'] as String,
        format: json['format'] as String,
        description: json['description'] as String?,
        isValid: json['isValid'] as bool?,
        lastValidatedAt: json['lastValidatedAt'] as String?,
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
      createdAt: deck['createdAt'] as String,
      updatedAt: deck['updatedAt'] as String,
      cards: (deck['cards'] as List<dynamic>?)
              ?.map((e) => DeckCardItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CollectionOptionDto {
  CollectionOptionDto({
    required this.collectionEntryId,
    required this.condition,
    required this.isFoil,
    required this.entryQuantity,
    required this.assignedTotal,
    required this.availableToAssign,
    required this.scryfallId,
    this.setCode,
    this.name,
    this.isExactPrinting = true,
  });

  final String collectionEntryId;
  final String condition;
  final bool isFoil;
  final int entryQuantity;
  final int assignedTotal;
  final int availableToAssign;
  final String scryfallId;
  final String? setCode;
  final String? name;
  final bool isExactPrinting;

  factory CollectionOptionDto.fromJson(Map<String, dynamic> json) =>
      CollectionOptionDto(
        collectionEntryId: json['collectionEntryId'] as String,
        condition: json['condition'] as String,
        isFoil: json['isFoil'] as bool? ?? false,
        entryQuantity: json['entryQuantity'] as int,
        assignedTotal: json['assignedTotal'] as int,
        availableToAssign: json['availableToAssign'] as int,
        scryfallId: json['scryfallId'] as String,
        setCode: json['setCode'] as String?,
        name: json['name'] as String?,
        isExactPrinting: json['isExactPrinting'] as bool? ?? true,
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
