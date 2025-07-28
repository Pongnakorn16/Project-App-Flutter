import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/GetSendOrder_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetUserSearch_Res.dart';
import 'package:mobile_miniproject_app/pages/Add_Item.dart';
import 'package:mobile_miniproject_app/pages/Home.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerProfile.dart';

class OrderinfoPage extends StatefulWidget {
  int info_send_uid; // ประกาศตัวแปรในคลาสนี้
  int selectedIndex = 0;
  int info_receive_uid; // ประกาศตัวแปรในคลาสนี้
  int info_oid;

  OrderinfoPage({
    super.key,
    required this.info_send_uid,
    required this.info_receive_uid,
    required this.selectedIndex,
    required this.info_oid,
  });

  @override
  State<OrderinfoPage> createState() => _OrderinfoPageState();
}

class _OrderinfoPageState extends State<OrderinfoPage> {
  MapController mapController = MapController();
  List<GetUserSearchRes> send_Info = [];
  List<GetUserSearchRes> receive_Info = [];
  List<GetUserSearchRes> rider_Info = [];
  List<LatLng> allSendLatLngs = [];
  List<LatLng> allReceiveLatLngs = [];
  List<List<LatLng>> allPolylinePoints = [];
  List<GetSendOrder> order_one = [];
  Map<int, LatLng> riderPositions = {};
  List<LatLng> allRiderLatLngs = [];

