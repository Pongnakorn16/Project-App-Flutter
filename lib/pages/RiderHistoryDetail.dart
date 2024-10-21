import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/GetOneUser_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetSendOrder_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetUserSearch_Res.dart';
import 'package:mobile_miniproject_app/pages/Add_Item.dart';
import 'package:mobile_miniproject_app/pages/Home.dart';
import 'package:mobile_miniproject_app/pages/Profile.dart';
import 'package:mobile_miniproject_app/pages/RiderReceive.dart';
import 'package:mobile_miniproject_app/pages/RiderHistory.dart';
import 'package:mobile_miniproject_app/pages/RiderHome.dart';
import 'package:mobile_miniproject_app/pages/RiderProfile.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';

class RiderHistoryDetail extends StatefulWidget {
  int info_send_uid; // ประกาศตัวแปรในคลาสนี้
  int selectedIndex = 0;
  int info_receive_uid; // ประกาศตัวแปรในคลาสนี้
  int info_oid;

  RiderHistoryDetail({
    super.key,
    required this.info_send_uid,
    required this.info_receive_uid,
    required this.selectedIndex,
    required this.info_oid,
  });

  @override
  State<RiderHistoryDetail> createState() => _RiderHistoryDetailState();
}

class _RiderHistoryDetailState extends State<RiderHistoryDetail> {
  MapController mapController = MapController();
  List<GetUserSearchRes> send_Info = [];
  List<GetUserSearchRes> receive_Info = [];
  List<GetUserSearchRes> rider_Info = [];
  List<GetSendOrder> order_one = [];
  int sender_uid = 0; // ประกาศตัวแปรเพื่อเก็บค่า
  int receiver_uid = 0;
  String sender_name = "";
  String receiver_name = "";
  String sender_address = "";
  String receiver_address = "";
  String product_name = "";
  String product_detail = "";
  String product_imgUrl = "";
  String product_imgUrl3 = "";
  String product_imgUrl4 = "";

