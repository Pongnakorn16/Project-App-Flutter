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
  StreamSubscription<DocumentSnapshot>?
      _firebaseStream; // ✅ เพิ่ม Firebase listener
  LatLng? riderPosition;
  LatLng? cusPosition;
  bool isLoading = true;
  final MapController mapController = MapController();
  List<LatLng> routePoints = [];
  StreamSubscription<Position>? _positionStream;
  bool isNearCustomer = false;
  LatLng? _lastRiderPos;
  final double routeUpdateThreshold = 50;

  @override
  void initState() {
    super.initState();
    _initMap();
    _listenToFirebaseChanges(); // ✅ เริ่มฟัง Firebase
  }

  // ✅ ฟังการเปลี่ยนแปลงของ Rider_coordinate จาก Firebase
  void _listenToFirebaseChanges() {
    _firebaseStream = FirebaseFirestore.instance
        .collection('BP_Order_detail')
        .doc('order${widget.ord_id}')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        var data = snapshot.data()!;
        String riderCoord = data['Rider_coordinate'] ?? '';

        if (riderCoord.isNotEmpty) {
          LatLng? newPos = _parseCoordinates(riderCoord);

          if (newPos != null && newPos != riderPosition) {
            setState(() {
              riderPosition = newPos;

              // อัปเดตสถานะใกล้ลูกค้าหรือไม่
              if (cusPosition != null) {
                double distanceInMeters = Geolocator.distanceBetween(
                  newPos.latitude,
                  newPos.longitude,
                  cusPosition!.latitude,
                  cusPosition!.longitude,
                );
                isNearCustomer = distanceInMeters <= 50;
              }
            });

            // เคลื่อนกล้องตามตำแหน่งใหม่
            mapController.move(newPos, mapController.camera.zoom);

            // รีคำนวณเส้นทางถ้าขยับมากพอ
            if (cusPosition != null) {
              bool shouldUpdateRoute = true;
              if (_lastRiderPos != null) {
                double movedDistance = Geolocator.distanceBetween(
                  _lastRiderPos!.latitude,
                  _lastRiderPos!.longitude,
                  newPos.latitude,
                  newPos.longitude,
                );
                if (movedDistance < routeUpdateThreshold) {
                  shouldUpdateRoute = false;
                }
              }

              if (shouldUpdateRoute) {
                _getRouteFromORS(newPos, cusPosition!).then((newRoute) {
                  if (mounted) {
                    setState(() {
                      routePoints = newRoute;
                      _lastRiderPos = newPos;
                    });
                  }
                });
              }
            }
          }
        }
      }
    });
  }

  void _startTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2,
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
            shouldUpdateRoute = false;
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

          _lastRiderPos = newPosition;
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
    _firebaseStream?.cancel(); // ✅ ยกเลิก Firebase listener
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initMap() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('BP_Order_detail')
          .doc('order${widget.ord_id}')
          .get();

      LatLng? initialRiderPos;

      if (snapshot.exists) {
        var data = snapshot.data()!;
        String cusCoordinate = data['Cus_coordinate'] ?? '';
        cusPosition = _parseCoordinates(cusCoordinate);

        String riderCoordinate = data['Rider_coordinate'] ?? '';
        if (riderCoordinate.isNotEmpty) {
          initialRiderPos = _parseCoordinates(riderCoordinate);
        }
      }

      if (initialRiderPos == null) {
        Position position = await _getCurrentLocation();
        initialRiderPos = LatLng(position.latitude, position.longitude);

        await FirebaseFirestore.instance
            .collection('BP_Order_detail')
            .doc('order${widget.ord_id}')
            .update({
          'Rider_coordinate':
              '${initialRiderPos.latitude},${initialRiderPos.longitude}',
        });
      }

      riderPosition = initialRiderPos;

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
      }

      setState(() => isLoading = false);

      _startTracking();
    } catch (e) {
      Fluttertoast.showToast(msg: "เกิดข้อผิดพลาด: $e");
      setState(() => isLoading = false);
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: "กรุณาเปิด GPS ก่อนใช้งาน");
      throw Exception('GPS not enabled');
    }

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
                  ],
                ),
    );
  }

  Future<List<LatLng>> _getRouteFromORS(LatLng start, LatLng end) async {
    const orsApiKey =
        'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjA5YzBkODc1YmM4MzQwNDZhNGRkZDcwODNjZDAxMTFkIiwiaCI6Im11cm11cjY0In0=';
    final url =
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$orsApiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}';

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
  }
}
