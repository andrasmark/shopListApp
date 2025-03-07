import 'package:flutter/material.dart';

class GroceryListPage extends StatelessWidget {
  final String listId;

  const GroceryListPage({super.key, required this.listId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Grocery List"),
      ),
      body: Center(
        child: Text("Details for list: $listId"),
        // Itt jelenítsd meg a lista termékeit (pl. egy ListView.builder-rel)
      ),
    );
  }
}
