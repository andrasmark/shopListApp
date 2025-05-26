import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_list_app/constants/color_scheme.dart';
import 'package:shop_list_app/pages/list_page.dart';
import 'package:table_calendar/table_calendar.dart';

import '../components/list_card_home.dart';
import '../components/nav_bar.dart';
import '../services/groceryLists_service.dart';
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
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();
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
      }
    });
  }

  Future<void> _loadReminders() async {
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
      body: Container(
        color: COLOR_BEIGE,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ListCardHome(
                icon: Icons.local_offer,
                title: "New Grocery List",
                subtitle: "Create a new grocery list, and add items anytime!",
                onTap: () async {
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
                    color: Colors.blue,
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
            ],
          ),
        ),
      ),
      //floatingActionButton: Fab(context),
      bottomNavigationBar: NavBar(_selectedIndex, _onNavBarItemTapped),
    );
  }
}
