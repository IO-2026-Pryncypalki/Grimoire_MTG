import 'card.dart';

class ScanResponse {
  ScanResponse({
    required this.resolution,
    this.parsed,
    required this.cards,
    required this.total,
  });

  final String resolution;
  final Map<String, dynamic>? parsed;
  final List<CardDto> cards;
  final int total;

  factory ScanResponse.fromJson(Map<String, dynamic> json) => ScanResponse(
        resolution: json['resolution'] as String,
        parsed: json['parsed'] as Map<String, dynamic>?,
        cards: (json['cards'] as List<dynamic>?)
                ?.map((e) => CardDto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        total: json['total'] as int? ?? 0,
      );

  bool get isUnique => resolution == 'unique';
  bool get isAmbiguous => resolution == 'ambiguous';
  bool get isNone => resolution == 'none';
}
