import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import '../pages/authentication/list_page.dart';

SpeedDial Fab(BuildContext context) {
  return SpeedDial(
    icon: Icons.add,
    activeIcon: Icons.close,
    backgroundColor: Colors.lightBlueAccent,
    foregroundColor: Colors.white,
    activeBackgroundColor: Colors.blueAccent,
    activeForegroundColor: Colors.white,
    buttonSize: Size(56.0, 56.0), //button size
    visible: true,
    closeManually: false,
    curve: Curves.bounceIn,
    overlayColor: Colors.black,
    overlayOpacity: 0.5,
    onOpen: () => print('OPENING DIAL'), // action when menu opens
    onClose: () => print('DIAL CLOSED'), //action when menu closes

    elevation: 8.0, //shadow elevation of button
    shape: CircleBorder(), //shape of button

    children: [
      SpeedDialChild(
        child: Icon(Icons.list),
        backgroundColor: Colors.lightBlueAccent,
        foregroundColor: Colors.white,
        label: 'Create new shop list',
        labelStyle: TextStyle(fontSize: 18.0),
        onTap: () => Navigator.pushNamed(context, ListPage.id),
        onLongPress: () => print('FIRST CHILD LONG PRESS'),
      ),
      SpeedDialChild(
        child: Icon(Icons.people),
        backgroundColor: Colors.lightBlueAccent,
        foregroundColor: Colors.white,
        label: 'Create public list',
        labelStyle: TextStyle(fontSize: 18.0),
        onTap: () => print('SECOND CHILD'),
        onLongPress: () => print('SECOND CHILD LONG PRESS'),
      ),
    ],
  );
}
