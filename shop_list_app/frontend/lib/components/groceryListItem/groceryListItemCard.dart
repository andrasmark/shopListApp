import 'package:flutter/material.dart';

import '../../models/product_model.dart';
import '../../services/groceryLists_service.dart';

class GroceryListItemCard extends StatefulWidget {
  final Product product;
  final String listId;
  final GrocerylistService groceryService;
  final VoidCallback onQuantityChanged;
  final Future<String?> addedBy;
  final Future<String?> store;

  const GroceryListItemCard({
    super.key,
    required this.product,
    required this.listId,
    required this.groceryService,
    required this.onQuantityChanged,
    required this.addedBy,
    required this.store,
  });

  @override
  State<GroceryListItemCard> createState() => _GroceryListItemCardState();
}

class _GroceryListItemCardState extends State<GroceryListItemCard> {
  late Future<int> _quantityFuture;

  @override
  void initState() {
    super.initState();
    _quantityFuture = _getQuantity();
  }

  Future<int> _getQuantity() async {
    return await widget.groceryService
        .getProductQuantity(widget.listId, widget.product.productUID!);
  }

  Future<void> _updateQuantity(int newQuantity) async {
    if (newQuantity >= 1) {
      await widget.groceryService.updateProductQuantity(
        widget.listId,
        widget.product.productUID!,
        newQuantity,
      );
      widget.onQuantityChanged();
      setState(() {
        _quantityFuture = Future.value(newQuantity);
      });
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Item'),
          content: const Text('Do you want to remove the item?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog first
                await widget.groceryService.deleteItemFromGroceryList(
                  widget.listId,
                  widget.product.productUID!,
                );
                widget.onQuantityChanged(); // To refresh UI/total
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _quantityFuture,
      builder: (context, snapshot) {
        final quantity = snapshot.data ?? 1;

        return FutureBuilder<String?>(
            future: widget.store,
            builder: (context, storeSnapshot) {
              final store = storeSnapshot.data ?? "Unknown";

              return FutureBuilder<String?>(
                  future: widget.addedBy,
                  builder: (context, addedbySnapshot) {
                    final addedBy = addedbySnapshot.data ?? "Unknown";

                    return GestureDetector(
                      onLongPress: () => _showDeleteDialog(context),
                      child: Card(
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // User who added the item
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline,
                                          size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        addedBy,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Store information
                                  Row(
                                    children: [
                                      const Icon(Icons.store_outlined,
                                          size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        store,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Termék kép
                            if (widget.product.productImage != null)
                              Image.network(
                                widget.product.productImage!,
                                height: 80,
                                width: 80,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image_not_supported,
                                        size: 50),
                              ),

                            // Termék név
                            if (widget.product.productName != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Text(widget.product.productName!),
                              ),

                            // Ár
                            if (widget.product.productPrice != null)
                              Text(
                                '${widget.product.productPrice!.toStringAsFixed(2)} Ron',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),

                            // Akció
                            if (widget.product.productDiscount != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Discount: ${widget.product.productDiscount}%',
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ),

                            // Mennyiség választó
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () =>
                                        _updateQuantity(quantity - 1),
                                  ),
                                  Text(
                                    '$quantity',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () =>
                                        _updateQuantity(quantity + 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  });
            });
      },
    );
  }
}
