import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/request/Cus_pro_edit_post_req.dart';
import 'package:mobile_miniproject_app/models/request/Res_pro_edit_post_req.dart';
import 'package:mobile_miniproject_app/models/request/user_edit_post_req.dart';
import 'package:mobile_miniproject_app/models/response/CusAddressGetRes.dart';
import 'package:mobile_miniproject_app/models/response/CusInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/GetUserSearch_Res.dart';
import 'package:mobile_miniproject_app/models/response/ResProfileGetRes.dart';
import 'package:mobile_miniproject_app/pages/Add_Item.dart';
import 'package:mobile_miniproject_app/pages/Home.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerHome.dart';
import 'package:mobile_miniproject_app/pages/login/Login.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ResProfilePage extends StatefulWidget {
  int uid = 0;
  String username = '';
  int selectedIndex = 0;
  int cart_length = 0;
  final VoidCallback onClose;

  ResProfilePage({
    super.key,
    required this.onClose,
    required this.selectedIndex,
  });

  @override
  State<ResProfilePage> createState() => _HomePageState();
}

class _HomePageState extends State<ResProfilePage> {
  late PageController _pageController;
  int uid = 0;
  int wallet = 0;
  TextEditingController phoneCtl = TextEditingController();
  TextEditingController nameCtl = TextEditingController();
  TextEditingController passwordCtl = TextEditingController();
  TextEditingController conPassCtl = TextEditingController();
  TextEditingController addressCtl = TextEditingController();
  TextEditingController desCtl = TextEditingController();
  TextEditingController opentimeCtl = TextEditingController();
  TextEditingController closetimeCtl = TextEditingController();
  LatLng? selectedCoordinate;
  String old_image = '';

