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
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(product.productImage, height: 150, width: 150),
              Text(product.productName, style: TextStyle(fontSize: 20)),
              Text(product.productPrice,
                  style: TextStyle(fontSize: 18)), // Stringként jelenítjük meg
              if (product.productDiscount != null)
                Text('Discount: ${product.productDiscount}',
                    style: TextStyle(fontSize: 16)),
              if (product.productOldPrice != null)
                Text('Old Price: ${product.productOldPrice}',
                    style: TextStyle(fontSize: 16)),
              if (product.productSubtitle != null)
                Text('Subtitle: ${product.productSubtitle}',
                    style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // TODO:
                },
                child: Text('Add to Grocery List'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
