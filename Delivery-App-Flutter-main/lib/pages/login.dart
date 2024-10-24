import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/request/user_login_post_req.dart';
import 'package:mobile_miniproject_app/models/response/UserLoginPostRes.dart';
import 'package:mobile_miniproject_app/pages/Home.dart';
import 'package:mobile_miniproject_app/pages/Register_User.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_miniproject_app/pages/Home_Send.dart';
import 'package:mobile_miniproject_app/pages/RiderHome.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var model;
  GetStorage gs = GetStorage();
  String text = '';
  int count = 0;
  String phoneNo = '', txt = '';
  TextEditingController PhoneCtl = TextEditingController();
  TextEditingController PasswordCtl = TextEditingController();
  String url = '';

  @override
  void initState() {
    super.initState();
    Configuration.getConfig().then((value) {
      setState(() {
        url = value['apiEndpoint'];
        log("API Endpoint: $url"); // ตรวจสอบค่า URL หลังจากตั้งค่าเสร็จ
        print(gs.read('Phone'));
        print(gs.read('Password'));

        if (gs.read('Phone') != null) {
          login();
        }
      });
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // รูปพื้นหลัง
          Positioned.fill(
            child: Image.asset(
              'assets/images/BG_delivery_login.png', // ลิงค์ของรูปพื้นหลัง
              fit: BoxFit.cover,
              // ปรับให้รูปภาพครอบคลุมพื้นที่ทั้งหมด
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: const Text(
                    'Log in',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 52, 51, 52),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: const Text(
                    'By signing in you are agreeing \n our Term and privacy policy',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color.fromARGB(255, 52, 51, 52),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                        child: TextField(
                          controller: PhoneCtl,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Color.fromARGB(255, 228, 225, 225),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide(width: 1),
                            ),
                            prefixIcon: Icon(
                                Icons.phone), // ใส่ไอคอนโทรศัพท์ที่ด้านซ้าย
                            hintText: 'Phone Number', // ใส่ placeholder
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 40.0, bottom: 16.0),
                        child: TextField(
                          controller: PasswordCtl,
                          obscureText: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Color.fromARGB(255, 228, 225, 225),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide(width: 1),
                            ),
                            prefixIcon:
                                Icon(Icons.lock), // ใส่ไอคอนโทรศัพท์ที่ด้านซ้าย
                            hintText: 'Password', // ใส่ placeholder
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: SizedBox(
                              width: 300,
                              height: 50,
                              child: FilledButton(
                                onPressed: () {
                                  gs.write('Phone', PhoneCtl.text);
                                  gs.write('Password', PasswordCtl.text);
                                  print(gs.read('Phone'));
                                  print(gs.read('Password'));
                                  login();
                                },
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.all(
                                      Color.fromARGB(255, 228, 217, 163)),
                                  foregroundColor:
                                      WidgetStateProperty.all(Colors.white),
                                ),
                                child: const Text(
                                  'Log in',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 90),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Do not have an account?'),
                            TextButton(
                              onPressed: register,
                              style: ButtonStyle(
                                // สีพื้นหลังของปุ่ม
                                foregroundColor: WidgetStateProperty.all(
                                    Color.fromARGB(255, 139, 15, 188)),
                              ),
                              child: const Text(
                                'Register Now',
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
        ],
      ),
    );
  }

  void login() async {
    log("API Endpoint: $url");
    String phone = gs.read('Phone');
    String password = gs.read('Password');
    log(phone);
    log(password);

    log("xxxxxxx");
    model = UserLoginPostRequest(Phone: phone, Password: password);

    try {
      var Value = await http.post(Uri.parse("$url/db/users/login"),
          headers: {"Content-Type": "application/json; charset=utf-8"},
          body: UserLoginPostRequestToJson(model));
      log(Value.body); // Log the raw response body

      List<dynamic> jsonResponse = json.decode(Value.body);
      var res = UserLoginPostResponse.fromJson(jsonResponse.first);
      User_Info_Send User = User_Info_Send();
      User.uid = res.uid;
      User.name = res.name;
      User.user_type = res.user_type;
      User.user_image = res.user_image;

      ///เดี๋ยวมาเพิ่มทีหลัง

      context.read<ShareData>().user_info_send = User;

      if (res.user_type == 'rider') {
        log("Admin User Logged In");
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RiderHomePage(),
            ));
      } else {
        // นำไปยังหน้า HomePage ตามปกติ
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(),
            ));
      }
    } catch (err) {
      log(err.toString());
      setState(() {
        Fluttertoast.showToast(
            msg:
                "เบอร์โทรศํพท์ หรือ รหัสผ่าน ไม่ถูกต้องโปรดตรวจสอบความถูกต้อง แล้วลองอีกครั้ง",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            // backgroundColor: Color.fromARGB(120, 0, 0, 0),
            backgroundColor: Color.fromARGB(255, 255, 0, 0),
            textColor: Colors.white,
            fontSize: 15.0);
      });

      setState(() {});
    }
  }

  void register() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RegisterUser(),
        ));
  }
}
