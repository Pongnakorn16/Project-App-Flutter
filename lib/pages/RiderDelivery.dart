import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/GetOneUser_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetSendOrder_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetUserSearch_Res.dart';
import 'package:mobile_miniproject_app/pages/Add_Item.dart';
import 'package:mobile_miniproject_app/pages/Home.dart';
import 'package:mobile_miniproject_app/pages/Profile.dart';
import 'package:mobile_miniproject_app/pages/RiderHistory.dart';
import 'package:mobile_miniproject_app/pages/RiderHome.dart';
import 'package:mobile_miniproject_app/pages/RiderProfile.dart';

class RiderDeliveryPage extends StatefulWidget {
  int info_send_uid; // ประกาศตัวแปรในคลาสนี้
  int selectedIndex = 0;
  int info_receive_uid; // ประกาศตัวแปรในคลาสนี้
  int info_oid;

  RiderDeliveryPage({
    super.key,
    required this.info_send_uid,
    required this.info_receive_uid,
    required this.selectedIndex,
    required this.info_oid,
  });

  @override
  State<RiderDeliveryPage> createState() => _RiderDeliveryPageState();
}

class _RiderDeliveryPageState extends State<RiderDeliveryPage> {
  MapController mapController = MapController();
  List<GetUserSearchRes> send_Info = [];
  List<GetUserSearchRes> receive_Info = [];
  List<GetSendOrder> order_one = [];
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
  List<LatLng> polylinePoints = [];
  var db = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  double distanceInKm = 0;
  final ImagePicker picker = ImagePicker();
  XFile? image;

  @override
  void initState() {
    super.initState();
    sender_uid = widget.info_send_uid;
    receiver_uid = widget.info_receive_uid;
    _selectedIndex = widget.selectedIndex;
    loadRiderLocation();
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
                      Marker(
                        point: send_latLng,
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
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
                      ),
                      // เพิ่ม Marker ของ Rider
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
                  if (polylinePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: polylinePoints,
                          strokeWidth: 4.0,
                          color: Colors.blue,
                        ),
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
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 30, right: 40, bottom: 20, top: 10),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // จัดตำแหน่งให้ห่างกัน
              children: [
                Column(
                  // ใช้ Column เพื่อจัดตำแหน่งปุ่มและไอคอนในแนวตั้ง
                  children: [
                    FilledButton(
                      onPressed: () {
                        sendImage();
                      },
                      child: Text(
                        "Delivered",
                        style: TextStyle(fontSize: 17),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                            255, 139, 15, 188), // เปลี่ยนสีพื้นหลังของปุ่ม
                        minimumSize: Size(200,
                            50), // กำหนดขนาดขั้นต่ำของปุ่ม (ความกว้าง, ความสูง)
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15), // กำหนดมุมโค้งของปุ่ม
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 10), // เพิ่ม padding ด้านซ้าย
                  child: image != null
                      ? Image.file(
                          File(image!.path), // แสดงรูปที่เลือก
                          width: 50.0, // กำหนดขนาดของรูปภาพ
                          height: 50.0,
                          fit: BoxFit.cover, // ทำให้รูปเต็มกรอบ
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Color.fromARGB(255, 255, 222, 78),
                          ),
                          iconSize: 50.0,
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
        ],
      ),
    );
  }

  Future<void> loadDataAsync() async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    var sender = await http.get(Uri.parse("$url/db/get_Send/${sender_uid}"));
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
        }
      }
    }

    var receiver =
        await http.get(Uri.parse("$url/db/get_Receive/${receiver_uid}"));
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
        }
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

  void sendImage() async {
    // แสดง Dialog Loading
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

    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    http.put(
      Uri.parse("$url/db/update_status/${widget.info_oid}/${4}"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
    );

    final storageRef = FirebaseStorage.instance.ref();
    final imageRef =
        storageRef.child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');

    await imageRef.putFile(File(image!.path));

    // รับ URL ของภาพที่อัปโหลด
    product_imgUrl_status4 = await imageRef.getDownloadURL();
    log(product_imgUrl_status4.toString());

    if (image == null) {
      // ปิด Dialog
      Navigator.of(context).pop();

      Fluttertoast.showToast(
          msg: "ข้อมูลไม่ถูกต้องโปรดตรวจสอบความถูกต้อง แล้วลองอีกครั้ง",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Color.fromARGB(255, 255, 0, 0),
          textColor: Colors.white,
          fontSize: 15.0);
      Navigator.of(context).pop();
    } else {
      try {
        // กำหนดชื่อเอกสาร
        var doc = "order${widget.info_oid}";

        // ข้อมูลที่ต้องการอัปเดต
        var dataToUpdate = {
          'Order_status': 4,
          'rider_coordinates':
              '${receive_latLng.latitude},${receive_latLng.longitude}',
          'status4_product_img': product_imgUrl_status4,
        };

        // อัปเดตข้อมูลใน Firebase
        await db.collection('Order_Info').doc(doc).update(dataToUpdate);

        log("Document updated successfully");

        Fluttertoast.showToast(
            msg: "ข้อมูลถูกอัปเดตเรียบร้อยแล้ว",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 15.0);

        // ปิด Dialog หลังจากอัปโหลดเสร็จสิ้น
        Navigator.of(context).pop();
        Get.to(() => RiderHomePage());
      } catch (e) {
        log('Error updating document: $e');

        // ปิด Dialog
        Navigator.of(context).pop();

        Fluttertoast.showToast(
            msg: "เกิดข้อผิดพลาดในการอัปเดตข้อมูล",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 15.0);
      }
    }
  }

  Future<void> loadRiderLocation() async {
    var riderDoc =
        await db.collection('Order_Info').doc('order${widget.info_oid}').get();
    if (riderDoc.exists) {
      String riderCoordinates = riderDoc.data()?['rider_coordinates'];
      print('Rider Coordinates: $riderCoordinates'); // เพิ่มการพิมพ์ข้อมูลพิกัด
      if (riderCoordinates != null) {
        List<String> latLngList = riderCoordinates.split(',');
        if (latLngList.length == 2) {
          double riderLat = double.parse(latLngList[0]);
          double riderLng = double.parse(latLngList[1]);
          riderLatLng = LatLng(riderLat, riderLng);
          print(
              'Parsed LatLngกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกกก: $riderLatLng'); // ตรวจสอบพิกัด
        }
      }
      setState(() {});
    }
  }
}
