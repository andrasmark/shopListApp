import 'package:flutter/material.dart';

class GroceryListCard extends StatelessWidget {
  final String listId;
  final String listName;
  final Function() onTap;

  const GroceryListCard({
    super.key,
    required this.listId,
    required this.listName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(listName),
        trailing: Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}
