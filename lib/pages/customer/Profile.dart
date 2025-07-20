import 'dart:convert';
import 'dart:developer';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/request/user_edit_post_req.dart';
import 'package:mobile_miniproject_app/models/response/CusAddressGetRes.dart';
import 'package:mobile_miniproject_app/models/response/CusInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/GetUserSearch_Res.dart';
import 'package:mobile_miniproject_app/pages/Add_Item.dart';
import 'package:mobile_miniproject_app/pages/Home.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerHome.dart';
import 'package:mobile_miniproject_app/pages/login/Login.dart';
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

  Future<void> showMapPickerDialog(BuildContext context) async {
    LatLng? pickedLocation;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('เลือกตำแหน่งบนแผนที่'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: StatefulBuilder(
              builder: (context, setState) {
                return FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(13.7563, 100.5018),
                    initialZoom: 13,
                    onTap: (tapPosition, latlng) {
                      print('ตำแหน่งที่เลือก: $latlng');
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.de/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                    ),
                  ],
                );
              },
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
                  Navigator.pop(context, pickedLocation); // ส่งค่าออก
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
    ).then((value) {
      if (value != null && value is LatLng) {
        final latLng = value;
        addressCtl.text = "${latLng.latitude}, ${latLng.longitude}";
      }
    });
  }

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
                        print('Image tapped');
                        // change_image();
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
                            hintText: cus_Info.cus_name.isNotEmpty
                                ? cus_Info.cus_name
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
                            hintText: cus_Info.cus_password.isNotEmpty
                                ? cus_Info.cus_password
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
                            hintText: cus_Info.cus_password.isNotEmpty
                                ? cus_Info.cus_password
                                : '', // ทำให้ hintText ว่างไปเลย
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
                                                  addresses[0].ca_detail ?? ''),
                                              onTap: () {
                                                final a = addresses[0];
                                                final addressText =
                                                    "${a.ca_address}, ${a.ca_detail}";
                                                addressCtl.text = addressText;
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
                                                  addresses[1].ca_detail ?? ''),
                                              onTap: () {
                                                final a = addresses[1];
                                                final addressText =
                                                    "${a.ca_address}, ${a.ca_detail}";
                                                addressCtl.text = addressText;
                                                Navigator.pop(context);
                                              },
                                            ),
                                          Divider(),
                                          ListTile(
                                            leading: Icon(Icons.gps_fixed,
                                                color: Colors.blue),
                                            title:
                                                Text("เลือกตำแหน่งจากแผนที่"),
                                            onTap: () async {
                                              Navigator.pop(
                                                  context); // ปิด popup ที่อยู่
                                              await showMapPickerDialog(
                                                  context); // เรียก popup map
                                            },
                                          ),
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40.0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2)),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: context.read<ShareData>().selected_index,
        onTap: _onItemTapped,
        selectedItemColor: const Color.fromARGB(255, 115, 28, 168),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        iconSize: 20,
        selectedLabelStyle:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'Favorite'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Notis'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Future<void> loadProfileData() async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];
    int userId = context.read<ShareData>().user_info_send.uid;

    final cusAddr = context
        .read<ShareData>()
        .customer_addresses[0]; ////////เดี์ยวหาวิธีแก้ก่อนหาคิดก่อน

    final addressText = "${cusAddr.ca_address}, ${cusAddr.ca_detail}";

    try {
      var res = await http.get(Uri.parse("$url/db/get_Profile/${userId}"));
      log("Response status: ${res.statusCode}");
      log("Response body: ${res.body}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        cus_Info = CusInfoGetResponse.fromJson(decoded[0]);

        phoneCtl.text = cus_Info.cus_phone;
        nameCtl.text = cus_Info.cus_name;
        passwordCtl.text = cus_Info.cus_password;
        conPassCtl.text = cus_Info.cus_password;
        addressCtl.text = addressText;
        context.read<ShareData>().cus_selected_add = addressText;
        if (cus_Info != null) {
          log("CUS_Info : " + cus_Info.toString());
          log(cus_Info.cus_name.toString());
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
      phoneCtl.text = cus_Info.cus_phone;
    }

    if (nameCtl.text.isEmpty) {
      nameCtl.text = cus_Info.cus_name;
    }

    if (passwordCtl.text.isEmpty) {
      passwordCtl.text = cus_Info.cus_password;
    }

    if (conPassCtl.text.isEmpty) {
      conPassCtl.text = cus_Info.cus_password; // กำหนดให้ตรงกับ password
    }

    if (addressCtl.text.isEmpty) {
      addressCtl.text = context.read<ShareData>().customer_addresses.toString();
      ;
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

    // Create the model only with changed fields
    // var model = UserEditPostRequest(
    //   uid: user_Info.first.uid, // แทนที่ userId ด้วย ID ของผู้ใช้ที่กำลังอัปเดต
    //   phone: phoneCtl.text == user_Info.first.phone
    //       ? user_Info.first.phone
    //       : phoneCtl.text,
    //   name: nameCtl.text == user_Info.first.name
    //       ? user_Info.first.name
    //       : nameCtl.text,
    //   password: passwordCtl.text == user_Info.first.password
    //       ? user_Info.first.password
    //       : passwordCtl.text,
    //   address: addressCtl.text == user_Info.first.address
    //       ? user_Info.first.address
    //       : addressCtl.text,
    //   coordinate: "${coor.latitude},${coor.longitude}",
    // );

    // Filter out null values
    //   var updatedModel = model.toJson()
    //     ..removeWhere((key, value) => value == null);

    //   var response = await http.put(
    //     Uri.parse("$url/db/editProfile/user"),
    //     headers: {"Content-Type": "application/json; charset=utf-8"},
    //     body: jsonEncode(updatedModel),
    //   );

    //   if (response.statusCode == 200) {
    //     log('Update is successful');
    //     Fluttertoast.showToast(
    //       msg: "แก้ไขข้อมูลสำเร็จแล้ว",
    //       toastLength: Toast.LENGTH_SHORT,
    //       gravity: ToastGravity.CENTER,
    //       timeInSecForIosWeb: 1,
    //       backgroundColor: Color.fromARGB(255, 7, 173, 45),
    //       textColor: Colors.white,
    //       fontSize: 15.0,
    //     );
    //     setState(() async {
    //       await loadProfileData();
    //       context.read<ShareData>().user_info_send.name = user_Info.first.name;
    //     });
    //   } else {
    //     // If the status code is not 200, get the message from response body
    //     var responseBody = jsonDecode(response.body);
    //     setState(() {
    //       Fluttertoast.showToast(
    //         msg: "หมายเลขโทรศัพท์นี้เป็นสมาชิกแล้ว!!!",
    //         toastLength: Toast.LENGTH_SHORT,
    //         gravity: ToastGravity.CENTER,
    //         timeInSecForIosWeb: 1,
    //         backgroundColor: Color.fromARGB(255, 255, 0, 0),
    //         textColor: Colors.white,
    //         fontSize: 15.0,
    //       );
    //     });
    //     log(responseBody['error']);
    //   }
    // }

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
                  minimumSize:
                      WidgetStateProperty.all<Size>(const Size(30, 30)),
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
                    // edit_image();
                    setState(() {
                      loadProfileData();
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

    // void edit_image() async {
    //   var value = await Configuration.getConfig();
    //   String url = value['apiEndpoint'];

    //   var body = jsonEncode({"url_image": imageCtl.text});

    //   var change_image = await http.put(
    //     Uri.parse('$url/db/user/change_image/${uid}'),
    //     headers: {"Content-Type": "application/json; charset=utf-8"},
    //     body: body,
    //   );

    //   var res = await http.get(Uri.parse("$url/db/user/${uid}"));
    //   if (res.statusCode == 200) {
    //     user_Info = getUserSearchResFromJson(res.body);
    //     if (user_Info != null) {
    //       log("user_Info: " + user_Info.toString());
    //     } else {
    //       log("Failed to parse user info.");
    //     }
    //   } else {
    //     log('Failed to load user info. Status code: ${res.statusCode}');
    //   }

    //   if (res.statusCode == 200) {
    //     setState(() {
    //       loadProfileData();
    //     });

    //     Fluttertoast.showToast(
    //         msg: "Image has changed !!!",
    //         toastLength: Toast.LENGTH_SHORT,
    //         gravity: ToastGravity.CENTER,
    //         timeInSecForIosWeb: 1,
    //         // backgroundColor: Color.fromARGB(120, 0, 0, 0),
    //         backgroundColor: Color.fromARGB(255, 250, 150, 44),
    //         textColor: Colors.white,
    //         fontSize: 15.0);
    //   } else {
    //     // จัดการกับ error ถ้า update ไม่สำเร็จ
    //     print('Failed to change name: ${res.body}');
    //   }
    // }
  }
}
