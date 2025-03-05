import 'package:flutter/material.dart';
import 'package:shop_list_app/constants/color_scheme.dart';
import 'package:shop_list_app/pages/home_page.dart';

import '../components/nav_bar.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import 'list_page.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});
  static String id = 'items_page';

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  int _selectedIndex = 2;
  final ProductService _productService = ProductService();

  void _onNavBarItemTapped(int index) {
    setState(() {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, ListPage.id);
          break;
        case 1:
          Navigator.pushReplacementNamed(context, HomePage.id);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Items"),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Container(
        color: COLOR_BEIGE,
        child: Column(
          children: [
            Text("Products from lidl"),
            StreamBuilder<List<Product>>(
              stream: _productService.getProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No products found.'));
                } else {
                  final products = snapshot.data!;
                  return Container(
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return ItemInfo(product: product);
                              },
                            );
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width / 3,
                            margin: EdgeInsets.symmetric(horizontal: 4.0),
                            child: ItemCard(product: product),
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavBar(_selectedIndex, _onNavBarItemTapped),
    );
  }
}

class ItemCard extends StatelessWidget {
  final Product product;

  const ItemCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(product.productImage, height: 100, width: 100),
          Text(product.productName),
          Text('\$${product.productPrice.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}

class ItemInfo extends StatelessWidget {
  final Product product;

  const ItemInfo({super.key, required this.product});

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
              Text('\$${product.productPrice.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18)),
              // További információk itt
            ],
          ),
        ],
      ),
    );
  }
}
