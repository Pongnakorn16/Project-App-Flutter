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
  MapController mapController = MapController();
  List<GetUserSearchRes> send_Info = [];
  List<GetUserSearchRes> receive_Info = [];
  int sender_uid = 0; // ประกาศตัวแปรเพื่อเก็บค่า
  int receiver_uid = 0;
  String sender_address = "";
  String receiver_address = "";
  LatLng send_latLng = LatLng(0, 0);
  LatLng receive_latLng = LatLng(0, 0);
  List<LatLng> polylinePoints = [];

  double distanceInKm = 0;

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
              initialCenter: send_latLng,
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
          )),
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
                    Text('Distance: ${distanceInKm.toStringAsFixed(2)} km'),
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

    // เรียก getRouteCoordinates หลังจากได้รับค่า latLng ของผู้ส่งและผู้รับ
    if (send_latLng != null && receive_latLng != null) {
      await getRouteCoordinates();
    }

    setState(() {});
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
}
