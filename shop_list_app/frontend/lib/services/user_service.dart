import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addUser(String userId, String email) async {
    String userName = email.split('@')[0];

    await _db.collection('users').doc(userId).set({
      'userId': userId,
      'userName': userName,
      'email': email,
    });
  }
}
