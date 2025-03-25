import 'package:flutter/material.dart';

import '../../models/product_model.dart';

class KauflandItemCard extends StatelessWidget {
  final Product product;

  const KauflandItemCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (product.productImage != null)
            Image.network(
              product.productImage!,
              height: 100,
              width: 100,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.image_not_supported, size: 50),
            ),
          if (product.productName != null)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(product.productName!),
            ),
          if (product.productPrice != null)
            Text(
              '${product.productPrice!.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          if (product.productDiscount != null)
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Discount: ${product.productDiscount}',
                style: TextStyle(color: Colors.green),
              ),
            ),
        ],
      ),
    );
  }
}
