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
    super.initState();
    uid = context.read<ShareData>().user_info_send.uid;
    send_user_name = context.read<ShareData>().user_info_send.name;
    send_user_type = context.read<ShareData>().user_info_send.user_type;
    send_user_image = context.read<ShareData>().user_info_send.user_image;
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
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/BG_delivery_profile.png',
                    fit: BoxFit.cover,
                  ),
                ),
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
                            const SizedBox(width: 6),
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
                            SizedBox(height: 15.0),
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
                            SizedBox(height: 15.0),
                            TextField(
                              obscureText: true,
                              controller: passwordCtl,
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
                                    ? 'กรอก password ใหม่ถ้าต้องการเปลี่ยน'
                                    : 'เข้าสู่ระบบด้วย Google แก้ไขไม่ได้',
                              ),
                            ),
                            SizedBox(height: 15.0),
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
                                    ? 'กรอก password ใหม่อีกครั้ง'
                                    : 'เข้าสู่ระบบด้วย Google แก้ไขไม่ได้',
                              ),
                            ),
                            SizedBox(height: 15.0),
                            TextField(
                              controller: addressCtl,
                              readOnly: true,
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
                                          content: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                for (int i = 0;
                                                    i < addresses.length &&
                                                        i < 2;
                                                    i++)
                                                  if (addresses[i] != null)
                                                    Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 6.0),
                                                      child: ListTile(
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12)),
                                                        tileColor:
                                                            Colors.grey[100],
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 12,
                                                                vertical: 8),
                                                        leading: CircleAvatar(
                                                          backgroundColor:
                                                              Colors.deepPurple,
                                                          radius: 16,
                                                          child: Text(
                                                            '${i + 1}',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                        ),
                                                        title: Text(
                                                          addresses[i]
                                                                  .ca_address ??
                                                              'ไม่มีที่อยู่',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        subtitle: Text(
                                                            addresses[i]
                                                                    .ca_detail ??
                                                                ''),
                                                        trailing: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            // ปุ่มแก้ไข
                                                            InkWell(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20),
                                                              child: Icon(
                                                                  Icons.edit,
                                                                  size: 24,
                                                                  color: Colors
                                                                      .orange),
                                                              onTap: () {
                                                                TextEditingController
                                                                    addressEditCtl =
                                                                    TextEditingController(
                                                                        text: addresses[i]
                                                                            .ca_address);
                                                                TextEditingController
                                                                    detailEditCtl =
                                                                    TextEditingController(
                                                                        text: addresses[i]
                                                                            .ca_detail);

                                                                showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (context) {
                                                                    return AlertDialog(
                                                                      title: Text(
                                                                          "แก้ไขที่อยู่"),
                                                                      content:
                                                                          Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          TextField(
                                                                            controller:
                                                                                addressEditCtl,
                                                                            decoration:
                                                                                InputDecoration(
                                                                              labelText: "ที่อยู่",
                                                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                              height: 10),
                                                                          TextField(
                                                                            controller:
                                                                                detailEditCtl,
                                                                            decoration:
                                                                                InputDecoration(
                                                                              labelText: "รายละเอียด",
                                                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed:
                                                                              () {
                                                                            Navigator.pop(context);
                                                                          },
                                                                          child:
                                                                              Text("ยกเลิก"),
                                                                        ),
                                                                        ElevatedButton(
                                                                          onPressed:
                                                                              () async {
                                                                            // บันทึกแก้ไขลง DB
                                                                            var value =
                                                                                await Configuration.getConfig();
                                                                            String
                                                                                url =
                                                                                value['apiEndpoint'];
                                                                            int selected_ca_id =
                                                                                addresses[i].ca_id;

                                                                            var model =
                                                                                {
                                                                              "address": addressEditCtl.text,
                                                                              "detail": detailEditCtl.text
                                                                            };

                                                                            var response =
                                                                                await http.put(
                                                                              Uri.parse("$url/db/edit_cusAdd/$selected_ca_id"),
                                                                              headers: {
                                                                                "Content-Type": "application/json; charset=utf-8"
                                                                              },
                                                                              body: jsonEncode(model),
                                                                            );

                                                                            if (response.statusCode ==
                                                                                200) {
                                                                              setState(() {
                                                                                addresses[i].ca_address = addressEditCtl.text;
                                                                                addresses[i].ca_detail = detailEditCtl.text;
                                                                                addressCtl.text = "${addresses[i].ca_address}, ${addresses[i].ca_detail}";
                                                                              });

                                                                              Fluttertoast.showToast(
                                                                                msg: "แก้ไขที่อยู่สำเร็จ",
                                                                                backgroundColor: Colors.green,
                                                                              );

                                                                              Navigator.pop(context); // ปิด popup edit
                                                                              Navigator.pop(context); // ปิด popup list
                                                                              await loadProfileData();
                                                                            } else {
                                                                              Fluttertoast.showToast(
                                                                                msg: "แก้ไขที่อยู่ไม่สำเร็จ",
                                                                                backgroundColor: Colors.red,
                                                                              );
                                                                            }
                                                                          },
                                                                          child:
                                                                              Text("บันทึก"),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  },
                                                                );
                                                              },
                                                            ),
                                                            SizedBox(width: 12),
                                                            // ปุ่มแผนที่
                                                            InkWell(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20),
                                                              child: Icon(
                                                                  Icons
                                                                      .location_on,
                                                                  size: 24,
                                                                  color: Colors
                                                                      .blue),
                                                              onTap: () {
                                                                context
                                                                        .read<
                                                                            ShareData>()
                                                                        .selected_ca_id =
                                                                    addresses[i]
                                                                        .ca_id;
                                                                context
                                                                    .read<
                                                                        ShareData>()
                                                                    .selected_address_index = i;
                                                                edit_cusShowMap(
                                                                    context,
                                                                    addresses[i]
                                                                        .ca_id);
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                        onTap: () {
                                                          final a =
                                                              addresses[i];
                                                          final addressText =
                                                              "${a.ca_address}, ${a.ca_detail}";
                                                          addressCtl.text =
                                                              addressText;
                                                          context
                                                              .read<ShareData>()
                                                              .selected_address_index = i;
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                      ),
                                                    ),
                                                if (addresses.length < 2) ...[
                                                  Divider(height: 20),
                                                  ListTile(
                                                    leading: Icon(
                                                        Icons
                                                            .add_circle_outline_rounded,
                                                        color: Colors.blue),
                                                    title: Text(
                                                        "เพิ่มที่อยู่โดยเลือกตำแหน่งจากแผนที่"),
                                                    onTap: () async {
                                                      await showMapPickerDialog(
                                                          context);
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                ],
                                              ],
                                            ),
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
                                        // ตรวจสอบว่ามีการแก้ไขอะไรบ้าง
                                        bool hasChanged = old_img !=
                                                cus_Info.cus_image ||
                                            phoneCtl.text !=
                                                cus_Info.cus_phone ||
                                            nameCtl.text != cus_Info.cus_name ||
                                            passwordCtl.text
                                                .trim()
                                                .isNotEmpty || // ถ้ามี password ใหม่
                                            addressCtl.text !=
                                                context
                                                    .read<ShareData>()
                                                    .cus_selected_add ||
                                            selectedCoordinate != null;

                                        if (!hasChanged) {
                                          Fluttertoast.showToast(
                                            msg: "กรุณาแก้ไขข้อมูลก่อนกดบันทึก",
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.CENTER,
                                            timeInSecForIosWeb: 1,
                                            backgroundColor: Color.fromARGB(
                                                255, 255, 247, 0),
                                            textColor: Colors.black,
                                            fontSize: 15.0,
                                          );
                                        } else {
                                          updateProfile();
                                        }
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 10.0, horizontal: 35.0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30.0),
                                        ),
                                      ),
                                      child: Text(
                                        "Save",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18.0,
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
                                        backgroundColor: Colors.red,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 10.0, horizontal: 26.0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30.0),
                                        ),
                                      ),
                                      child: Text(
                                        "Logout",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18.0,
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

  // ฟังก์ชันเพิ่มที่อยู่ใหม่ - ไม่แปลงพิกัด
  Future<void> showMapPickerDialog(BuildContext context) async {
    LatLng? pickedLocation;
    TextEditingController newAddressCtl = TextEditingController();
    TextEditingController newDetailCtl = TextEditingController();

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
              title: Text('เพิ่มที่อยู่ใหม่'),
              content: SizedBox(
                width: double.maxFinite,
                height: 550,
                child: Column(
                  children: [
                    // กรอกที่อยู่
                    TextField(
                      controller: newAddressCtl,
                      decoration: InputDecoration(
                        labelText: "ที่อยู่",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    // กรอกรายละเอียด
                    TextField(
                      controller: newDetailCtl,
                      decoration: InputDecoration(
                        labelText: "รายละเอียด",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    // แสดงพิกัดที่เลือก
                    if (pickedLocation != null)
                      Container(
                        padding: EdgeInsets.all(8),
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
                    SizedBox(height: 10),
                    // แผนที่
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
                  onPressed: () async {
                    if (pickedLocation == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('กรุณาเลือกตำแหน่งก่อน')),
                      );
                      return;
                    }
                    if (newAddressCtl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('กรุณากรอกที่อยู่')),
                      );
                      return;
                    }

                    // บันทึกที่อยู่ใหม่ไปยัง API
                    var value = await Configuration.getConfig();
                    String url = value['apiEndpoint'];
                    int userId = context.read<ShareData>().user_info_send.uid;

                    var model = {
                      "cus_id": userId,
                      "address": newAddressCtl.text,
                      "detail": newDetailCtl.text,
                      "coordinate":
                          "${pickedLocation!.latitude},${pickedLocation!.longitude}",
                    };

                    var response = await http.post(
                      Uri.parse("$url/db/add_cusAllAdd"),
                      headers: {
                        "Content-Type": "application/json; charset=utf-8"
                      },
                      body: jsonEncode(model),
                    );

                    if (response.statusCode == 200 ||
                        response.statusCode == 201) {
                      Fluttertoast.showToast(
                        msg: "เพิ่มที่อยู่สำเร็จ",
                        backgroundColor: Colors.green,
                      );
                      Navigator.pop(context);
                      await loadProfileData();
                    } else {
                      Fluttertoast.showToast(
                        msg: "เพิ่มที่อยู่ไม่สำเร็จ",
                        backgroundColor: Colors.red,
                      );
                    }
                  },
                  child: Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ฟังก์ชันแก้ไขพิกัด - บันทึกพิกัดเท่านั้น
  Future<void> edit_cusShowMap(BuildContext context, int selected_ca_id) async {
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
              title: Text('เลือกพิกัดบนแผนที่'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
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
                  onPressed: () async {
                    if (pickedLocation == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('กรุณาเลือกตำแหน่งก่อน')),
                      );
                      return;
                    }

                    // บันทึกพิกัดที่เลือก
                    var value = await Configuration.getConfig();
                    String url = value['apiEndpoint'];

                    var model = {
                      "coordinate":
                          "${pickedLocation!.latitude},${pickedLocation!.longitude}",
                    };

                    log("Updating coordinates for ca_id: $selected_ca_id");
                    log("New coordinates: ${model['coordinate']}");

                    var response = await http.put(
                      Uri.parse("$url/db/edit_cusCoordinate/$selected_ca_id"),
                      headers: {
                        "Content-Type": "application/json; charset=utf-8"
                      },
                      body: jsonEncode(model),
                    );

                    log("Response status: ${response.statusCode}");
                    log("Response body: ${response.body}");

                    if (response.statusCode == 200) {
                      Fluttertoast.showToast(
                        msg: "บันทึกพิกัดสำเร็จ",
                        backgroundColor: Colors.green,
                      );
                      Navigator.pop(context);
                      await loadProfileData();
                    } else {
                      Fluttertoast.showToast(
                        msg: "บันทึกพิกัดไม่สำเร็จ",
                        backgroundColor: Colors.red,
                      );
                    }
                  },
                  child: Text('บันทึกพิกัด'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> loadProfileData() async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];
    int userId = context.read<ShareData>().user_info_send.uid;
    log("$userId + Loading profile data");

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
        return;
      } else {
        phoneCtl.text = cus_Info.cus_phone;
      }
    }

    if (phoneCtl.text.length != 10) {
      Fluttertoast.showToast(
        msg: "เบอร์โทรศัพท์ต้องมี 10 ตัวเลข",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Color.fromARGB(255, 255, 0, 0),
        textColor: Colors.white,
        fontSize: 15.0,
      );
      return;
    }

    if (nameCtl.text.isEmpty) {
      nameCtl.text = cus_Info.cus_name;
    }

    String passwordToSave = "";
    if (passwordCtl.text.trim().isNotEmpty) {
      passwordToSave =
          passwordCtl.text; // ส่งเฉพาะ password ใหม่ไปให้ backend hash
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
        return;
      } else {
        addressCtl.text = context.read<ShareData>().cus_selected_add;
      }
    }

    // ใช้พิกัดเริ่มต้นจาก database
    String coordinates = "0,0";
    if (context.read<ShareData>().customer_addresses.isNotEmpty) {
      int selectedIndex = context.read<ShareData>().selected_address_index;
      cusAddr = context.read<ShareData>().customer_addresses[selectedIndex];
      coordinates = cusAddr!.ca_coordinate ?? "0,0";
      address = cusAddr!.ca_address;
      detail = cusAddr!.ca_detail;
      ca_id_check = cusAddr!.ca_id;
    }

    var model = CusProEditPostRequest(
      cus_id: cus_Info.cus_id,
      cus_phone: phoneCtl.text,
      cus_name: nameCtl.text,
      cus_password: passwordCtl.text,
      cus_image: cus_Info.cus_image,
      ca_id: ca_id_check,
      ca_address: address,
      ca_detail: detail,
      ca_coordinates: coordinates,
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
          isLoading = true;
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
          isLoading = false;
        });
      } catch (e) {
        print('❌ เกิดข้อผิดพลาดในการอัปโหลด: $e');
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
