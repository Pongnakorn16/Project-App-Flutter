import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:math' hide log;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/request/rider_address_post_req.dart';
import 'package:mobile_miniproject_app/models/response/GetSendOrder_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetUserSearch_Res.dart';
import 'package:mobile_miniproject_app/pages/Home_Send.dart';
import 'package:mobile_miniproject_app/pages/RiderReceive.dart';
import 'package:mobile_miniproject_app/pages/RiderHistory.dart';
import 'package:mobile_miniproject_app/pages/RiderOrderInfo.dart';
import 'package:mobile_miniproject_app/pages/RiderProfile.dart';
import 'package:mobile_miniproject_app/pages/Shop.dart';
import 'package:mobile_miniproject_app/pages/Ticket.dart';
import 'package:mobile_miniproject_app/pages/Profile.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';

class RiderHomePage extends StatefulWidget {
  int selectedIndex = 0;
  RiderHomePage({
    super.key,
  });

  @override
  State<RiderHomePage> createState() => _RiderHomePageState();
}

class _RiderHomePageState extends State<RiderHomePage> {
  List<GetUserSearchRes> send_Info = [];
  int send_uid = 0;
  int info_send_uid = 0;
  int info_receive_uid = 0;
  String send_user_name = '';
  String send_user_type = '';
  String send_user_image = '';
  LatLng? currentLocation;
  String currentAddress = '';

  int receive_uid = 0;
  String receive_user_name = '';
  String receive_user_type = '';
  String receive_user_image = '';
  String username = '';
  int wallet = 0;
  int cart_length = 0;
  GetStorage gs = GetStorage();
  String url = '';
  List<GetSendOrder> rider_Orders = [];
  List<GetUserSearchRes> order_user = [];
  List<Map<String, String>> senderInfoList = [];
  List<String> M_CheckUId = [];
  late Future<void> loadData;
  int _selectedIndex = 0;
  bool _showReceivePage = false;
  late AnimationController _animationController;
  late Animation<Offset> _pageSlideAnimation;
  var db = FirebaseFirestore.instance;
  var New_Dv_status;

