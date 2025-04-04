import 'package:flutter/material.dart';

import '../components/groceryListItem/groceryListItemCard.dart';
import '../models/product_model.dart';
import '../services/groceryLists_service.dart';

class GroceryListPage extends StatelessWidget {
  final String listId;
  final GrocerylistService _groceryListService = GrocerylistService();

  GroceryListPage({super.key, required this.listId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Grocery List"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text("Details for list: $listId"),
            Expanded(
              child: StreamBuilder<List<Product>>(
                stream: _groceryListService.getItemsFromList(listId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No items in this list yet'));
                  } else {
                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final product = snapshot.data![index];
                        return GroceryListItemCard(
                          product: product,
                          listId: listId,
                          groceryService: _groceryListService,
                        );
                      },
                    );
                  }
                  return const CircularProgressIndicator();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
