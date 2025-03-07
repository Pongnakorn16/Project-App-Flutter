import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_miniproject_app/models/request/user_order_post_req.dart';
import 'package:mobile_miniproject_app/models/response/GetNewOid_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetUserSearch_Res.dart';
import 'package:mobile_miniproject_app/pages/Home.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';

class AddItemPage extends StatefulWidget {
  AddItemPage({super.key});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  int uid = 0;
  int orderNo = 0;
  int orderStatus = 0;
  String send_user_name = '';
  String send_user_type = '';
  String send_user_image = '';
  String receiver_address = "";
  List<GetUserSearchRes> receive_Info = [];
  LatLng receive_latLng = LatLng(0, 0);
  List<GetUserSearchRes> all_userSearch = [];
  MapController mapController = MapController();
  TextEditingController searchCtl = TextEditingController();
  TextEditingController send_nameCtl = TextEditingController();
  TextEditingController product_nameCtl = TextEditingController();
  TextEditingController product_detailCtl = TextEditingController();
  TextEditingController receive_nameCtl = TextEditingController();
  final ImagePicker picker = ImagePicker();
  XFile? image;
  String To_userImage = '';
  String To_userName = '';
  String To_phone = '';
  int To_uid = 0;
  var db = FirebaseFirestore.instance;
  String product_imgUrl = '';

