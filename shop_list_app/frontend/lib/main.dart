import 'package:flutter/material.dart';
import 'package:shop_list_app/pages/home_page.dart';
import 'package:shop_list_app/pages/items_page.dart';
import 'package:shop_list_app/pages/list_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(),
      routes: {
        HomePage.id: (context) => HomePage(),
        ItemsPage.id: (context) => ItemsPage(),
        ListPage.id: (context) => ListPage(),
      },
    );
  }
}