  String send_user_name = '';
  String send_user_type = '';
  String send_user_image = '';
  String username = '';
  int cart_length = 0;
  GetStorage gs = GetStorage();
  TextEditingController imageCtl = TextEditingController();
  late LatLng coor;
  ResProfileGetResponse res_Info = ResProfileGetResponse();
  late Future<void> loadData;
  bool isLoading = false;
  String address = '';
  String detail = '';
  int ca_id_check = 0;
  CusAddressGetResponse? cusAddr;
  var localCusAddr;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    uid = context.read<ShareData>().user_info_send.uid;
    send_user_name = context.read<ShareData>().user_info_send.name;
    send_user_type = context.read<ShareData>().user_info_send.user_type;
    send_user_image = context.read<ShareData>().user_info_send.user_image;
    // log(widget.uid.toString());
    context.read<ShareData>().selected_index = widget.selectedIndex;
    loadData = loadProfileData();
    _pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset: false,
          body: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Stack(
              children: [
                // รูปพื้นหลัง
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/BG_delivery_profile.png', // ลิงค์ของรูปพื้นหลัง
                    fit: BoxFit.cover,
                  ),
                ),
                // เพิ่ม Padding เพื่อไม่ให้รูปภาพชนกับขอบ
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 80.0, bottom: 30.0),
                        child: GestureDetector(
                          onTap: () {
                            uploadProfileImage();
                          },
                          child: Stack(
                            children: [
                              ClipOval(
                                child: Image.network(
                                  (res_Info.res_image != null &&
                                          res_Info.res_image.isNotEmpty)
                                      ? res_Info.res_image
                                      : 'https://th.bing.com/th/id/R.db989291b2539b817e46ad20d4947c36?rik=5AQ%2b6OG1VA05yg&riu=http%3a%2f%2fgetdrawings.com%2ffree-icon%2fcool-profile-icons-70.png&ehk=qe8q701EM70pD%2b3qlduqUPsiVZbx8Uqjo%2fE5hU%2f9G%2fc%3d&risl=&pid=ImgRaw&r=0',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // เพิ่ม Padding รอบ ๆ ฟิลด์กรอกข้อมูล
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            TextField(
                              controller: phoneCtl,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Color.fromARGB(255, 228, 225, 225),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(width: 1),
                                ),
                                prefixIcon: Icon(Icons.phone),
                                hintText: res_Info.res_phone.isNotEmpty
                                    ? res_Info.res_phone
                                    : 'เพิ่มเบอร์โทร',
                              ),
                            ),
                            SizedBox(height: 15.0), // เพิ่มระยะห่างระหว่างฟิลด์
                            TextField(
                              controller: nameCtl,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Color.fromARGB(255, 228, 225, 225),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(width: 1),
                                ),
                                prefixIcon: Icon(Icons.person),
                                hintText: res_Info.res_name.isNotEmpty
                                    ? res_Info.res_name
                                    : '',
                              ),
                            ),
                            SizedBox(height: 15.0), // เพิ่มระยะห่างระหว่างฟิลด์
                            TextField(
                              obscureText: true,
                              controller: passwordCtl,
                              enabled: res_Info.res_password
                                  .isNotEmpty, // ถ้า password ว่าง จะ disable field
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Color.fromARGB(255, 228, 225, 225),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(width: 1),
                                ),
                                prefixIcon: Icon(Icons.lock),
                                hintText: res_Info.res_password.isNotEmpty
                                    ? '' // ถ้ามี password ก็ไม่ต้องแสดง hint
                                    : 'เข้าสู่ระบบด้วย Google แก้ไขไม่ได้',
                              ),
                            ),

                            SizedBox(height: 15.0), // เพิ่มระยะห่างระหว่างฟิลด์
                            TextField(
                              obscureText: true,
                              controller: conPassCtl,
                              enabled: res_Info.res_password.isNotEmpty,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Color.fromARGB(255, 228, 225, 225),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(width: 1),
                                ),
                                prefixIcon: Icon(Icons.lock),
                                hintText: res_Info.res_password.isNotEmpty
                                    ? ''
                                    : 'เข้าสู่ระบบด้วย Google แก้ไขไม่ได้', // ทำให้ hintText ว่างไปเลย
                              ),
                            ),

                            SizedBox(height: 15.0), // เพิ่มระยะห่างระหว่างฟิลด์
                            TextField(
                              controller: desCtl,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Color.fromARGB(255, 228, 225, 225),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(width: 1),
                                ),
                                prefixIcon: Icon(Icons.description),
                                hintText: res_Info.res_description.isNotEmpty
                                    ? res_Info.res_description
                                    : 'เพิ่มคำอธิบายร้านอาหาร',
                              ),
                            ),
                            SizedBox(height: 15.0), // เพิ่มระยะห่างระหว่างฟิลด์
                            // TextField สำหรับเวลาเปิดร้าน
                            TextField(
                              controller: opentimeCtl,
                              readOnly: true, // ป้องกันพิมพ์เอง
                              onTap: () async {
                                TimeOfDay? pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );

                                if (pickedTime != null) {
                                  final now = DateTime.now();
                                  final dt = DateTime(
                                      now.year,
                                      now.month,
                                      now.day,
                                      pickedTime.hour,
                                      pickedTime.minute);
                                  // แปลงเป็นรูปแบบ HH:mm:ss
                                  String formattedTime =
                                      DateFormat('HH:mm:ss').format(dt);
                                  opentimeCtl.text = formattedTime;
                                }
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Color.fromARGB(255, 228, 225, 225),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(width: 1),
                                ),
                                prefixIcon: Icon(Icons.timer_rounded),
                                hintText: res_Info.res_opening_time.isNotEmpty
                                    ? res_Info.res_opening_time
                                    : 'เพิ่มเวลาเปิดร้าน',
                              ),
                            ),

                            SizedBox(height: 15.0),

