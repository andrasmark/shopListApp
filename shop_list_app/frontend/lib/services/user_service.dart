import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addUser(String userId, String email) async {
    String userName = email.split('@')[0];

    await _db.collection('users').doc(userId).set({
      'userId': userId,
      'userName': userName,
      'email': email,
      'groceryLists': [],
    });
  }

  Future<List<Map<String, dynamic>>> getUserGroceryLists(String userId) async {
    try {
      print('Fetching user document for userId: $userId');
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final groceryListIds = userDoc.data()?['groceryLists'] as List<dynamic>?;
      print('Grocery List IDs: $groceryListIds');

      if (groceryListIds == null || groceryListIds.isEmpty) {
        return [];
      }

      final groceryLists = await Future.wait(groceryListIds.map((listId) async {
        print('Fetching list document for listId: $listId');
        final listDoc = await _db.collection('groceryLists').doc(listId).get();
        print('List Data: ${listDoc.data()}');
        return {
          'id': listDoc.id,
          ...listDoc.data() ?? {},
        };
      }));

      return groceryLists;
    } catch (e) {
      print('Error fetching grocery lists: $e');
      throw Exception('Failed to fetch grocery lists');
    }
  }
}
