import 'package:flutter/material.dart';
import 'package:shop_list_app/pages/home_page.dart';

import '../components/nav_bar.dart';
import 'list_page.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});
  static String id = 'items_page';

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  int _selectedIndex = 2;

  void _onNavBarItemTapped(int index) {
    setState(() {
      // _selectedIndex = index;
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
      body: Text("items page"),
      bottomNavigationBar: NavBar(_selectedIndex, _onNavBarItemTapped),
    );
  }
}