// TextField สำหรับเวลาปิดร้าน
                            TextField(
                              controller: closetimeCtl,
                              readOnly: true,
                              onTap: () async {
                                TimeOfDay? pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );

                                if (pickedTime != null) {
                                  final now = DateTime.now();
                                  final dt = DateTime(
                                      now.year,
                                      now.month,
                                      now.day,
                                      pickedTime.hour,
                                      pickedTime.minute);
                                  String formattedTime =
                                      DateFormat('HH:mm:ss').format(dt);
                                  closetimeCtl.text = formattedTime;
                                }
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Color.fromARGB(255, 228, 225, 225),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(width: 1),
                                ),
                                prefixIcon: Icon(Icons.timer_off_rounded),
                                hintText: res_Info.res_closing_time.isNotEmpty
                                    ? res_Info.res_closing_time
                                    : 'เพิ่มเวลาปิดร้าน',
                              ),
                            ),
                            SizedBox(height: 15.0),
                            TextField(
                              controller: addressCtl,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Color.fromARGB(255, 228, 225, 225),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(width: 1),
                                ),
                                prefixIcon: Icon(Icons.location_on),

                                // 👇 เพิ่มปุ่มแก้ไขที่ท้าย TextField
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () async {
                                    await showMapPickerDialog(context);
                                  },
                                ),

                                hintText: context
                                        .read<ShareData>()
                                        .res_selected_add
                                        .isNotEmpty
                                    ? context.read<ShareData>().res_selected_add
                                    : 'เพิ่มที่อยู่',
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 10),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    FilledButton(
                                      onPressed: () {
                                        if (old_image == res_Info.res_image &&
                                            phoneCtl.text ==
                                                res_Info.res_phone &&
                                            nameCtl.text == res_Info.res_name &&
                                            passwordCtl.text ==
                                                res_Info.res_password &&
                                            conPassCtl.text ==
                                                res_Info.res_password &&
                                            desCtl.text ==
                                                res_Info.res_description &&
                                            opentimeCtl.text ==
                                                res_Info.res_opening_time &&
                                            closetimeCtl.text ==
                                                res_Info.res_closing_time &&
                                            addressCtl.text ==
                                                context
                                                    .read<ShareData>()
                                                    .res_selected_add &&
                                            selectedCoordinate == null) {
                                          Fluttertoast.showToast(
                                            msg: "กรุณาแก้ไขข้อมูลก่อนกดบันทึก",
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.CENTER,
                                            timeInSecForIosWeb: 1,
                                            backgroundColor: Color.fromARGB(
                                                255, 255, 247, 0),
                                            textColor: const Color.fromARGB(
                                                255, 0, 0, 0),
                                            fontSize: 15.0,
                                          );
                                        } else {
                                          updateProfile();
                                        }
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors
                                            .green, // เปลี่ยนสีพื้นหลังของปุ่ม
                                        padding: EdgeInsets.symmetric(
                                            vertical: 10.0,
                                            horizontal:
                                                35.0), // กำหนดขนาดของปุ่ม
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              30.0), // กำหนดรูปแบบมุมปุ่ม
                                        ),
                                      ),
                                      child: Text(
                                        "Save",
                                        style: TextStyle(
                                          color:
                                              Colors.white, // เปลี่ยนสีตัวอักษร
                                          fontSize: 18.0, // ขนาดตัวอักษร
                                        ),
                                      ),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        Get.to(() => LoginPage());
                                        context
                                            .read<ShareData>()
                                            .res_selected_add = '';
                                        context
                                            .read<ShareData>()
                                            .selected_address_index = 0;
                                        context
                                            .read<ShareData>()
                                            .user_info_send = User_Info_Send();
                                        context
                                                .read<ShareData>()
                                                .user_info_receive =
                                            User_Info_Receive();
                                        context
                                            .read<ShareData>()
                                            .customer_addresses = [];
                                        context
                                            .read<ShareData>()
                                            .restaurant_type = [];
                                        context
                                            .read<ShareData>()
                                            .restaurant_near = [];
                                        context
                                            .read<ShareData>()
                                            .restaurant_all = [];
                                        Get.to(() => LoginPage());
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors
                                            .red, // เปลี่ยนสีพื้นหลังของปุ่ม
                                        padding: EdgeInsets.symmetric(
                                            vertical: 10.0,
                                            horizontal:
                                                26.0), // กำหนดขนาดของปุ่ม
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              30.0), // กำหนดรูปแบบมุมปุ่ม
                                        ),
                                      ),
                                      child: Text(
                                        "Logout",
                                        style: TextStyle(
                                          color:
                                              Colors.white, // เปลี่ยนสีตัวอักษร
                                          fontSize: 18.0, // ขนาดตัวอักษร
                                        ),
                                      ),
                                    )
                                  ]),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
        ),
        // 3. Overlay Loader
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  void _onItemTapped(int index) {
    if (index == 2) return;
    if (index == 0) {
      Navigator.pop(context);
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (context) => CustomerHomePage()),
      // );
    } else {
      _pageController.animateToPage(
        index > 2 ? index - 1 : index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<LatLng> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw Exception("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permission denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied.");
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return LatLng(position.latitude, position.longitude);
  }

  Future<void> showMapPickerDialog(BuildContext context) async {
    LatLng? pickedLocation;

    await showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<LatLng>(
          future: getCurrentLocation(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                title: Text('กำลังโหลดตำแหน่ง...'),
                content: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return AlertDialog(
                title: Text('เกิดข้อผิดพลาด'),
                content: Text('ไม่สามารถดึงตำแหน่งได้: ${snapshot.error}'),
              );
            }

            LatLng currentCenter = snapshot.data!;

            return AlertDialog(
              title: Text('เลือกตำแหน่งบนแผนที่'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    // แสดงพิกัดที่เลือก
                    if (pickedLocation != null)
                      Container(
                        padding: EdgeInsets.all(8),
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'พิกัด: ${pickedLocation!.latitude.toStringAsFixed(6)}, ${pickedLocation!.longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    Expanded(
                      child: StatefulBuilder(
                        builder: (context, setState) {
                          return FlutterMap(
                            options: MapOptions(
                              initialCenter: currentCenter,
                              initialZoom: 15,
                              minZoom: 5,
                              maxZoom: 19,
                              onTap: (tapPosition, latlng) {
                                setState(() {
                                  pickedLocation = latlng;
                                });
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png",
                                userAgentPackageName: 'com.example.app',
                              ),
                              // แสดงตำแหน่งปัจจุบัน
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: currentCenter,
                                    width: 30,
                                    height: 30,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: Icon(
                                        Icons.my_location,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // แสดงตำแหน่งที่เลือก
                              if (pickedLocation != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: pickedLocation!,
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
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (pickedLocation != null) {
                      Navigator.pop(context, pickedLocation);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('กรุณาเลือกตำแหน่งก่อน')),
                      );
                    }
                  },
                  child: Text('ตกลง'),
                ),
              ],
            );
          },
        );
      },
    ).then((value) async {
      if (value != null && value is LatLng) {
        try {
          // ✅ บันทึกพิกัดที่เลือกจริง
          selectedCoordinate = value;

          print(
              '📍 Selected exact coordinates: ${value.latitude}, ${value.longitude}');

          List<Placemark> placemarks = await placemarkFromCoordinates(
            value.latitude,
            value.longitude,
            localeIdentifier: 'th_TH',
          );

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            print('🏠 Placemark result: $place');

            List<String> addressParts = [];

            if (place.street != null && place.street!.isNotEmpty) {
              addressParts.add(place.street!);
            }
            if (place.subLocality != null && place.subLocality!.isNotEmpty) {
              addressParts.add(place.subLocality!);
            }
            if (place.locality != null && place.locality!.isNotEmpty) {
              addressParts.add(place.locality!);
            }
            if (place.administrativeArea != null &&
                place.administrativeArea!.isNotEmpty) {
              addressParts.add(place.administrativeArea!);
            }

            final address = addressParts.isNotEmpty
                ? addressParts.join(', ')
                : "${value.latitude.toStringAsFixed(6)}, ${value.longitude.toStringAsFixed(6)}";

            addressCtl.text = address;
            context.read<ShareData>().res_selected_add = address;

            print('📝 Final address: $address');
            print(
                '✅ Exact coordinates stored: ${selectedCoordinate!.latitude}, ${selectedCoordinate!.longitude}');
          } else {
            final coordinateString =
                "${value.latitude.toStringAsFixed(6)}, ${value.longitude.toStringAsFixed(6)}";
            addressCtl.text = coordinateString;
            context.read<ShareData>().res_selected_add = coordinateString;
          }
        } catch (e) {
          print('❌ Error in reverse geocoding: $e');
          final coordinateString =
              "${value.latitude.toStringAsFixed(6)}, ${value.longitude.toStringAsFixed(6)}";
          addressCtl.text = coordinateString;
          context.read<ShareData>().res_selected_add = coordinateString;
        }
      }
    });
  }

  Future<void> loadProfileData() async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];
    int userId = context.read<ShareData>().user_info_send.uid;

    try {
      var res = await http.get(Uri.parse("$url/db/get_ResProfile/$userId"));
      log("Response status: ${res.statusCode}");
      log("Response body: ${res.body}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded != null && decoded.isNotEmpty) {
          res_Info = ResProfileGetResponse.fromJson(decoded[0]);

          String addressText = '';
          if (res_Info != null) {
            if (res_Info.res_coordinate.isNotEmpty) {
              final parts = res_Info.res_coordinate.split(',');
              if (parts.length == 2) {
                final lat = double.tryParse(parts[0].trim());
                final lng = double.tryParse(parts[1].trim());

                if (lat != null && lng != null) {
                  List<Placemark> placemarks =
                      await placemarkFromCoordinates(lat, lng);
                  if (placemarks.isNotEmpty) {
                    final place = placemarks.first;
                    final address =
                        "${place.thoroughfare ?? ''} ${place.subThoroughfare ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}";

                    addressCtl.text = address;
                    context.read<ShareData>().res_selected_add = address;
                  } else {
                    addressCtl.text = res_Info.res_coordinate;
                    context.read<ShareData>().res_selected_add =
                        res_Info.res_coordinate;
                  }
                }
              }
            } else {
              addressCtl.text = res_Info.res_coordinate;
              context.read<ShareData>().res_selected_add =
                  res_Info.res_coordinate;
            }
          }

          if (res_Info != null) {
            phoneCtl.text = res_Info.res_phone;
            nameCtl.text = res_Info.res_name;
            passwordCtl.text = res_Info.res_password;
            conPassCtl.text = res_Info.res_password;
            desCtl.text = res_Info.res_description;
            opentimeCtl.text = res_Info.res_opening_time;
            closetimeCtl.text = res_Info.res_closing_time;
            old_image = res_Info.res_image;

            log("res_Info : " + res_Info.toString());
            log(res_Info.res_name.toString());
            setState(() {});
          }
        } else {
          log("ไม่มีข้อมูลผู้ใช้");
        }
      } else {
        log('โหลดข้อมูลผู้ใช้ไม่สำเร็จ: ${res.statusCode}');
      }
    } catch (e) {
      log("เกิดข้อผิดพลาด: $e");
    }
  }

  void updateProfile() async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    if (passwordCtl.text != conPassCtl.text) {
      Fluttertoast.showToast(
          msg:
              "ข้อมูล Password และ ข้อมูล Confirm Password ไม่ตรงกัน กรุณาลองใหม่",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Color.fromARGB(255, 255, 0, 0),
          textColor: Colors.white,
          fontSize: 15.0);
      return;
    }

    // ... existing validation code ...

    if (phoneCtl.text.isEmpty) {
      if (res_Info.res_phone.isEmpty) {
        Fluttertoast.showToast(
          msg: "กรุณากรอกหมายเลขโทรศัพท์",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Color.fromARGB(255, 255, 0, 0),
          textColor: Colors.white,
          fontSize: 15.0,
        );
        return;
      } else {
        phoneCtl.text = res_Info.res_phone;
      }
    }

    if (nameCtl.text.isEmpty) {
      nameCtl.text = res_Info.res_name;
    }

    if (passwordCtl.text.isEmpty) {
      passwordCtl.text = res_Info.res_password;
    }

    if (conPassCtl.text.isEmpty) {
      conPassCtl.text = res_Info.res_password;
    }

    if (addressCtl.text.isEmpty) {
      if (context.read<ShareData>().res_selected_add.isEmpty) {
        Fluttertoast.showToast(
          msg: "กรุณาเพิ่มที่อยู่",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Color.fromARGB(255, 255, 0, 0),
          textColor: Colors.white,
          fontSize: 15.0,
        );
        return;
      } else {
        addressCtl.text = context.read<ShareData>().res_selected_add.toString();
      }
    }

    // ✅ ใช้พิกัดที่เลือกจริงแทนการแปลงจากที่อยู่
    LatLng coor;

    if (selectedCoordinate != null) {
      // ✅ ใช้พิกัดที่เลือกจากแผนที่โดยตรง
      coor = selectedCoordinate!;
      print(
          '🎯 Using selected coordinate: ${coor.latitude}, ${coor.longitude}');
    } else {
      // ถ้าไม่มีการเลือกใหม่ ให้ใช้พิกัดเดิม
      if (res_Info.res_coordinate.isNotEmpty) {
        final parts = res_Info.res_coordinate.split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null) {
            coor = LatLng(lat, lng);
            print(
                '📍 Using existing coordinate: ${coor.latitude}, ${coor.longitude}');
          } else {
            coor = LatLng(0, 0);
          }
        } else {
          coor = LatLng(0, 0);
        }
      } else {
        // ถ้าไม่มีพิกัดเดิมและไม่ได้เลือกใหม่ ให้แปลงจากที่อยู่
        try {
          List<Location> locations = await locationFromAddress(addressCtl.text);
          coor = LatLng(locations.first.latitude, locations.first.longitude);
          print(
              '🔄 Converted from address: ${coor.latitude}, ${coor.longitude}');
        } catch (e) {
          print('❌ Error occurred while fetching coordinates: $e');
          coor = LatLng(0, 0);
        }
      }
    }

    print('💾 Final coordinate to save: ${coor.latitude}, ${coor.longitude}');

    // สร้าง model สำหรับส่งข้อมูล
    var model = ResProEditPostRequest(
      res_id: res_Info.res_id,
      res_phone: phoneCtl.text == res_Info.res_phone
          ? res_Info.res_phone
          : phoneCtl.text,
      res_name:
          nameCtl.text == res_Info.res_name ? res_Info.res_name : nameCtl.text,
      res_password: passwordCtl.text == res_Info.res_password
          ? res_Info.res_password
          : passwordCtl.text,
      res_image: res_Info.res_image,
      res_description: desCtl.text,
      res_opening_time: opentimeCtl.text,
      res_closing_time: closetimeCtl.text,
      res_coordinate: "${coor.latitude},${coor.longitude}",
    );

    var response = await http.put(
      Uri.parse("$url/db/edit_ResProfile"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: jsonEncode(model),
    );

    print('📡 Response status code: ${response.statusCode}');
    print('📡 Response body: ${response.body}');

    if (response.statusCode == 200) {
      print('✅ Update successful');

      // ✅ รีเซ็ต selectedCoordinate หลังจากบันทึกสำเร็จ
      selectedCoordinate = null;

      Fluttertoast.showToast(
        msg: "แก้ไขข้อมูลสำเร็จแล้ว",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Color.fromARGB(255, 7, 173, 45),
        textColor: Colors.white,
        fontSize: 15.0,
      );
      await loadProfileData();
      setState(() {});
    } else {
      var responseBody = jsonDecode(response.body);
      Fluttertoast.showToast(
        msg: "หมายเลขโทรศัพท์นี้เป็นสมาชิกแล้ว!!!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Color.fromARGB(255, 255, 0, 0),
        textColor: Colors.white,
        fontSize: 15.0,
      );
      log('❌ ${responseBody['error']}');
    }
  }

  Future<void> uploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);

      try {
        setState(() {
          isLoading = true; // เริ่มโหลด
        });

        String fileName =
            'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final ref = FirebaseStorage.instance
            .ref()
            .child('BP_ResProfile_image')
            .child(fileName);

        await ref.putFile(file);
        String downloadURL = await ref.getDownloadURL();

        print('✅ อัปโหลดสำเร็จ: $downloadURL');
        setState(() {
          res_Info.res_image = downloadURL;
          isLoading = false; // โหลดเสร็จ
        });
      } catch (e) {
        print('❌ เกิดข้อผิดพลาดในการอัปโหลด: $e');
        setState(() {
          isLoading = false; // โหลดเสร็จแม้ error
        });
      }
    }
  }
}
