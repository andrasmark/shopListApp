import 'package:flutter/material.dart';
import 'package:shop_list_app/pages/home_page.dart';

import '../components/nav_bar.dart';
import '../components/product_kaufland/item_card.dart';
import '../components/product_kaufland/item_info.dart';
import '../constants/color_scheme.dart';
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

  String _selectedStore = 'Kaufland'; // Default selected store
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final List<String> stores = ['Kaufland', 'Lidl', 'Carrefour', 'Auchan'];

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

  Stream<List<Product>> _getFilteredProducts() {
    switch (_selectedStore) {
      case 'Kaufland':
        return _productService.getProductsFromKaufland();
      case 'Lidl':
        return _productService.getProductsFromLidl();
      default:
        return _productService.getProductsFromKaufland();
    }
  }

  List<Product> _filterProducts(List<Product> products) {
    if (_searchQuery.isEmpty) {
      return products;
    }
    final searchLower = _searchQuery.toLowerCase();
    return products.where((product) {
      final productName = product.productName?.toLowerCase() ?? '';
      return productName.contains(searchLower);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            // Search bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Store filter buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: stores.map((store) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: FilterChip(
                      label: Text(store),
                      selected: _selectedStore == store,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedStore = selected ? store : 'Kaufland';
                          _searchQuery = ''; // Clear search when changing store
                          _searchController.clear();
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: 8),

            // Store name header
            Text("Products from $_selectedStore"),

            // Products list
            Expanded(
              child: StreamBuilder<List<Product>>(
                stream: _getFilteredProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No products found.'));
                  } else {
                    final products = _filterProducts(snapshot.data!);
                    if (products.isEmpty) {
                      return Center(child: Text('No matching products found.'));
                    }
                    return GridView.builder(
                      padding: EdgeInsets.all(8.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
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
      bottomNavigationBar: NavBar(_selectedIndex, _onNavBarItemTapped),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text("Items"),
  //       backgroundColor: Colors.lightBlueAccent,
  //     ),
  //     body: Container(
  //       color: COLOR_BEIGE,
  //       child: Column(
  //         children: [
  //           Text("Products from Kaufland"),
  //           StreamBuilder<List<Product>>(
  //             stream: _productService.getProductsFromKaufland(),
  //             builder: (context, snapshot) {
  //               if (snapshot.connectionState == ConnectionState.waiting) {
  //                 return Center(child: CircularProgressIndicator());
  //               } else if (snapshot.hasError) {
  //                 return Center(child: Text('Error: ${snapshot.error}'));
  //               } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
  //                 return Center(child: Text('No products found.'));
  //               } else {
  //                 final products = snapshot.data!;
  //                 print(products);
  //                 return Container(
  //                   padding: EdgeInsets.all(8.0),
  //                   decoration: BoxDecoration(
  //                     color: Colors.white,
  //                     borderRadius: BorderRadius.circular(8.0),
  //                   ),
  //                   height: 200,
  //                   child: ListView.builder(
  //                     scrollDirection: Axis.horizontal,
  //                     itemCount: products.length,
  //                     itemBuilder: (context, index) {
  //                       final product = products[index];
  //                       return GestureDetector(
  //                         onTap: () {
  //                           showDialog(
  //                             context: context,
  //                             builder: (BuildContext context) {
  //                               return KauflandItemInfo(product: product);
  //                             },
  //                           );
  //                         },
  //                         child: Container(
  //                           width: MediaQuery.of(context).size.width / 3,
  //                           margin: EdgeInsets.symmetric(horizontal: 4.0),
  //                           child: KauflandItemCard(product: product),
  //                         ),
  //                       );
  //                     },
  //                   ),
  //                 );
  //               }
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //     bottomNavigationBar: NavBar(_selectedIndex, _onNavBarItemTapped),
  //   );
  // }
}
