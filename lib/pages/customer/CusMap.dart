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
import 'package:mobile_miniproject_app/pages/rider/RiderConfirm.dart';

class CusMapPage extends StatefulWidget {
  final int ord_id;
  const CusMapPage({super.key, required this.ord_id});

  @override
  State<CusMapPage> createState() => _CusMapPageState();
}

class _CusMapPageState extends State<CusMapPage> {
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<DocumentSnapshot>? _firebaseStream;
  LatLng? riderPosition;
  LatLng? cusPosition;
  bool isLoading = true;
  final MapController mapController = MapController();
  List<LatLng> routePoints = [];
  bool isNearCustomer = false;

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _firebaseStream?.cancel();
    super.dispose();
  }

  // ✅ ฟังการเปลี่ยนแปลงของ Rider_coordinate จาก Firebase
  void _listenToFirebaseChanges() {
    print("🔥 Starting Firebase listener...");
    _firebaseStream = FirebaseFirestore.instance
        .collection('BP_Order_detail')
        .doc('order${widget.ord_id}')
        .snapshots()
        .listen((snapshot) {
      print("🔥 Firebase snapshot received");
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

            // ✅ คำนวณระยะทางกับลูกค้า
            bool nearCustomer = false;
            if (cusPosition != null) {
              double distanceInMeters = Geolocator.distanceBetween(
                newPos.latitude,
                newPos.longitude,
                cusPosition!.latitude,
                cusPosition!.longitude,
              );
              nearCustomer = distanceInMeters <= 50;
              print("🔥 Distance to customer: ${distanceInMeters}m");
            }

            setState(() {
              riderPosition = newPos;
              isNearCustomer = nearCustomer;
            });
            print("🔥 UI Updated!");

            // เคลื่อนกล้องตามตำแหน่งใหม่
            mapController.move(newPos, mapController.camera.zoom);

            // รีคำนวณเส้นทาง
            if (cusPosition != null) {
              _getRouteFromORS(newPos, cusPosition!).then((newRoute) {
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

      // ✅ คำนวณระยะทางกับลูกค้า
      bool nearCustomer = false;
      if (cusPosition != null) {
        double distanceInMeters = Geolocator.distanceBetween(
          newPosition.latitude,
          newPosition.longitude,
          cusPosition!.latitude,
          cusPosition!.longitude,
        );
        nearCustomer = distanceInMeters <= 50;
        print("📍 Distance to customer: ${distanceInMeters}m");
      }

      // ✅ อัปเดต UI
      setState(() {
        riderPosition = newPosition;
        isNearCustomer = nearCustomer;
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
      if (cusPosition != null) {
        try {
          final newRoute = await _getRouteFromORS(riderPosition!, cusPosition!);
          if (mounted) {
            setState(() {
              routePoints = newRoute;
            });
          }
        } catch (e) {
          print('❌ Routing update failed: $e');
        }
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

        // ดึงพิกัดลูกค้า
        String cusCoordinate = data['Cus_coordinate'] ?? '';
        cusPosition = _parseCoordinates(cusCoordinate);
        print("🏠 Customer position: $cusPosition");

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
      if (riderPosition != null && cusPosition != null) {
        routePoints = await _getRouteFromORS(riderPosition!, cusPosition!);
        mapController.move(riderPosition!, 13);

        // เช็คระยะทางเริ่มต้น
        double distanceInMeters = Geolocator.distanceBetween(
          riderPosition!.latitude,
          riderPosition!.longitude,
          cusPosition!.latitude,
          cusPosition!.longitude,
        );
        isNearCustomer = distanceInMeters <= 50;
        print("📏 Initial distance: ${distanceInMeters}m");
      }

      setState(() => isLoading = false);

      // ✅ เริ่มทั้ง GPS tracking และ Firebase listener
      await startRiderMovement();
      _listenToFirebaseChanges();

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
        title: const Text("แผนที่นำทางไปยังลูกค้า"),
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (riderPosition == null || cusPosition == null)
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
                              point: cusPosition!,
                              width: 60,
                              height: 60,
                              child: const Icon(
                                Icons.home,
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
                                  : [riderPosition!, cusPosition!],
                              color: Colors.green,
                              strokeWidth: 4.0,
                            ),
                          ],
                        ),
                      ],
                    ),
                    // ✅ แสดงปุ่มเมื่อใกล้ลูกค้า
                    if (isNearCustomer)
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: ElevatedButton(
                          onPressed: () {
                            _positionStream?.cancel();
                            _firebaseStream?.cancel();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RiderConfirmPage(ord_id: widget.ord_id),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            "ยืนยันการส่งอาหารให้ลูกค้า",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
                              "Near: $isNearCustomer",
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
