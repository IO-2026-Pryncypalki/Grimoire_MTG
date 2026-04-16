import 'package:flutter/material.dart';

class CreateDeckScreen extends StatelessWidget {
  const CreateDeckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nowa Talia'),
        actions: [TextButton(onPressed: () {}, child: const Text('ZAPISZ'))],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(decoration: InputDecoration(labelText: 'Nazwa talii', border: OutlineInputBorder())),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 0, // Pusta lista na start
              itemBuilder: (context, index) => ListTile(title: Text('Karta $index')),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Dodaj karty z kolekcji'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}