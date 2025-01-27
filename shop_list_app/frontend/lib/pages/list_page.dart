import 'package:flutter/material.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key});
  static String id = "list_page";

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Shop list"),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Text("Szia"),
    );
  }
}
