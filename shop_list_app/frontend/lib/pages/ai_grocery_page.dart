import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shop_list_app/constants/color_scheme.dart';
import 'package:shop_list_app/pages/home_page.dart';
import 'package:shop_list_app/pages/recommended_lists_page.dart';

import '../components/nav_bar.dart';
import 'authentication/login_page.dart';
import 'items_page.dart';
import 'list_page.dart';

class AiGroceryPage extends StatefulWidget {
  const AiGroceryPage({super.key});
  static String id = 'ai_grocery_page';

  @override
  State<AiGroceryPage> createState() => _AiGroceryPageState();
}

class _AiGroceryPageState extends State<AiGroceryPage> {
  int _selectedIndex = 3;
  double budget = 100;
  double protein = 30;
  double carbs = 40;
  double herbs = 30;
  double fats = 0;
  double fiber = 0;

  String result = "";
  bool isLoading = false;

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
        case 2:
          Navigator.pushReplacementNamed(context, ItemsPage.id);
          break;
      }
    });
  }

  void showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("You need to log in"),
        content: const Text("Please log in to use this feature."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, LoginPage.id);
            },
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }

  Future<void> saveResultToFirebase(String result) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    await userDoc.update({
      'ai_lists': FieldValue.arrayUnion([result]),
    });
  }

  Future<void> generateGroceryList() async {
    setState(() {
      isLoading = true;
      result = "";
    });

    final prompt = """
You are a grocery assistant. Your job is to generate a weekly grocery list under ${budget.toInt()} RON based on Romanian supermarket prices (Lidl, Carrefour, Kaufland, Auchan).

Break down the total budget using the following percentage allocations:
- Protein: ${protein.toInt()}%
- Carbs: ${carbs.toInt()}%
- Herbs/Spices: ${herbs.toInt()}%
- Fats: ${fats.toInt()}%
- Fiber: ${fiber.toInt()}%

IMPORTANT FORMAT INSTRUCTIONS 
- For **each category**, list EXACTLY 3 options.
- Each option is a BULLET POINT (•), and contains 1–2 food items, quantities, and NO price.
- Do NOT add any explanations, titles, or greetings.
- Only output the raw list using the following format:

Protein - X%:
• 500g chicken and 4 eggs  
• 1kg beans and 2 yogurts  
• 300g tuna and 500g cottage cheese

Carbs - X%:
• 1kg potatoes and 500g rice  
• 500g pasta and 2 bread rolls  
• 1kg cornmeal

Herbs/Spices - X%:
• 500g parsley and 1 bunch dill  
• 1kg tomatoes and 300g green onions  
• 500g cucumber and 1 bunch celery

...

! Never change the structure. No headings, no introductions, no extra info. Just the raw categories and bullets as shown.
""";

    final apiKey = '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';

    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "model": "gemma2-9b-it",
        "messages": [
          {"role": "user", "content": prompt}
        ]
      }),
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200 &&
        data['choices'] != null &&
        data['choices'].isNotEmpty) {
      setState(() {
        result = data['choices'][0]['message']['content'];
        isLoading = false;
      });
    } else {
      setState(() {
        result = "Erro occured: ${data['error']?['message'] ?? 'Unkown error'}";
        isLoading = false;
      });
    }
    print(result);
  }

  double get remainingPercentage =>
      100 - protein - carbs - herbs - fats - fiber;

  Widget buildSlider(String label, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toInt()}%'),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 100,
          label: '${value.toInt()}%',
          activeColor: COLOR_ORANGE,
          inactiveColor: COLOR_ORANGE.withOpacity(0.3),
          onChanged: (newVal) {
            double total =
                protein + carbs + herbs + fats + fiber - value + newVal;
            if (total <= 100) {
              onChanged(newVal);
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "AI Grocery List Generator",
          style: GoogleFonts.notoSerif(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            color: Colors.black,
            onPressed: () {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                showLoginPrompt(context);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RecommendedListsPage()),
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        color: COLOR_BEIGE,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                "Budget: ${budget.toInt()} RON",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Slider(
                value: budget,
                min: 5,
                max: 500,
                divisions: 49,
                label: '${budget.toInt()} RON',
                activeColor: COLOR_ORANGE,
                inactiveColor: COLOR_ORANGE.withOpacity(0.3),
                onChanged: (value) => setState(() => budget = value),
              ),
              buildSlider(
                  "Protein", protein, (val) => setState(() => protein = val)),
              buildSlider("Carbs", carbs, (val) => setState(() => carbs = val)),
              buildSlider("Herbs", herbs, (val) => setState(() => herbs = val)),
              buildSlider("Fats", fats, (val) => setState(() => fats = val)),
              buildSlider("Fiber", fiber, (val) => setState(() => fiber = val)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: isLoading || remainingPercentage < 0.1
                        ? null
                        : generateGroceryList,
                    child: const Text("Generate Grocery List"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: COLOR_ORANGE,
                      foregroundColor: Colors.white, // szövegszín
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                  SizedBox(
                    width: 16,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        showLoginPrompt(context);
                      } else {
                        saveResultToFirebase("Budget: " +
                            budget.toInt().toString() +
                            "  " +
                            result);
                      }
                    },
                    child: const Text("Save"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: COLOR_ORANGE,
                      foregroundColor: Colors.white, // szövegszín
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text("You can choose from 3 recommendations per category."),
              const SizedBox(height: 16),
              if (isLoading) const CircularProgressIndicator(),
              if (result.isNotEmpty)
                Expanded(
                  child: SingleChildScrollView(child: Text(result)),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavBar(_selectedIndex, _onNavBarItemTapped),
    );
  }
}