  @override
  void initState() {
    send_uid = context.read<ShareData>().user_info_send.uid;
    send_user_name = context.read<ShareData>().user_info_send.name;
    send_user_type = context.read<ShareData>().user_info_send.user_type;
    send_user_image = context.read<ShareData>().user_info_send.user_image;

    receive_uid = context.read<ShareData>().user_info_send.uid;
    receive_user_name = context.read<ShareData>().user_info_send.name;
    receive_user_type = context.read<ShareData>().user_info_send.user_type;
    receive_user_image = context.read<ShareData>().user_info_send.user_image;

    _getCurrentLocation();
    loadData = loadDataAsync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Welcome Rider ', // ข้อความปกติ
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextSpan(
                text: context
                    .read<ShareData>()
                    .user_info_send
                    .name, // ข้อความที่ต้องการเปลี่ยนสี
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(
                      255, 115, 28, 168), // เปลี่ยนสีตามที่ต้องการ
                ),
              ),
            ],
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: FutureBuilder(
                      future: loadData,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (context
                                    .read<ShareData>()
                                    .rider_order_share
                                    .where((order) => M_CheckUId.contains(
                                        order.se_Uid.toString()))
                                    .isEmpty)
                                  const Center(
                                    child: Text(
                                      "There are no orders at the moment,please wait a moment...",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  )
                                else
                                  ...context
                                      .read<ShareData>()
                                      .rider_order_share
                                      .where((order) => M_CheckUId.contains(
                                          order.se_Uid.toString()))
                                      .map((orders) => Card(
                                          elevation: 4.0, // ความลึกเงาของ Card
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                10.0), // กำหนดความโค้งของขอบ
                                          ),
                                          margin: EdgeInsets.all(
                                              8.0), // กำหนดระยะห่าง
                                          child: FutureBuilder(
                                            future: buildOrderItem(
                                                orders), // รอผลลัพธ์จาก Future
                                            builder: (BuildContext context,
                                                AsyncSnapshot<Widget>
                                                    snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                // แสดง loading เมื่อกำลังโหลดข้อมูล
                                                return CircularProgressIndicator();
                                              } else if (snapshot.hasError) {
                                                // แสดงข้อความเมื่อเกิดข้อผิดพลาด
                                                return Text(
                                                    'Error: ${snapshot.error}');
                                              } else if (snapshot.hasData) {
                                                // แสดง Widget เมื่อมีข้อมูล
                                                return snapshot.data!;
                                              } else {
                                                // กรณีที่ไม่มีข้อมูล
                                                return Text(
                                                    'No data available');
                                              }
                                            },
                                          ) // Widget ที่ต้องการแสดงใน Card
                                          ))
                                      .toList(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Receive page
        ],
      ),
      bottomNavigationBar: buildBottomNavigationBar(),
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

  Future<Widget> buildOrderItem(GetSendOrder orders) async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];
    if (orders == null) {
      return Text('Order information is not available');
    }
    // log(url);
    // log(send_uid.toString());
    // log(send_Orders.length.toString());

    if (context.read<ShareData>().listener != null) {
      context.read<ShareData>().listener!.cancel();
      context.read<ShareData>().listener = null;
      log("listener stopped");
    }
    log("Realtime Started!!!!!!!!!!!!!!!!");
    final collectionRef = db.collection("Order_Info");
    context.read<ShareData>().listener = collectionRef.snapshots().listen(
      (snapshot) {
        for (var docChange in snapshot.docChanges) {
          // ตรวจสอบเฉพาะการเปลี่ยนแปลง (modified) เท่านั้น
          if (docChange.type == DocumentChangeType.modified) {
            var data = docChange.doc.data();
            var docId = docChange.doc.id; // ชื่อเอกสารที่มีการเปลี่ยนแปลง

            // แสดง Snackbar เฉพาะเมื่อมีการเปลี่ยนแปลงข้อมูล พร้อมแสดงชื่อเอกสาร
            Get.snackbar(
              "Document: $docId | Status: ${data!['Order_status']}",
              "Order Time: ${data['Order_time_at'].toString()}",
            );
            setState(() {});

            // ตรวจสอบการเปลี่ยนแปลงสถานะใหม่
            if (New_Dv_status != data['Order_status'] ||
                New_Dv_status == null) {
              New_Dv_status = data['Order_status'];
              log("${New_Dv_status}+NEWNEWNENWNEDVVVVVVVVVVVVVVVVSTATATUS (Document: $docId)");
            }
          }
        }
      },
      onError: (error) => log("Listen failed: $error"),
    );

    var result =
        await db.collection('Order_Info').doc("order${orders.oid}").get();
    var data = result.data();

    if (data == null) {
      return Text('Order data not found');
    }

    var Dv_status = data['Order_status'] ?? 0;

    var receive = await http
        .get(Uri.parse("$url/db/get_Order/${orders.se_Uid}/${orders.re_Uid}"));
    var order = json.decode(receive.body);
    var seUser = order['se_user'];
    var reUser = order['re_user'];
    var seUserData = getUserSearchResFromJson(jsonEncode(seUser));
    var reUserData = getUserSearchResFromJson(jsonEncode(reUser));

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IntrinsicWidth(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(FontAwesomeIcons.box,
                        color: const Color.fromARGB(255, 115, 28, 168),
                        size: 20), // ปรับขนาดไอคอน
                    SizedBox(width: 5),
                    Text(
                      orders.p_Name,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.location_on,
                      color: Colors.red, size: 14), // ปรับขนาดไอคอน
                  SizedBox(width: 5),
                  Text(seUserData.first.name),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.location_on,
                      color: Color.fromARGB(255, 79, 252, 10),
                      size: 14), // ปรับขนาดไอคอน
                  SizedBox(width: 5),
                  Text(reUserData.first.name),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Get.to(() => RiderOrderinfoPage(
                            info_send_uid: orders.se_Uid,
                            info_receive_uid: orders.re_Uid,
                            info_oid: orders.oid,
                            selectedIndex: 1));
                      },
                      child: Text("Click for details"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red, // ตั้งค่าสีของข้อความ
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            FilledButton(
              onPressed: () {
                UpdateStatus(orders.oid);
                Get.to(() => RiderReceivePage(
                    info_send_uid: orders.se_Uid,
                    info_receive_uid: orders.re_Uid,
                    info_oid: orders.oid,
                    selectedIndex: 1));
                context.read<ShareData>().listener!.cancel();
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(
                    Color.fromARGB(255, 190, 154, 205)), // สีพื้นหลัง
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0), // ขอบโค้งมน
                  ),
                ),
                padding: WidgetStateProperty.all<EdgeInsets>(
                  EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8), // ปรับลดระยะห่างรอบข้อความและไอคอน
                ),
              ),
              child: Row(
                mainAxisSize:
                    MainAxisSize.min, // ขนาดของ Row จะปรับตามเนื้อหาภายใน
                children: [
                  Text(
                    "Hire",
                    style: TextStyle(
                      color: Color.fromARGB(255, 90, 4, 134), // สีข้อความ
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          ],
        )
      ]),
    );
  }

  Future<void> loadDataAsync() async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];
    log(url);
    log(send_uid.toString());
    log("sddddddddddddddd");
    log(rider_Orders.length.toString());

    var response = await http.get(Uri.parse("$url/db/get_Rider_Order"));
    if (response.statusCode == 200) {
      rider_Orders = getSendOrderFromJson(response.body);
      log(jsonEncode(rider_Orders));
      log("sdddddddddddddddxxxxxxxxxxxxxxxxxx");
      log(rider_Orders.length.toString());

      setState(() {
        context.read<ShareData>().rider_order_share = rider_Orders;
      });
    } else {
      log('Failed to load lottery numbers. Status code: ${response.statusCode}');
    }

    for (var OD in context.read<ShareData>().rider_order_share) {
      var sender = await http.get(Uri.parse("$url/db/get_Send/${OD.se_Uid}"));

      if (sender.statusCode == 200) {
        send_Info = getUserSearchResFromJson(sender.body);

        if (send_Info.isNotEmpty) {
          String sender_name = send_Info.first.name ?? "N/A";
          String sender_address = send_Info.first.address ?? "N/A";

          // เก็บข้อมูล sender_name และ sender_address ใน Map แล้วเพิ่มเข้าไปในลิสต์
          senderInfoList.add({
            "uid": send_Info.first.uid.toString(),
            "sender_name": sender_name,
            "sender_address": sender_address,
            "sender_coordinate": send_Info.first.coordinates.toString(),
          });
        }
      } else {
        log("Failed to load sender info for uid: ${send_Info.first.uid}");
      }
    }

