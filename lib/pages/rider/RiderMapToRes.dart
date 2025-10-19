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
import 'package:mobile_miniproject_app/pages/rider/RiderMapToCus.dart';

class RiderMapToResPage extends StatefulWidget {
  final int ord_id;
  const RiderMapToResPage({super.key, required this.ord_id});

  @override
  State<RiderMapToResPage> createState() => _RiderMapToResPageState();
}

class _RiderMapToResPageState extends State<RiderMapToResPage> {
  StreamSubscription<DocumentSnapshot>? _orderStream;
  StreamSubscription<DocumentSnapshot>? _coordinateStream;
  StreamSubscription<Position>? _positionStream;
  LatLng? riderPosition;
  LatLng? resPosition;
  bool isLoading = true;
  final MapController mapController = MapController();
  List<LatLng> routePoints = [];

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  @override
  void dispose() {
    _orderStream?.cancel();
    _coordinateStream?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  // ✅ ฟังการเปลี่ยนแปลง Order_status
  void _listenToOrderStatus() {
    print("🔥 Starting Order Status listener...");
    _orderStream = FirebaseFirestore.instance
        .collection('BP_Order_detail')
        .doc('order${widget.ord_id}')
        .snapshots()
        .listen((snapshot) {
      print("🔥 Order Status snapshot received");
      if (snapshot.exists) {
        var data = snapshot.data()!;
        int ordStatus = data['Order_status'] ?? 0;
        print("🔥 Order_status: $ordStatus");

        // ✅ เช็ค Order_status = 2 (ไปส่งลูกค้า)
        if (ordStatus == 2) {
          print("✅ Order status changed to 2! Moving to customer page...");
          _positionStream?.cancel();
          _coordinateStream?.cancel();
          _orderStream?.cancel();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("ไรเดอร์รับอาหารจากร้านแล้ว! ไปส่งลูกค้าได้เลย"),
              duration: Duration(seconds: 3),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => RiderMapToCusPage(ord_id: widget.ord_id),
            ),
          );
        }
      }
    });
  }

  // ✅ ฟังการเปลี่ยนแปลง Rider_coordinate จาก Firebase
  void _listenToCoordinateChanges() {
    print("🔥 Starting Coordinate listener...");
    _coordinateStream = FirebaseFirestore.instance
        .collection('BP_Order_detail')
        .doc('order${widget.ord_id}')
        .snapshots()
        .listen((snapshot) {
      print("🔥 Coordinate snapshot received");
      if (snapshot.exists) {
        var data = snapshot.data()!;
        String riderCoord = data['Rider_coordinate'] ?? '';
        print("🔥 Rider_coordinate from Firebase: $riderCoord");

        if (riderCoord.isNotEmpty) {
          LatLng? newPos = _parseCoordinates(riderCoord);

          if (newPos != null) {
            print(
                "🔥 New position parsed: ${newPos.latitude}, ${newPos.longitude}");
            print(
                "🔥 Current position: ${riderPosition?.latitude}, ${riderPosition?.longitude}");

            setState(() {
              riderPosition = newPos;
            });
            print("🔥 UI Updated!");

            // เคลื่อนกล้องตามตำแหน่งใหม่
            mapController.move(newPos, mapController.camera.zoom);

            // รีคำนวณเส้นทาง
            if (resPosition != null) {
              _getRouteFromORS(newPos, resPosition!).then((newRoute) {
                if (mounted) {
                  setState(() {
                    routePoints = newRoute;
                  });
                  print("🔥 Route updated!");
                }
              });
            }
          }
        }
      }
    });
  }

  // ✅ เริ่มติดตามตำแหน่งไรเดอร์ด้วย GPS
  Future<void> startRiderMovement() async {
    print("📍 Starting GPS tracking...");

    // ตรวจสอบการอนุญาตตำแหน่ง
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: "กรุณาเปิด GPS ก่อนใช้งาน");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: "ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(msg: "การเข้าถึงตำแหน่งถูกปฏิเสธถาวร");
      return;
    }

    // ✅ เริ่มติดตามตำแหน่ง GPS
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // ลดเหลือ 5 เมตร เพื่อให้อัปเดตบ่อยขึ้น
      ),
    ).listen((Position position) async {
      print("📍 GPS Update: ${position.latitude}, ${position.longitude}");

      LatLng newPosition = LatLng(position.latitude, position.longitude);

      // ✅ อัปเดต UI
      setState(() {
        riderPosition = newPosition;
      });

      // ✅ เคลื่อนกล้องตามตำแหน่งไรเดอร์
      mapController.move(riderPosition!, mapController.camera.zoom);

      // ✅ อัปเดตตำแหน่งไปยัง Firebase
      try {
        await FirebaseFirestore.instance
            .collection('BP_Order_detail')
            .doc('order${widget.ord_id}')
            .update({
          'Rider_coordinate': '${position.latitude},${position.longitude}',
        });
        print("✅ Firebase updated successfully");
      } catch (e) {
        print("❌ Error updating Firebase: $e");
      }

      // ✅ คำนวณเส้นทางใหม่
      if (resPosition != null) {
        final newRoute = await _getRouteFromORS(riderPosition!, resPosition!);
        setState(() {
          routePoints = newRoute;
        });
      }
    });
  }

  // ✅ เริ่มต้นแผนที่
  Future<void> _initMap() async {
    try {
      print("🚀 Initializing map...");

      var snapshot = await FirebaseFirestore.instance
          .collection('BP_Order_detail')
          .doc('order${widget.ord_id}')
          .get();

      if (snapshot.exists) {
        var data = snapshot.data()!;

        // ดึงพิกัดร้านอาหาร
        String resCoordinate = data['Res_coordinate'] ?? '';
        resPosition = _parseCoordinates(resCoordinate);
        print("🏪 Restaurant position: $resPosition");

        // ดึงพิกัดไรเดอร์ (ถ้ามี)
        String riderCoordinate = data['Rider_coordinate'] ?? '';
        if (riderCoordinate.isNotEmpty) {
          riderPosition = _parseCoordinates(riderCoordinate);
          print("🏍️ Initial rider position: $riderPosition");
        }
      }

      // ถ้ายังไม่มีตำแหน่งไรเดอร์ ใช้ตำแหน่งปัจจุบัน
      if (riderPosition == null) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        riderPosition = LatLng(position.latitude, position.longitude);
        print("📍 Current GPS position: $riderPosition");

        // บันทึกตำแหน่งเริ่มต้นลง Firebase
        await FirebaseFirestore.instance
            .collection('BP_Order_detail')
            .doc('order${widget.ord_id}')
            .update({
          'Rider_coordinate': '${position.latitude},${position.longitude}',
        });
      }

      // คำนวณเส้นทาง
      if (riderPosition != null && resPosition != null) {
        routePoints = await _getRouteFromORS(riderPosition!, resPosition!);
        mapController.move(riderPosition!, 13);
      }

      setState(() => isLoading = false);

      // ✅ เริ่มทั้ง GPS tracking และ Firebase listeners
      await startRiderMovement();
      _listenToOrderStatus();
      _listenToCoordinateChanges();

      print("✅ Map initialized successfully!");
    } catch (e) {
      print("❌ Error initializing map: $e");
      Fluttertoast.showToast(msg: "เกิดข้อผิดพลาด: $e");
      setState(() => isLoading = false);
    }
  }

  // แปลงพิกัดจาก String เป็น LatLng
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
      appBar: AppBar(
        title: const Text("แผนที่นำทางไปยังร้าน"),
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (riderPosition == null || resPosition == null)
              ? const Center(child: Text("ไม่พบข้อมูลพิกัด"))
              : Stack(
                  children: [
                    FlutterMap(
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

                    // ✅ Debug info (ลบออกได้เมื่อทดสอบเสร็จ)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Rider: ${riderPosition?.latitude.toStringAsFixed(6)}, ${riderPosition?.longitude.toStringAsFixed(6)}",
                              style: const TextStyle(fontSize: 10),
                            ),
                            Text(
                              "Restaurant: ${resPosition?.latitude.toStringAsFixed(6)}, ${resPosition?.longitude.toStringAsFixed(6)}",
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  // ดึงเส้นทางจาก OpenRouteService API
  Future<List<LatLng>> _getRouteFromORS(LatLng start, LatLng end) async {
    const orsApiKey =
        'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjA5YzBkODc1YmM4MzQwNDZhNGRkZDcwODNjZDAxMTFkIiwiaCI6Im11cm11cjY0In0=';
    final url =
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$orsApiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coords = data['features'][0]['geometry']['coordinates'] as List;
        return coords
            .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
            .toList();
      } else {
        print('❌ Routing API Error: ${response.statusCode}');
        return [start, end];
      }
    } catch (e) {
      print('❌ Error fetching route: $e');
      return [start, end];
    }
  }
}
