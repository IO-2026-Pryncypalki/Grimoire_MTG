import '../utils/json_parse.dart';

class CardDto {
  CardDto({
    required this.scryfallId,
    this.name,
    this.setCode,
    this.setName,
    this.collectorNumber,
    this.lang,
    this.imageUrl,
    this.imageUrlHiRes,
    this.price,
    this.releasedAt,
  });

  final String scryfallId;
  final String? name;
  final String? setCode;
  final String? setName;
  final String? collectorNumber;
  final String? lang;
  final String? imageUrl;
  final String? imageUrlHiRes;
  final double? price;
  final String? releasedAt;

  int? get releasedYear {
    final value = releasedAt;
    if (value == null || value.length < 4) return null;
    return int.tryParse(value.substring(0, 4));
  }

  factory CardDto.fromJson(Map<String, dynamic> json) => CardDto(
        scryfallId: json['scryfallId'] as String,
        name: json['name'] as String?,
        setCode: json['setCode'] as String?,
        setName: json['setName'] as String?,
        collectorNumber: json['collectorNumber'] as String?,
        lang: json['lang'] as String?,
        imageUrl: json['imageUrl'] as String?,
        imageUrlHiRes: json['imageUrlHiRes'] as String?,
        price: readDouble(json['price']),
        releasedAt: json['releasedAt'] as String?,
      );
}

class CardDetailDto extends CardDto {
  CardDetailDto({
    required super.scryfallId,
    super.name,
    super.setCode,
    super.setName,
    super.collectorNumber,
    super.lang,
    super.imageUrl,
    super.imageUrlHiRes,
    super.price,
    super.releasedAt,
    this.manaCost,
    this.cmc,
    this.typeLine,
    this.oracleText,
    this.power,
    this.toughness,
    this.rarity,
    this.colors = const [],
    this.colorIdentity = const [],
    this.priceUsd,
    this.priceUsdFoil,
    this.priceEur,
    this.priceEurFoil,
    this.scryfallUri,
  });

  final String? manaCost;
  final double? cmc;
  final String? typeLine;
  final String? oracleText;
  final String? power;
  final String? toughness;
  final String? rarity;
  final List<String> colors;
  final List<String> colorIdentity;
  final double? priceUsd;
  final double? priceUsdFoil;
  final double? priceEur;
  final double? priceEurFoil;
  final String? scryfallUri;

  factory CardDetailDto.fromJson(Map<String, dynamic> json) => CardDetailDto(
        scryfallId: json['scryfallId'] as String,
        name: json['name'] as String?,
        setCode: json['setCode'] as String?,
        setName: json['setName'] as String?,
        collectorNumber: json['collectorNumber'] as String?,
        lang: json['lang'] as String?,
        imageUrl: json['imageUrl'] as String?,
        imageUrlHiRes: json['imageUrlHiRes'] as String?,
        price: readDouble(json['price']),
        releasedAt: json['releasedAt'] as String?,
        manaCost: json['manaCost'] as String?,
        cmc: readDouble(json['cmc']),
        typeLine: json['typeLine'] as String?,
        oracleText: json['oracleText'] as String?,
        power: json['power'] as String?,
        toughness: json['toughness'] as String?,
        rarity: json['rarity'] as String?,
        colors: (json['colors'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        colorIdentity: (json['colorIdentity'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        priceUsd: readDouble(json['priceUsd']),
        priceUsdFoil: readDouble(json['priceUsdFoil']),
        priceEur: readDouble(json['priceEur']),
        priceEurFoil: readDouble(json['priceEurFoil']),
        scryfallUri: json['scryfallUri'] as String?,
      );
}
