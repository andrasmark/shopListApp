import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_list_app/constants/color_scheme.dart';

class RecommendedListsPage extends StatefulWidget {
  const RecommendedListsPage({super.key});

  @override
  State<RecommendedListsPage> createState() => _RecommendedListsPageState();
}

class _RecommendedListsPageState extends State<RecommendedListsPage> {
  List<String> aiLists = [];

  @override
  void initState() {
    super.initState();
    fetchAiLists();
  }

  Future<void> fetchAiLists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = snapshot.data();
    if (data != null && data['ai_lists'] != null) {
      setState(() {
        aiLists = List<String>.from(data['ai_lists']);
      });
    }
  }

  void showPopup(String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("AI Grocery List"),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
            style: TextButton.styleFrom(
              foregroundColor: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Saved Recommended Lists",
          style: GoogleFonts.notoSerif(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        color: COLOR_BEIGE,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: aiLists.isEmpty
              ? const Center(child: Text("No saved lists yet."))
              : ListView.builder(
                  itemCount: aiLists.length,
                  itemBuilder: (context, index) {
                    final list = aiLists[index];
                    return GestureDetector(
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text(
                                  'Do you want to delete this recommended list?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Cancel'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.teal,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final user =
                                        FirebaseAuth.instance.currentUser;
                                    if (user != null) {
                                      final userRef = FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user.uid);

                                      await userRef.update({
                                        'ai_lists':
                                            FieldValue.arrayRemove([list])
                                      });

                                      setState(() {
                                        aiLists.remove(list);
                                      });
                                    }

                                    Navigator.pop(context);
                                  },
                                  child: const Text('Delete'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Card(
                        color: Colors.white,
                        child: ListTile(
                          title: Text(list.substring(
                                  0, list.length > 15 ? 15 : list.length) +
                              "..."),
                          onTap: () => showPopup(list),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
