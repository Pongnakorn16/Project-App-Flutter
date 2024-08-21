import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/request/customers_login_post_req.dart';
import 'package:mobile_miniproject_app/models/response/customersLoginPostRes.dart';
import 'package:mobile_miniproject_app/pages/login.dart';
import 'package:mobile_miniproject_app/pages/register_practice.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_miniproject_app/pages/showtrip.dart';
import 'package:mobile_miniproject_app/pages/showtrip_practice.dart';

class LoginPage_practice extends StatefulWidget {
  const LoginPage_practice({super.key});

  @override
  State<LoginPage_practice> createState() => _LoginPage_practiceState();
}

class _LoginPage_practiceState extends State<LoginPage_practice> {
  String text = '';
  int count = 0;
  String phoneNo = '', txt = '';
  TextEditingController phoneCtl = TextEditingController();
  TextEditingController passCtl = TextEditingController();
  String url = '';
  //1. Function ที่ทำงานครั้งเดียว เมื่อเปิดหน้านั้น
  //2. มัร

  @override
  void initState() {
    super.initState();
    Configuration.getConfig().then((value) {
      url = value['apiEndpoint'];
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onDoubleTap: () {
                log('Image double tap');
              },
              child: Image.asset('assets/images/logo.png'),
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'หมายเลขโทรศัพท์',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 119, 24, 141),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: TextField(
                      // onChanged: (value) {
                      //   log(value);
                      //   phoneNo = value;
                      // },
                      controller: phoneCtl,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                            borderSide: BorderSide(width: 1)),
                      ),
                    ),
                  ),
                  const Text(
                    'รหัสผ่าน',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 131, 26, 141),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: TextField(
                      obscureText: true,
                      controller: passCtl,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                            borderSide: BorderSide(width: 1)),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: register,
                        child: const Text('ลงทะเบียนใหม่'),
                      ),
                      FilledButton(
                        onPressed: login,
                        child: const Text('เข้าสู่ระบบ'),
                      ),
                    ],
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
    );
  }

  void login() async {
    var data = {"phone": "0817399999", "password": "1111"};
    //Create Model Object
    var model =
        CustomersLoginPostRequest(phone: phoneCtl.text, password: passCtl.text);
    try {
      var Value = await http.post(Uri.parse("$url/customers/login"),
          headers: {"Content-Type": "application/json; charset=utf-8"},
          //jsonEncode() = Convert object to Json String
          // body: jsonEncode(data))
          body: customersLoginPostRequestToJson(model));
      var cust = customersLoginPostResponseFromJson(Value.body);
      log(cust.customer.image);
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShowtripPracticePage(idx: cust.customer.idx),
          ));
    } catch (err) {
      log(err.toString());
      setState(() {
        txt = "Invalid PhoneNumber Or Password!!!";
      });

      setState(() {});
    }

    // void login() {
    //   var data = {"phone": "0817399999", "password": "1111"};
    //   //Create Model Object
    //   var model =
    //       CustomersLoginPostRequest(phone: phoneCtl.text, password: passCtl.text);
    //   http
    //       .post(Uri.parse("http://10.160.70.61:3000/customers/login"),
    //           headers: {"Content-Type": "application/json; charset=utf-8"},
    //           //jsonEncode() = Convert object to Json String
    //           // body: jsonEncode(data))
    //           body: customersLoginPostRequestToJson(model))
    //       .then(
    //     (value) {
    //       //jsonDecode() = Convert Json String to Object (Map)
    //       // var jsonObj = jsonDecode(value.body);
    //       // log(jsonObj['customer']['email']);
    //       var cus = customersLoginPostResponseFromJson(value.body);
    //       log(cus.customer.image);
    //       Navigator.push(
    //           context,
    //           MaterialPageRoute(
    //             builder: (context) => const ShowtripPracticePage(),
    //           ));
    //     },
    //   ).catchError((err) {
    //     log(err.toString());
    //     setState(() {
    //       txt = "Invalid PhoneNumber Or Password!!!";
    //     });
    //   });

    // http.get(Uri.parse("http://10.160.70.61:3000/customers"))
    // .then(
    //   (value) {
    //     log(value.body);
    //   },
    // ).catchError((err) {
    //   log(err.toString());
    // });

    // if (phoneCtl.text == '0812345678' && passCtl.text == '1234') {
    //   Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //         builder: (context) => const ShowtripPracticePage(),
    //       ));
    // } else {
    //   setState(() {
    //     txt = "Invalid PhoneNumber Or Password!!!";
    //   });
    //   log("Invalid PhoneNumber Or Password!!!");
    // }

    // if (model.phone == '0817399999' && model.password == '1111') {
    //   Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //         builder: (context) => const ShowtripPracticePage(),
    //       ));
    // } else {
    //   setState(() {
    //     txt = "Invalid PhoneNumber Or Password!!!";
    //   });
    //   log("Invalid PhoneNumber Or Password!!!");
    // }

    // log(phoneCtl.text);
    // Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //       builder: (context) => const ShowtripPage(),
    //     ));
    // log('This login button');
    // setState(() {
    //   count++;
    //   text = 'Login Time: $count';
    // });
  }

  void register() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RegisterPracticePage(),
        ));
  }
}
