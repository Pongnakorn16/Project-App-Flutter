import 'dart:convert';
import 'dart:developer';
import 'dart:ui';
import 'package:flutter_map/flutter_map.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/request/customer_regis_post_req.dart';
import 'package:mobile_miniproject_app/models/request/rider_regis_post_req.dart';
import 'package:mobile_miniproject_app/models/request/user_regis_post_req.dart';
import 'package:mobile_miniproject_app/pages/login/Login.dart';
import 'package:mobile_miniproject_app/pages/Home_Send.dart';
import 'package:mobile_miniproject_app/pages/register/Register_Customer.dart';
import 'package:mobile_miniproject_app/pages/register/Register_Restaurant.dart';
import 'package:mobile_miniproject_app/pages/register/Register_Rider.dart';

class RegisterRider extends StatefulWidget {
  const RegisterRider({super.key});

  @override
  State<RegisterRider> createState() => _RegisterCustomerState();
}

class _RegisterCustomerState extends State<RegisterRider> {
  String txt = '';
  LatLng? selectedLocation;
  LatLng? currentLocation;
  MapController mapController = MapController();
  TextEditingController nameCtl = TextEditingController();
  TextEditingController EmailCtl = TextEditingController();
  TextEditingController passwordCtl = TextEditingController();
  TextEditingController conPassCtl = TextEditingController();
  TextEditingController phoneCtl = TextEditingController();
  TextEditingController licenseCtl = TextEditingController();

  String url = '';
  GetStorage gs = GetStorage();
  late LatLng coor;
  bool showImage = false;

  @override
  void initState() {
    super.initState();
    //อ่านค่า config
    Configuration.getConfig().then((value) {
      url = value['apiEndpoint'];
    });
    _getCurrentLocation();
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
                        Expanded(
                          // ✅ ป้องกัน overflow
                          child: Text(
                            'Create "Rider" Account',
                            textAlign:
                                TextAlign.center, // ✅ จัดข้อความให้อยู่กึ่งกลาง
                            style: TextStyle(
                              fontSize: 28,
                              color: Color.fromARGB(255, 79, 78, 78),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: ToggleButtons(
                            isSelected: [
                              false,
                              false,
                              true
                            ], // ตั้งค่าเริ่มต้นของปุ่ม
                            onPressed: (index) {
                              if (index == 2) {
                                // ไปที่หน้าลูกค้า
                              } else if (index == 1) {
                                registerRes();
                              } else {
                                registerCus();
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            selectedColor: Colors.white,
                            fillColor: Color.fromARGB(255, 139, 15, 188),
                            color: Colors.black,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('Customer',
                                    style: TextStyle(fontSize: 16)),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('Restaurant',
                                    style: TextStyle(fontSize: 16)),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('Rider',
                                    style: TextStyle(fontSize: 16)),
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
                            controller: EmailCtl,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Color.fromARGB(255, 228, 225, 225),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide(width: 1),
                              ),
                              prefixIcon: Icon(Icons.email_outlined),
                              hintText: 'Email',
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
                              hintText: 'Name',
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
                            controller: phoneCtl,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Color.fromARGB(255, 228, 225, 225),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide(width: 1),
                              ),
                              prefixIcon: Icon(Icons.phone), // ไอคอนด้านหน้า
                              hintText: 'Phone',
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
                              prefixIcon:
                                  Icon(Icons.motorcycle), // ไอคอนด้านหน้า
                              hintText: 'License plate number',
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
    gs.remove('Phone');

    if (EmailCtl.text.isEmpty ||
        phoneCtl.text.isEmpty ||
        nameCtl.text.isEmpty ||
        passwordCtl.text.isEmpty ||
        conPassCtl.text.isEmpty ||
        licenseCtl.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "กรุณากรอกข้อมูลให้ครบถ้วน",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Color.fromARGB(255, 255, 0, 0),
        textColor: Colors.white,
        fontSize: 15.0,
      );
      return;
    }

    if (!EmailCtl.text.contains('@')) {
      Fluttertoast.showToast(
        msg: "ใน Email ต้องมี @ กรอกแล้วลองใหม่อีกครั้ง",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Color.fromARGB(255, 255, 0, 0),
        textColor: Colors.white,
        fontSize: 15.0,
      );
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(phoneCtl.text)) {
      Fluttertoast.showToast(
        msg: "เบอร์โทรศัพท์ต้องเป็นตัวเลขเท่านั้น",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Color.fromARGB(255, 255, 0, 0),
        textColor: Colors.white,
        fontSize: 15.0,
      );
      return;
    }

    if (passwordCtl.text != conPassCtl.text) {
      Fluttertoast.showToast(
        msg: "รหัสผ่านทั้งสองช่องไม่ตรงกัน",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Color.fromARGB(255, 255, 0, 0),
        textColor: Colors.white,
        fontSize: 15.0,
      );
      return;
    }

    var model = RiderPostRequest(
        rid_phone: phoneCtl.text,
        rid_name: nameCtl.text,
        rid_password: passwordCtl.text,
        rid_email: EmailCtl.text,
        rid_license: licenseCtl.text);

    var Value = await http.post(Uri.parse("$url/db/register/rider"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: RiderPostRequestToJson(model));

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
            msg: "อีเมลนี้เป็นสมาชิกแล้ว!!!",
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

  void registerCus() {
    Get.to(() => const RegisterCustomer());
  }

  void registerRes() {
    Get.to(() => const RegisterRestaurant());
  }

  void login() {
    gs.remove('Email');
    Get.to(() => const LoginPage());
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(
          msg: "ไม่สามารถใช้งาน GPS ได้ กรุณาอนุญาตการใช้งานตำแหน่ง",
          backgroundColor: Colors.red,
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
        msg: "กรุณาเปิดการใช้งานตำแหน่งในการตั้งค่า",
        backgroundColor: Colors.red,
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // ใช้ mounted check ก่อนเรียก setState
      if (!mounted) return;

      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        // อัพเดท selectedLocation ด้วยถ้ายังไม่มีการเลือกตำแหน่ง
        if (selectedLocation == null) {
          selectedLocation = currentLocation;
        }
      });
    } catch (e) {
      print('Error getting current location: $e');
      if (!mounted) return;

      Fluttertoast.showToast(
        msg: "ไม่สามารถดึงตำแหน่งปัจจุบันได้ กรุณาตรวจสอบการเชื่อมต่อ GPS",
        backgroundColor: Colors.red,
      );
    }
  }
}
