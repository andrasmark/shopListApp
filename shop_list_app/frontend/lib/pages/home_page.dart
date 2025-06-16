import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_list_app/constants/color_scheme.dart';
import 'package:shop_list_app/pages/ai_grocery_page.dart';
import 'package:shop_list_app/pages/list_page.dart';
import 'package:shop_list_app/pages/settings_page.dart';
import 'package:table_calendar/table_calendar.dart';

import '../components/list_card_home.dart';
import '../components/nav_bar.dart';
import '../components/pie_chart.dart';
import '../services/groceryLists_service.dart';
import 'authentication/login_page.dart';
import 'items_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static String id = 'home_page';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1;
  Map<DateTime, List<String>> _reminderEvents = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  GrocerylistService _grocerylistService = GrocerylistService();
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  late Future<Map<String, double>> _monthlyStatsFuture;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      _monthlyStatsFuture =
          _grocerylistService.getMonthlySpendingPerCategoryFromReminders(
        _focusedMonth,
        user.uid,
      );
    } else {
      _monthlyStatsFuture = Future.value({});
    }

    _loadReminders();
  }

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
        case 3:
          Navigator.pushReplacementNamed(context, AiGroceryPage.id);
          break;
      }
    });
  }

  IconData getCategoryIcon(String? category) {
    switch (category) {
      case 'Meat':
        return Icons.set_meal;
      case 'Fruit':
        return Icons.apple;
      case 'Vegetable':
        return Icons.energy_savings_leaf;
      case 'Cleaning':
        return Icons.cleaning_services;
      case 'Drink':
        return Icons.local_drink;
      case 'Snack':
        return Icons.fastfood;
      case 'Food':
        return Icons.restaurant;
      default:
        return Icons.category;
    }
  }

  Future<void> _loadReminders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _reminderEvents = {};
      });
      return;
    }

    final userId = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('groceryLists')
        .where('sharedWith', arrayContains: userId)
        .get();

    final Map<DateTime, List<String>> events = {};

    for (var doc in snapshot.docs) {
      final reminderTimestamp = doc['reminder'];
      if (reminderTimestamp != null) {
        final date = (reminderTimestamp as Timestamp).toDate();
        final eventDay = DateTime(date.year, date.month, date.day);

        events.putIfAbsent(eventDay, () => []);
        events[eventDay]!.add(doc['listName'] ?? 'Unnamed List');
      }
    }

    setState(() {
      _reminderEvents = events;
    });
  }

  bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          "Welcome to Grocely!",
          style: GoogleFonts.notoSerif(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
            icon: Icon(Icons.settings),
            color: Colors.black,
          ),
          if (isGuest)
            IconButton(
              icon: const Icon(Icons.person),
              color: Colors.black,
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
            )
          else
            IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                print('User logged out');
                Navigator.pushReplacementNamed(context, LoginPage.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out.'),
                  ),
                );
              },
              icon: Icon(Icons.logout),
              color: Colors.black,
            ),
        ],
      ),
      //backgroundColor: Colors.white,
      body: Container(
        color: COLOR_BEIGE,
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ListCardHome(
                  icon: Icons.local_offer,
                  title: "New Grocery List",
                  subtitle: "Create a new grocery list, and add items anytime!",
                  onTap: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Not Logged In"),
                            content: const Text("You need to log in!"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("OK"),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => LoginPage()),
                                  );
                                },
                                child: const Text("Log In"),
                              ),
                            ],
                          );
                        },
                      );
                      return;
                    }
                    final TextEditingController controller =
                        TextEditingController();
                    await showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("New Grocery List"),
                          content: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                                hintText: "Enter list name"),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final listName = controller.text.trim();
                                if (listName.isNotEmpty) {
                                  await GrocerylistService()
                                      .createNewList(listName);
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text("Create"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                TableCalendar(
                  focusedDay: _focusedDay,
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: _calendarFormat,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                    CalendarFormat.twoWeeks: '2 Weeks',
                    CalendarFormat.week: 'Week',
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    final newMonth =
                        DateTime(focusedDay.year, focusedDay.month);
                    if (!isSameMonth(_focusedMonth, newMonth)) {
                      setState(() {
                        _focusedMonth = newMonth;
                        _monthlyStatsFuture = _grocerylistService
                            .getMonthlySpendingPerCategoryFromReminders(
                          _focusedMonth,
                          FirebaseAuth.instance.currentUser!.uid,
                        );
                      });
                      _loadReminders();
                    }

                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  eventLoader: (day) {
                    return _reminderEvents[
                            DateTime(day.year, day.month, day.day)] ??
                        [];
                  },
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                if (_selectedDay != null)
                  ..._reminderEvents[DateTime(_selectedDay!.year,
                              _selectedDay!.month, _selectedDay!.day)]
                          ?.map((name) => ListTile(
                                leading: const Icon(Icons.list),
                                title: Text(name),
                              )) ??
                      [const Text("No lists scheduled for this day.")],
                SizedBox(
                  height: 20,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: FutureBuilder<Map<String, double>>(
                        future: _monthlyStatsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final data = snapshot.data ?? {};
                          if (data.isEmpty) {
                            return const Text(
                                "You didn't buy anything this month.");
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Spending for category this month:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              buildPieChart(data),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: FutureBuilder<Map<String, double>>(
                        future: _monthlyStatsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final data = snapshot.data ?? {};
                          if (data.isEmpty) {
                            return const Text("");
                            // return const Text("You didn't buy anything this month.");
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                //'Spending for each category this month:',
                                '',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 60),
                              ...data.entries.map(
                                (entry) => ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  leading: Icon(getCategoryIcon(entry.key)),
                                  title: Text(
                                    entry.key,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  trailing: Text(
                                      '${entry.value.toStringAsFixed(2)} RON'),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (isGuest)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    alignment: Alignment.center,
                    child: const Text(
                      "You need to log in to access this page",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      //floatingActionButton: Fab(context),
      bottomNavigationBar: NavBar(_selectedIndex, _onNavBarItemTapped),
    );
  }
}
