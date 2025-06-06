import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InviteUserDialog extends StatefulWidget {
  final String listId;

  const InviteUserDialog({super.key, required this.listId});

  @override
  State<InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends State<InviteUserDialog> {
  final TextEditingController _emailController = TextEditingController();
  String? _statusMessage;
  bool _isLoading = false;

  Future<void> _inviteUser() async {
    final enteredEmail = _emailController.text.trim();
    if (enteredEmail.isEmpty) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: enteredEmail)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      setState(() {
        _statusMessage = 'Email not found.';
        _isLoading = false;
      });
      return;
    }

    final userDoc = querySnapshot.docs.first;
    final invitedUserId = userDoc.id;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: enteredEmail)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _statusMessage = 'Email not found.';
          _isLoading = false;
        });
        return;
      }

      final userId = querySnapshot.docs.first.id;

      final listRef = FirebaseFirestore.instance
          .collection('groceryLists')
          .doc(widget.listId);

      await listRef.update({
        'sharedWith': FieldValue.arrayUnion([userId])
      });
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(invitedUserId);

      await userRef.set({
        'groceryLists': FieldValue.arrayUnion([widget.listId])
      }, SetOptions(merge: true));

      setState(() {
        _statusMessage = 'Invite succesfull!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error occured: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite user'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: CircularProgressIndicator(),
            ),
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_statusMessage!,
                  style: TextStyle(
                    color: _statusMessage == 'Invite succesfull!'
                        ? Colors.green
                        : Colors.red,
                  )),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _inviteUser,
          child: const Text('Invite'),
        ),
      ],
    );
  }
}
