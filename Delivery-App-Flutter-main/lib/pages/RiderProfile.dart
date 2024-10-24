import 'dart:convert';
import 'dart:developer';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/request/user_edit_post_req.dart';
import 'package:mobile_miniproject_app/models/response/GetRiderInfo_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetUserSearch_Res.dart';
import 'package:mobile_miniproject_app/models/response/customers_idx_get_res.dart';
import 'package:mobile_miniproject_app/pages/Add_Item.dart';
import 'package:mobile_miniproject_app/pages/Home.dart';
import 'package:mobile_miniproject_app/pages/Home_Send.dart';
import 'package:mobile_miniproject_app/pages/Login.dart';
import 'package:mobile_miniproject_app/pages/RiderHistory.dart';
import 'package:mobile_miniproject_app/pages/RiderHome.dart';
import 'package:mobile_miniproject_app/pages/Shop.dart';
import 'package:mobile_miniproject_app/pages/Ticket.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';

class RiderProfilePage extends StatefulWidget {
  int uid = 0;
  String username = '';
  int selectedIndex = 0;
  final VoidCallback onClose;

  RiderProfilePage({
    super.key,
    required this.onClose,
    required this.selectedIndex,
  });

  @override
  State<RiderProfilePage> createState() => _RiderProfilePageState();
}

class _RiderProfilePageState extends State<RiderProfilePage> {
  int uid = 0;
  int wallet = 0;
  TextEditingController phoneCtl = TextEditingController();
  TextEditingController nameCtl = TextEditingController();
  TextEditingController passwordCtl = TextEditingController();
  TextEditingController conPassCtl = TextEditingController();
  TextEditingController licenseCtl = TextEditingController();
  String send_user_name = '';
  String send_user_type = '';
  String send_user_image = '';
  String username = '';
  int cart_length = 0;
  GetStorage gs = GetStorage();
  List<GetRiderInfoRes> rider_Info = [];
  TextEditingController imageCtl = TextEditingController();
  int _selectedIndex = 0;
  late LatLng coor;

