import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _locationKey = 'allow_location';
  static const String _notificationsKey = 'allow_notifications';

  Future<bool> getLocationAllowed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationKey) ?? false;
  }

  Future<void> setLocationAllowed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationKey, value);
  }

  Future<bool> getNotificationsAllowed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey) ?? false;
  }

  Future<void> setNotificationsAllowed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
  }
}
