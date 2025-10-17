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

class RiderMapToCusPage extends StatefulWidget {
  final int ord_id;
  const RiderMapToCusPage({super.key, required this.ord_id});

  @override
  State<RiderMapToCusPage> createState() => _RiderMapToCusPageState();
}

class _RiderMapToCusPageState extends State<RiderMapToCusPage> {
  LatLng? riderPosition;
  LatLng? cusPosition;
  bool isLoading = true;
  final MapController mapController = MapController();
  List<LatLng> routePoints = [];
  StreamSubscription<Position>? _positionStream;
  bool isNearCustomer = false;
  LatLng? _lastRiderPos; // เก็บตำแหน่งก่อนหน้าเพื่อตรวจระยะทาง
  final double routeUpdateThreshold = 50; // เมตร

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  void _startTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) async {
      final newPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        riderPosition = newPosition;

        if (cusPosition != null) {
          double distanceInMeters = Geolocator.distanceBetween(
            newPosition.latitude,
            newPosition.longitude,
            cusPosition!.latitude,
            cusPosition!.longitude,
          );
          isNearCustomer = distanceInMeters <= 50;
        }
      });

      mapController.move(newPosition, 13);

      // อัปเดต Firebase
      await FirebaseFirestore.instance
          .collection('BP_Order_detail')
          .doc('order${widget.ord_id}')
          .update({
        'Rider_coordinate': '${position.latitude},${position.longitude}',
      });

      // เช็คว่าต้องอัปเดต route หรือใช้ cache
      if (cusPosition != null) {
        bool shouldUpdateRoute = true;
        if (_lastRiderPos != null) {
          double movedDistance = Geolocator.distanceBetween(
            _lastRiderPos!.latitude,
            _lastRiderPos!.longitude,
            newPosition.latitude,
            newPosition.longitude,
          );
          if (movedDistance < routeUpdateThreshold) {
            shouldUpdateRoute = false; // ขยับน้อย ใช้ route เดิม
          }
        }

        if (shouldUpdateRoute) {
          try {
            final newRoute = await _getRouteFromORS(newPosition, cusPosition!);
            if (mounted) {
              setState(() {
                routePoints = newRoute;
              });
            }
          } catch (e) {
            print('❌ Routing update failed: $e');
          }

          _lastRiderPos = newPosition; // อัปเดตตำแหน่งล่าสุด
        }
      }
    });
  }

  bool checkIsNearCustomer(LatLng rider, LatLng customer,
      {double threshold = 50}) {
    double distance = Geolocator.distanceBetween(
      rider.latitude,
      rider.longitude,
      customer.latitude,
      customer.longitude,
    );
    return distance <= threshold;
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
        String cusCoordinate = data['Cus_coordinate'] ?? '';
        cusPosition = _parseCoordinates(cusCoordinate);

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

      // 3️⃣ สร้าง route ถ้ามี cusPosition
      if (riderPosition != null && cusPosition != null) {
        routePoints = await _getRouteFromORS(riderPosition!, cusPosition!);
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

  Stream<LatLng?> riderPositionStream() {
    return FirebaseFirestore.instance
        .collection('BP_Order_detail')
        .doc('order${widget.ord_id}')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final coordStr = data['Rider_coordinate'] ?? '';
        return _parseCoordinates(coordStr);
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("แผนที่นำทางไปยังลูกค้า"),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<LatLng?>(
        stream: riderPositionStream(),
        builder: (context, snapshot) {
          // ✅ ตรงนี้คือจุดที่ใส่
          final displayRiderPos = snapshot.data ?? riderPosition;
          final nearCustomer = (displayRiderPos != null && cusPosition != null)
              ? checkIsNearCustomer(displayRiderPos, cusPosition!)
              : false;

          // อัปเดต route ถ้าตำแหน่งเปลี่ยน
          if (displayRiderPos != null &&
              cusPosition != null &&
              (routePoints.isEmpty ||
                  _lastRiderPos == null ||
                  Geolocator.distanceBetween(
                        _lastRiderPos!.latitude,
                        _lastRiderPos!.longitude,
                        displayRiderPos.latitude,
                        displayRiderPos.longitude,
                      ) >
                      routeUpdateThreshold)) {
            _getRouteFromORS(displayRiderPos, cusPosition!).then((newRoute) {
              if (mounted) {
                setState(() {
                  routePoints = newRoute;
                  _lastRiderPos = displayRiderPos;
                });
              }
            });
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: displayRiderPos ?? LatLng(0, 0),
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  MarkerLayer(
                    markers: [
                      if (displayRiderPos != null)
                        Marker(
                          point: displayRiderPos,
                          width: 60,
                          height: 60,
                          child: const Icon(
                            Icons.motorcycle,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                      if (cusPosition != null)
                        Marker(
                          point: cusPosition!,
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
                  if (displayRiderPos != null && cusPosition != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [
                            displayRiderPos,
                            ...routePoints,
                            cusPosition!
                          ],
                          color: Colors.green,
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                ],
              ),
              // ✅ ใช้ nearCustomer แทน isNearCustomer
              if (nearCustomer)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RiderConfirmPage(ord_id: widget.ord_id),
                        ),
                      );
                    },
                    child: const Text("ยืนยันการส่งอาหารให้ลูกค้า"),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<List<LatLng>> _getRouteFromORS(LatLng start, LatLng end) async {
    const orsApiKey =
        'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjA5YzBkODc1YmM4MzQwNDZhNGRkZDcwODNjZDAxMTFkIiwiaCI6Im11cm11cjY0In0='; /////////////  ตรงนี้มีจำกัด
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
