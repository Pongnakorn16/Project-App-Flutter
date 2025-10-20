import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class CusMapPage extends StatefulWidget {
  final int ord_id;
  const CusMapPage({super.key, required this.ord_id});

  @override
  State<CusMapPage> createState() => _CusMapPageState();
}

class _CusMapPageState extends State<CusMapPage> {
  StreamSubscription<DocumentSnapshot>? _firebaseStream;
  LatLng? riderPosition;
  LatLng? cusPosition;
  bool isLoading = true;
  final MapController mapController = MapController();
  List<LatLng> routePoints = [];
  double? distanceToCustomer;

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  @override
  void dispose() {
    _firebaseStream?.cancel();
    super.dispose();
  }

  // ✅ ฟังการเปลี่ยนแปลงของ Rider_coordinate จาก Firebase (ลูกค้าดูอย่างเดียว ไม่ได้ update)
  void _listenToFirebaseChanges() {
    print("🔥 [Customer] Starting Firebase listener...");
    _firebaseStream = FirebaseFirestore.instance
        .collection('BP_Order_detail')
        .doc('order${widget.ord_id}')
        .snapshots()
        .listen((snapshot) {
      print("🔥 [Customer] Firebase snapshot received");
      if (snapshot.exists) {
        var data = snapshot.data()!;
        String riderCoord = data['Rider_coordinate'] ?? '';
        print("🔥 [Customer] Rider_coordinate from Firebase: $riderCoord");

        if (riderCoord.isNotEmpty) {
          LatLng? newPos = _parseCoordinates(riderCoord);

          if (newPos != null) {
            print(
                "🔥 [Customer] New rider position: ${newPos.latitude}, ${newPos.longitude}");

            // ✅ คำนวณระยะทางกับลูกค้า
            double? distance;
            if (cusPosition != null) {
              distance = Geolocator.distanceBetween(
                newPos.latitude,
                newPos.longitude,
                cusPosition!.latitude,
                cusPosition!.longitude,
              );
              print(
                  "🔥 [Customer] Distance to customer: ${distance.toStringAsFixed(2)}m");
            }

            setState(() {
              riderPosition = newPos;
              distanceToCustomer = distance;
            });
            print("🔥 [Customer] UI Updated!");

            // เคลื่อนกล้องตามตำแหน่งไรเดอร์
            mapController.move(newPos, mapController.camera.zoom);

            // รีคำนวณเส้นทาง
            if (cusPosition != null) {
              _getRouteFromORS(newPos, cusPosition!).then((newRoute) {
                if (mounted) {
                  setState(() {
                    routePoints = newRoute;
                  });
                  print("🔥 [Customer] Route updated!");
                }
              });
            }
          }
        }
      }
    });
  }

  // ✅ เริ่มต้นแผนที่
  Future<void> _initMap() async {
    try {
      print("🚀 [Customer] Initializing map...");

      var snapshot = await FirebaseFirestore.instance
          .collection('BP_Order_detail')
          .doc('order${widget.ord_id}')
          .get();

      if (snapshot.exists) {
        var data = snapshot.data()!;

        // ดึงพิกัดลูกค้า
        String cusCoordinate = data['Cus_coordinate'] ?? '';
        cusPosition = _parseCoordinates(cusCoordinate);
        print("🏠 [Customer] Customer position: $cusPosition");

        // ดึงพิกัดไรเดอร์
        String riderCoordinate = data['Rider_coordinate'] ?? '';
        if (riderCoordinate.isNotEmpty) {
          riderPosition = _parseCoordinates(riderCoordinate);
          print("🏍️ [Customer] Initial rider position: $riderPosition");
        }
      }

      // ถ้ายังไม่มีตำแหน่งไรเดอร์ ให้แสดง error
      if (riderPosition == null || cusPosition == null) {
        setState(() => isLoading = false);
        Fluttertoast.showToast(msg: "ไม่พบข้อมูลตำแหน่ง");
        return;
      }

      // คำนวณเส้นทาง
      if (riderPosition != null && cusPosition != null) {
        routePoints = await _getRouteFromORS(riderPosition!, cusPosition!);

        // เซ็ตกล้องให้เห็นทั้งไรเดอร์และลูกค้า
        _fitBounds();

        // คำนวณระยะทางเริ่มต้น
        distanceToCustomer = Geolocator.distanceBetween(
          riderPosition!.latitude,
          riderPosition!.longitude,
          cusPosition!.latitude,
          cusPosition!.longitude,
        );
        print(
            "📏 [Customer] Initial distance: ${distanceToCustomer!.toStringAsFixed(2)}m");
      }

      setState(() => isLoading = false);

      // ✅ เริ่มฟัง Firebase เท่านั้น (ไม่มี GPS tracking)
      _listenToFirebaseChanges();

      print("✅ [Customer] Map initialized successfully!");
    } catch (e) {
      print("❌ [Customer] Error initializing map: $e");
      Fluttertoast.showToast(msg: "เกิดข้อผิดพลาด: $e");
      setState(() => isLoading = false);
    }
  }

  // ✅ ปรับมุมกล้องให้เห็นทั้งไรเดอร์และลูกค้า
  void _fitBounds() {
    if (riderPosition != null && cusPosition != null) {
      double minLat = riderPosition!.latitude < cusPosition!.latitude
          ? riderPosition!.latitude
          : cusPosition!.latitude;
      double maxLat = riderPosition!.latitude > cusPosition!.latitude
          ? riderPosition!.latitude
          : cusPosition!.latitude;
      double minLng = riderPosition!.longitude < cusPosition!.longitude
          ? riderPosition!.longitude
          : cusPosition!.longitude;
      double maxLng = riderPosition!.longitude > cusPosition!.longitude
          ? riderPosition!.longitude
          : cusPosition!.longitude;

      LatLng center = LatLng(
        (minLat + maxLat) / 2,
        (minLng + maxLng) / 2,
      );

      mapController.move(center, 13);
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
        title: const Text("ติดตามไรเดอร์"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (riderPosition == null || cusPosition == null)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text("ไม่พบข้อมูลตำแหน่งไรเดอร์"),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("กลับ"),
                      ),
                    ],
                  ),
                )
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

                    // ✅ แสดงระยะทางด้านบน
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.motorcycle,
                                    color: Colors.blue),
                                const SizedBox(width: 8),
                                const Text(
                                  "ไรเดอร์กำลังมาส่งอาหาร",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (distanceToCustomer != null)
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    "ห่างจากคุณ ${_formatDistance(distanceToCustomer!)}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),

                    // ✅ ปุ่มกลับไปกลางแผนที่
                    Positioned(
                      bottom: 80,
                      right: 16,
                      child: FloatingActionButton(
                        heroTag: "recenter",
                        onPressed: _fitBounds,
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.center_focus_strong,
                            color: Colors.blue),
                      ),
                    ),
                  ],
                ),
    );
  }

  // ✅ แปลงระยะทางให้อ่านง่าย
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return "${meters.toStringAsFixed(0)} เมตร";
    } else {
      return "${(meters / 1000).toStringAsFixed(2)} กิโลเมตร";
    }
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
