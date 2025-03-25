import 'package:flutter/material.dart';

import '../../models/product_model.dart';

class KauflandItemInfo extends StatelessWidget {
  final Product product;

  const KauflandItemInfo({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (product.productImage != null)
                  Image.network(
                    product.productImage!,
                    height: 150,
                    width: 150,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.image_not_supported, size: 80),
                  ),
                if (product.productName != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      product.productName!,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (product.productPrice != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Price: ${product.productPrice!.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                if (product.productOldPrice != null)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Old Price: ${product.productOldPrice!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                if (product.productDiscount != null)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Discount: ${product.productDiscount}',
                      style: TextStyle(fontSize: 16, color: Colors.green),
                    ),
                  ),
                if (product.productSubtitle != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      product.productSubtitle!,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Add to grocery list implementation
                  },
                  child: Text('Add to Grocery List'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
