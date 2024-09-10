import 'dart:convert';
import 'dart:developer';
import 'dart:ui';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/request/customers_regis_post_req.dart';
import 'package:mobile_miniproject_app/pages/Login.dart';
import 'package:mobile_miniproject_app/pages/Home.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String txt = '';
  TextEditingController emailCtl = TextEditingController();
  TextEditingController usernameCtl = TextEditingController();
  TextEditingController passwordCtl = TextEditingController();
  TextEditingController conPassCtl = TextEditingController();
  TextEditingController walletCtl = TextEditingController();
  String url = '';

  @override
  void initState() {
    super.initState();
    //อ่านค่า config
    Configuration.getConfig().then((value) {
      url = value['apiEndpoint'];
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: SizedBox(
                width: 300,
                height: 100,
                child: Image.network(
                  'https://cdn-icons-png.freepik.com/256/16939/16939342.png?semt=ais_hybrid',
                  // กำหนดการจัดตำแหน่งของรูปภาพ
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 16.0, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 79, 78, 78),
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'Email',
              style: TextStyle(
                color: Color.fromARGB(255, 15, 15, 15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 16.0),
              child: TextField(
                controller: emailCtl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(255, 228, 225, 225),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(width: 1)),
                ),
              ),
            ),
            const Text(
              'Username',
              style: TextStyle(
                color: Color.fromARGB(255, 15, 15, 15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 16.0),
              child: TextField(
                controller: usernameCtl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(255, 228, 225, 225),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(width: 1)),
                ),
              ),
            ),
            const Text(
              'Password',
              style: TextStyle(
                color: Color.fromARGB(255, 15, 15, 15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 16.0),
              child: TextField(
                obscureText: true,
                controller: passwordCtl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(255, 228, 225, 225),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(width: 1)),
                ),
              ),
            ),
            const Text(
              'Confirm Password',
              style: TextStyle(
                color: Color.fromARGB(255, 15, 15, 15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 16.0),
              child: TextField(
                obscureText: true,
                controller: conPassCtl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(255, 228, 225, 225),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(width: 1)),
                ),
              ),
            ),
            const Text(
              'Wallet',
              style: TextStyle(
                color: Color.fromARGB(255, 84, 82, 82),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 16.0),
              child: TextField(
                controller: walletCtl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(255, 228, 225, 225),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(width: 1)),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 320,
                  height: 50,
                  child: FilledButton(
                    onPressed: register,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                          Color.fromARGB(255, 69, 162, 254)),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                    ),
                    child: const Text(
                      'Create Account',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                    ),
                  ),
                )
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 15.0, bottom: 5.0),
              child: Divider(
                color: Colors.grey,
                thickness: 1,
                indent: 10,
                endIndent: 10,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have Account?'),
                TextButton(
                  onPressed: login,
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.all(
                        const Color.fromARGB(255, 69, 162, 254)),
                  ),
                  child: const Text(
                    'Sign in',
                    style: TextStyle(fontWeight: FontWeight.w400),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80.0),
              child: Text(
                txt,
                style: TextStyle(color: Color.fromARGB(255, 223, 7, 7)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void register() async {
    if (emailCtl.text.isEmpty ||
        usernameCtl.text.isEmpty ||
        passwordCtl.text.isEmpty ||
        conPassCtl.text.isEmpty ||
        walletCtl.text.isEmpty ||
        passwordCtl.text != conPassCtl.text) {
      Fluttertoast.showToast(
          msg: "ข้อมูลไม่ถูกต้องโปรดตรวจสอบความถูกต้อง แล้วลองอีกครั้ง",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          // backgroundColor: Color.fromARGB(120, 0, 0, 0),
          backgroundColor: Color.fromARGB(255, 255, 0, 0),
          textColor: Colors.white,
          fontSize: 15.0);
      return;
    }

    var model = CustomersRegisterPostRequest(
        email: emailCtl.text,
        username: usernameCtl.text,
        password: passwordCtl.text,
        wallet: int.tryParse(walletCtl.text) ?? 0,
        image:
            'http://202.28.34.197:8888/contents/4a00cead-afb3-45db-a37a-c8bebe08fe0d.png');

    var Value = await http.post(Uri.parse("$url/db/register/user"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: customersRegisterPostRequestToJson(model));

    if (Value.statusCode == 200) {
      log('Registration is successful');
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ));
    } else {
      // ถ้า status code ไม่ใช่ 200 ให้ดึงข้อความจาก response body
      var responseBody = jsonDecode(Value.body);
      setState(() {
        Fluttertoast.showToast(
            msg: "Email นี้เป็นสมาชิกแล้ว!!!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            // backgroundColor: Color.fromARGB(120, 0, 0, 0),
            backgroundColor: Color.fromARGB(255, 255, 0, 0),
            textColor: Colors.white,
            fontSize: 15.0);
      });
      log(responseBody['error']);
    }
  }

  void login() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ));
  }
}