// ตอนนี้ senderInfoList จะมีข้อมูลของ sender ทั้งหมดในลิสต์
    log("Sender Info List: $senderInfoList+JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ");
  }

  void UpdateStatus(int oid) async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    http.put(
      Uri.parse(
          "$url/db/update_status/${oid}/${2}/${context.read<ShareData>().user_info_send.uid}"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
    );

    var doc = "order${oid}";

    // ข้อมูลที่ต้องการอัปเดต
    var dataToUpdate = {
      'Order_status': 2,
    };

    // อัปเดตข้อมูลใน Firebase
    await db.collection('Order_Info').doc(doc).update(dataToUpdate);
  }

  Future<String> getAddressFromLatLng(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isEmpty) return "ไม่พบข้อมูลที่อยู่";

      Placemark place = placemarks[0];

      // สร้างที่อยู่แบบละเอียด
      String address = "";

      if (place.street?.isNotEmpty ?? false) {
        address += "${place.street}";
      }

      if (place.subLocality?.isNotEmpty ?? false) {
        address +=
            address.isEmpty ? place.subLocality! : ", ${place.subLocality}";
      }

      return address;
    } catch (e) {
      return "ไม่สามารถแปลงพิกัดเป็นที่อยู่ได้: $e";
    }
  }

  Future<void> M_check() async {
    M_CheckUId.clear(); // Clear the list before checking

    if (currentLocation == null) {
      print('Current location is not available');
      return;
    }

    // Create Distance calculator from latlong2 package
    final Distance distance = const Distance();

    for (var senderInfo in senderInfoList) {
      // Get coordinates string from senderInfo
      String coordinatesStr = senderInfo["sender_coordinate"] ?? "";

      // Remove any brackets and split the coordinates
      coordinatesStr = coordinatesStr.replaceAll('[', '').replaceAll(']', '');
      List<String> coordinates = coordinatesStr.split(',');

      if (coordinates.length == 2) {
        try {
          // Convert coordinates to double
          double senderLat = double.parse(coordinates[0].trim());
          double senderLng = double.parse(coordinates[1].trim());

          // Calculate distance in meters
          double distanceInMeters = distance.as(
              LengthUnit.Meter,
              LatLng(currentLocation!.latitude, currentLocation!.longitude),
              LatLng(senderLat, senderLng));

          // Check if distance is less than or equal to 20 meters
          if (distanceInMeters <= 20) {
            M_CheckUId.add(senderInfo["uid"]!);
            print(
                'Found nearby sender with UID: ${senderInfo["uid"]} at distance: ${distanceInMeters.toStringAsFixed(2)} meters');
          }
        } catch (e) {
          print(
              'Error parsing coordinates for sender ${senderInfo["uid"]}: $e');
        }
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

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

      if (!mounted) return;

      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });

      await M_check();
      log("${M_CheckUId}+IUDIUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU");

      // แปลงพิกัดเป็นที่อยู่
      String address = await getAddressFromLatLng(currentLocation!);

      // แสดงที่อยู่ (ตัวอย่าง)
      if (mounted) {
        setState(() {
          // สร้าง variable สำหรับเก็บที่อยู่
          currentAddress = address;
        });
      }

      // ตรวจสอบว่า currentLocation ไม่เป็น null ก่อนเข้าถึง latitude และ longitude
      if (currentLocation != null) {
        var model = RiderAddressPostRequest(
          address: currentAddress,
          coordinate:
              "${currentLocation!.latitude},${currentLocation!.longitude}",
        );

        await http.put(
          Uri.parse(
            "$url/db/update_riderAddress/${context.read<ShareData>().user_info_send.uid}",
          ),
          headers: {"Content-Type": "application/json; charset=utf-8"},
          body: RiderAddressPostRequestToJson(model),
        );
      }
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
