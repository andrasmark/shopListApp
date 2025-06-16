import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_list_app/services/auth_checker.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  static String id = 'splash_page';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      // Navigator.pushReplacementNamed(context, HomePage.id);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AuthChecker()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
                left: 80.0, right: 80.0, bottom: 80.0, top: 120),
            child: Image.asset('assets/images/grocery_icon.jpg'),
          ),
          Padding(
            padding: const EdgeInsets.all(60.0),
            child: Text(
              "GROCELY",
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSerif(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Text(
            "Find groceries and create grocery-lists",
            style: TextStyle(
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