  late Future<void> loadData;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    uid = context.read<ShareData>().user_info_send.uid;
    send_user_name = context.read<ShareData>().user_info_send.name;
    send_user_type = context.read<ShareData>().user_info_send.user_type;
    send_user_image = context.read<ShareData>().user_info_send.user_image;
    // log(widget.uid.toString());
    _selectedIndex = widget.selectedIndex;
    loadData = loadDataAsync();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        // ฟังก์ชันที่คุณต้องการทำเมื่อกดรูป
                        print('Image tapped');
                        // หรือเรียกฟังก์ชันอื่น เช่น เปิดหน้าเปลี่ยนรูปภาพ
                        change_image();
                      },
                      child: ClipOval(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: rider_Info.isNotEmpty
                                  ? NetworkImage(rider_Info.first.userImage)
                                  : NetworkImage(
                                      'https://t4.ftcdn.net/jpg/04/70/29/97/360_F_470299797_UD0eoVMMSUbHCcNJCdv2t8B2g1GVqYgs.jpg'), // ใส่รูป default ถ้าไม่มีข้อมูล
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
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
                            hintText: rider_Info.isNotEmpty
                                ? rider_Info.first.phone
                                : '',
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
                            hintText: rider_Info.isNotEmpty
                                ? rider_Info.first.name
                                : '',
                          ),
                        ),
                        SizedBox(height: 15.0), // เพิ่มระยะห่างระหว่างฟิลด์
                        TextField(
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
                            hintText: rider_Info.isNotEmpty
                                ? rider_Info.first.password
                                : '', // ทำให้ hintText ว่างไปเลย
                          ),
                        ),
                        SizedBox(height: 15.0), // เพิ่มระยะห่างระหว่างฟิลด์
                        TextField(
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
                            hintText: rider_Info.isNotEmpty
                                ? rider_Info.first.password
                                : '', // ทำให้ hintText ว่างไปเลย
                          ),
                        ),

                        SizedBox(height: 15.0), // เพิ่มระยะห่างระหว่างฟิลด์
                        TextField(
                          controller: licenseCtl,
                          enabled: false, // ล็อคไม่ให้แก้ไข
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Color.fromARGB(255, 228, 225, 225),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide(width: 1),
                            ),
                            prefixIcon: Icon(Icons.motorcycle_rounded),
                            hintText: rider_Info.isNotEmpty
                                ? rider_Info.first.licensePlate
                                : '',
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 10),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                FilledButton(
                                  onPressed: () {
                                    updateProfile();
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors
                                        .green, // เปลี่ยนสีพื้นหลังของปุ่ม
                                    padding: EdgeInsets.symmetric(
                                        vertical: 10.0,
                                        horizontal: 35.0), // กำหนดขนาดของปุ่ม
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          30.0), // กำหนดรูปแบบมุมปุ่ม
                                    ),
                                  ),
                                  child: Text(
                                    "Save",
                                    style: TextStyle(
                                      color: Colors.white, // เปลี่ยนสีตัวอักษร
                                      fontSize: 18.0, // ขนาดตัวอักษร
                                    ),
                                  ),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    Get.to(() => LoginPage());
                                    gs.remove('Phone');
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        Colors.red, // เปลี่ยนสีพื้นหลังของปุ่ม
                                    padding: EdgeInsets.symmetric(
                                        vertical: 10.0,
                                        horizontal: 26.0), // กำหนดขนาดของปุ่ม
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          30.0), // กำหนดรูปแบบมุมปุ่ม
                                    ),
                                  ),
                                  child: Text(
                                    "Logout",
                                    style: TextStyle(
                                      color: Colors.white, // เปลี่ยนสีตัวอักษร
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
      bottomNavigationBar: buildBottomNavigationBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40.0),
          topRight: Radius.circular(40.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40.0),
          topRight: Radius.circular(40.0),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.yellow,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          iconSize: 20,
          selectedLabelStyle:
              TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_edu_outlined), // Icon for the Add button
              label: 'History', // Label for the Add button
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      if (index == 0) {
        // Navigate to Home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => RiderHomePage()), // สมมติว่ามี HomePage
        );
      } else if (index == 1) {
        // Navigate to Add page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RiderHistoryPage(onClose: () {}, selectedIndex: 1),
          ),
        );
      } else if (index == 2) {
        // Navigate to Profile page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RiderProfilePage(onClose: () {}, selectedIndex: 2),
          ),
        );
      }
    });
  }

  Future<void> loadDataAsync() async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    try {
      var res = await http.get(Uri.parse("$url/db/get_RiderProfile/${uid}"));
      log("Response status: ${res.statusCode}");
      log("Response body: ${res.body}");

      if (res.statusCode == 200) {
        rider_Info = getRiderInfoResFromJson(res.body);
        log("SSSSSSSSSSSS");
        log(rider_Info.first.name.toString());
        log("xxxxxxxxxxxxxxxxxxxxx");
        phoneCtl.text = rider_Info.first.phone;
        nameCtl.text = rider_Info.first.name;
        passwordCtl.text = rider_Info.first.password;
        conPassCtl.text = rider_Info.first.password;
        licenseCtl.text = rider_Info.first.licensePlate ?? '';
        if (rider_Info != null) {
          log("user_Info : " + rider_Info.toString());
          log(rider_Info.first.name.toString());
          setState(() {});
        } else {
          log("Failed to parse user info.");
        }
      } else {
        log('Failed to load user info. Status code: ${res.statusCode}');
      }
    } catch (e) {
      log("Error occurred: $e");
    }
  }

  void updateProfile() async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    // Validate input fields
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

    if (phoneCtl.text.isEmpty) {
      phoneCtl.text = rider_Info.first.phone;
    }

    if (nameCtl.text.isEmpty) {
      nameCtl.text = rider_Info.first.name;
    }

    if (passwordCtl.text.isEmpty) {
      passwordCtl.text = rider_Info.first.password;
    }

    if (conPassCtl.text.isEmpty) {
      conPassCtl.text = rider_Info.first.password; // กำหนดให้ตรงกับ password
    }

    if (licenseCtl.text.isEmpty) {
      licenseCtl.text = rider_Info.first.licensePlate;
    }

    // Getting coordinates from the address
    LatLng coor;
    try {
      List<Location> locations = await locationFromAddress(licenseCtl.text);
      coor = LatLng(locations.first.latitude, locations.first.longitude);
      log("${coor.latitude},${coor.longitude}");
    } catch (e) {
      print('Error occurred while fetching coordinates: $e');
      coor = LatLng(0, 0); // Default value in case of error
    }

    // Create the model only with changed fields
    var model = UserEditPostRequest(
      uid:
          rider_Info.first.uid, // แทนที่ userId ด้วย ID ของผู้ใช้ที่กำลังอัปเดต
      phone: phoneCtl.text == rider_Info.first.phone
          ? rider_Info.first.phone
          : phoneCtl.text,
      name: nameCtl.text == rider_Info.first.name
          ? rider_Info.first.name
          : nameCtl.text,
      password: passwordCtl.text == rider_Info.first.password
          ? rider_Info.first.password
          : passwordCtl.text,
      address: licenseCtl.text == rider_Info.first.address
          ? rider_Info.first.licensePlate
          : licenseCtl.text,
      coordinate: "${coor.latitude},${coor.longitude}",
    );

    // Filter out null values
    var updatedModel = model.toJson()
      ..removeWhere((key, value) => value == null);

    var response = await http.put(
      Uri.parse("$url/db/editProfile/user"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: jsonEncode(updatedModel),
    );

    if (response.statusCode == 200) {
      log('Update is successful');
      Fluttertoast.showToast(
        msg: "แก้ไขข้อมูลสำเร็จแล้ว",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Color.fromARGB(255, 7, 173, 45),
        textColor: Colors.white,
        fontSize: 15.0,
      );
      setState(() async {
        await loadDataAsync();
        context.read<ShareData>().user_info_send.name = rider_Info.first.name;
      });
    } else {
      // If the status code is not 200, get the message from response body
      var responseBody = jsonDecode(response.body);
      setState(() {
        Fluttertoast.showToast(
          msg: "หมายเลขโทรศัพท์นี้เป็นสมาชิกแล้ว!!!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Color.fromARGB(255, 255, 0, 0),
          textColor: Colors.white,
          fontSize: 15.0,
        );
      });
      log(responseBody['error']);
    }
  }

  void change_image() {
    imageCtl.clear();
    showDialog(
      context: context,
      barrierDismissible: false, // กำหนดให้ dialog ไม่หายเมื่อแตะบริเวณรอบนอก
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('เปลี่ยนรูป'),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Icon(
                Icons.close,
                size: 25,
              ),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.red),
                foregroundColor: WidgetStateProperty.all(Colors.white),
                padding: WidgetStateProperty.all<EdgeInsets>(EdgeInsets.zero),
                minimumSize: WidgetStateProperty.all<Size>(const Size(30, 30)),
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('กรอก URL ของรูปที่ต้องการจะเปลี่ยน'),
            const SizedBox(height: 10),
            TextField(
              controller: imageCtl,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color.fromARGB(255, 228, 225, 225),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: const BorderSide(width: 1),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center, // ปรับตำแหน่งปุ่มให้ตรงกลาง
            children: [
              FilledButton(
                onPressed: () {
                  edit_image();
                  setState(() {
                    loadDataAsync();
                  });
                  Navigator.pop(context);
                },
                child: const Text('ยืนยัน'),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.blue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void edit_image() async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    var body = jsonEncode({"url_image": imageCtl.text});

    var change_image = await http.put(
      Uri.parse('$url/db/user/change_image/${uid}'),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: body,
    );

    var res = await http.get(Uri.parse("$url/db/user/${uid}"));
    if (res.statusCode == 200) {
      rider_Info = getRiderInfoResFromJson(res.body);
      if (rider_Info != null) {
        log("user_Info: " + rider_Info.toString());
      } else {
        log("Failed to parse user info.");
      }
    } else {
      log('Failed to load user info. Status code: ${res.statusCode}');
    }

    if (res.statusCode == 200) {
      setState(() {
        loadDataAsync();
      });

      Fluttertoast.showToast(
          msg: "Image has changed !!!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          // backgroundColor: Color.fromARGB(120, 0, 0, 0),
          backgroundColor: Color.fromARGB(255, 250, 150, 44),
          textColor: Colors.white,
          fontSize: 15.0);
    } else {
      // จัดการกับ error ถ้า update ไม่สำเร็จ
      print('Failed to change name: ${res.body}');
    }
  }
}
