import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../services/symbology_service.dart';

/// Renders a string that may contain Scryfall mana/symbol tokens like `{R}`,
/// `{T}`, `{2/W}`, etc. as inline SVG images sourced from the Scryfall CDN.
/// Unknown or unparseable tokens are rendered as plain text.
class ManaSymbolText extends StatelessWidget {
  const ManaSymbolText(
    this.text, {
    super.key,
    this.style,
    this.symbolSize = 16.0,
  });

  final String text;
  final TextStyle? style;

  /// Height (and width) of each inline symbol image in logical pixels.
  final double symbolSize;

  static final _tokenPattern = RegExp(r'(\{[^}]+\})');

  @override
  Widget build(BuildContext context) {
    final symbology = context.watch<SymbologyService>();
    final baseStyle = style ?? DefaultTextStyle.of(context).style;

    final spans = <InlineSpan>[];
    int cursor = 0;

    for (final match in _tokenPattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }

      final token = match.group(0)!;
      final uri = symbology.svgUri(token);

      if (uri != null) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: SvgPicture.network(
              uri,
              width: symbolSize,
              height: symbolSize,
              placeholderBuilder: (_) => SizedBox(
                width: symbolSize,
                height: symbolSize,
              ),
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: token));
      }

      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
    );
  }
}
