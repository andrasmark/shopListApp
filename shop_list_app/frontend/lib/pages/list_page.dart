import 'package:flutter/material.dart';
import 'package:shop_list_app/pages/items_page.dart';
import 'package:shop_list_app/services/authorization.dart';

import '../components/groceryListCard.dart';
import '../components/nav_bar.dart';
import '../services/user_service.dart';
import 'groceryListPage.dart';
import 'home_page.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key});
  static String id = "list_page";

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  String? _userId;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _userId = _authService.getUserId();
  }

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
    if (_userId == null) {
      return Center(child: Text("User not logged in."));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("My Grocery Lists"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _userService.getUserGroceryLists(_userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No grocery lists found.'));
          } else {
            final groceryLists = snapshot.data!;
            return ListView.builder(
              itemCount: groceryLists.length,
              itemBuilder: (context, index) {
                final list = groceryLists[index];
                return GroceryListCard(
                  listId: list['id'],
                  listName: list['listName'] ?? 'Unnamed List',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            GroceryListPage(listId: list['id']),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
      bottomNavigationBar: NavBar(_selectedIndex, _onNavBarItemTapped),
    );
  }
}
