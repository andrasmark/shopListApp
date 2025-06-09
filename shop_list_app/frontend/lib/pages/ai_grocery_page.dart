import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop_list_app/pages/home_page.dart';

import '../components/nav_bar.dart';
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

  Future<void> generateGroceryList() async {
    setState(() {
      isLoading = true;
      result = "";
    });

    final prompt = """
Generate a weekly grocery list under ${budget.toInt()} RON, with:
- ${protein.toInt()}% protein-rich items
- ${carbs.toInt()}% carbs
- ${herbs.toInt()}% herbs/spices

Return only the grocery list in bullet points.
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

// HIBAELLENŐRZÉS HOZZÁADÁSA
    if (response.statusCode == 200 &&
        data['choices'] != null &&
        data['choices'].isNotEmpty) {
      setState(() {
        result = data['choices'][0]['message']['content'];
        isLoading = false;
      });
    } else {
      setState(() {
        result =
            "Hiba történt: ${data['error']?['message'] ?? 'Ismeretlen hiba'}";
        isLoading = false;
      });
    }
    print(result);
  }

  Widget buildSlider(String label, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toInt()}%'),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 20,
          label: '${value.toInt()}',
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Grocery Generator"),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Budget: ${budget.toInt()} RON"),
            Slider(
              value: budget,
              min: 5,
              max: 500,
              divisions: 48,
              label: '${budget.toInt()} RON',
              onChanged: (value) => setState(() => budget = value),
            ),
            buildSlider(
                "Protein", protein, (val) => setState(() => protein = val)),
            buildSlider("Carbs", carbs, (val) => setState(() => carbs = val)),
            buildSlider("Herbs", herbs, (val) => setState(() => herbs = val)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : generateGroceryList,
              child: const Text("Generate Grocery List"),
            ),
            const SizedBox(height: 16),
            if (isLoading) const CircularProgressIndicator(),
            if (result.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(child: Text(result)),
              ),
          ],
        ),
      ),
      bottomNavigationBar: NavBar(_selectedIndex, _onNavBarItemTapped),
    );
  }
}
