import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/GetSendOrder_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetUserSearch_Res.dart';
import 'package:mobile_miniproject_app/pages/Add_Item.dart';
import 'package:mobile_miniproject_app/pages/Home.dart';
import 'package:mobile_miniproject_app/pages/Profile.dart';
import 'package:mobile_miniproject_app/pages/RiderHistory.dart';
import 'package:mobile_miniproject_app/pages/RiderHome.dart';
import 'package:mobile_miniproject_app/pages/RiderProfile.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';

class SendAllMapPage extends StatefulWidget {
  int info_send_uid; // ประกาศตัวแปรในคลาสนี้
  int selectedIndex = 0;
  int info_receive_uid; // ประกาศตัวแปรในคลาสนี้
  int info_oid;

  SendAllMapPage({
    super.key,
    required this.info_send_uid,
    required this.info_receive_uid,
    required this.selectedIndex,
    required this.info_oid,
  });

  @override
  State<SendAllMapPage> createState() => _SendAllMapPageState();
}

class _SendAllMapPageState extends State<SendAllMapPage> {
  MapController mapController = MapController();
  List<GetUserSearchRes> send_Info = [];
  List<GetUserSearchRes> receive_Info = [];
  List<GetSendOrder> allSend_order = [];
  List<LatLng> riderLatLngs = [];

  int sender_uid = 0; // ประกาศตัวแปรเพื่อเก็บค่า
  int receiver_uid = 0;
  String sender_address = "";
  String receiver_address = "";
  String product_name = "";
  String product_detail = "";
  String product_imgUrl = "";
  String product_imgUrl_status4 = "";
  LatLng riderLatLng = LatLng(0, 0);
  LatLng send_latLng = LatLng(0, 0);
  LatLng receive_latLng = LatLng(0, 0);
  List<LatLng> allSendLatLngs = [];
  List<LatLng> allReceiveLatLngs = [];
  List<List<LatLng>> allPolylinePoints = [];
  List<LatLng> allRiderLatLngs = [];
  Map<int, LatLng> riderPositions = {};

  var db = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  double distanceInKm = 0;
  final ImagePicker picker = ImagePicker();
  XFile? image;

