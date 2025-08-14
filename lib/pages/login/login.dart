import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/request/user_login_post_req.dart';
import 'package:mobile_miniproject_app/models/response/GoogleLoginUser.dart';
import 'package:mobile_miniproject_app/models/response/UserLoginPostRes.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerHome.dart';
import 'package:mobile_miniproject_app/pages/Home.dart';
import 'package:mobile_miniproject_app/pages/register/Register_Customer.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_miniproject_app/pages/Home_Send.dart';
import 'package:mobile_miniproject_app/pages/restaurant/RestaurantHome.dart';
import 'package:mobile_miniproject_app/pages/rider/RiderHome.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  TextEditingController EmailCtl = TextEditingController();
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
                          controller: EmailCtl,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Color.fromARGB(255, 228, 225, 225),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide(width: 1),
                            ),
                            prefixIcon: Icon(
                                Icons.email), // ใส่ไอคอนโทรศัพท์ที่ด้านซ้าย
                            hintText: 'Email', // ใส่ placeholder
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
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 40),
                                child: SizedBox(
                                  width: 300,
                                  height: 50,
                                  child: FilledButton(
                                    onPressed: () {
                                      gs.write('Email', EmailCtl.text);
                                      gs.write('Password', PasswordCtl.text);
                                      print(gs.read('Email'));
                                      print(gs.read('Password'));
                                      login();
                                    },
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(
                                          Color.fromRGBO(251, 215, 88, 1.0)),
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
                              const SizedBox(
                                  height: 20), // เพิ่มระยะห่างระหว่างปุ่ม
                              SizedBox(
                                width: 300,
                                height: 50,
                                child: FilledButton(
                                  onPressed: signInWithGoogle_Check,
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.all(
                                        Color.fromRGBO(66, 133, 244, 1.0)),
                                    foregroundColor:
                                        WidgetStateProperty.all(Colors.white),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.login,
                                          size: 24, color: Colors.white),
                                      SizedBox(width: 10),
                                      Text(
                                        'Login with Google',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w400),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
                                foregroundColor:
                                    WidgetStateProperty.all(Color(0xFF562364)),
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

    String email = gs.read('Email');
    String password = gs.read('Password');
    log(email);
    log(password);

    // เช็คว่ากรอกครบหรือยัง
    if (EmailCtl.text.isEmpty || PasswordCtl.text.isEmpty) {
      Fluttertoast.showToast(
          msg: "กรุณากรอกอีเมลและรหัสผ่าน",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Color.fromARGB(255, 255, 0, 0),
          textColor: Colors.white,
          fontSize: 15.0);
      return; // ต้อง return เพื่อไม่ให้ทำต่อ
    }

    log("xxxxxxx");

    // สร้างโมเดลข้อมูล login
    var model = UserLoginPostRequest(Email: email, Password: password);

    try {
      var response = await http.post(
        Uri.parse("$url/db/users/login"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: UserLoginPostRequestToJson(model),
      );
      log("SPIDERMAN");
      log(response.body); // log ข้อมูลที่ได้จาก API
      log("Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        var res = UserLoginPostResponse.fromJson(jsonResponse);
        log(res.id.toString() + "ASASASDDDDDDDDDDDDDDDDDDDDD");

        // เก็บข้อมูลผู้ใช้ลงใน ShareData
        User_Info_Send User = User_Info_Send();
        User.uid = res.id;
        User.email = res.email;
        User.name = res.name;
        User.phone = res.phone;
        User.user_image = res.user_image;
        User.balance = res.balance;
        User.active_status = res.active_status;
        User.user_type = res.source_table;

        context.read<ShareData>().user_info_send = User;

        // นำทางตามประเภทผู้ใช้
        if (res.source_table == 'rider') {
          log("Rider User Logged In");
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RiderHomePage()),
          );
        } else if (res.source_table == 'restaurant') {
          log("Restaurant User Logged In");
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RestaurantHomePage()),
          );
        } else if (res.source_table == 'customer') {
          log("Customer User Logged In");
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CustomerHomePage()),
          );
        } else {
          log("Unknown user type");
          Fluttertoast.showToast(
            msg: "ประเภทผู้ใช้ไม่ถูกต้อง",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      } else {
        // ถ้า status ไม่ใช่ 200 แสดงว่า login fail
        Fluttertoast.showToast(
            msg: "อีเมล หรือ รหัสผ่านไม่ถูกต้อง โปรดลองใหม่อีกครั้ง",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Color.fromARGB(255, 255, 0, 0),
            textColor: Colors.white,
            fontSize: 15.0);
      }
    } catch (err) {
      log("Login Failed:");
      log(err.toString());
      Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาด โปรดลองใหม่",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Color.fromARGB(255, 255, 0, 0),
          textColor: Colors.white,
          fontSize: 15.0);
    }
  }

  void register() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RegisterCustomer(),
        ));
  }

  void signInWithGoogle_Check() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        Fluttertoast.showToast(msg: "ผู้ใช้ยกเลิกการล็อกอิน");
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;

      if (user != null) {
        var google_model = GoogleLoginUser(
            email: user.email.toString(),
            displayName: user.displayName.toString(),
            photoUrl: user.photoURL.toString());

        try {
          var response = await http.post(
            Uri.parse("$url/db/google_login_check"),
            headers: {"Content-Type": "application/json; charset=utf-8"},
            body: GoogleLoginUserToJson(google_model),
          );

          log(response.body);
          log("Status Code: ${response.statusCode}");

          if (response.statusCode == 200) {
            var data = jsonDecode(response.body);

            if (data['status'] == 'exist') {
              // login สำเร็จ เข้าใช้งานได้เลย
              // ย้ายไปหน้า home หรืออื่น ๆ ได้เลย

              Map<String, dynamic> jsonResponse = json.decode(response.body);
              var res = UserLoginPostResponse.fromJson(jsonResponse);
              log(res.id.toString() + "ASASASDDDDDDDDDDDDDDDDDDDDD");
              User_Info_Send User = User_Info_Send();
              User.uid = res.id;
              User.email = res.email;
              User.name = res.name;
              User.phone = res.phone;
              User.user_image = res.user_image;
              User.balance = res.balance;
              User.active_status = res.active_status;
              User.user_type = res.source_table;

              context.read<ShareData>().user_info_send = User;
              Fluttertoast.showToast(msg: "ล็อกอินด้วย Google สำเร็จ");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CustomerHomePage()),
              );
              log("Login OK - User exists");
              Fluttertoast.showToast(msg: "เข้าสู่ระบบสำเร็จ");
              // ทำอย่างอื่นต่อ เช่นไปหน้า Home
            } else if (data['status'] == 'new') {
              // กรณี user ใหม่ ต้องเลือกประเภท
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(
                      'เนื่องจากใช้บัญชี Google นี้ login เป็นครั้งแรก กรุณาเลือกประเภทผู้ใช้',
                      style: TextStyle(
                        fontSize: 15, // ใส่ขนาดที่ต้องการ
                        fontWeight: FontWeight.bold, // ใส่หรือไม่ใส่ก็ได้
                      ),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            GoogleRegister(google_model, 'customer');
                          },
                          child: Text('ลูกค้า'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            GoogleRegister(google_model, 'restaurant');
                          },
                          child: Text('ร้านอาหาร'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            GoogleRegister(google_model, 'rider');
                          },
                          child: Text('ไรเดอร์'),
                        ),
                      ],
                    ),
                  );
                },
              );
            } else {
              Fluttertoast.showToast(
                  msg: "เกิดข้อผิดพลาด ไม่สามารถเข้าสู่ระบบได้",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  backgroundColor: Colors.red,
                  textColor: Colors.white);
            }
          } else {
            Fluttertoast.showToast(
              msg: "อีเมล หรือ รหัสผ่านไม่ถูกต้อง โปรดลองใหม่อีกครั้ง",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
          }
        } catch (err) {
          log("Login Failed:");
          log(err.toString());
          Fluttertoast.showToast(
            msg: "เกิดข้อผิดพลาด โปรดลองใหม่",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }

        // คุณสามารถเก็บข้อมูลผู้ใช้ไว้ใน ShareData หรือดึงข้อมูลเพิ่มจาก backend ได้ที่นี่
        log("${user.displayName}");
        log("${user.email}");
      }
    } catch (e) {
      log(e.toString());
      Fluttertoast.showToast(
        msg: "เกิดข้อผิดพลาด: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  void GoogleRegister(GoogleLoginUser googleModel, String role) async {
    Map<String, dynamic> registerBody = {
      'email': googleModel.email,
      'displayName': googleModel.displayName,
      'photoUrl': googleModel.photoUrl,
      'role': role,
    };

    try {
      var registerResponse = await http.post(
        Uri.parse("$url/db/google_register"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: jsonEncode(registerBody),
      );
      log("SPIDERMAN");
      log(registerResponse.body);
      log("Status Code: ${registerResponse.statusCode}");

      if (registerResponse.statusCode == 200) {
        Map<String, dynamic> jsonResponse = json.decode(registerResponse.body);
        var res = UserLoginPostResponse.fromJson(jsonResponse);
        log("Parsed ID from model: ${res.id}");
        Fluttertoast.showToast(msg: "สมัครสมาชิกสำเร็จ");
        log(res.id.toString() + "ASASASDDDDDDDDDDDDDDDDDDDDD");
        User_Info_Send User = User_Info_Send();
        User.uid = res.id;
        User.email = res.email;
        User.name = res.name;
        User.phone = res.phone;
        User.user_image = res.user_image;
        User.balance = res.balance;
        User.active_status = res.active_status;
        User.user_type = res.source_table;

        context.read<ShareData>().user_info_send = User;

        // ไปยังหน้าตาม role
        if (role == "customer") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => CustomerHomePage()),
          );
        } else if (role == "restaurant") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => RestaurantHomePage()),
          );
        } else if (role == "rider") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => RiderHomePage()),
          );
        }
      } else {
        Fluttertoast.showToast(msg: "สมัครสมาชิกไม่สำเร็จ");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "เกิดข้อผิดพลาดระหว่างสมัครสมาชิก");
    }
  }
}