  int sender_uid = 0; // ประกาศตัวแปรเพื่อเก็บค่า
  int receiver_uid = 0;
  String sender_address = "";
  String receiver_address = "";
  String product_name = "";
  String product_detail = "";
  String product_imgUrl = "";
  String? licence_plate = "";
  String? rider_phone = "";
  String? rider_name = "";
  String product_imgUrl3 = "";
  String product_imgUrl4 = "";
  LatLng send_latLng = LatLng(0, 0);
  LatLng receive_latLng = LatLng(0, 0);
  LatLng riderLatLng = LatLng(0, 0);
  List<LatLng> polylinePoints = [];
  var db = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  double distanceInKm = 0;
  var Dv_date;

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
                      Marker(
                        point: riderLatLng,
                        width: 60, // เพิ่มขนาดให้ใหญ่ขึ้น
                        height: 60, // เพิ่มขนาดให้ใหญ่ขึ้น
                        child: Icon(
                          Icons.motorcycle,
                          color: Colors.blue,
                          size: 30, // เพิ่มขนาดไอคอน
                        ),
                      ),
                    ],
                  ),
                  PolylineLayer(
                    polylines: [
                      for (int i = 0; i < allPolylinePoints.length; i++) ...[
                        Polyline(
                          points: allPolylinePoints[i],
                          strokeWidth: 4.0,
                          color: Colors.blue,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          )),
          Container(
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Row(
                          children: [
                            Icon(Icons.location_on,
                                color: Colors.red, size: 14), // ปรับขนาดไอคอน
                            SizedBox(width: 5),
                            Text(sender_address.toString()),
                          ],
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5, top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.location_on,
                                color: const Color.fromARGB(255, 79, 252, 10),
                                size: 14), // ปรับขนาดไอคอน
                            SizedBox(width: 5),
                            Text(receiver_address.toString()),
                          ],
                        ),
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
                              ),
                              Text(
                                '${product_detail}',
                                style: TextStyle(fontSize: 15),
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
                      padding: EdgeInsets.only(top: 10.0, bottom: 15.0),
                      child: Divider(
                        color: Colors.black,
                        thickness: 2,
                        indent: 2,
                        endIndent: 2,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'จัดส่งโดย : ${rider_name ?? 'null'}',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'ทะเบียน : ${licence_plate ?? 'null'}',
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
                                    'Rider tel. : ${rider_phone ?? 'null'}',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Delivery date : ${Dv_date}',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          )),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 10, top: 15, right: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              // ใช้ Expanded ที่นี่
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: FutureBuilder(
                                  future: _loadImage3(product_imgUrl3),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<Widget> snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return CircularProgressIndicator();
                                    } else if (snapshot.hasError) {
                                      return Text('Error loading image');
                                    } else {
                                      return SizedBox(
                                        // ใช้ SizedBox เพื่อกำหนดขนาดของรูป
                                        width: 100, // กำหนดความกว้างของรูป
                                        height: 100, // กำหนดความสูงของรูป
                                        child:
                                            snapshot.data!, // แสดงภาพที่โหลดได้
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          )),
                          Expanded(
                            // ใช้ Expanded ที่นี่
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 30),
                                  child: FutureBuilder(
                                    future: _loadImage4(product_imgUrl4),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<Widget> snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (snapshot.hasError) {
                                        return Text('Error loading image');
                                      } else {
                                        return SizedBox(
                                          // ใช้ SizedBox เพื่อกำหนดขนาดของรูป
                                          width: 100, // กำหนดความกว้างของรูป
                                          height: 100, // กำหนดความสูงของรูป
                                          child: snapshot
                                              .data!, // แสดงภาพที่โหลดได้
                                        ); // แสดงภาพหรือ Icon
                                      }
                                    },
                                  ),
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
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color.fromARGB(255, 115, 28, 168),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          iconSize: 20,
          selectedLabelStyle:
              TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline), // Icon for the Add button
              label: 'Add', // Label for the Add button
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
              builder: (context) => HomePage()), // สมมติว่ามี HomePage
        );
      } else if (index == 1) {
        // Navigate to Add page
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AddItemPage()), // เปลี่ยนเป็น AddPage()
        );
      } else if (index == 2) {
        // Navigate to Profile page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(onClose: () {}, selectedIndex: 1),
          ),
        );
      }
    });
  }

  Future<void> loadDataAsync() async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    // ตรวจสอบ sender
    var sender = await http.get(Uri.parse("$url/db/get_Send/${sender_uid}"));
    if (sender.statusCode == 200) {
      send_Info = getUserSearchResFromJson(sender.body);
      if (send_Info.isNotEmpty) {
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
      } else {
        print('send_Info is empty'); // หรือจัดการกรณีที่ไม่มีข้อมูล
      }
    }

    // ตรวจสอบ receiver
    var receiver =
        await http.get(Uri.parse("$url/db/get_Receive/${receiver_uid}"));
    if (receiver.statusCode == 200) {
      receive_Info = getUserSearchResFromJson(receiver.body);
      if (receive_Info.isNotEmpty) {
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
      } else {
        print('receive_Info is empty'); // หรือจัดการกรณีที่ไม่มีข้อมูล
      }
    }

    // ตรวจสอบ order
    var order =
        await http.get(Uri.parse("$url/db/get_OneOrder/${widget.info_oid}"));
    if (order.statusCode == 200) {
      order_one = getSendOrderFromJson(order.body);
      if (order_one.isNotEmpty) {
        product_name = order_one.first.p_Name.toString();
        product_detail = order_one.first.p_Detail.toString();
      } else {
        print('order_one is empty'); // หรือจัดการกรณีที่ไม่มีข้อมูล
      }
    }

    // ตรวจสอบ rider
    var rider = await http.get(Uri.parse(
        "$url/db/get_Rider/${order_one.isNotEmpty ? order_one.first.ri_Uid : ''}"));
    if (rider.statusCode == 200) {
      rider_Info = getUserSearchResFromJson(rider.body);
      if (rider_Info.isNotEmpty) {
        licence_plate = rider_Info.first.licensePlate;
        rider_phone = rider_Info.first.phone;
        rider_name = rider_Info.first.name;
      } else {
        print('rider_Info is empty'); // หรือจัดการกรณีที่ไม่มีข้อมูล
      }
      if (rider_Info.isNotEmpty) {
        licence_plate = rider_Info.first.licensePlate;
        rider_phone = rider_Info.first.phone;
        rider_name = rider_Info.first.name;
      } else {
        // ถ้า rider_Info ว่าง ให้ตั้งค่าตัวแปรเป็น null
        licence_plate = null;
        rider_phone = null;
        rider_name = null;
      }
    }

    var result =
        await db.collection('Order_Info').doc("order${widget.info_oid}").get();
    if (result.exists) {
      var data = result.data();
      if (data != null) {
        var timestamp = data['Order_time_at'];
        if (timestamp != null) {
          DateTime orderDate = timestamp.toDate();
          Dv_date = DateFormat('dd/MM/yyyy').format(orderDate);
        } else {
          Dv_date = "N/A";
        }
      }
    }

    // เรียก getRouteCoordinates หลังจากได้รับค่า latLng ของผู้ส่งและผู้รับ
    loadRiderLocation(order_one.first.oid);
    if (send_latLng != null && receive_latLng != null) {
      await getRouteCoordinates(order_one.first.se_Uid, order_one.first.re_Uid);
    }

    setState(() {});
  }

  Future<Image> _loadImage(String url) async {
    var inboxRef = db.collection("Order_Info");
    var document = await inboxRef.doc("order${widget.info_oid}");
    var result = await document.get();

    // ตรวจสอบว่าผลลัพธ์ไม่เป็น null และค่า URL มีค่า
    product_imgUrl = result.data()?['product_img'] ?? '';
    if (product_imgUrl.isEmpty) {
      return Image.asset('assets/images/placeholder.png'); // หรือใช้ Icon แทน
    }
    final image = Image.network(product_imgUrl);
    await precacheImage(image.image, context);
    return image;
  }

  Future<Widget> _loadImage3(String url) async {
    var inboxRef = db.collection("Order_Info");
    var document = await inboxRef.doc("order${widget.info_oid}");
    var result = await document.get();

    // ตรวจสอบว่าผลลัพธ์ไม่เป็น null และค่า URL มีค่า
    product_imgUrl3 = result.data()?['status3_product_img'] ?? '';
    if (product_imgUrl3.isEmpty) {
      return Icon(Icons.image, size: 100); // ใช้ Icon แทน
    }

    final image = Image.network(product_imgUrl3);
    await precacheImage(image.image, context);
    return image;
  }

  Future<Widget> _loadImage4(String url) async {
    var inboxRef = db.collection("Order_Info");
    var document = await inboxRef.doc("order${widget.info_oid}");
    var result = await document.get();

    // ตรวจสอบว่าผลลัพธ์ไม่เป็น null และค่า URL มีค่า
    product_imgUrl4 = result.data()?['status4_product_img'] ?? '';
    if (product_imgUrl4.isEmpty) {
      return Icon(Icons.image, size: 100); // ใช้ Icon แทน
    }

    final image = Image.network(product_imgUrl4);
    await precacheImage(image.image, context);
    return image;
  }

  Future<void> getRouteCoordinates(int se_uid, int re_uid) async {
    // Move the map to the sender's location
    mapController.move(send_latLng, mapController.camera.zoom);

    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    var sender = await http.get(Uri.parse("$url/db/get_Send/${se_uid}"));
    if (sender.statusCode == 200) {
      send_Info = getUserSearchResFromJson(sender.body);
      sender_address = send_Info.first.address.toString();

      String? send_coordinates = send_Info.first.coordinates;
      if (send_coordinates != null) {
        List<String> latLngList = send_coordinates.split(',');
        if (latLngList.length == 2) {
          double send_latitude = double.parse(latLngList[0]);
          double send_longitude = double.parse(latLngList[1]);
          send_latLng = LatLng(send_latitude, send_longitude);

          // เก็บค่า send_latLng ลงใน List
          allSendLatLngs.add(send_latLng);
        }
      }
    }

    var receiver = await http.get(Uri.parse("$url/db/get_Receive/${re_uid}"));
    if (receiver.statusCode == 200) {
      receive_Info = getUserSearchResFromJson(receiver.body);
      receiver_address = receive_Info.first.address.toString();

      String? re_coordinates = receive_Info.first.coordinates;
      if (re_coordinates != null) {
        List<String> latLngList = re_coordinates.split(',');
        if (latLngList.length == 2) {
          double re_latitude = double.parse(latLngList[0]);
          double re_longitude = double.parse(latLngList[1]);
          receive_latLng = LatLng(re_latitude, re_longitude);

          // เก็บค่า receive_latLng ลงใน List
          allReceiveLatLngs.add(receive_latLng);
        }
      }
    }

    final url_location =
        'https://router.project-osrm.org/route/v1/driving/${send_latLng.longitude},${send_latLng.latitude};${receive_latLng.longitude},${receive_latLng.latitude}?geometries=geojson';
    final response = await http.get(Uri.parse(url_location));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Get route coordinates for polyline
      final coordinates = data['routes'][0]['geometry']['coordinates'];
      List<LatLng> routePoints = coordinates.map<LatLng>((coord) {
        return LatLng(coord[1], coord[0]);
      }).toList();

      // เก็บค่าของเส้นทางลงใน List
      allPolylinePoints.add(routePoints);
    } else {
      print('Error getting route');
    }

    setState(() {});
  }

  Future<void> loadRiderLocation(int oid) async {
    var riderDoc = await db.collection('Order_Info').doc('order${oid}').get();
    if (riderDoc.exists) {
      String riderCoordinates = riderDoc.data()?['rider_coordinates'];
      print('Rider Coordinates: $riderCoordinates'); // เพิ่มการพิมพ์ข้อมูลพิกัด
      if (riderCoordinates != null) {
        List<String> latLngList = riderCoordinates.split(',');
        if (latLngList.length == 2) {
          double riderLat = double.parse(latLngList[0]);
          double riderLng = double.parse(latLngList[1]);
          LatLng riderLatLng = LatLng(riderLat, riderLng);

          // แทนที่ตำแหน่งไรเดอร์ใน Map
          riderPositions[oid] = riderLatLng;

          // อัปเดตตำแหน่งไรเดอร์ทั้งหมดใน allRiderLatLngs
          allRiderLatLngs = riderPositions.values.toList();

          print('Parsed LatLng: $riderLatLng'); // ตรวจสอบพิกัด
        }
      }
      setState(() {}); // เรียก setState เพื่ออัปเดต UI
    }
  }
}
