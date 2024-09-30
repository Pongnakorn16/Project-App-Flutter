import 'dart:convert';
import 'dart:developer';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/GetOneUser_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetUserSearch_Res.dart';

class OrderinfoPage extends StatefulWidget {
  int info_send_uid; // ประกาศตัวแปรในคลาสนี้
  int info_receive_uid; // ประกาศตัวแปรในคลาสนี้

  OrderinfoPage({
    super.key,
    required this.info_send_uid,
    required this.info_receive_uid,
  });

  @override
  State<OrderinfoPage> createState() => _OrderinfoPageState();
}

class _OrderinfoPageState extends State<OrderinfoPage> {
  LatLng latLng = const LatLng(16.43975309178151, 102.82754949093136);
  MapController mapController = MapController();
  List<GetUserSearchRes> send_Info = [];
  List<GetUserSearchRes> receive_Info = [];
  int sender_uid = 0; // ประกาศตัวแปรเพื่อเก็บค่า
  int receiver_uid = 0;
  String sender_address = "";
  String receiver_address = "";

  @override
  void initState() {
    super.initState();
    sender_uid = widget.info_send_uid;
    receiver_uid = widget.info_receive_uid;
    loadDataAsync(); // กำหนดค่าใน initState
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: latLng,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                  maxNativeZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: latLng,
                      width: 40,
                      height: 40,
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Container(
                          child: Icon(
                            Icons.motorcycle,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0), // เพิ่ม Padding รอบๆ Card
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0), // กำหนดมุมโค้ง
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0), // Padding ใน Card
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // จัดเรียงข้อความไปทางซ้าย
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            color: Colors.red, size: 14), // ปรับขนาดไอคอน
                        SizedBox(width: 5),
                        Text(sender_address.toString()),
                      ],
                    ),
                    SizedBox(height: 8), // ระยะห่างระหว่างข้อความ
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            color: const Color.fromARGB(255, 79, 252, 10),
                            size: 14), // ปรับขนาดไอคอน
                        SizedBox(width: 5),
                        Text(receiver_address.toString()),
                      ],
                    ),
                  ],
                ),
              ),
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
      log("sddddddddddddddd");
      log(jsonEncode(send_Info));
      sender_address = send_Info.first.address.toString();
      setState(() {});
    } else {
      log('Failed to load lottery numbers. Status code: ${sender.statusCode}');
    }

    var receiver =
        await http.get(Uri.parse("$url/db/get_Receive/${receiver_uid}"));
    if (receiver.statusCode == 200) {
      receive_Info = getUserSearchResFromJson(receiver.body);
      log("sddddddddddddddd");
      log(jsonEncode(receive_Info));
      receiver_address = receive_Info.first.address.toString();
      setState(() {});
    } else {
      log('Failed to load lottery numbers. Status code: ${receiver.statusCode}');
    }
  }
}
