import 'package:flutter/material.dart';

import '../components/product/item_card.dart';
import '../components/product/item_info.dart';
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
                      padding: EdgeInsets.all(8.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final product = snapshot.data![index];
                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return ItemInfo(product: product);
                              },
                            );
                          },
                          child: ItemCard(product: product),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
