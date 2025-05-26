import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

import '../models/product_model.dart';

class GrocerylistService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // final CollectionReference groceryLists =
  //     FirebaseFirestore.instance.collection('groceryLists');

  Future<Map<String, double>> getMonthlySpendingPerCategoryFromReminders(
      String userId) async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    final firestore = FirebaseFirestore.instance;

    // Csak azokat a groceryList-okat kérjük le, ahol reminder ebben a hónapban van
    final querySnapshot = await firestore
        .collection('groceryLists')
        .where('reminder',
            isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
        .where('reminder',
            isLessThanOrEqualTo: Timestamp.fromDate(lastDayOfMonth))
        .get();

    Map<String, double> categoryTotals = {};

    for (var doc in querySnapshot.docs) {
      final itemsRef = doc.reference.collection('items');
      final itemsSnapshot = await itemsRef
          .where('addedBy',
              isEqualTo: userId) // csak az adott user által hozzáadott elemek
          .get();

      for (var itemDoc in itemsSnapshot.docs) {
        final data = itemDoc.data();
        final quantity = (data['quantity'] ?? 1) as int;
        final price = (data['productPrice'] ?? 0.0) as num;
        final category = data['category'] ?? 'Other';

        final total = price * quantity;
        categoryTotals[category] = (categoryTotals[category] ?? 0) + total;
      }
    }

    return categoryTotals;
  }

  // Future<Map<String, double>> getMonthlySpendingPerCategory(
  //     String userId) async {
  //   final now = DateTime.now();
  //   final firstDayOfMonth = DateTime(now.year, now.month, 1);
  //   final firestore = FirebaseFirestore.instance;
  //
  //   final querySnapshot = await firestore.collection('groceryLists').get();
  //
  //   Map<String, double> categoryTotals = {};
  //
  //   for (var doc in querySnapshot.docs) {
  //     final itemsRef = doc.reference.collection('items');
  //     final itemsSnapshot = await itemsRef
  //         .where('addedBy', isEqualTo: userId)
  //         .where('addedAt',
  //             isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
  //         .get();
  //
  //     for (var itemDoc in itemsSnapshot.docs) {
  //       final data = itemDoc.data();
  //       final quantity = data['quantity'] ?? 1;
  //       final price = data['productPrice'] ?? 0.0;
  //       final category = data['category'] ?? 'Other';
  //
  //       final total = price * quantity;
  //       categoryTotals[category] = (categoryTotals[category] ?? 0) + total;
  //     }
  //   }
  //
  //   return categoryTotals;
  // }

  Future<void> createNewList(String listName) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // 1. Új lista létrehozása groceryLists kollekcióban
      DocumentReference listRef = await _db.collection('groceryLists').add({
        'listName': listName,
        'favourite': false,
        'reminder': null,
        'sharedWith': [uid],
        'createdAt': Timestamp.now(),
      });

      // 2. Lista ID hozzáadása a felhasználó groceryLists mezőjéhez
      final userDocRef = _db.collection('users').doc(uid);

      await userDocRef.set({
        'groceryLists': FieldValue.arrayUnion([listRef.id])
      }, SetOptions(merge: true));
    } catch (e) {
      print('Hiba a lista létrehozásakor: $e');
    }
  }

  Future<void> deleteItemFromGroceryList(
      String listId, String productId) async {
    try {
      // Delete from the main products map
      await _db.collection('groceryLists').doc(listId).set({
        'products': {
          productId: FieldValue.delete(),
        }
      }, SetOptions(merge: true));

      // Delete from the items subcollection
      await _db
          .collection('groceryLists')
          .doc(listId)
          .collection('items')
          .doc(productId)
          .delete();
    } catch (e) {
      debugPrint("Error deleting item: $e");
      rethrow;
    }
  }

  Future<String?> getUserNameWhoAddedProduct(
      String listId, String? productId) async {
    try {
      final listDoc = await _db.collection('groceryLists').doc(listId).get();
      if (!listDoc.exists) return null;

      final productsMap =
          listDoc.data()?['products'] as Map<String, dynamic>? ?? {};
      final productEntry = productsMap[productId] as Map<String, dynamic>?;

      final userId = productEntry?['addedBy'];
      if (userId == null) return null;

      final userDoc = await _db.collection('users').doc(userId).get();
      return userDoc.data()?['userName'];
    } catch (e) {
      debugPrint("Error getting user who added product: $e");
      return null;
    }
  }

  Future<String?> getStoreForProduct(String? productId) async {
    try {
      final kauflandDoc =
          await _db.collection('productsKaufland').doc(productId).get();
      if (kauflandDoc.exists) return "Kaufland";

      final lidlDoc = await _db.collection('productsLidl').doc(productId).get();
      if (lidlDoc.exists) return "Lidl";

      return null; // Product not found in either collection
    } catch (e) {
      debugPrint("Error getting store for product: $e");
      return null;
    }
  }

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
