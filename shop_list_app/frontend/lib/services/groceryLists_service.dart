import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';

class GrocerylistService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Product>> getItemsFromList(String listId) {
    return _db
        .collection('groceryLists')
        .doc(listId)
        .snapshots()
        .asyncMap((listDoc) async {
      final productsMap =
          (listDoc.data()?['products'] as Map<String, dynamic>?) ?? {};

      if (productsMap.isEmpty) {
        return <Product>[];
      }

      final productIds = productsMap.keys.toList();

      final products = await _db
          .collection('productsKaufland')
          .where(FieldPath.documentId, whereIn: productIds)
          .get();

      return products.docs.map((doc) {
        final data = doc.data();
        return Product(
          productUID: doc.id,
          productName: data['productName'] ?? 'Névtelen termék',
          productImage: data['productImage'] ?? '',
          productPrice: _parseDouble(data['productPrice']),
          productOldPrice: _parseDouble(data['productOldPrice']),
          productDiscount: data['productDiscount'],
          productSubtitle: data['productSubtitle'],
          // quantity: productsMap[doc.id]?['quantity'] ?? 1,
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

  Future<void> removeItemFromList(String listId, String itemId) async {
    await _db
        .collection('groceryLists')
        .doc(listId)
        .collection('items')
        .doc(itemId)
        .delete();
  }
}

//ezeket meg lehet hogy fel lehet hasznalni

// Stream<List<Product>> getItemsFromList(String listId) {
//   return _db.collection('groceryLists').doc(listId).snapshots().asyncMap((listDoc) async {
//     final productIds = (listDoc.data()?['products'] as List<dynamic>?)?.cast<String>() ?? [];
//     if (productIds.isEmpty) return <Product>[];
//
//     final products = await _db.collection('productsKaufland')
//         .where(FieldPath.documentId, whereIn: productIds)
//         .get();
//
//     return products.docs.map((doc) => Product.fromFirestore(doc)).toList();
//   });
// }

// Stream<List<Product>> getItemsFromList2(String listId) async* {
//   final listDoc = await _db.collection('groceryLists').doc(listId).get();
//   final productIds =
//       (listDoc.data()?['products'] as List<dynamic>?)?.cast<String>() ?? [];
//
//   if (productIds.isEmpty) {
//     yield [];
//     return;
//   }
//
//   yield* _db
//       .collection('productsKaufland')
//       .where(FieldPath.documentId, whereIn: productIds)
//       .snapshots()
//       .map((snapshot) => snapshot.docs.map((doc) {
//     final data = doc.data();
//     return Product(
//       productUID: doc.id,
//       productName: data['productName'],
//       productImage: data['productImage'],
//       productPrice: _parseDouble(data['productPrice']),
//       productOldPrice: _parseDouble(data['productOldPrice']),
//       productDiscount: data['productDiscount'],
//       productSubtitle: data['productSubtitle'],
//     );
//   }).toList());
// }
