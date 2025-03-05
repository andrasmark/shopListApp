import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream<List<Map<String, dynamic>>> getProducts() {
  //   return _db.collection("products").snapshots().map((snapshot) =>
  //       snapshot.docs.map((doc) => {"id": doc.id, ...doc.data()}).toList());
  // }
  Stream<List<Product>> getProducts() {
    return _db
        .collection("products")
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Product(
                doc.id,
                data['productName'] ?? '',
                data['productImage'] ?? '',
                (data['productPrice'] ?? 0).toDouble(),
              );
            }).toList());
  }
}
