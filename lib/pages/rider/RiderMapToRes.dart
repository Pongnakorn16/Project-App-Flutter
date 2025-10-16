import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:http/http.dart' as http;

class RiderMapToResPage extends StatefulWidget {
  final int ord_id;
  const RiderMapToResPage({super.key, required this.ord_id});

  @override
  State<RiderMapToResPage> createState() => _RiderMapToResPageState();
}

class _RiderMapToResPageState extends State<RiderMapToResPage> {
  LatLng? riderPosition;
  LatLng? resPosition;
  bool isLoading = true;
  final MapController mapController = MapController();
  List<LatLng> routePoints = [];
  StreamSubscription<Position>? _positionStream;
  @override
  void initState() {
    super.initState();
    _initMap();
  }

  void _startTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // อัปเดตทุก 5 เมตร
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) async {
      final newPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        riderPosition = newPosition;
      });

      // เคลื่อนกล้องตามตำแหน่งใหม่
      mapController.move(riderPosition!, mapController.camera.zoom);

      // 🔄 อัปเดตตำแหน่งไปยัง Firestore
      await FirebaseFirestore.instance
          .collection('BP_Order_detail')
          .doc('order${widget.ord_id}')
          .update({
        'Rider_coordinate':
            '${position.latitude},${position.longitude}', // เก็บเป็น string เช่น "16.4332,102.8231"
      });

      // ถ้ามี resPosition ให้รีเฟรชเส้นทาง
      if (resPosition != null) {
        final newRoute = await _getRouteFromORS(riderPosition!, resPosition!);
        setState(() {
          routePoints = newRoute;
        });
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initMap() async {
    try {
      // 1️⃣ ดึงข้อมูลจาก Firebase ก่อน
      var snapshot = await FirebaseFirestore.instance
          .collection('BP_Order_detail')
          .doc('order${widget.ord_id}')
          .get();

      LatLng? initialRiderPos;

      if (snapshot.exists) {
        var data = snapshot.data()!;
        String resCoordinate = data['Res_coordinate'] ?? '';
        resPosition = _parseCoordinates(resCoordinate);

        // ✅ ถ้ามี Rider_coordinate เก็บไว้ ให้ใช้
        String riderCoordinate = data['Rider_coordinate'] ?? '';
        if (riderCoordinate.isNotEmpty) {
          initialRiderPos = _parseCoordinates(riderCoordinate);
        }
      }

      // 2️⃣ ถ้าไม่มี Rider_coordinate ให้ fallback ไปที่ GPS
      if (initialRiderPos == null) {
        Position position = await _getCurrentLocation();
        initialRiderPos = LatLng(position.latitude, position.longitude);

        // อัปเดตตำแหน่งเริ่มต้นใน Firebase ด้วย
        await FirebaseFirestore.instance
            .collection('BP_Order_detail')
            .doc('order${widget.ord_id}')
            .update({
          'Rider_coordinate':
              '${initialRiderPos.latitude},${initialRiderPos.longitude}',
        });
      }

      riderPosition = initialRiderPos;

      // 3️⃣ สร้าง route ถ้ามี resPosition
      if (riderPosition != null && resPosition != null) {
        routePoints = await _getRouteFromORS(riderPosition!, resPosition!);
        mapController.move(riderPosition!, 13);
      }

      setState(() => isLoading = false);

      // 4️⃣ เริ่มติดตามตำแหน่งจาก GPS และอัปเดต Firebase
      _startTracking();
    } catch (e) {
      Fluttertoast.showToast(msg: "เกิดข้อผิดพลาด: $e");
      setState(() => isLoading = false);
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // ตรวจสอบว่าเปิด GPS หรือยัง
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: "กรุณาเปิด GPS ก่อนใช้งาน");
      throw Exception('GPS not enabled');
    }

    // ขอสิทธิ์การเข้าถึง
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: "ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง");
        throw Exception('Permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(msg: "การเข้าถึงตำแหน่งถูกปฏิเสธถาวร");
      throw Exception('Permission denied forever');
    }

    // คืนค่าตำแหน่งปัจจุบัน
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  LatLng? _parseCoordinates(String coordinates) {
    try {
      var parts = coordinates.split(',');
      if (parts.length >= 2) {
        return LatLng(
          double.parse(parts[0].trim()),
          double.parse(parts[1].trim()),
        );
      }
    } catch (e) {
      print('❌ แปลงพิกัดผิดพลาด: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("แผนที่นำทางไปยังร้าน")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (riderPosition == null || resPosition == null)
              ? const Center(child: Text("ไม่พบข้อมูลพิกัด"))
              : FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: riderPosition!,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    MarkerLayer(
                      markers: [
                        // ✅ Marker: Rider
                        Marker(
                          point: riderPosition!,
                          width: 60,
                          height: 60,
                          child: const Icon(
                            Icons.motorcycle,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                        // ✅ Marker: ร้าน
                        Marker(
                          point: resPosition!,
                          width: 60,
                          height: 60,
                          child: const Icon(
                            Icons.store,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                    // ✅ เส้นเชื่อมระหว่าง Rider กับ ร้าน
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints.isNotEmpty
                              ? routePoints
                              : [riderPosition!, resPosition!],
                          color: Colors.green,
                          strokeWidth: 4.0,
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }

  Future<List<LatLng>> _getRouteFromORS(LatLng start, LatLng end) async {
    const orsApiKey = 'ใส่_API_KEY_ของคุณที่นี่';
    final url =
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$orsApiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coords = data['features'][0]['geometry']['coordinates'] as List;
      // แปลงเป็น List<LatLng>
      return coords
          .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
          .toList();
    } else {
      print('❌ Routing API Error: ${response.statusCode}');
      return [start, end];
    }
  }
}
