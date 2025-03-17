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
    return _db
        .collection("productsKaufland")
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Product(
                doc.id,
                data['productName'] ?? 'N/A',
                data['productImage'] ?? '',
                data['productPrice']?.toString() ?? '0',
                data['productDiscount']?.toString() ?? '0',
                data['productOldPrice']?.toString() ?? '0',
                data['productSubtitle'] ?? 'N/A',
              );
            }).toList());
  }
}
