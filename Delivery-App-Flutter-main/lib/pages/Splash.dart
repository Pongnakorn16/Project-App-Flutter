import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_miniproject_app/pages/Login.dart';

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
          Color.fromARGB(255, 251, 238, 165), // เปลี่ยนเป็นสีพื้นหลังที่ต้องการ
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 400,
              height: 250,
              child: Image.network(
                'https://cdn-icons-png.flaticon.com/512/2203/2203145.png', // กำหนดการจัดตำแหน่งของรูปภาพ
              ),
            ),
            SizedBox(height: 10), // เพิ่มช่องว่างระหว่างรูปภาพกับข้อความ
            Text(
              'PARCELPRO', // ข้อความที่จะแสดง
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
