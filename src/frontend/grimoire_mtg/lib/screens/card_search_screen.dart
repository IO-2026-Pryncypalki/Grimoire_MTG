import 'package:flutter/material.dart';

import '../models/card.dart';
import '../widgets/card_search_body.dart';
import 'card_detail_screen.dart';

class CardSearchScreen extends StatelessWidget {
  const CardSearchScreen({super.key});

  void _openDetail(BuildContext context, CardDto card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardDetailScreen(scryfallId: card.scryfallId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Szukaj kart')),
      body: CardSearchBody(onCardTap: (card) => _openDetail(context, card)),
    );
  }
}
