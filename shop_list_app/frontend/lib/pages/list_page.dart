import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_list_app/constants/color_scheme.dart';
import 'package:shop_list_app/pages/items_page.dart';
import 'package:shop_list_app/services/authorization.dart';

import '../components/groceryListCard.dart';
import '../components/nav_bar.dart';
import '../services/groceryLists_service.dart';
import '../services/user_service.dart';
import 'ai_grocery_page.dart';
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
  String _selectedFilter = 'All';
  late Future<List<Map<String, dynamic>>> _groceryListsFuture;
  final List<String> _filters = ['All', 'Favourites', 'Scheduled'];

  @override
  void initState() {
    super.initState();
    _userId = _authService.getUserId();
    if (_userId != null) {
      _groceryListsFuture = _userService.getUserGroceryLists(_userId!);
    }
  }

  void _onNavBarItemTapped(int index) {
    setState(() {
      switch (index) {
        case 1:
          Navigator.pushReplacementNamed(context, HomePage.id);
          break;
        case 2:
          Navigator.pushReplacementNamed(context, ItemsPage.id);
          break;
        case 3:
          Navigator.pushReplacementNamed(context, AiGroceryPage.id);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          "My Grocery Lists",
          style: GoogleFonts.notoSerif(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.notifications),
          //   onPressed: () async {
          //     try {
          //       await NotificationService().showTestNotification();
          //       // Success feedback (opcionális)
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(
          //           content: Text('Test notification sent!'),
          //           duration: Duration(seconds: 2),
          //         ),
          //       );
          //     } catch (e) {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         SnackBar(
          //           content: Text('Error sending notification: $e'),
          //           backgroundColor: Colors.red,
          //           duration: const Duration(seconds: 3),
          //         ),
          //       );
          //     }
          //   },
          // ),
        ],
      ),
      body: Container(
        color: COLOR_BEIGE,
        child: _userId == null
            ? Center(child: Text("Please log in to see your grocery lists."))
            : Column(
                children: [
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 10),
                    child: Row(
                      children: _filters.map((filter) {
                        final bool isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: FilterChip(
                            label: Text(filter),
                            selected: _selectedFilter == filter,
                            selectedColor: Colors.teal,
                            onSelected: (bool selected) {
                              setState(() {
                                _selectedFilter = selected ? filter : 'All';
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  // List content
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      //future: _userService.getUserGroceryLists(_userId!),
                      future: _groceryListsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Center(child: Text('No grocery lists found.'));
                        } else {
                          final allLists = snapshot.data!;
                          List<Map<String, dynamic>> filteredLists = allLists;

                          if (_selectedFilter == 'Favourites') {
                            filteredLists = allLists
                                .where((list) => list['favourite'] == true)
                                .toList();
                          } else if (_selectedFilter == 'Scheduled') {
                            filteredLists = allLists.where((list) {
                              final reminders = list['reminder'];
                              if (reminders != null && reminders is List) {
                                return reminders.any((r) =>
                                    r is Timestamp &&
                                    r.toDate().isAfter(DateTime.now()));
                              }
                              return false;
                            }).toList();
                          }

                          return ListView.builder(
                            itemCount: filteredLists.length,
                            itemBuilder: (context, index) {
                              final list = filteredLists[index];
                              // final reminderTimestamp = list['reminder'];
                              // final reminderDate = reminderTimestamp != null
                              //     ? (reminderTimestamp as Timestamp).toDate()
                              //     : null;
                              final reminderList = list['reminder'];
                              DateTime? reminderDate;

                              if (reminderList is List &&
                                  reminderList.isNotEmpty) {
                                reminderList.sort((a, b) =>
                                    (a as Timestamp).compareTo(b as Timestamp));
                                reminderDate =
                                    (reminderList.first as Timestamp).toDate();
                              }

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
                                          IconButton(
                                            onPressed: () async {
                                              Navigator.pop(context);
                                              await _grocerylistService
                                                  .deleteGroceryList(
                                                      list['id']);
                                              setState(() {
                                                _groceryListsFuture =
                                                    _userService
                                                        .getUserGroceryLists(
                                                            _userId!);
                                              });
                                            },
                                            icon: const Icon(Icons.delete),
                                            color: Colors.red,
                                            iconSize: 32,
                                            tooltip: 'Delete this list',
                                          ),
                                          SizedBox(
                                            width: 55,
                                          ),
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.teal,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.teal,
                                              foregroundColor: Colors.white,
                                            ),
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
                                  reminder: reminderDate,
                                  isFavourite: list['favourite'] == true,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            GroceryListPage(listId: list['id']),
                                      ),
                                    );
                                    if (_userId != null) {
                                      setState(() {
                                        _groceryListsFuture = _userService
                                            .getUserGroceryLists(_userId!);
                                      });
                                    }
                                  },
                                ),
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
}
