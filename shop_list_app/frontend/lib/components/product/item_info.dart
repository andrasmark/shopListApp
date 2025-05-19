import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shop_list_app/services/authorization.dart';

import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../services/user_service.dart';

class ItemInfo extends StatelessWidget {
  final Product product;

  final UserService _userService = UserService();
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();
  int _quantity = 1;

  ItemInfo({super.key, required this.product});

  Future<void> _addToGroceryList(BuildContext context, String listId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not logged in!')),
      );
      return;
    }
    try {
      await _productService.addProductToList(
        listId: listId,
        productId: product.productUID!,
        quantity: _quantity,
        productName: product.productName!,
        productImage: product.productImage,
        price: product.productPrice,
        oldPrice: product.productOldPrice,
        discount: product.productDiscount,
        subtitle: product.productSubtitle,
        userId: userId,
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_quantity db termék hozzáadva')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hiba: ${e.toString()}')),
      );
    }
  }

  void _showListSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Termék hozzáadása'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Mennyiség:'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () {
                        if (_quantity > 1) {
                          setState(() => _quantity--);
                        }
                      },
                    ),
                    Text('$_quantity', style: TextStyle(fontSize: 20)),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _userService
                      .getUserGroceryLists(_authService.getUserId()),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Text('Hiba a listák betöltésében');
                    }
                    final lists = snapshot.data!;
                    if (lists.isEmpty) {
                      return Text('Nincs elérhető lista');
                    }
                    return Column(
                      children: lists
                          .map((list) => ListTile(
                                title:
                                    Text(list['listName'] ?? 'Névtelen lista'),
                                onTap: () =>
                                    _addToGroceryList(context, list['id']),
                              ))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Mégse'),
              ),
            ],
          );
        },
      ),
    );
  }

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
                  onPressed: () => _showListSelectionDialog(context),
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
