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
          Image.network(product.productImage, height: 100, width: 100),
          Text(product.productName),
          Text(product.productPrice), // Stringként jelenítjük meg
          if (product.productDiscount != null)
            Text('Discount: ${product.productDiscount}'),
        ],
      ),
    );
  }
}
