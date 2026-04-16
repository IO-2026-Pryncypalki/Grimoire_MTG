import 'package:flutter/material.dart';

class DeckOverviewScreen extends StatelessWidget {
  const DeckOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moje Talie')),
      body: ListView.builder(
        itemCount: 5, // Placeholder
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.style),
          title: Text('Talia #${index + 1}'),
          subtitle: const Text('60 kart | Standard'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {},
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}