  var db = FirebaseFirestore.instance;
  var Dv_date;
  var Dv_status;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    sender_uid = widget.info_send_uid;
    receiver_uid = widget.info_receive_uid;
    _selectedIndex = widget.selectedIndex;
    loadDataAsync();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            // ใช้ Expanded เพื่อให้ Card ขยายเต็มพื้นที่
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(17.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product_name ?? 'N/A',
                                  style: TextStyle(fontSize: 30),
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                ),
                                Text(
                                  product_detail ?? 'N/A',
                                  style: TextStyle(fontSize: 15),
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 20),
                                  child: FutureBuilder(
                                    future: _loadImage(product_imgUrl),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<Image> snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (snapshot.hasError) {
                                        return Text('Error loading image');
                                      } else {
                                        return Image.network(
                                          product_imgUrl,
                                          height: 100,
                                          width: 50,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                        child: Divider(
                          color: Colors.black,
                          thickness: 2,
                          indent: 2,
                          endIndent: 2,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 5, top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on,
                                color: Colors.red, size: 14),
                            SizedBox(width: 5),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sender_name),
                                  Text(
                                    sender_address,
                                    softWrap: true,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 5, top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on,
                                color: const Color.fromARGB(255, 79, 252, 10),
                                size: 14),
                            SizedBox(width: 5),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(receiver_name),
                                  Text(
                                    receiver_address,
                                    softWrap: true,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10, top: 120),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'จัดส่งโดย : ${rider_Info.isNotEmpty ? rider_Info.first.name : "N/A"}',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'ทะเบียน : ${rider_Info.isNotEmpty ? rider_Info.first.licensePlate : "N/A"}',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: 30,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Rider tel. : ${rider_Info.isNotEmpty ? rider_Info.first.phone : "N/A"}',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Delivery date : ${Dv_date ?? "N/A"}',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 30, left: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 20),
                              child: FutureBuilder(
                                future: _loadImage(product_imgUrl),
                                builder: (BuildContext context,
                                    AsyncSnapshot<Image> snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  } else if (snapshot.hasError) {
                                    return Text('Error loading image');
                                  } else {
                                    return Image.network(
                                      product_imgUrl,
                                      height: 100,
                                      width: 70,
                                    );
                                  }
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 20),
                              child: FutureBuilder(
                                future: _loadImage3(product_imgUrl3),
                                builder: (BuildContext context,
                                    AsyncSnapshot<Image> snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  } else if (snapshot.hasError) {
                                    return Text('Error loading image');
                                  } else {
                                    return Image.network(
                                      product_imgUrl3,
                                      height: 100,
                                      width: 70,
                                    );
                                  }
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: FutureBuilder(
                                future: _loadImage4(product_imgUrl4),
                                builder: (BuildContext context,
                                    AsyncSnapshot<Image> snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  } else if (snapshot.hasError) {
                                    return Text('Error loading image');
                                  } else {
                                    return Image.network(
                                      product_imgUrl4,
                                      height: 100,
                                      width: 70,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 90),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  color: Dv_status == 1
                                      ? Colors.grey
                                      : Dv_status == 2
                                          ? Colors.yellow
                                          : Dv_status == 3
                                              ? Colors.yellow
                                              : Dv_status == 4
                                                  ? Colors.green
                                                  : Colors
                                                      .black, // กำหนดสีตาม dv_Status
                                  size: 9,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  Dv_status == 1
                                      ? 'รอไรเดอร์มารับสินค้า'
                                      : Dv_status == 2
                                          ? 'ไรเดอร์รับงาน'
                                          : Dv_status == 3
                                              ? 'ไรเดอร์รับสินค้าแล้วและกำลังเดินทาง'
                                              : Dv_status == 4
                                                  ? 'จัดส่งสำเร็จ'
                                                  : 'สถานะไม่ถูกต้อง', // กำหนดข้อความตาม dv_Status
                                  style: TextStyle(
                                    fontSize: Dv_status == 3
                                        ? 10
                                        : 15, // กำหนดขนาดฟอนต์
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          buildBottomNavigationBar(),
        ],
      ),
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
          currentIndex: 1,
          onTap: _onItemTapped,
          selectedItemColor: Colors.yellow, // สีของ icon ที่เลือก
          unselectedItemColor: Colors.grey, // สีของ icon ที่ไม่ได้เลือก
          backgroundColor: Colors.white,
          iconSize: 20,
          selectedLabelStyle: TextStyle(
              fontSize: 15, fontWeight: FontWeight.normal), // ปรับขนาดฟอนต์
          unselectedLabelStyle: TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_edu_outlined), // Icon for the Add button
              label: 'History', // Label for the Add button
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          type: BottomNavigationBarType.fixed, // ใช้ประเภท Fixed
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
    try {
      var value = await Configuration.getConfig();
      String url = value['apiEndpoint'];

      var sender = await http.get(Uri.parse("$url/db/get_Send/${sender_uid}"));
      if (sender.statusCode == 200) {
        send_Info = getUserSearchResFromJson(sender.body);
        if (send_Info.isNotEmpty) {
          sender_name = send_Info.first.name ?? "N/A";
          sender_address = send_Info.first.address ?? "N/A";
        }
      }

      var receiver =
          await http.get(Uri.parse("$url/db/get_Receive/${receiver_uid}"));
      if (receiver.statusCode == 200) {
        receive_Info = getUserSearchResFromJson(receiver.body);
        if (receive_Info.isNotEmpty) {
          receiver_name = receive_Info.first.name ?? "N/A";
          receiver_address = receive_Info.first.address ?? "N/A";
        }
      }

      var order =
          await http.get(Uri.parse("$url/db/get_OneOrder/${widget.info_oid}"));
      if (order.statusCode == 200) {
        order_one = getSendOrderFromJson(order.body);
        if (order_one.isNotEmpty) {
          product_name = order_one.first.p_Name ?? "N/A";
          product_detail = order_one.first.p_Detail ?? "N/A";

          var rider = await http
              .get(Uri.parse("$url/db/get_Rider/${order_one.first.ri_Uid}"));
          if (rider.statusCode == 200) {
            rider_Info = getUserSearchResFromJson(rider.body);
          }
        }
      }

      var result = await db
          .collection('Order_Info')
          .doc("order${widget.info_oid}")
          .get();
      if (result.exists) {
        var data = result.data();
        if (data != null) {
          Dv_status = data['Order_status'] ?? 0;
          var timestamp = data['Order_time_at'];
          if (timestamp != null) {
            DateTime orderDate = timestamp.toDate();
            Dv_date = DateFormat('dd/MM/yyyy').format(orderDate);
          } else {
            Dv_date = "N/A";
          }
        }
      }

      setState(() {});
    } catch (e) {
      log("Error in loadDataAsync: $e");
      // Handle error appropriately
    }
  }

  Future<Image> _loadImage(String url) async {
    var inboxRef = db.collection("Order_Info");
    var document = await inboxRef.doc(
        "order${widget.info_oid}"); // ดึงเอกสารที่มีชื่อ document ตรงกับค่าที่กรอก
    var result = await document.get();
    log(result.data()!['product_img'].toString());
    product_imgUrl = result.data()!['product_img'].toString();
    final image = Image.network(product_imgUrl);
    // รอให้ภาพโหลด
    await precacheImage(image.image, context);

    return image;
  }

  Future<Image> _loadImage3(String url) async {
    var inboxRef = db.collection("Order_Info");
    var document = await inboxRef.doc(
        "order${widget.info_oid}"); // ดึงเอกสารที่มีชื่อ document ตรงกับค่าที่กรอก
    var result = await document.get();
    log(result.data()!['product_img'].toString());
    product_imgUrl3 = result.data()!['status3_product_img'].toString();
    final image = Image.network(product_imgUrl3);
    // รอให้ภาพโหลด
    await precacheImage(image.image, context);

    return image;
  }

  Future<Image> _loadImage4(String url) async {
    var inboxRef = db.collection("Order_Info");
    var document = await inboxRef.doc(
        "order${widget.info_oid}"); // ดึงเอกสารที่มีชื่อ document ตรงกับค่าที่กรอก
    var result = await document.get();
    log(result.data()!['product_img'].toString());
    product_imgUrl4 = result.data()!['status4_product_img'].toString();
    final image = Image.network(product_imgUrl4);
    // รอให้ภาพโหลด
    await precacheImage(image.image, context);

    return image;
  }
}
