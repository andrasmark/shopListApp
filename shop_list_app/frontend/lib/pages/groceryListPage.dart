import 'package:flutter/material.dart';

import '../components/groceryListItem/groceryListItemCard.dart';
import '../models/product_model.dart';
import '../services/groceryLists_service.dart';

class GroceryListPage extends StatefulWidget {
  final String listId;

  const GroceryListPage({super.key, required this.listId});

  @override
  State<GroceryListPage> createState() => _GroceryListPageState();
}

class _GroceryListPageState extends State<GroceryListPage> {
  final GrocerylistService _groceryListService = GrocerylistService();
  double _totalPrice = 0.0;
  List<Product> _currentProducts = [];
  bool _isInitialLoad = true;

  Future<void> _updateTotalPrice() async {
    final total = await _groceryListService.calculateTotalPrice(widget.listId);
    if (mounted) {
      setState(() {
        _totalPrice = total;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Load initial price immediately
    _updateTotalPrice();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Grocery List")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text("Details for list: ${widget.listId}"),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (_) => true, // Prevent rebuilds on scroll
                child: StreamBuilder<List<Product>>(
                  stream: _groceryListService.getItemsFromList(widget.listId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        _isInitialLoad) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('No items in this list yet'));
                    } else {
                      // Only update products if they actually changed

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _currentProducts = snapshot.data!;
                        _updateTotalPrice();
                        _isInitialLoad = false;
                      });

                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: _currentProducts.length,
                        itemBuilder: (context, index) {
                          final product = _currentProducts[index];
                          return GroceryListItemCard(
                            key: ValueKey(product
                                .productUID), // Important for state preservation
                            product: product,
                            listId: widget.listId,
                            groceryService: _groceryListService,
                            onQuantityChanged: _updateTotalPrice,
                            addedBy:
                                _groceryListService.getUserNameWhoAddedProduct(
                                    widget.listId, product.productUID),
                            store: _groceryListService
                                .getStoreForProduct(product.productUID),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ),
            // Total price container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total:",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("${_totalPrice.toStringAsFixed(2)} Ron",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
