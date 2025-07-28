import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/GetSendOrder_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetUserSearch_Res.dart';
import 'package:mobile_miniproject_app/pages/Add_Item.dart';
import 'package:mobile_miniproject_app/pages/Home.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerProfile.dart';
import 'package:mobile_miniproject_app/pages/rider/RiderReceive.dart';
import 'package:mobile_miniproject_app/pages/rider/RiderHistory.dart';
import 'package:mobile_miniproject_app/pages/rider/RiderHome.dart';
import 'package:mobile_miniproject_app/pages/rider/RiderProfile.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';

class RiderOrderinfoPage extends StatefulWidget {
  int info_send_uid; // ประกาศตัวแปรในคลาสนี้
  int selectedIndex = 0;
  int info_receive_uid; // ประกาศตัวแปรในคลาสนี้
  int info_oid;

  RiderOrderinfoPage({
    super.key,
    required this.info_send_uid,
    required this.info_receive_uid,
    required this.selectedIndex,
    required this.info_oid,
  });

  @override
  State<RiderOrderinfoPage> createState() => _RiderOrderinfoPageState();
}

class _RiderOrderinfoPageState extends State<RiderOrderinfoPage> {
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
  LatLng send_latLng = LatLng(0, 0);
  LatLng receive_latLng = LatLng(0, 0);
  LatLng rider_latLng = LatLng(0, 0);
  List<LatLng> polylinePoints = [];
  var db = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  double distanceInKm = 0;