  @override
  void initState() {
    super.initState();
    // sender_uid = widget.info_send_uid;
    // receiver_uid = widget.info_receive_uid;
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
                  ),
                  MarkerLayer(
                    markers: [
                      for (int i = 0; i < allSendLatLngs.length; i++) ...[
                        Marker(
                          point: allSendLatLngs[i],
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                        Marker(
                          point: allReceiveLatLngs[i],
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.location_on,
                            color: Colors.green,
                            size: 40,
                          ),
                        ),
                        if (i <
                            allRiderLatLngs
                                .length) // ตรวจสอบว่า index มีอยู่ใน allRiderLatLngs
                          Marker(
                            point: allRiderLatLngs[i],
                            width: 60,
                            height: 60,
                            child: Icon(
                              Icons.motorcycle,
                              color: Colors.blue,
                              size: 30,
                            ),
                          ),
                      ],
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
          // Container(
          //   padding: const EdgeInsets.all(8.0), // เพิ่ม Padding รอบๆ Card
          //   child: Card(
          //     elevation: 4,
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(12.0), // กำหนดมุมโค้ง
          //     ),
          //     child: Padding(
          //       padding: const EdgeInsets.all(17.0), // Padding ใน Card
          //       child: Column(
          //         crossAxisAlignment:
          //             CrossAxisAlignment.start, // จัดเรียงข้อความไปทางซ้าย
          //         children: [
          //           Padding(
          //             padding: const EdgeInsets.only(left: 5),
          //             child: Row(
          //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //               children: [
          //                 Column(
          //                   crossAxisAlignment: CrossAxisAlignment.start,
          //                   children: [
          //                     Text(
          //                       '${product_name}',
          //                       style: TextStyle(fontSize: 30),
          //                     ),
          //                     Text(
          //                       '${product_detail}',
          //                       style: TextStyle(fontSize: 15),
          //                     ),
          //                   ],
          //                 ),
          //                 Column(
          //                   children: [
          //                     Padding(
          //                       padding: const EdgeInsets.only(right: 20),
          //                       child: FutureBuilder(
          //                         future: _loadImage(product_imgUrl),
          //                         builder: (BuildContext context,
          //                             AsyncSnapshot<Image> snapshot) {
          //                           if (snapshot.connectionState ==
          //                               ConnectionState.waiting) {
          //                             // แสดงวงโหลดเมื่อกำลังโหลดภาพ
          //                             return CircularProgressIndicator();
          //                           } else if (snapshot.hasError) {
          //                             // แสดงข้อความหรือ widget อื่นๆ ในกรณีที่เกิดข้อผิดพลาด
          //                             return Text('Error loading image');
          //                           } else {
          //                             // แสดงภาพเมื่อโหลดเสร็จ
          //                             return Image.network(
          //                               product_imgUrl,
          //                               height: 100,
          //                               width: 50,
          //                             );
          //                           }
          //                         },
          //                       ),
          //                     ),
          //                   ],
          //                 )
          //               ],
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
          Padding(
            padding:
                const EdgeInsets.only(left: 30, right: 40, bottom: 20, top: 10),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // จัดตำแหน่งให้ห่างกัน
              children: [
                Column(
                  // ใช้ Column เพื่อจัดตำแหน่งปุ่มและไอคอนในแนวตั้ง
                  children: [
                    FilledButton(
                      onPressed: () {
                        Get.to(HomePage());
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.yellow, // สีพื้นหลังของปุ่ม
                        foregroundColor: const Color.fromARGB(
                            255, 115, 28, 168), // สีข้อความ
                        padding: EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15), // ระยะห่างภายในปุ่ม
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12), // ขอบปุ่มโค้งมน
                        ),
                        elevation: 5, // เงาของปุ่มเพื่อเพิ่มมิติ
                      ),
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min, // กำหนดขนาดให้ Row ตามเนื้อหา
                        mainAxisAlignment:
                            MainAxisAlignment.center, // จัดเรียงเนื้อหาใน Row
                        children: [
                          Text(
                            "Back to HomePage",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8), // ระยะห่างระหว่างข้อความและไอคอน
                          Icon(
                            FontAwesomeIcons.house, // ไอคอนที่คุณต้องการใช้
                            size: 20, // ขนาดของไอคอน
                            color: const Color.fromARGB(
                                255, 115, 28, 168), // สีของไอคอน
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> loadDataAsync() async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    if (context.read<ShareData>().listener != null) {
      context.read<ShareData>().listener!.cancel();
      context.read<ShareData>().listener = null;
      log("listener stopped");
    }
    log("Realtime Started!!!!!!!!!!!!!!!!");

    final collectionRef = db.collection("Order_Info");
    context.read<ShareData>().listener = collectionRef.snapshots().listen(
      (snapshot) {
        // รีเซ็ตค่าตำแหน่งไรเดอร์
        for (var docChange in snapshot.docChanges) {
          if (docChange.type == DocumentChangeType.modified) {
            var data = docChange.doc.data();
            var docId = docChange.doc.id;
            int orderId = int.parse(docId.replaceAll('order', ''));

            // แสดง Snackbar เฉพาะเมื่อมีการเปลี่ยนแปลงข้อมูล พร้อมแสดงชื่อเอกสาร
            Get.snackbar(
              "Document: $docId | Status: ${data!['Order_status']}",
              "Order Time: ${data['Order_time_at'].toString()}",
            );

            // เรียก loadRiderLocation ใหม่เพื่ออัปเดตข้อมูลไรเดอร์
            loadRiderLocation(orderId);
          }
        }

        // เรียก setState เพื่ออัปเดต UI และแผนที่ทุกครั้งที่มีการเปลี่ยนแปลง
        setState(() {});
      },
      onError: (error) => log("Listen failed: $error"),
    );

    var order = await http
        .get(Uri.parse("$url/db/get_SendOrder/${widget.info_send_uid}"));

    if (order.statusCode == 200) {
      allSend_order = getSendOrderFromJson(order.body);

      for (var singleOrder in allSend_order) {
        loadRiderLocation(singleOrder.oid);
        if (send_latLng != null && receive_latLng != null) {
          await getRouteCoordinates(singleOrder.se_Uid, singleOrder.re_Uid);
        }
      }
    } else {
      print("Error: ${order.statusCode}");
    }

    setState(() {});
  }

  // Future<Image> _loadImage(String url) async {
  //   var inboxRef = db.collection("Order_Info");
  //   var document = await inboxRef.doc(
  //       "order${widget.info_oid}"); // ดึงเอกสารที่มีชื่อ document ตรงกับค่าที่กรอก
  //   var result = await document.get();
  //   log(result.data()!['product_img'].toString());
  //   product_imgUrl = result.data()!['product_img'].toString();
  //   final image = Image.network(product_imgUrl);
  //   // รอให้ภาพโหลด
  //   await precacheImage(image.image, context);
  //   return image;
  // }

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
