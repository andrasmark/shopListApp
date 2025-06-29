import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/groceryListItem/groceryListItemCard.dart';
import '../components/invite_user_dialog.dart';
import '../constants/color_scheme.dart';
import '../models/product_model.dart';
import '../services/groceryLists_service.dart';
import '../services/notification_service.dart';
import '../services/product_service.dart';
import 'map_page.dart';

class GroceryListPage extends StatefulWidget {
  final String listId;

  const GroceryListPage({super.key, required this.listId});

  @override
  State<GroceryListPage> createState() => _GroceryListPageState();
}

class _GroceryListPageState extends State<GroceryListPage> {
  final GrocerylistService _groceryListService = GrocerylistService();
  final ProductService _productService = ProductService();
  double _totalPrice = 0.0;
  List<Product> _currentProducts = [];
  bool _isInitialLoad = true;
  bool isFavourite = false;
  Timestamp? _reminder;
  //List<Timestamp>? _reminder;

  Map<String, dynamic>? currentGroceryList;
  String? _categoryFilter;

  Future<void> _updateTotalPrice() async {
    final total = await _groceryListService.calculateTotalPrice(widget.listId);
    if (mounted) {
      setState(() {
        _totalPrice = total;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _updateTotalPrice();
    _loadFavouriteStatus();
    _fetchReminder();
    fetchGroceryList();
  }

  Future<void> fetchGroceryList() async {
    final doc = await FirebaseFirestore.instance
        .collection('groceryLists')
        .doc(widget.listId)
        .get();

    if (doc.exists) {
      setState(() {
        currentGroceryList = doc.data();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("List not found")),
      );
    }
  }

  // Future<void> _fetchReminder() async {
  //   final doc = await FirebaseFirestore.instance
  //       .collection('groceryLists')
  //       .doc(widget.listId)
  //       .get();
  //
  //   final data = doc.data();
  //   if (data != null && data['reminder'] != null) {
  //     setState(() {
  //       _reminder = data['reminder'];
  //     });
  //   }
  // }
  Future<void> _fetchReminder() async {
    final doc = await FirebaseFirestore.instance
        .collection('groceryLists')
        .doc(widget.listId)
        .get();

    final data = doc.data();
    if (data != null && data['reminder'] is List) {
      final List<Timestamp> reminders =
          (data['reminder'] as List).whereType<Timestamp>().toList();

      if (reminders.isNotEmpty) {
        // closest time in future
        reminders.sort((a, b) => a.compareTo(b));
        final now = DateTime.now();
        final upcoming = reminders.firstWhere(
          (ts) => ts.toDate().isAfter(now),
          orElse: () => reminders.first,
        );

        setState(() {
          _reminder = upcoming;
        });
      }
    }
  }

  Future<void> _scheduleNotificationIfNeeded() async {
    final doc = await FirebaseFirestore.instance
        .collection('groceryLists')
        .doc(widget.listId)
        .get();

    final data = doc.data();
    if (data == null || data['reminder'] == null) return;

    final Timestamp reminderTime = data['reminder'];
    await NotificationService().scheduleReminder(
      listId: widget.listId,
      reminderTime: reminderTime,
    );
  }

  Future<void> _pickReminderDateTime(BuildContext context) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    final DateTime combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final Timestamp reminderTimestamp = Timestamp.fromDate(combined);

    // Firestore-ban hozzáadjuk a tömbhöz
    await FirebaseFirestore.instance
        .collection('groceryLists')
        .doc(widget.listId)
        .update({
      'reminder': FieldValue.arrayUnion([reminderTimestamp]),
    });

    // Lokális értesítés
    await NotificationService().scheduleReminder(
      listId: widget.listId,
      reminderTime: reminderTimestamp,
    );

    setState(() {
      _reminder =
          reminderTimestamp; // ez most csak az utolsó, tetszés szerint listává is teheted
    });
  }

  // Future<void> _pickReminderDateTime(BuildContext context) async {
  //   final DateTime? date = await showDatePicker(
  //     context: context,
  //     initialDate: DateTime.now(),
  //     firstDate: DateTime.now(),
  //     lastDate: DateTime.now().add(const Duration(days: 365)),
  //   );
  //
  //   if (date == null) return;
  //
  //   final TimeOfDay? time = await showTimePicker(
  //     context: context,
  //     initialTime: TimeOfDay.now(),
  //   );
  //
  //   if (time == null) return;
  //
  //   final DateTime combined = DateTime(
  //     date.year,
  //     date.month,
  //     date.day,
  //     time.hour,
  //     time.minute,
  //   );
  //
  //   final Timestamp reminderTimestamp = Timestamp.fromDate(combined);
  //
  //   await FirebaseFirestore.instance
  //       .collection('groceryLists')
  //       .doc(widget.listId)
  //       .update({'reminder': reminderTimestamp});
  //
  //   await NotificationService().scheduleReminder(
  //     listId: widget.listId,
  //     reminderTime: reminderTimestamp,
  //   );
  //
  //   setState(() {
  //     _reminder = reminderTimestamp;
  //   });
  // }

  Future<void> _loadFavouriteStatus() async {
    final doc = await FirebaseFirestore.instance
        .collection('groceryLists')
        .doc(widget.listId)
        .get();

    if (doc.exists) {
      setState(() {
        isFavourite = doc.data()?['favourite'] ?? false;
      });
    }
  }

  Future<void> _toggleFavourite() async {
    final newValue = !isFavourite;

    await FirebaseFirestore.instance
        .collection('groceryLists')
        .doc(widget.listId)
        .update({'favourite': newValue});

    setState(() {
      isFavourite = newValue;
    });
  }

  void _showCategoryDialog(
      BuildContext context, String listId, String itemId) async {
    final currentCategory =
        await _productService.getCurrentCategoryForItem(listId, itemId);

    final categories = [
      'Meat',
      'Fruit',
      'Vegetable',
      'Cleaning',
      'Drink',
      'Snack',
      'Food',
      'Other'
    ];
    String? selectedCategory = currentCategory;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose category'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButton<String?>(
                isExpanded: true,
                value: categories.contains(selectedCategory)
                    ? selectedCategory
                    : null,
                hint: const Text("No category yet"),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text("No category yet"),
                  ),
                  ...categories.map((cat) => DropdownMenuItem<String?>(
                        value: cat,
                        child: Text(cat),
                      )),
                ],
                onChanged: (val) {
                  setState(() {
                    selectedCategory = val;
                  });
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal,
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (selectedCategory != currentCategory) {
                  await _productService.updateProductCategory(
                    listId: listId,
                    itemId: itemId,
                    newCategory: selectedCategory,
                  );
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Grocery List",
          style: GoogleFonts.notoSerif(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            color: Colors.black, // invite icon
            tooltip: 'Invite user',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => InviteUserDialog(listId: widget.listId),
              );
            },
          ),
        ],
      ),
      body: Container(
        //color: Colors.white,
        color: COLOR_BEIGE,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              //Text("Details for list: ${widget.listId}"),

              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (_) => true, // Prevent rebuilds on scroll
                  child: StreamBuilder<List<Product>>(
                    stream: _groceryListService.getItemsFromList(widget.listId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          _isInitialLoad) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                            child: Text('No items in this list yet'));
                      } else {
                        // Only update products if they actually changed

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _currentProducts = snapshot.data!;
                          _updateTotalPrice();
                          _isInitialLoad = false;
                        });

                        return GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: _currentProducts.length,
                          itemBuilder: (context, index) {
                            final product = _currentProducts[index];
                            return GestureDetector(
                              onTap: () {
                                _showCategoryDialog(context, widget.listId,
                                    product.productUID!);
                              },
                              child: GroceryListItemCard(
                                key: ValueKey(product
                                    .productUID), // Important for state preservation
                                product: product,
                                listId: widget.listId,
                                groceryService: _groceryListService,
                                onQuantityChanged: _updateTotalPrice,
                                addedBy: _groceryListService
                                    .getUserNameWhoAddedProduct(
                                        widget.listId, product.productUID),
                                store: _groceryListService
                                    .getStoreForProduct(product.productUID),
                                category:
                                    _productService.getCurrentCategoryForItem(
                                        widget.listId, product.productUID),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  width: 200,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text("Total:",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Text("${_totalPrice.toStringAsFixed(2)} Ron",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            _reminder != null &&
                                    _reminder!.toDate().isAfter(DateTime.now())
                                ? Icons.notifications_active
                                : Icons.notifications_none,
                            color: Colors.black,
                          ),
                          // onPressed: () => _pickReminderDateTime(context),
                          onPressed: () => _pickReminderDateTime(context),
                          // onPressed: () async {
                          //   await NotificationService().scheduleNotification(
                          //     title: 'Grocely Reminder',
                          //     body: 'A list was scheduled for this time',
                          //     hour: 22,
                          //     minute: 24,
                          //   );
                          // },
                        ),
                        IconButton(
                          icon: Icon(
                            isFavourite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.black,
                          ),
                          onPressed: _toggleFavourite,
                        ),
                        IconButton(
                          icon: const Icon(Icons.map_outlined),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MapPage(groceryList: currentGroceryList),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                )
              ]),
              // Total price container
              // Row(
              //   //mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Container(
              //       padding: const EdgeInsets.all(16),
              //       width: 220,
              //       height: 80,
              //       decoration: BoxDecoration(
              //         color: COLOR_BEIGE,
              //         borderRadius: BorderRadius.circular(8),
              //       ),
              //       child: Row(
              //         //mainAxisAlignment: MainAxisAlignment.spaceAround,
              //         children: [
              //           const Text("Total:",
              //               style: TextStyle(
              //                   fontSize: 18, fontWeight: FontWeight.bold)),
              //           SizedBox(
              //             width: 10,
              //           ),
              //           Text("${_totalPrice.toStringAsFixed(2)} Ron",
              //               style: const TextStyle(
              //                   fontSize: 18, fontWeight: FontWeight.bold)),
              //         ],
              //       ),
              //     ),
              //     Container(
              //       padding: const EdgeInsets.all(16),
              //       width: 200,
              //       height: 80,
              //       decoration: BoxDecoration(
              //         color: COLOR_BEIGE,
              //         borderRadius: BorderRadius.circular(8),
              //       ),
              //       child: Row(
              //         mainAxisAlignment: MainAxisAlignment.spaceAround,
              //         children: [
              //           IconButton(
              //             icon: Icon(
              //               _reminder != null &&
              //                       _reminder!.toDate().isAfter(DateTime.now())
              //                   ? Icons.notifications_active
              //                   : Icons.notifications_none,
              //               color: Colors.black,
              //             ),
              //             // onPressed: () async {
              //             //   await NotificationService.showTestNotification();
              //             // },
              //             onPressed: () => _pickReminderDateTime(context),
              //           ),
              //           IconButton(
              //             icon: Icon(
              //               isFavourite
              //                   ? Icons.favorite
              //                   : Icons.favorite_border,
              //               color: Colors.black,
              //             ),
              //             onPressed: _toggleFavourite,
              //           ),
              //           IconButton(
              //             icon: const Icon(Icons.map_outlined),
              //             onPressed: () {
              //               Navigator.push(
              //                 context,
              //                 MaterialPageRoute(
              //                     builder: (context) =>
              //                         MapPage(groceryList: currentGroceryList)),
              //               );
              //             },
              //           ),
              //         ],
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
