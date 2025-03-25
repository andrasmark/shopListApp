import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Stream<List<Product>> getProducts() {
  //   return _db
  //       .collection("products")
  //       .snapshots()
  //       .map((snapshot) => snapshot.docs.map((doc) {
  //             final data = doc.data();
  //             return Product(
  //               doc.id,
  //               data['productName'] ?? '',
  //               data['productImage'] ?? '',
  //               (data['productPrice'] ?? 0).toDouble(),
  //             );
  //           }).toList());
  // }

  Stream<List<Product>> getProductsFromKaufland() {
    return _db.collection("productsKaufland").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          productUID: doc.id,
          productName: data['productName'],
          productImage: data['productImage'],
          productPrice: _parseDouble(data['productPrice']),
          productOldPrice: _parseDouble(data['productOldPrice']),
          productSubtitle: data['productSubtitle'],
          productDiscount: data['productDiscount'],
        );
      }).toList();
    });
  }

  Stream<List<Product>> getProductsFromLidl() {
    return _db.collection("productsLidl").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          productUID: doc.id,
          productName: data['productName'],
          productImage: data['productImage'],
          productPrice: _parseDouble(data['productPrice']),
          productOldPrice: _parseDouble(data['productOldPrice']),
          productDiscount: data['productDiscount'],
          productSubtitle: null, // Lidl products don't have subtitle
        );
      }).toList();
    });
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(
          value.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.-]'), ''));
    }
    return null;
  }
}
