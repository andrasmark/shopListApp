import 'package:flutter/material.dart';
import 'package:shop_list_app/constants/color_scheme.dart';
import 'package:shop_list_app/pages/items_page.dart';
import 'package:shop_list_app/services/authorization.dart';

import '../components/groceryListCard.dart';
import '../components/nav_bar.dart';
import '../services/groceryLists_service.dart';
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
  final GrocerylistService _grocerylistService = GrocerylistService();
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("My Grocery Lists"),
      ),
      body: Container(
        color: COLOR_BEIGE,
        child: _userId == null
            ? Center(child: Text("Please log in to see your grocery lists."))
            : FutureBuilder<List<Map<String, dynamic>>>(
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
                        return GestureDetector(
                          onLongPress: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                String newListName = '';

                                return AlertDialog(
                                  title: const Text(
                                      'Do you want to create a copy of this list?'),
                                  content: TextField(
                                    decoration: const InputDecoration(
                                        labelText: 'New list name'),
                                    onChanged: (value) {
                                      newListName = value;
                                    },
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await _grocerylistService
                                            .createCopyOfGroceryListWithName(
                                          originalListId: list['id'],
                                          newName: newListName.isNotEmpty
                                              ? newListName
                                              : 'Copied List',
                                          userId: _userId!,
                                        );
                                        setState(() {});
                                      },
                                      child: const Text('Copy'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: GroceryListCard(
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
                          ),
                        );
                      },
                    );
                  }
                },
              ),
      ),
      bottomNavigationBar: NavBar(_selectedIndex, _onNavBarItemTapped),
    );
  }
}
