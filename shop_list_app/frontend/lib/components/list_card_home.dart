import 'package:flutter/material.dart';

class ListCardHome extends StatelessWidget {
  const ListCardHome({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),

        // Same margin for all cards
        child: GestureDetector(
          onTap: onTap,
          child: Card(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: ListTile(
                leading: Icon(icon, size: 40),
                title: Text(
                  title,
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  subtitle,
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
