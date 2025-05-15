import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../models/product_model.dart';

class GrocerylistService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<double> calculateTotalPrice(String listId) async {
    try {
      // 1. Get the list document
      final listDoc = await _db.collection('groceryLists').doc(listId).get();
      if (!listDoc.exists) return 0.0;

      // 2. Get all product IDs with quantities
      final productsMap =
          (listDoc.data()?['products'] as Map<String, dynamic>?) ?? {};
      if (productsMap.isEmpty) return 0.0;

      final productIds = productsMap.keys.toList();

      // 3. Get all product details from both collections
      final kauflandProducts = await _db
          .collection('productsKaufland')
          .where(FieldPath.documentId, whereIn: productIds)
          .get();

      final lidlProducts = await _db
          .collection('productsLidl')
          .where(FieldPath.documentId, whereIn: productIds)
          .get();

      // Combine results (note: same product shouldn't exist in both collections)
      final allProducts = [...kauflandProducts.docs, ...lidlProducts.docs];

      // 4. Calculate total price
      double total = 0.0;

      for (final productDoc in allProducts) {
        final productData = productDoc.data();
        final productId = productDoc.id;
        final quantity = (productsMap[productId] is Map)
            ? (productsMap[productId] as Map)['quantity'] ?? 1
            : 1;

        // Get the effective price (use discounted price if available)
        final price = _parseDouble(productData['productPrice']);
        final discount = productData['productDiscount']?.toString();
        final discountedPrice = (discount != null && discount.isNotEmpty)
            ? price! * (1 - (double.tryParse(discount) ?? 0) / 100)
            : price;

        total += (discountedPrice! * quantity)!;
      }

      return total;
    } catch (e) {
      debugPrint('Error calculating total price: $e');
      return 0.0;
    }
  }

  Future<int> getProductQuantity(String listId, String productId) async {
    try {
      final doc = await _db.collection('groceryLists').doc(listId).get();
      if (!doc.exists) return 1;

      final products = doc.data()?['products'] as Map<String, dynamic>? ?? {};

      if (products[productId] is Map) {
        return (products[productId] as Map)['quantity'] ?? 1;
      }

      return 1;
    } catch (e) {
      debugPrint('Hiba a mennyiség lekérdezésekor: $e');
      return 1;
    }
  }

  Future<void> updateProductQuantity(
      String listId, String productId, int newQuantity) async {
    try {
      // Frissítjük a mennyiséget a meglévő Map struktúrán belül
      await _db.collection('groceryLists').doc(listId).update({
        'products.$productId.quantity': newQuantity,
      });
    } catch (e) {
      debugPrint('Hiba a mennyiség frissítésekor: $e');
      // Ha valamiért nem működik, alternatív megközelítés
      await _db.collection('groceryLists').doc(listId).set({
        'products': {
          productId: {'quantity': newQuantity}
        }
      }, SetOptions(merge: true));
    }
  }

  Stream<List<Product>> getItemsFromList(String listId) {
    return _db
        .collection('groceryLists')
        .doc(listId)
        .snapshots()
        .map((listDoc) {
      final productsMap =
          (listDoc.data()?['products'] as Map<String, dynamic>?) ?? {};
      final productIds = productsMap.keys.toList();

      if (productIds.isEmpty) return <Product>[];

      // Return just the product IDs - we'll fetch details separately
      return productIds.map((id) => Product(productUID: id)).toList();
    }).asyncMap((productList) async {
      if (productList.isEmpty) return <Product>[];

      final productsKaufland = await _db
          .collection('productsKaufland')
          .where(FieldPath.documentId,
              whereIn: productList.map((p) => p.productUID).toList())
          .get();

      final productsLidl = await _db
          .collection('productsLidl')
          .where(FieldPath.documentId,
              whereIn: productList.map((p) => p.productUID).toList())
          .get();

      final allProducts = [
        ...productsKaufland.docs,
        ...productsLidl.docs, // These overwrite Lidl products with same ID
      ];

      return allProducts.map((doc) {
        final data = doc.data();
        return Product(
          productUID: doc.id,
          productName: data['productName'] ?? 'Névtelen termék',
          productImage: data['productImage'] ?? '',
          productPrice: _parseDouble(data['productPrice']),
          productOldPrice: _parseDouble(data['productOldPrice']),
          productDiscount: data['productDiscount'],
          productSubtitle: data['productSubtitle'],
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

// Segédosztály a termék és mennyiség tárolásához
// class ProductWithQuantity {
//   final Product product;
//   final int quantity;
//
//   ProductWithQuantity({
//     required this.product,
//     required this.quantity,
//   });
// }

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

// Frissített getItemsFromList metódus (figyeli a mennyiségeket is)
// Stream<List<ProductWithQuantity>> getItemsFromList(String listId) {
//   return _db
//       .collection('groceryLists')
//       .doc(listId)
//       .snapshots()
//       .asyncMap((listDoc) async {
//     final productsMap =
//         (listDoc.data()?['products'] as Map<String, dynamic>?) ?? {};
//
//     if (productsMap.isEmpty) {
//       return <ProductWithQuantity>[];
//     }
//
//     final productIds = productsMap.keys.toList();
//
//     final products = await _db
//         .collection('productsKaufland')
//         .where(FieldPath.documentId, whereIn: productIds)
//         .get();
//
//     return products.docs.map((doc) {
//       final data = doc.data();
//       final quantity = productsMap[doc.id]?['quantity'] ?? 1;
//
//       return ProductWithQuantity(
//         product: Product(
//           productUID: doc.id,
//           productName: data['productName'] ?? 'Névtelen termék',
//           productImage: data['productImage'] ?? '',
//           productPrice: _parseDouble(data['productPrice']),
//           productOldPrice: _parseDouble(data['productOldPrice']),
//           productDiscount: data['productDiscount'],
//           productSubtitle: data['productSubtitle'],
//         ),
//         quantity: quantity,
//       );
//     }).toList();
//   });
// }
