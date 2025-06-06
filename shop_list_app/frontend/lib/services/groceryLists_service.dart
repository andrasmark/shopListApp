import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

import '../models/product_model.dart';

class GrocerylistService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<String>> getStoresForList(
      Map<String, dynamic> groceryList) async {
    final allStores = ['Lidl', 'Auchan', 'Carrefour', 'Kaufland'];
    final requiredStores = <String>{};

    final products = groceryList['products'] as Map<String, dynamic>? ?? {};

    for (final productId in products.keys) {
      for (final store in allStores) {
        final productDoc =
            await _db.collection('products$store').doc(productId).get();

        if (productDoc.exists) {
          requiredStores.add(store);
          break;
        }
      }
    }

    return requiredStores.toList();
  }

  Future<void> createCopyOfGroceryListWithName({
    required String originalListId,
    required String newName,
    required String userId,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final originalDoc =
        await firestore.collection('groceryLists').doc(originalListId).get();

    if (!originalDoc.exists) return;

    final originalData = originalDoc.data()!;
    final originalItems = await originalDoc.reference.collection('items').get();

    final newDocRef = await firestore.collection('groceryLists').add({
      'listName': newName,
      'sharedWith': [userId],
      'favourite': false,
      'reminder': null,
      'products': originalData['products'] ?? {},
    });

    for (final item in originalItems.docs) {
      await newDocRef.collection('items').doc(item.id).set(item.data());
    }
    final userDocRef = firestore.collection('users').doc(userId);
    await userDocRef.update({
      'groceryLists': FieldValue.arrayUnion([newDocRef.id]),
    });
  }

  Future<Map<String, double>> getMonthlySpendingPerCategoryFromReminders(
      DateTime selectedMonth, String currentUserId) async {
    final start = DateTime(selectedMonth.year, selectedMonth.month);
    final end = DateTime(selectedMonth.year, selectedMonth.month + 1);
    final user = FirebaseAuth.instance.currentUser;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    final listIds = List<String>.from(userDoc.data()?['groceryLists'] ?? []);

    Map<String, double> spendingPerCategory = {};

    for (final listId in listIds) {
      final listDoc = await FirebaseFirestore.instance
          .collection('groceryLists')
          .doc(listId)
          .get();

      final reminder = listDoc.data()?['reminder'];
      if (reminder is Timestamp) {
        final reminderDate = reminder.toDate();
        if (reminderDate.isBefore(start) || reminderDate.isAfter(end)) {
          continue;
        }
      } else {
        continue;
      }

      final products = listDoc.data()?['products'] as Map<String, dynamic>?;

      if (products != null && products.isNotEmpty) {
        for (final entry in products.entries) {
          final itemId = entry.key;
          final productData = entry.value;

          final quantity = productData['quantity'] ?? 1;
          final category = productData['category'] ?? 'Unknown';

          final itemDoc =
              await listDoc.reference.collection('items').doc(itemId).get();
          final price = itemDoc.data()?['price'] ?? 0;

          final total = quantity * price;

          spendingPerCategory[category] =
              (spendingPerCategory[category] ?? 0) + total;
        }
      }
    }

    return spendingPerCategory;
  }

  // Future<Map<String, double>> getMonthlySpendingPerCategoryFromReminders(
  //     DateTime selectedMonth) async {
  //   final start = DateTime(selectedMonth.year, selectedMonth.month);
  //   final end = DateTime(selectedMonth.year, selectedMonth.month + 1);
  //
  //   final querySnapshot = await FirebaseFirestore.instance
  //       .collection('groceryLists')
  //       .where('reminder', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
  //       .where('reminder', isLessThan: Timestamp.fromDate(end))
  //       .get();
  //
  //   Map<String, double> spendingPerCategory = {};
  //
  //   for (final doc in querySnapshot.docs) {
  //     final products = doc.data()['products'] as Map<String, dynamic>?;
  //
  //     if (products != null && products.isNotEmpty) {
  //       for (final entry in products.entries) {
  //         final itemId = entry.key;
  //         final productData = entry.value;
  //
  //         final quantity = productData['quantity'] ?? 1;
  //         final category = productData['category'] ?? 'Unknown';
  //
  //         final itemDoc =
  //             await doc.reference.collection('items').doc(itemId).get();
  //         final price = itemDoc.data()?['price'] ?? 0;
  //
  //         final total = quantity * price;
  //
  //         spendingPerCategory[category] =
  //             (spendingPerCategory[category] ?? 0) + total;
  //       }
  //     }
  //   }
  //
  //   return spendingPerCategory;
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
