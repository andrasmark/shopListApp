import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shop_list_app/pages/ai_grocery_page.dart';
import 'package:shop_list_app/pages/authentication/login_page.dart';
import 'package:shop_list_app/pages/authentication/registration_page.dart';
import 'package:shop_list_app/pages/home_page.dart';
import 'package:shop_list_app/pages/items_page.dart';
import 'package:shop_list_app/pages/list_page.dart';
import 'package:shop_list_app/pages/splash_page.dart';
import 'package:shop_list_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashPage(),
      routes: {
        HomePage.id: (context) => HomePage(),
        ItemsPage.id: (context) => ItemsPage(),
        ListPage.id: (context) => ListPage(),
        SplashPage.id: (context) => SplashPage(),
        RegistrationPage.id: (context) => RegistrationPage(),
        LoginPage.id: (context) => LoginPage(),
        AiGroceryPage.id: (context) => AiGroceryPage(),
      },
    );
  }
}
