import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_list_app/pages/list_page.dart';

import '../components/list_card_home.dart';
import '../components/nav_bar.dart';
import 'items_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static String id = 'home_page';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1;

  void _onNavBarItemTapped(int index) {
    setState(() {
      // _selectedIndex = index;
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, ListPage.id);
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
        title: Text(
          "Welcome to Grocely!",
          style: GoogleFonts.notoSerif(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        //backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ListCardHome(
              icon: Icons.bakery_dining,
              title: "New Grocery List",
              subtitle: "Create a new grocery list, and add items anytime!",
              onTap: () => print("Shop Now Clicked"),
            ),
            ListCardHome(
              icon: Icons.supervisor_account,
              title: "New Shared List",
              subtitle: "Create a new shared list, and invite others to it!",
              onTap: () => print("Order History Clicked"),
            ),
            ListCardHome(
              icon: Icons.local_offer,
              title: "",
              subtitle: "",
              onTap: () => print(""),
            ),
          ],
        ),
      ),
      //floatingActionButton: Fab(context),
      bottomNavigationBar: NavBar(_selectedIndex, _onNavBarItemTapped),
    );
  }
}
