import 'package:flutter/material.dart';

import '../../models/product_model.dart';
import '../../services/groceryLists_service.dart';

class GroceryListItemCard extends StatefulWidget {
  final Product product;
  final String listId;
  final GrocerylistService groceryService;

  const GroceryListItemCard({
    super.key,
    required this.product,
    required this.listId,
    required this.groceryService,
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
      setState(() {
        _quantityFuture = Future.value(newQuantity);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _quantityFuture,
      builder: (context, snapshot) {
        final quantity = snapshot.data ?? 1;

        return Card(
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Termék kép
              if (widget.product.productImage != null)
                Image.network(
                  widget.product.productImage!,
                  height: 100,
                  width: 100,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported, size: 50),
                ),

              // Termék név
              if (widget.product.productName != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(widget.product.productName!),
                ),

              // Ár
              if (widget.product.productPrice != null)
                Text(
                  '${widget.product.productPrice!.toStringAsFixed(2)} Ft',
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () => _updateQuantity(quantity - 1),
                    ),
                    Text(
                      '$quantity',
                      style: const TextStyle(fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _updateQuantity(quantity + 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
