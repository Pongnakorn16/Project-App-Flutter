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
import 'package:mobile_miniproject_app/models/request/user_regis_post_req.dart';
import 'package:mobile_miniproject_app/pages/Login.dart';
import 'package:mobile_miniproject_app/pages/Home_Send.dart';
import 'package:mobile_miniproject_app/pages/Register_Rider.dart';

class RegisterUser extends StatefulWidget {
  const RegisterUser({super.key});

  @override
  State<RegisterUser> createState() => _RegisterUserState();
}

class _RegisterUserState extends State<RegisterUser> {
  String txt = '';
  LatLng? selectedLocation;
  LatLng? currentLocation;
  MapController mapController = MapController();
  TextEditingController phoneCtl = TextEditingController();
  TextEditingController nameCtl = TextEditingController();
  TextEditingController passwordCtl = TextEditingController();
  TextEditingController conPassCtl = TextEditingController();
  TextEditingController addressCtl = TextEditingController();
  String url = '';
  GetStorage gs = GetStorage();
  late LatLng coor;

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
                        Text(
                          'Create "User" Account',
                          style: TextStyle(
                            fontSize: 28,
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
                                onPressed: () {},
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
                                onPressed: registerRider,
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
                            controller: addressCtl,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Color.fromARGB(255, 228, 225, 225),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide(width: 1),
                              ),
                              prefixIcon:
                                  Icon(Icons.location_on), // ไอคอนด้านหน้า
                              hintText: 'Address',
                              suffixIcon: IconButton(
                                icon: Icon(Icons.map), // ไอคอนแผนที่ด้านท้าย
                                onPressed: () {
                                  // เรียกฟังก์ชันแผนที่เมื่อกดไอคอนนี้
                                  showMapDialog();
                                },
                              ),
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
    if (phoneCtl.text.isEmpty ||
        nameCtl.text.isEmpty ||
        passwordCtl.text.isEmpty ||
        conPassCtl.text.isEmpty ||
        addressCtl.text.isEmpty ||
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

    // LatLng coor = await getCoordinatesFromAddress(addressCtl);

    try {
      List<Location> locations = await locationFromAddress(addressCtl.text);
      coor = LatLng(locations.first.latitude, locations.first.longitude);
      log("${coor.latitude},${coor.longitude}");
    } catch (e) {
      print('Error occurred while fetching coordinates: $e');
      coor = LatLng(0, 0); // ค่าพื้นฐานเมื่อเกิดข้อผิดพลาด
    }

    var model = UserRegisterPostRequest(
        phone: phoneCtl.text,
        name: nameCtl.text,
        password: passwordCtl.text,
        address: addressCtl.text,
        coordinate: "${coor.latitude},${coor.longitude}",
        user_type: "user",
        license_plate: null,
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
            msg: "หมายเลขโทรศัพท์นี้เป็นสมาชิกแล้ว!!!",
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

  void registerRider() {
    Get.to(() => const RegisterRider());
  }

  void login() {
    gs.remove('Phone');
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

  void showMapDialog() async {
    await _getCurrentLocation();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 400,
                width: double.infinity,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        // ใช้ตำแหน่งปัจจุบันถ้ามี ถ้าไม่มีใช้ค่าเริ่มต้น
                        initialCenter:
                            currentLocation ?? LatLng(13.7563, 100.5018),
                        initialZoom: 15.0,
                        onTap: (tapPosition, latLng) async {
                          setState(() {
                            selectedLocation = latLng;
                            coor = latLng;
                          });

                          try {
                            List<Placemark> placemarks =
                                await placemarkFromCoordinates(
                              latLng.latitude,
                              latLng.longitude,
                            );
                            if (placemarks.isNotEmpty) {
                              Placemark place = placemarks[0];
                              String address =
                                  "${place.street ?? ''} ${place.subLocality ?? ''} ";
                              setState(() {
                                addressCtl.text = address.trim();
                              });
                            }
                          } catch (e) {
                            print('Error getting address: $e');
                          }

                          Navigator.of(context).pop();
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
                          maxNativeZoom: 19,
                        ),
                        MarkerLayer(
                          markers: [
                            if (selectedLocation != null)
                              Marker(
                                point: selectedLocation!,
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'แตะที่แผนที่เพื่อเลือกตำแหน่ง',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // เพิ่มปุ่มกลับไปยังตำแหน่งปัจจุบัน
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton(
                        mini: true,
                        onPressed: () async {
                          // เรียกดึงตำแหน่งปัจจุบันใหม่
                          await _getCurrentLocation();
                          if (currentLocation != null) {
                            mapController.move(currentLocation!, 15.0);
                            // บังคับให้ rebuild widget เพื่ออัพเดท marker
                            setState(() {});
                          }
                        },
                        child: Icon(Icons.my_location),
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('ยกเลิก'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
