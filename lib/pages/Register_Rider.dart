import 'dart:convert';
import 'dart:developer';
import 'dart:ui';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/request/user_regis_post_req.dart';
import 'package:mobile_miniproject_app/pages/Login.dart';
import 'package:mobile_miniproject_app/pages/Home.dart';
import 'package:mobile_miniproject_app/pages/Register_User.dart';

class RegisterRider extends StatefulWidget {
  const RegisterRider({super.key});

  @override
  State<RegisterRider> createState() => _RegisterRiderState();
}

class _RegisterRiderState extends State<RegisterRider> {
  String txt = '';
  TextEditingController phoneCtl = TextEditingController();
  TextEditingController nameCtl = TextEditingController();
  TextEditingController passwordCtl = TextEditingController();
  TextEditingController conPassCtl = TextEditingController();
  TextEditingController licenseCtl = TextEditingController();
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
      body: Stack(
        children: [
          // รูปพื้นหลัง
          Positioned.fill(
            child: Image.asset(
              'assets/images/BG_delivery_register.png', // ลิงค์ของรูปพื้นหลัง
              fit: BoxFit.cover,
              // ปรับให้รูปภาพครอบคลุมพื้นที่ทั้งหมด
            ),
          ),
          // เนื้อหาของหน้า
          Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0, bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 30,
                            color: Color.fromARGB(255, 79, 78, 78),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Image.network(
                          'https://static-00.iconduck.com/assets.00/person-add-icon-512x512-qnly9xgp.png',
                          width: 60, // กำหนดความกว้างของรูปภาพ
                          height: 60, // กำหนดความสูงของรูปภาพ
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: registerUser,
                                style: ButtonStyle(
                                  foregroundColor: WidgetStateProperty.all(
                                    Color.fromARGB(255, 139, 15, 188),
                                  ),
                                ),
                                child: const Text(
                                  'User',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400),
                                ),
                              ),
                              SizedBox(width: 50),
                              TextButton(
                                onPressed: () {},
                                style: ButtonStyle(
                                  foregroundColor: WidgetStateProperty.all(
                                    Color.fromARGB(255, 139, 15, 188),
                                  ),
                                ),
                                child: const Text(
                                  'Rider',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 5.0, bottom: 16.0),
                          child: TextField(
                            controller: phoneCtl,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Color.fromARGB(255, 228, 225, 225),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide(width: 1),
                              ),
                              prefixIcon: Icon(Icons.phone),
                              hintText: 'Phone Number',
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 8.0, bottom: 16.0),
                          child: TextField(
                            controller: nameCtl,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Color.fromARGB(255, 228, 225, 225),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide(width: 1),
                              ),
                              prefixIcon: Icon(Icons.person),
                              hintText: 'Username',
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 8.0, bottom: 16.0),
                          child: TextField(
                            obscureText: true,
                            controller: passwordCtl,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Color.fromARGB(255, 228, 225, 225),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide(width: 1),
                              ),
                              prefixIcon: Icon(Icons.lock),
                              hintText: 'Password',
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 8.0, bottom: 16.0),
                          child: TextField(
                            obscureText: true,
                            controller: conPassCtl,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Color.fromARGB(255, 228, 225, 225),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide(width: 1),
                              ),
                              prefixIcon: Icon(Icons.lock),
                              hintText: 'Confirm Password',
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 8.0, bottom: 16.0),
                          child: TextField(
                            controller: licenseCtl,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Color.fromARGB(255, 228, 225, 225),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide(width: 1),
                              ),
                              prefixIcon: Icon(Icons.motorcycle),
                              hintText: 'License Plate',
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 290,
                              height: 50,
                              child: FilledButton(
                                onPressed: register,
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.all(
                                    Color.fromARGB(255, 111, 9, 152),
                                  ),
                                  foregroundColor:
                                      WidgetStateProperty.all(Colors.white),
                                ),
                                child: const Text(
                                  'Create Account',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400),
                                ),
                              ),
                            )
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('If you have an account'),
                              TextButton(
                                onPressed: login,
                                style: ButtonStyle(
                                  foregroundColor: WidgetStateProperty.all(
                                    const Color.fromARGB(255, 255, 222, 78),
                                  ),
                                ),
                                child: const Text(
                                  'Sign in',
                                  style: TextStyle(fontWeight: FontWeight.w400),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 80.0),
                    child: Text(
                      txt,
                      style: TextStyle(color: Color.fromARGB(255, 223, 7, 7)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void register() async {
    if (phoneCtl.text.isEmpty ||
        nameCtl.text.isEmpty ||
        passwordCtl.text.isEmpty ||
        conPassCtl.text.isEmpty ||
        licenseCtl.text.isEmpty ||
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

    // if (walletCtl.text.isEmpty) {
    //   walletCtl.text = "1000";
    // }

    var model = UserRegisterPostRequest(
        phone: phoneCtl.text,
        name: nameCtl.text,
        password: passwordCtl.text,
        address: null,
        user_type: "rider",
        license_plate: licenseCtl.text,
        user_image:
            'http://202.28.34.197:8888/contents/4a00cead-afb3-45db-a37a-c8bebe08fe0d.png');

    var Value = await http.post(Uri.parse("$url/db/register/user"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: UserRegisterPostRequestToJson(model));

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

  void registerUser() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RegisterUser(),
        ));
  }

  void login() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ));
  }
}
