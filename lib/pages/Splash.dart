import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_miniproject_app/pages/login/Login.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Color.fromARGB(255, 86, 13, 94), // เปลี่ยนเป็นสีพื้นหลังที่ต้องการ
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/BG_splash.png', // ลิงค์ของรูปพื้นหลัง
              fit: BoxFit.cover,
            ),
          ],
        ),
      ),
    );
  }
}
