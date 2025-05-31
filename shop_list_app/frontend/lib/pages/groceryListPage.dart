import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shop_list_app/constants/color_scheme.dart';

import '../components/groceryListItem/groceryListItemCard.dart';
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
    // Load initial price immediately
    _updateTotalPrice();
    _loadFavouriteStatus();
    _fetchReminder();
  }

  Future<void> _fetchReminder() async {
    final doc = await FirebaseFirestore.instance
        .collection('groceryLists')
        .doc(widget.listId)
        .get();

    final data = doc.data();
    if (data != null && data['reminder'] != null) {
      setState(() {
        _reminder = data['reminder'];
      });
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

    // Frissítés Firestore-ban
    await FirebaseFirestore.instance
        .collection('groceryLists')
        .doc(widget.listId)
        .update({'reminder': reminderTimestamp});

    // Lokális értesítés ütemezése
    await NotificationService().scheduleReminder(
      listId: widget.listId,
      reminderTime: reminderTimestamp,
    );

    setState(() {
      _reminder = reminderTimestamp;
    });
  }

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
            ),
            ElevatedButton(
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
      appBar: AppBar(title: const Text("Grocery List")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text("Details for list: ${widget.listId}"),
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
                              _showCategoryDialog(
                                  context, widget.listId, product.productUID!);
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
            // Total price container
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  width: 220,
                  height: 80,
                  decoration: BoxDecoration(
                    color: COLOR_BEIGE,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    //mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Text("Total:",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(
                        width: 10,
                      ),
                      Text("${_totalPrice.toStringAsFixed(2)} Ron",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  width: 200,
                  height: 80,
                  decoration: BoxDecoration(
                    color: COLOR_BEIGE,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: Icon(
                          _reminder != null &&
                                  _reminder!.toDate().isAfter(DateTime.now())
                              ? Icons.notifications_active
                              : Icons.notifications_none,
                          color: Colors.black,
                        ),
                        // onPressed: () async {
                        //   await NotificationService.showTestNotification();
                        // },
                        onPressed: () => _pickReminderDateTime(context),
                      ),
                      // IconButton(
                      //   icon: const Icon(Icons.notifications_none),
                      //   onPressed: () {
                      //     // TODO: Add your notification logic
                      //   },
                      // ),
                      IconButton(
                        icon: Icon(
                          isFavourite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.black,
                        ),
                        onPressed: _toggleFavourite,
                      ),
                      IconButton(
                        icon: const Icon(Icons.map_outlined),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MapPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