  @override
  void initState() {
    super.initState();
    sender_uid = widget.info_send_uid;
    receiver_uid = widget.info_receive_uid;
    _selectedIndex = widget.selectedIndex;
    loadDataAsync(); // กำหนดค่าใน initState
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
              child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0), // กำหนดมุมโค้ง
              ),
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: send_latLng,
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
                        point: send_latLng,
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                        alignment: Alignment.center,
                      ),
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
                  if (polylinePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: polylinePoints, // แสดงเส้นทางที่คำนวณได้
                          strokeWidth: 4.0,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          )),
          Padding(
            padding: const EdgeInsets.all(8.0), // เพิ่ม Padding รอบๆ Card
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0), // กำหนดมุมโค้ง
              ),
              child: Padding(
                padding: const EdgeInsets.all(17.0), // Padding ใน Card
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // จัดเรียงข้อความไปทางซ้าย
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
                                '${product_name}',
                                style: TextStyle(fontSize: 30),
                                softWrap:
                                    true, // ทำให้ข้อความเว้นบรรทัดอัตโนมัติ
                                overflow:
                                    TextOverflow.visible, // ให้ข้อความแสดงต่อไป
                              ),
                              Text(
                                '${product_detail}',
                                style: TextStyle(fontSize: 15),
                                softWrap:
                                    true, // ทำให้ข้อความเว้นบรรทัดอัตโนมัติ
                                overflow:
                                    TextOverflow.visible, // ให้ข้อความแสดงต่อไป
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
                                      // แสดงวงโหลดเมื่อกำลังโหลดภาพ
                                      return CircularProgressIndicator();
                                    } else if (snapshot.hasError) {
                                      // แสดงข้อความหรือ widget อื่นๆ ในกรณีที่เกิดข้อผิดพลาด
                                      return Text('Error loading image');
                                    } else {
                                      // แสดงภาพเมื่อโหลดเสร็จ
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
                        crossAxisAlignment:
                            CrossAxisAlignment.start, // จัดแนวข้อความไปทางซ้าย
                        children: [
                          Icon(Icons.location_on,
                              color: Colors.red, size: 14), // ปรับขนาดไอคอน
                          SizedBox(width: 5),
                          Expanded(
                            // ใช้ Expanded เพื่อให้ Text ใช้พื้นที่ว่างที่เหลือ
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // จัดแนวข้อความไปทางซ้าย
                              children: [
                                Text(sender_name),
                                Text(
                                  sender_address, // จะอยู่ใต้ receiver_name
                                  softWrap:
                                      true, // ทำให้ข้อความเว้นบรรทัดอัตโนมัติ
                                  maxLines:
                                      2, // กำหนดจำนวนบรรทัดสูงสุดที่จะแสดง
                                  overflow: TextOverflow
                                      .ellipsis, // แสดง ... ถ้ามีข้อความเกิน
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
                        crossAxisAlignment:
                            CrossAxisAlignment.start, // จัดแนวข้อความไปทางซ้าย
                        children: [
                          Icon(Icons.location_on,
                              color: const Color.fromARGB(255, 79, 252, 10),
                              size: 14), // ปรับขนาดไอคอน
                          SizedBox(width: 5),
                          Expanded(
                            // ใช้ Expanded เพื่อให้ Text ใช้พื้นที่ว่างที่เหลือ
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // จัดแนวข้อความไปทางซ้าย
                              children: [
                                Text(receiver_name),
                                Text(
                                  receiver_address, // จะอยู่ใต้ receiver_name
                                  softWrap:
                                      true, // ทำให้ข้อความเว้นบรรทัดอัตโนมัติ
                                  maxLines:
                                      2, // กำหนดจำนวนบรรทัดสูงสุดที่จะแสดง
                                  overflow: TextOverflow
                                      .ellipsis, // แสดง ... ถ้ามีข้อความเกิน
                                ),
                              ],
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
          Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 10),
            child: FilledButton(
              onPressed: () {
                UpdateStatus(widget.info_oid);
                Get.to(() => RiderReceivePage(
                    info_send_uid: widget.info_send_uid,
                    info_receive_uid: widget.info_receive_uid,
                    info_oid: widget.info_oid,
                    selectedIndex: 1));
                var doc = "order${widget.info_oid}";
                // ข้อมูลที่ต้องการอัปเดต
                var dataToUpdate = {
                  'Order_status': 2,
                  'rider_coordinates':
                      '${rider_latLng.latitude},${rider_latLng.longitude}',
                };
                db.collection('Order_Info').doc(doc).update(dataToUpdate);
                context.read<ShareData>().listener!.cancel();
              },
              child: Text(
                "Hire",
                style: TextStyle(fontSize: 20),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color.fromARGB(
                    255, 139, 15, 188), // เปลี่ยนสีพื้นหลังของปุ่ม
                minimumSize: Size(
                    200, 50), // กำหนดขนาดขั้นต่ำของปุ่ม (ความกว้าง, ความสูง)
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15), // กำหนดมุมโค้งของปุ่ม
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
          currentIndex: 0,
          onTap: _onItemTapped,
          selectedItemColor: Colors.black, // สีของ icon ที่เลือก
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
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    var sender = await http.get(Uri.parse("$url/db/get_Send/${sender_uid}"));
    if (sender.statusCode == 200) {
      send_Info = getUserSearchResFromJson(sender.body);
      sender_name = send_Info.first.name.toString();
      sender_address = send_Info.first.address.toString();

      String? send_coordinates = send_Info.first.coordinates;
      if (send_coordinates != null) {
        List<String> latLngList = send_coordinates.split(',');
        if (latLngList.length == 2) {
          double send_latitude = double.parse(latLngList[0]);
          double send_longitude = double.parse(latLngList[1]);
          send_latLng = LatLng(send_latitude, send_longitude);
        }
      }
    }

    var receiver =
        await http.get(Uri.parse("$url/db/get_Receive/${receiver_uid}"));
    if (receiver.statusCode == 200) {
      receive_Info = getUserSearchResFromJson(receiver.body);
      receiver_name = receive_Info.first.name.toString();
      receiver_address = receive_Info.first.address.toString();

      String? re_coordinates = receive_Info.first.coordinates;
      if (re_coordinates != null) {
        List<String> latLngList = re_coordinates.split(',');
        if (latLngList.length == 2) {
          double re_latitude = double.parse(latLngList[0]);
          double re_longitude = double.parse(latLngList[1]);
          receive_latLng = LatLng(re_latitude, re_longitude);
        }
      }
    }

    var rider = await http.get(Uri.parse(
        "$url/db/get_Rider/${context.read<ShareData>().user_info_send.uid}"));
    if (rider.statusCode == 200) {
      rider_Info = getUserSearchResFromJson(rider.body);
      if (rider_Info.first.coordinates != null) {
        final coords = rider_Info.first.coordinates!.split(',');
        final lat = double.parse(coords[0]);
        final lng = double.parse(coords[1]);
        rider_latLng = LatLng(lat, lng);
      } else {
        // Handle null case
      }
    }

    var order =
        await http.get(Uri.parse("$url/db/get_OneOrder/${widget.info_oid}"));
    if (order.statusCode == 200) {
      order_one = getSendOrderFromJson(order.body);
      product_name = order_one.first.p_Name.toString();
      product_detail = order_one.first.p_Detail.toString();

      String? re_coordinates = receive_Info.first.coordinates;
      if (re_coordinates != null) {
        List<String> latLngList = re_coordinates.split(',');
        if (latLngList.length == 2) {
          double re_latitude = double.parse(latLngList[0]);
          double re_longitude = double.parse(latLngList[1]);
          receive_latLng = LatLng(re_latitude, re_longitude);
        }
      }
    }

    // เรียก getRouteCoordinates หลังจากได้รับค่า latLng ของผู้ส่งและผู้รับ
    if (send_latLng != null && receive_latLng != null) {
      await getRouteCoordinates();
    }

    setState(() {});
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

  Future<void> getRouteCoordinates() async {
    // Move the map to the sender's location
    mapController.move(send_latLng, mapController.camera.zoom);

    final url =
        'https://router.project-osrm.org/route/v1/driving/${send_latLng.longitude},${send_latLng.latitude};${receive_latLng.longitude},${receive_latLng.latitude}?geometries=geojson';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Get route distance
      final distance = data['routes'][0]['distance'];

      // Convert distance from meters to kilometers
      distanceInKm = distance / 1000;

      // Print distance (or you can display it on the UI)
      print('Distance: ${distanceInKm.toStringAsFixed(2)} km');

      // Get route coordinates for polyline
      final coordinates = data['routes'][0]['geometry']['coordinates'];
      List<LatLng> routePoints = coordinates.map<LatLng>((coord) {
        return LatLng(coord[1], coord[0]);
      }).toList();

      setState(() {
        polylinePoints = routePoints;
      });
    } else {
      print('Error getting route');
    }
  }

  void UpdateStatus(int oid) async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    http.put(
      Uri.parse(
          "$url/db/update_status/${oid}/${2}/${context.read<ShareData>().user_info_send.uid}"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
    );
  }
}
