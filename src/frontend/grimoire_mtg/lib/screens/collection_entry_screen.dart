import 'package:flutter/material.dart';

import '../models/collection.dart';
import 'card_detail_screen.dart';

class CollectionEntryScreen extends StatelessWidget {
  const CollectionEntryScreen({super.key, required this.entry});

  final CollectionEntryDto entry;

  @override
  Widget build(BuildContext context) {
    return CardDetailScreen(
      scryfallId: entry.scryfallId,
      collectionEntry: entry,
    );
  }
}
