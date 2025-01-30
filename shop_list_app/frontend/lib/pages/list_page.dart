import 'package:flutter/material.dart';
import 'package:shop_list_app/components/product_list.dart';

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
      body: Column(
        children: [Text("Szia"), Container(child: ProductList())],
      ),
    );
  }
}
