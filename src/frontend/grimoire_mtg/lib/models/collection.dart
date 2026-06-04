import 'card.dart';
import '../utils/json_parse.dart';

const cardConditions = ['M', 'NM', 'GD', 'LP', 'MP', 'HP', 'DMG'];

class CollectionEntryDto {
  CollectionEntryDto({
    this.collectionEntryId,
    required this.scryfallId,
    this.name,
    this.setCode,
    this.imageUrl,
    this.price,
    required this.quantity,
    required this.condition,
    required this.isFoil,
    this.notes,
  });

  final String? collectionEntryId;
  final String scryfallId;
  final String? name;
  final String? setCode;
  final String? imageUrl;
  final double? price;
  final int quantity;
  final String condition;
  final bool isFoil;
  final String? notes;

  factory CollectionEntryDto.fromJson(Map<String, dynamic> json) =>
      CollectionEntryDto(
        collectionEntryId: json['collectionEntryId'] as String?,
        scryfallId: json['scryfallId'] as String,
        name: json['name'] as String?,
        setCode: json['setCode'] as String?,
        imageUrl: json['imageUrl'] as String?,
        price: readDouble(json['price']),
        quantity: readInt(json['quantity'], defaultValue: 1),
        condition: json['condition'] as String? ?? 'NM',
        isFoil: readBool(json['isFoil']),
        notes: json['notes'] as String?,
      );

  CardDto toCardDto() => CardDto(
        scryfallId: scryfallId,
        name: name,
        setCode: setCode,
        imageUrl: imageUrl,
        price: price,
      );
}

class CollectionResponse {
  CollectionResponse({required this.entries, required this.totalValue});

  final List<CollectionEntryDto> entries;
  final double totalValue;

  factory CollectionResponse.fromJson(Map<String, dynamic> json) =>
      CollectionResponse(
        entries: (json['entries'] as List<dynamic>? ?? [])
            .map((e) => CollectionEntryDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalValue: readDouble(json['totalValue']) ?? 0,
      );
}

class CollectionFilters {
  CollectionFilters({this.color, this.type, this.edition, this.cmc});

  final String? color;
  final String? type;
  final String? edition;
  final int? cmc;

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (color != null && color!.isNotEmpty) params['color'] = color!;
    if (type != null && type!.isNotEmpty) params['type'] = type!;
    if (edition != null && edition!.isNotEmpty) params['edition'] = edition!;
    if (cmc != null) params['cmc'] = cmc.toString();
    return params;
  }
}
