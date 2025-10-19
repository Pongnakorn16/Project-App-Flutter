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
import 'package:mobile_miniproject_app/models/response/CusAddressGetRes.dart';
import 'package:mobile_miniproject_app/models/response/CusInfoGetRes.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerHome.dart';
import 'package:mobile_miniproject_app/pages/customer/TopUp.dart';
import 'package:mobile_miniproject_app/pages/login/Login.dart';
import 'package:mobile_miniproject_app/shared/firebase_message_service.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ProfilePage extends StatefulWidget {
  int uid = 0;
  String username = '';
  int selectedIndex = 0;
  int cart_length = 0;
  final VoidCallback onClose;

  ProfilePage({
    super.key,
    required this.onClose,
    required this.selectedIndex,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late PageController _pageController;
  int uid = 0;
  int wallet = 0;
  TextEditingController phoneCtl = TextEditingController();
  TextEditingController nameCtl = TextEditingController();
  TextEditingController passwordCtl = TextEditingController();
  TextEditingController conPassCtl = TextEditingController();
  TextEditingController addressCtl = TextEditingController();
  LatLng? selectedCoordinate;
  String old_img = '';
  String send_user_name = '';
  String send_user_type = '';
  String send_user_image = '';
  String username = '';
  int cart_length = 0;
  GetStorage gs = GetStorage();
  TextEditingController imageCtl = TextEditingController();
  late LatLng coor;
  CusInfoGetResponse cus_Info = CusInfoGetResponse();
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
    final cus_id = context.read<ShareData>().user_info_send.uid;
    OrderNotificationService().listenOrderChanges(context, cus_id,
        (orderId, newStep) {
      if (!mounted) return;
    });
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
                        padding: const EdgeInsets.only(top: 80.0, bottom: 10.0),
                        child: GestureDetector(
                          onTap: () {
                            uploadProfileImage();
                          },
                          child: Stack(
                            children: [
                              ClipOval(
                                child: Image.network(
                                  (cus_Info.cus_image != null &&
                                          cus_Info.cus_image.isNotEmpty)
                                      ? cus_Info.cus_image
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

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TopupPage()),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // เหรียญ D
                            Container(
                              width: 25,
                              height: 25,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.amber,
                              ),
                              child: const Center(
                                child: Text(
                                  'D',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                                width: 6), // เว้นระยะระหว่างเหรียญกับตัวเลข
                            Text(
                              NumberFormat('#,###').format(context
                                  .read<ShareData>()
                                  .user_info_send
                                  .balance),
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ],
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
                                hintText: cus_Info.cus_phone.isNotEmpty
                                    ? cus_Info.cus_phone
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
                                hintText: cus_Info.cus_name.isNotEmpty
                                    ? cus_Info.cus_name
                                    : '',
                              ),
                            ),
                            SizedBox(height: 15.0), // เพิ่มระยะห่างระหว่างฟิลด์
                            TextField(
                              obscureText: true,
                              controller: passwordCtl,
                              enabled: cus_Info.cus_password
                                  .isNotEmpty, // ถ้า password ว่าง จะ disable field
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Color.fromARGB(255, 228, 225, 225),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(width: 1),
                                ),
                                prefixIcon: Icon(Icons.lock),
                                hintText: cus_Info.cus_password.isNotEmpty
                                    ? '' // ถ้ามี password ก็ไม่ต้องแสดง hint
                                    : 'เข้าสู่ระบบด้วย Google แก้ไขไม่ได้',
                              ),
                            ),

                            SizedBox(height: 15.0), // เพิ่มระยะห่างระหว่างฟิลด์
                            TextField(
                              obscureText: true,
                              controller: conPassCtl,
                              enabled: cus_Info.cus_password.isNotEmpty,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Color.fromARGB(255, 228, 225, 225),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                  borderSide: BorderSide(width: 1),
                                ),
                                prefixIcon: Icon(Icons.lock),
                                hintText: cus_Info.cus_password.isNotEmpty
                                    ? cus_Info.cus_password
                                    : 'เข้าสู่ระบบด้วย Google แก้ไขไม่ได้', // ทำให้ hintText ว่างไปเลย
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
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    final addresses = context
                                        .read<ShareData>()
                                        .customer_addresses;

                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text("เลือกที่อยู่"),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (addresses.isNotEmpty &&
                                                  addresses[0] != null)
                                                ListTile(
                                                  leading: Text('1.'),
                                                  title: Text(
                                                      addresses[0].ca_address ??
                                                          'ไม่มีที่อยู่'),
                                                  subtitle: Text(
                                                      addresses[0].ca_detail ??
                                                          ''),
                                                  trailing: SizedBox(
                                                    width:
                                                        30, // กำหนดความกว้างให้พอดี
                                                    height: 30,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      child: Icon(Icons.edit,
                                                          size: 18,
                                                          color: Colors.blue),
                                                      onTap: () {
                                                        context
                                                                .read<ShareData>()
                                                                .selected_ca_id =
                                                            addresses[0].ca_id;
                                                        context
                                                            .read<ShareData>()
                                                            .selected_address_index = 0;
                                                        edit_cusShowMap(
                                                            context,
                                                            context
                                                                .read<
                                                                    ShareData>()
                                                                .selected_ca_id);
                                                      },
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    final a = addresses[0];
                                                    final addressText =
                                                        "${a.ca_address}, ${a.ca_detail}";
                                                    addressCtl.text =
                                                        addressText;
                                                    context
                                                        .read<ShareData>()
                                                        .selected_address_index = 0;
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                              if (addresses.length > 1 &&
                                                  addresses[1] != null)
                                                ListTile(
                                                  leading: Text('2.'),
                                                  title: Text(
                                                      addresses[1].ca_address ??
                                                          'ไม่มีที่อยู่'),
                                                  subtitle: Text(
                                                      addresses[1].ca_detail ??
                                                          ''),
                                                  trailing: SizedBox(
                                                    width:
                                                        30, // กำหนดความกว้างให้พอดี
                                                    height: 30,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      child: Icon(Icons.edit,
                                                          size: 18,
                                                          color: Colors.blue),
                                                      onTap: () {
                                                        context
                                                                .read<ShareData>()
                                                                .selected_ca_id =
                                                            addresses[1].ca_id;
                                                        context
                                                            .read<ShareData>()
                                                            .selected_address_index = 1;
                                                        edit_cusShowMap(
                                                            context,
                                                            context
                                                                .read<
                                                                    ShareData>()
                                                                .selected_ca_id);
                                                      },
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    final a = addresses[1];
                                                    final addressText =
                                                        "${a.ca_address}, ${a.ca_detail}";
                                                    addressCtl.text =
                                                        addressText;
                                                    context
                                                        .read<ShareData>()
                                                        .selected_address_index = 1;
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                              if (addresses.length < 2) ...[
                                                Divider(),
                                                ListTile(
                                                  leading: Icon(
                                                    Icons
                                                        .add_circle_outline_rounded,
                                                    color: Colors.blue,
                                                  ),
                                                  title: Text(
                                                      "เพิ่มที่อยู่โดยเลือกตำแหน่งจากแผนที่"),
                                                  onTap: () async {
                                                    // ปิด popup ที่อยู่
                                                    await showMapPickerDialog(
                                                        context); // เรียก popup map
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                hintText: context
                                        .read<ShareData>()
                                        .cus_selected_add
                                        .isNotEmpty
                                    ? context.read<ShareData>().cus_selected_add
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
                                        if (old_img == cus_Info.cus_image &&
                                            phoneCtl.text ==
                                                cus_Info.cus_phone &&
                                            nameCtl.text == cus_Info.cus_name &&
                                            passwordCtl.text ==
                                                cus_Info.cus_password &&
                                            conPassCtl.text ==
                                                cus_Info.cus_password &&
                                            addressCtl.text ==
                                                context
                                                    .read<ShareData>()
                                                    .cus_selected_add &&
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
                                            .cus_selected_add = '';
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
                          'พิกัด: ${pickedLocation!.latitude}, ${pickedLocation!.longitude}',
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

  Future<void> edit_cusShowMap(BuildContext context, int selected_ca_id) async {
    LatLng? pickedLocation;
    var config = await Configuration.getConfig();
    String url = config['apiEndpoint'];

    await showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<LatLng>(
          future: getCurrentLocation(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                title: Text('กำลังโหลดตำแหน่ง...'),
                content: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            } else if (snapshot.hasError) {
              return AlertDialog(
                title: Text('เกิดข้อผิดพลาด'),
                content: Text('ไม่สามารถดึงตำแหน่งได้: ${snapshot.error}'),
              );
            }

            LatLng initialCenter = snapshot.data!;

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
                              initialCenter: initialCenter,
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
                                    point: initialCenter,
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
            ;
          },
        );
      },
    ).then((value) async {
      if (value != null && value is LatLng) {
        pickedLocation = value;
        try {
          List<Placemark> placemarks =
              await placemarkFromCoordinates(value.latitude, value.longitude);
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            final address =
                "${place.thoroughfare ?? ''} ${place.subThoroughfare ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}";
            addressCtl.text = address;
          } else {
            addressCtl.text = "${value.latitude}, ${value.longitude}";
          }
        } catch (e) {
          print('Error in reverse geocoding: $e');
          addressCtl.text = "${value.latitude}, ${value.longitude}";
        }
      }

      if (pickedLocation != null) {
        int select_ca_id = context.read<ShareData>().selected_ca_id;
        context.read<ShareData>().cus_selected_add = addressCtl.text;
        List<String> addressParts =
            context.read<ShareData>().cus_selected_add.split(',');
        String addressFromUI =
            addressParts.isNotEmpty ? addressParts[0].trim() : '';
        String detailFromUI = addressParts.length > 1
            ? addressParts.sublist(1).join(',').trim()
            : '';

        var model = {
          "coordinate":
              "${pickedLocation!.latitude}, ${pickedLocation!.longitude}", // รวมเป็น string เดียว
          "address": addressFromUI,
          "detail": detailFromUI
        };
        log("${context.read<ShareData>().selected_ca_id}");
        log("${model}");

        var response = await http.put(
          Uri.parse("$url/db/edit_cusAdd/$select_ca_id"),
          headers: {"Content-Type": "application/json; charset=utf-8"},
          body: jsonEncode(model),
        );

        log("Response status: ${response.statusCode}");
        log("Response body: ${response.body}");
      }
      Navigator.pop(context);
      loadProfileData();
    });
  }

  Future<void> loadProfileData() async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];
    int userId = context.read<ShareData>().user_info_send.uid;
    log("${userId} + IDDDDDIIIIIIIIIIIIIIIIIIDDDDDDDDDDDDDDDIDDDDDDDDDDDDDDDDD");

    final cus_balance =
        await http.get(Uri.parse("$url/db/loadCusbalance/$userId"));
    print('Status code: ${cus_balance.statusCode}');
    print('Response body: ${cus_balance.body}');

    if (cus_balance.statusCode == 200) {
      final data = jsonDecode(cus_balance.body);
      final int balance = data['balance'] ?? 0;
      context.read<ShareData>().user_info_send.balance = balance.toDouble();
    } else {
      Fluttertoast.showToast(msg: "โหลดยอดเงินไม่สำเร็จ");
    }
    final res_Add = await http.get(Uri.parse("$url/db/loadCusAdd/$userId"));
    if (res_Add.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(res_Add.body);
      final List<CusAddressGetResponse> res_addList =
          jsonResponse.map((e) => CusAddressGetResponse.fromJson(e)).toList();

      context.read<ShareData>().customer_addresses = res_addList;
    }

    String addressText = '';
    if (context.read<ShareData>().customer_addresses.isNotEmpty) {
      if (context.read<ShareData>().selected_address_index == 0) {
        final cusAddr = context.read<ShareData>().customer_addresses[0];
        addressText = "${cusAddr.ca_address}, ${cusAddr.ca_detail}";
      } else {
        final cusAddr = context.read<ShareData>().customer_addresses[1];
        addressText = "${cusAddr.ca_address}, ${cusAddr.ca_detail}";
      }
      context.read<ShareData>().cus_selected_add = addressText;
      addressCtl.text = addressText;
    }

    try {
      var res = await http.get(Uri.parse("$url/db/get_CusProfile/$userId"));
      log("Response status: ${res.statusCode}");
      log("Response body: ${res.body}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded != null && decoded.isNotEmpty) {
          cus_Info = CusInfoGetResponse.fromJson(decoded[0]);

          if (cus_Info != null) {
            phoneCtl.text = cus_Info.cus_phone;
            nameCtl.text = cus_Info.cus_name;
            passwordCtl.text = cus_Info.cus_password;
            conPassCtl.text = cus_Info.cus_password;
            old_img = cus_Info.cus_image;

            log("CUS_Info : " + cus_Info.toString());
            log(cus_Info.cus_name.toString());
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

    if (phoneCtl.text.isEmpty) {
      if (cus_Info.cus_phone.isEmpty) {
        Fluttertoast.showToast(
          msg: "กรุณากรอกหมายเลขโทรศัพท์",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Color.fromARGB(255, 255, 0, 0),
          textColor: Colors.white,
          fontSize: 15.0,
        );
      } else {
        phoneCtl.text = cus_Info.cus_phone;
      }
    }

    if (nameCtl.text.isEmpty) {
      nameCtl.text = cus_Info.cus_name;
    }

    if (passwordCtl.text.isEmpty) {
      if (cus_Info.cus_password.isEmpty) {
        passwordCtl.text = "";
      }
      passwordCtl.text = cus_Info.cus_password;
    }

    if (conPassCtl.text.isEmpty) {
      if (cus_Info.cus_password.isEmpty) {
        conPassCtl.text = "";
      }
      conPassCtl.text = cus_Info.cus_password; // กำหนดให้ตรงกับ password
    }

    if (addressCtl.text.isEmpty) {
      if (context.read<ShareData>().customer_addresses.isEmpty) {
        Fluttertoast.showToast(
          msg: "กรุณาเพิ่มที่อยู่",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Color.fromARGB(255, 255, 0, 0),
          textColor: Colors.white,
          fontSize: 15.0,
        );
      } else {
        addressCtl.text =
            context.read<ShareData>().customer_addresses.toString();
      }
    }

    // Getting coordinates from the address
    LatLng coor;
    try {
      List<Location> locations = await locationFromAddress(addressCtl.text);
      coor = LatLng(locations.first.latitude, locations.first.longitude);
      log("${coor.latitude},${coor.longitude}");
    } catch (e) {
      print('Error occurred while fetching coordinates: $e');
      coor = LatLng(0, 0); // Default value in case of error
    }

    if (context.read<ShareData>().customer_addresses.isNotEmpty) {
      cusAddr = context
          .read<ShareData>()
          .customer_addresses[0]; ////////เดี์ยวหาวิธีแก้ก่อนหาคิดก่อน

      address = cusAddr!.ca_address;
      detail = cusAddr!.ca_detail;
    } else {
      localCusAddr = cusAddr;
      cusAddr = null;
      address = "";
      detail = "";
    }

    context.read<ShareData>().cus_selected_add = addressCtl.text;
    List<String> addressParts =
        context.read<ShareData>().cus_selected_add.split(',');
    String addressFromUI =
        addressParts.isNotEmpty ? addressParts[0].trim() : '';
    String detailFromUI =
        addressParts.length > 1 ? addressParts.sublist(1).join(',').trim() : '';
    log("cus_selected_add: ${context.read<ShareData>().cus_selected_add}");
    log("addressFromUI: $addressFromUI");
    log("detailFromUI: $detailFromUI");

    // Create the model only with changed fields

    var model = CusProEditPostRequest(
      cus_id: cus_Info.cus_id,
      cus_phone: phoneCtl.text == cus_Info.cus_phone
          ? cus_Info.cus_phone
          : phoneCtl.text,
      cus_name:
          nameCtl.text == cus_Info.cus_name ? cus_Info.cus_name : nameCtl.text,
      cus_password: passwordCtl.text == cus_Info.cus_password
          ? cus_Info.cus_password
          : passwordCtl.text,
      cus_image: cus_Info.cus_image,
      ca_id: localCusAddr != null ? localCusAddr.ca_id : ca_id_check,
      ca_address: addressFromUI,
      ca_detail: detailFromUI,
      ca_coordinates: "${coor.latitude},${coor.longitude}",
    );

    var response = await http.put(
      Uri.parse("$url/db/edit_CusProfile"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: jsonEncode(model),
    );

    log('Response status code: ${response.statusCode}');
    log('Response body: ${response.body}');

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
      await loadProfileData();
      setState(() {});
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
            .child('BP_CusProfile_image')
            .child(fileName);

        await ref.putFile(file);
        String downloadURL = await ref.getDownloadURL();

        print('✅ อัปโหลดสำเร็จ: $downloadURL');
        setState(() {
          cus_Info.cus_image = downloadURL;
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
