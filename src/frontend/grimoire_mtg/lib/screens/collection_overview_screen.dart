import 'package:flutter/material.dart';

class CollectionOverviewScreen extends StatelessWidget {
  const CollectionOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moja Kolekcja'),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 20, // Placeholder
        itemBuilder: (context, index) => Card(
          color: Colors.grey[800],
          child: const Center(child: Text('Karta', style: TextStyle(color: Colors.white))),
        ),
      ),
    );
  }
}