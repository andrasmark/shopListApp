import 'package:flutter/material.dart';
import 'package:shop_list_app/components/product_list.dart';
import 'package:shop_list_app/pages/items_page.dart';

import '../../components/nav_bar.dart';
import '../home_page.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key});
  static String id = "list_page";

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  int _selectedIndex = 0;

  void _onNavBarItemTapped(int index) {
    setState(() {
      // _selectedIndex = index;
      switch (index) {
        case 1:
          Navigator.pushReplacementNamed(context, HomePage.id);
          break;
        case 2:
          Navigator.pushReplacementNamed(context, ItemsPage.id);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Shop list"),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Column(
        children: [Text("Szia"), Container(child: ProductList())],
      ),
      bottomNavigationBar: NavBar(_selectedIndex, _onNavBarItemTapped),
    );
  }
}
