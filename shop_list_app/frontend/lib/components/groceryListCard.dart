import 'package:flutter/material.dart';

class GroceryListCard extends StatelessWidget {
  final String listId;
  final String listName;
  final Function() onTap;
  final DateTime? reminder;
  final bool isFavourite;

  const GroceryListCard({
    super.key,
    required this.listId,
    required this.listName,
    required this.onTap,
    this.reminder,
    this.isFavourite = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final showReminder = reminder != null && reminder!.isAfter(now);

    return Card(
      margin: EdgeInsets.all(8.0),
      color: Colors.white,
      child: ListTile(
        title: Text(
          listName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isFavourite)
              const Text(
                "★ Favourite",
                style: TextStyle(color: Colors.orange),
              ),
            if (reminder != null && reminder!.isAfter(now))
              Text(
                'Scheduled for: ${reminder!.day.toString().padLeft(2, '0')}.${reminder!.month.toString().padLeft(2, '0')}.${reminder!.year}',
              )
          ],
        ),
        trailing: Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}
