import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _locationAllowed = false;
  bool _notificationsAllowed = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final locationStatus = await Permission.location.status;
    final notificationStatus = await Permission.notification.status;

    setState(() {
      _locationAllowed = locationStatus.isGranted;
      _notificationsAllowed = notificationStatus.isGranted;
    });
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      setState(() => _locationAllowed = true);
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      setState(() => _notificationsAllowed = true);
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text("Location Access"),
            value: _locationAllowed,
            onChanged: (_) async {
              await _requestLocationPermission();
              await _checkPermissions();
            },
          ),
          SwitchListTile(
            title: const Text("Notifications"),
            value: _notificationsAllowed,
            onChanged: (_) async {
              await _requestNotificationPermission();
              await _checkPermissions();
            },
          ),
        ],
      ),
    );
  }
}