  @override
  void initState() {
    uid = context.read<ShareData>().user_info_send.uid;
    send_user_name = context.read<ShareData>().user_info_send.name;
    send_user_type = context.read<ShareData>().user_info_send.user_type;
    send_user_image = context.read<ShareData>().user_info_send.user_image;
    send_nameCtl.text = send_user_name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Container(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(
                          255, 228, 225, 225), // สีพื้นหลังของ TextField
                      borderRadius: BorderRadius.circular(30.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5), // สีของเงา
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset: Offset(0, 3), // การเยื้องของเงา
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: searchCtl,
                      onChanged: (query) {
                        if (query.length >= 1) {
                          // Or whatever minimum length you prefer
                          showSearchPopup(context, query, searchCtl);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Search Receiver Phone Number',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none, // ไม่มีขอบ
                        ),
                        filled: true,
                        fillColor: Colors
                            .transparent, // ทำให้พื้นหลังโปร่งใส เนื่องจากใช้สีใน Container แล้ว
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
                  child: Row(
                    children: [
                      // TextField ขนาดเต็มที่ขยายเต็มที่ของ Row
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color.fromARGB(
                                255, 228, 225, 225), // สีพื้นหลังของ TextField
                            borderRadius: BorderRadius.circular(30.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5), // สีของเงา
                                spreadRadius: 2,
                                blurRadius: 7,
                                offset: Offset(0, 3), // การเยื้องของเงา
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: product_nameCtl,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors
                                  .transparent, // เนื่องจากเราตั้งสีใน Container แล้ว
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide.none, // ไม่มีขอบ
                              ),
                              hintText: 'Product Name', // ใส่ placeholder
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          width:
                              10), // เว้นระยะห่างระหว่าง TextField กับปุ่มรูปภาพ
                      // ปุ่มรูปภาพหรือไอคอน
                      Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: image != null
                            ? Image.file(
                                File(image!.path), // แสดงรูปที่เลือก
                                width: 90.0, // กำหนดขนาดของรูปภาพ
                                height: 90.0,
                                fit: BoxFit.cover, // ทำให้รูปเต็มกรอบ
                              )
                            : IconButton(
                                icon: Icon(
                                  Icons.add_photo_alternate_rounded,
                                  color: Color.fromARGB(255, 255, 222, 78),
                                ),
                                iconSize: 90.0,
                                onPressed: () async {
                                  image = await picker.pickImage(
                                      source: ImageSource.camera);
                                  if (image != null) {
                                    log(image!.path.toString());
                                    setState(() {}); // อัพเดต UI เมื่อเลือกรูป
                                  } else {
                                    log('No Image');
                                  }
                                  print('Icon button pressed');
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 10, right: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(
                          255, 228, 225, 225), // สีพื้นหลังของ TextField
                      borderRadius: BorderRadius.circular(30.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5), // สีของเงา
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset: Offset(0, 3), // การเยื้องของเงา
                        ),
                      ],
                    ),
                    child: Container(
                      width: 300, // กำหนดความกว้าง
                      height: 100, // กำหนดความสูง
                      child: TextField(
                        controller: product_detailCtl,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors
                              .transparent, // เนื่องจากเราตั้งสีใน Container แล้ว
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none, // ไม่มีขอบ
                          ), // ใส่ไอคอนโทรศัพท์ที่ด้านซ้าย
                          hintText: 'Product Detail', // ใส่ placeholder
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(
                          255, 228, 225, 225), // สีพื้นหลังของ TextField
                      borderRadius: BorderRadius.circular(30.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5), // สีของเงา
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset: Offset(0, 3), // การเยื้องของเงา
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: send_nameCtl,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  100.0), // กำหนดความโค้งของขอบ
                              child: SizedBox(
                                width: 20, // กำหนดความกว้างของรูปภาพ
                                height: 20, // กำหนดความสูงของรูปภาพ
                                child: Image.network(
                                  send_user_image, // URL ของรูปภาพ
                                  fit: BoxFit
                                      .cover, // ทำให้ภาพพอดีกับขนาดที่กำหนด
                                ),
                              ),
                            )),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: FaIcon(
                            FontAwesomeIcons.circleChevronRight,
                            color: Colors.red,
                          ), // ไอคอนที่ด้านขวา
                        ),
                        filled: true,
                        fillColor: Colors
                            .transparent, // เนื่องจากเราตั้งสีใน Container แล้ว
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none, // ไม่มีขอบ
                        ), // ใส่ไอคอนโทรศัพท์ที่ด้านซ้าย
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
                  child: Column(
                    children: [
                      // TextField
                      Container(
                        decoration: BoxDecoration(
                          color: Color.fromARGB(
                              255, 228, 225, 225), // สีพื้นหลังของ TextField
                          borderRadius: BorderRadius.circular(100.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5), // สีของเงา
                              spreadRadius: 2,
                              blurRadius: 7,
                              offset: Offset(0, 3), // การเยื้องของเงา
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: receive_nameCtl,
                          onChanged: (query) {
                            if (query.length >= 1) {
                              // Or whatever minimum length you prefer
                              showNameSearchPopup(
                                  context, query, receive_nameCtl);
                            }
                          },
                          decoration: InputDecoration(
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    100.0), // กำหนดความโค้งของขอบ
                                child: SizedBox(
                                  width: 20, // กำหนดความกว้างของรูปภาพ
                                  height: 20, // กำหนดความสูงของรูปภาพ
                                  child: To_userImage.isNotEmpty
                                      ? Image.network(
                                          To_userImage, // URL ของรูปภาพ
                                          fit: BoxFit
                                              .cover, // ปรับรูปภาพให้พอดีกับขนาดที่กำหนด
                                        )
                                      : Container(), // ถ้า To_userImage ว่าง ให้แสดง Container ว่าง
                                ),
                              ),
                            ),
                            filled: true,
                            fillColor: Colors
                                .transparent, // เนื่องจากเราตั้งสีใน Container แล้ว
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide.none, // ไม่มีขอบ
                            ),
                            hintText: To_userName.isNotEmpty
                                ? "${To_userName} tel. ${To_phone}"
                                : 'To',
                            suffixIcon: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: FaIcon(
                                FontAwesomeIcons.circleChevronLeft,
                                color: Colors.green,
                              ), // ไอคอนที่ด้านขวา
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                          height:
                              20), // เว้นระยะห่างระหว่าง TextField กับแผนที่

                      // FlutterMap
                      Container(
                        height: 100, // กำหนดความสูงของแผนที่
                        child: FlutterMap(
                          mapController: mapController,
                          options: MapOptions(
                            initialCenter: receive_latLng,
                            initialZoom: 15.0,
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
                                Marker(
                                  point: receive_latLng,
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.location_on,
                                    color: Colors.green,
                                    size: 40,
                                  ),
                                  alignment: Alignment.center,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        height: 50,
                        child: FilledButton(
                          onPressed: () async {
                            send();
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                                Color.fromARGB(255, 255, 222, 78)),
                            foregroundColor:
                                WidgetStateProperty.all(Colors.white),
                            shadowColor:
                                WidgetStateProperty.all(Colors.grey), // สีเงา
                            elevation: WidgetStateProperty.all(
                                5), // ความสูงของเงา (ยิ่งมากยิ่งชัด)
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(30), // ขอบมน
                              ),
                            ),
                          ),
                          child: Text(
                            "Send", // ใช้ตัวแปรโดยตรง
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w400),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: IconButton(
                          icon: Icon(Icons.cancel_outlined,
                              color: Color.fromARGB(255, 139, 15,
                                  188)), // ไอคอนที่ต้องการแสดงในปุ่ม
                          iconSize: 50.0, // ขนาดของไอคอน
                          onPressed: () {
                            Get.to(() => HomePage());
                            print('Icon button pressed');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> showSearchPopup(BuildContext context, String query,
      TextEditingController searchController) async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    var response = await http.get(Uri.parse("$url/db/get_userSearch/${uid}"));

    if (response.statusCode == 200) {
      all_userSearch = getUserSearchResFromJson(response.body);
      log(jsonEncode(all_userSearch));

      var searchResults =
          all_userSearch.where((user) => user.phone.startsWith(query)).toList();

      // ตรวจสอบว่ามีผลลัพธ์การค้นหาหรือไม่
      if (searchResults.isNotEmpty) {
        OverlayEntry? overlayEntry;

        overlayEntry = OverlayEntry(
          builder: (context) => Positioned(
            top: 160, // ปรับค่านี้ตามความสูงของ app bar ของคุณ
            left: 20,
            right: 20,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                constraints:
                    BoxConstraints(maxHeight: 300), // จำกัดความสูงสูงสุด
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    var searchResult = searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(searchResult.userImage),
                      ),
                      title: Text(searchResult.name),
                      onTap: () async {
                        ////////////////////////////
                        User_Info_Receive User_Re = User_Info_Receive();
                        User_Re.uid = searchResult.uid;
                        User_Re.name = searchResult.name;
                        User_Re.user_type = searchResult.userType;
                        User_Re.user_image = searchResult.userImage;

                        ///เดี๋ยวมาเพิ่มทีหลัง

                        // เพิ่มส่วนการเรียก API แบบ async
                        try {
                          var receiver = await http.get(
                            Uri.parse(
                                "$url/db/get_Receive/${searchResult.uid}"),
                          );

                          if (receiver.statusCode == 200) {
                            receive_Info =
                                getUserSearchResFromJson(receiver.body);
                            if (receive_Info.isNotEmpty) {
                              receiver_address =
                                  receive_Info.first.address.toString();

                              String? re_coordinates =
                                  receive_Info.first.coordinates;
                              if (re_coordinates != null) {
                                List<String> latLngList =
                                    re_coordinates.split(',');
                                if (latLngList.length == 2) {
                                  double re_latitude =
                                      double.parse(latLngList[0]);
                                  double re_longitude =
                                      double.parse(latLngList[1]);
                                  receive_latLng =
                                      LatLng(re_latitude, re_longitude);
                                }
                              }
                            } else {
                              print(
                                  'receive_Info is empty'); // จัดการกรณีที่ไม่มีข้อมูล
                            }
                          } else {
                            print(
                                'Failed to load receiver info: ${receiver.statusCode}');
                          }
                        } catch (error) {
                          print('Error: $error'); // จัดการข้อผิดพลาด
                        }
                        mapController.move(
                            receive_latLng, mapController.camera.zoom);

                        // อัพเดต context และ UI
                        context.read<ShareData>().user_info_receive = User_Re;
                        log(context.read<ShareData>().user_info_receive.name);
                        To_userImage = searchResult.userImage;
                        To_userName = searchResult.name;
                        To_phone = searchResult.phone;
                        receive_nameCtl.text =
                            "${searchResult.name} Tel. ${searchResult.phone}";
                        To_uid = searchResult.uid;
                        setState(() {});
                        searchController.text = searchResult
                            .phone; // เปลี่ยนจาก searchResult.name เป็น phone
                        overlayEntry?.remove();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // แทรก overlay ลงในต้นไม้ widget
        Overlay.of(context).insert(overlayEntry);

        // เพิ่ม listener เพื่อลบ overlay เมื่อข้อความค้นหาเปลี่ยน
        searchController.addListener(() {
          if (searchController.text != query) {
            overlayEntry?.remove();
          }
        });
      } else {
        // ไม่มีผลลัพธ์การค้นหา ไม่ต้องทำอะไร
        log('ไม่พบผลลัพธ์การค้นหาสำหรับ: $query');
      }
    } else {
      log('ไม่สามารถโหลดข้อมูล userSearch ได้ รหัสสถานะ: ${response.statusCode}');
    }
  }

  Future<void> showNameSearchPopup(BuildContext context, String query,
      TextEditingController searchController) async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    var response = await http.get(Uri.parse("$url/db/get_userSearch/${uid}"));

    if (response.statusCode == 200) {
      all_userSearch = getUserSearchResFromJson(response.body);
      log(jsonEncode(all_userSearch));

      var searchResults =
          all_userSearch.where((user) => user.name.startsWith(query)).toList();

      // ตรวจสอบว่ามีผลลัพธ์การค้นหาหรือไม่
      if (searchResults.isNotEmpty) {
        OverlayEntry? overlayEntry;

        overlayEntry = OverlayEntry(
          builder: (context) => Positioned(
            top: 290, // ปรับค่านี้ตามความสูงของ app bar ของคุณ
            left: 20,
            right: 20,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                constraints:
                    BoxConstraints(maxHeight: 300), // จำกัดความสูงสูงสุด
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    var searchResult = searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(searchResult.userImage),
                      ),
                      title: Text(searchResult.name),
                      onTap: () async {
                        ////////////////////////////
                        User_Info_Receive User_Re = User_Info_Receive();
                        User_Re.uid = searchResult.uid;
                        User_Re.name = searchResult.name;
                        User_Re.user_type = searchResult.userType;
                        User_Re.user_image = searchResult.userImage;

                        ///เดี๋ยวมาเพิ่มทีหลัง

                        try {
                          // ทำการเรียก API และรอการตอบกลับจากเซิร์ฟเวอร์
                          var receiver = await http.get(
                            Uri.parse(
                                "$url/db/get_Receive/${searchResult.uid}"),
                          );

                          if (receiver.statusCode == 200) {
                            receive_Info =
                                getUserSearchResFromJson(receiver.body);
                            if (receive_Info.isNotEmpty) {
                              receiver_address =
                                  receive_Info.first.address.toString();

                              String? re_coordinates =
                                  receive_Info.first.coordinates;
                              if (re_coordinates != null) {
                                List<String> latLngList =
                                    re_coordinates.split(',');
                                if (latLngList.length == 2) {
                                  double re_latitude =
                                      double.parse(latLngList[0]);
                                  double re_longitude =
                                      double.parse(latLngList[1]);
                                  receive_latLng =
                                      LatLng(re_latitude, re_longitude);
                                }
                              }
                            } else {
                              print(
                                  'receive_Info is empty'); // หรือจัดการกรณีที่ไม่มีข้อมูล
                            }
                          } else {
                            print(
                                'Failed to load receiver info: ${receiver.statusCode}');
                          }
                        } catch (error) {
                          print('Error: $error'); // จัดการข้อผิดพลาด
                        }
                        mapController.move(
                            receive_latLng, mapController.camera.zoom);

                        // อัพเดต context และ UI
                        context.read<ShareData>().user_info_receive = User_Re;
                        log(context.read<ShareData>().user_info_receive.name);
                        To_userImage = searchResult.userImage;
                        To_userName = searchResult.name;
                        To_phone = searchResult.phone;
                        receive_nameCtl.text = searchResult.name;
                        To_uid = searchResult.uid;
                        setState(() {});
                        searchController.text =
                            "${searchResult.name} Tel. ${searchResult.phone}";
                        overlayEntry?.remove();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // แทรก overlay ลงในต้นไม้ widget
        Overlay.of(context).insert(overlayEntry);

        // เพิ่ม listener เพื่อลบ overlay เมื่อข้อความค้นหาเปลี่ยน
        searchController.addListener(() {
          if (searchController.text != query) {
            overlayEntry?.remove();
          }
        });
      } else {
        // ไม่มีผลลัพธ์การค้นหา ไม่ต้องทำอะไร
        log('ไม่พบผลลัพธ์การค้นหาสำหรับ: $query');
      }
    } else {
      log('ไม่สามารถโหลดข้อมูล userSearch ได้ รหัสสถานะ: ${response.statusCode}');
    }
  }

  void send() async {
    await uploadAndNavigate();
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    if (product_nameCtl.text.isEmpty ||
        product_detailCtl.text.isEmpty ||
        receive_nameCtl.text.isEmpty ||
        image == null) {
      Fluttertoast.showToast(
          msg: "ข้อมูลไม่ถูกต้องโปรดตรวจสอบความถูกต้อง แล้วลองอีกครั้ง",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          // backgroundColor: Color.fromARGB(120, 0, 0, 0),
          backgroundColor: Color.fromARGB(255, 255, 0, 0),
          textColor: Colors.white,
          fontSize: 15.0);
      Navigator.of(context).pop();
      return;
    }

    var model = UserOrderPostReq(
      p_Name: product_nameCtl.text,
      p_Detail: product_detailCtl.text,
      se_Uid: uid,
      re_Uid: To_uid,
      ri_Uid: null,
      dv_Status: 1,
    );

    var Value = await http.post(Uri.parse("$url/db/add_order"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: userOrderPostReqToJson(model));

    if (Value.statusCode == 200) {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef
          .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      await imageRef.putFile(File(image!.path));

      // รับ URL ของภาพที่อัปโหลด
      product_imgUrl = await imageRef.getDownloadURL();
      log(product_imgUrl.toString());

      var response = await http.get(Uri.parse("$url/db/get_NewOrder"));
      if (response.statusCode == 200) {
        // แปลง JSON เป็น List<Map<String, dynamic>>
        List<dynamic> data_oid = jsonDecode(response.body);
        // เข้าถึงค่า oid จาก List
        if (data_oid.isNotEmpty) {
          var oid = data_oid[0]['oid']; // เข้าถึง oid ของแถวแรก
          log(oid.toString() +
              "oooooooooooooooooooooooooooooooooooooooooooooooooo"); // แสดงค่า oid

          orderStatus = 1;

          var doc = "order${oid}";
          var data = {
            'product_img': product_imgUrl,
            'Order_time_at': DateTime.timestamp(),
            'Order_status': orderStatus,
            'status3_product_img': null,
            'status4_product_img': null,
            'rider_coordinates': null,
          };

          db.collection('Order_Info').doc(doc).set(data);
        } else {
          log('No data found');
        }
      } else {
        log('Error: ${response.statusCode}');
      }
      Navigator.of(context).pop(); // ปิด dialog
      log('Registration is successful');
      Get.to(() => HomePage());
    } else {
      // ถ้า status code ไม่ใช่ 200 ให้ดึงข้อความจาก response body
      var responseBody = jsonDecode(Value.body);
      setState(() {
        Fluttertoast.showToast(
            msg: "เกิดข้อผิดพลาด!!!",
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

  Future<void> uploadAndNavigate() async {
    // แสดงวงโหลด
    showDialog(
      context: context,
      barrierDismissible: false, // ไม่ให้ปิดเมื่อแตะนอก
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // เปลี่ยนรูปทรงของ Dialog
          ),
          child: Container(
            padding: EdgeInsets.all(24), // เพิ่ม Padding
            height: 120, // กำหนดความสูง
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 50),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        const Color.fromARGB(
                            255, 139, 15, 188)), // เปลี่ยนสีของวงโหลด
                  ),
                ),
                SizedBox(width: 15),
                Text(
                  'Loading...', // ข้อความที่จะแสดง
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
