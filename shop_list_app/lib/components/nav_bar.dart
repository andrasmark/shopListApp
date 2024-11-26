import 'package:flutter/material.dart';

BottomNavigationBar NavBar(
    int _selectedIndex, void Function(int) _onNavBarItemTapped) {
  return BottomNavigationBar(
    currentIndex: _selectedIndex,
    onTap: _onNavBarItemTapped,
    selectedItemColor: Colors.grey,
    unselectedItemColor: Colors.lightBlueAccent,
    items: const [
      BottomNavigationBarItem(
        icon: Icon(
          Icons.home,
          size: 30,
        ),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          Icons.shop,
          size: 30,
        ),
        label: 'Items',
      ),
    ],
  );
}
