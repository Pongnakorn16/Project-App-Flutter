import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/CusAddressGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerHome.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerProfile.dart';
import 'package:mobile_miniproject_app/pages/customer/TopUp.dart';
import 'package:mobile_miniproject_app/shared/firebase_message_service.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';

class RiderOrderPage extends StatefulWidget {
  final List<dynamic> mergedMenus;
  final int deliveryFee;
  final int order_id;
  final int res_id;
  final int cus_id;
  final int order_status;
  final String? previousPage;

  const RiderOrderPage({
    Key? key,
    required this.mergedMenus,
    required this.deliveryFee,
    required this.order_id,
    required this.res_id,
    required this.cus_id,
    required this.order_status,
    this.previousPage,
  }) : super(key: key);

  @override
  State<RiderOrderPage> createState() => _HomePageState();
}

class _HomePageState extends State<RiderOrderPage> {
  int _currentStep = 0;
  late Timer _timer;
  String url = '';
  bool isLoading = true;
  String? _restaurantAddress; // ที่อยู่ร้านที่จะแสดง
  String? _customerAddress; // ที่อยู่ลูกค้าที่จะแสดง

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // โหลด config
      final config = await Configuration.getConfig();
      if (mounted) {
        url = config['apiEndpoint'];
      }

      // โหลดข้อมูลที่อยู่และเปรียบเทียบ
      await _loadAndCompareAddresses();

      // ตั้งค่า current step
      if (mounted && widget.order_status != -1) {
        _currentStep = widget.order_status;
      }

      // เริ่ม timer
      if (mounted) {
        _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          if (_currentStep != 0) {
            timer.cancel();
          }
        });
      }
    } catch (e) {
      log('❌ Initialization error: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาดในการโหลดข้อมูล",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// โหลดและเปรียบเทียบที่อยู่จาก Firebase และ SQL
  Future<void> _loadAndCompareAddresses() async {
    if (!mounted) return;

    try {
      // 1️⃣ โหลดพิกัดจาก Firebase
      String? firebaseCusCoordinate;
      String? firebaseResCoordinate;

      final orderDoc = await FirebaseFirestore.instance
          .collection('BP_Order_detail')
          .doc('order${widget.order_id}')
          .get();

      if (orderDoc.exists) {
        firebaseCusCoordinate = orderDoc.data()?['Cus_coordinate']?.toString();
        firebaseResCoordinate = orderDoc.data()?['Res_coordinate']?.toString();
        log("✅ Firebase Cus_coordinate = $firebaseCusCoordinate");
        log("✅ Firebase Res_coordinate = $firebaseResCoordinate");
      }

      // 2️⃣ โหลดที่อยู่ลูกค้าจาก SQL และเปรียบเทียบ
      await _loadCustomerAddress(firebaseCusCoordinate);

      // 3️⃣ โหลดที่อยู่ร้านจาก SQL และเปรียบเทียบ
      await _loadRestaurantAddress(firebaseResCoordinate);
    } catch (e) {
      log("❌ LoadAndCompare Error: $e");
      if (mounted) {
        Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาดในการโหลดที่อยู่",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  /// โหลดและเปรียบเทียบที่อยู่ลูกค้า
  Future<void> _loadCustomerAddress(String? firebaseCusCoordinate) async {
    if (!mounted) return;

    try {
      // โหลดที่อยู่ลูกค้าจาก SQL
      final cusRes = await http.get(
        Uri.parse("$url/db/loadCusAdd/${widget.cus_id}"),
      );

      if (cusRes.statusCode == 200 && mounted) {
        final List<dynamic> jsonResponse = json.decode(cusRes.body);
        final cusAddressList =
            jsonResponse.map((e) => CusAddressGetResponse.fromJson(e)).toList();

        context.read<ShareData>().customer_addresses = cusAddressList;

        if (firebaseCusCoordinate != null && firebaseCusCoordinate.isNotEmpty) {
          // เทียบพิกัดลูกค้า
          final matchedCusAddress = cusAddressList.firstWhere(
            (item) => item.ca_coordinate.trim() == firebaseCusCoordinate.trim(),
            orElse: () => CusAddressGetResponse(
              ca_id: 0,
              ca_coordinate: '',
              ca_address: '',
              ca_detail: '',
            ),
          );

          if (matchedCusAddress.ca_id != 0) {
            // ✅ พิกัดตรง → ใช้ที่อยู่จาก SQL
            _customerAddress =
                "${matchedCusAddress.ca_address}, ${matchedCusAddress.ca_detail}";
            context.read<ShareData>().final_cus_add = _customerAddress!;

            // เก็บ index ของที่อยู่ที่ตรงกัน
            final matchedIndex = cusAddressList.indexOf(matchedCusAddress);
            context.read<ShareData>().selected_address_index = matchedIndex;

            log("✅ ที่อยู่ลูกค้าตรง: $_customerAddress");
          } else {
            // ❌ พิกัดไม่ตรง → แปลงพิกัดจาก Firebase เป็นที่อยู่
            final convertedAddress =
                await _getAddressFromLatLng(firebaseCusCoordinate);
            _customerAddress = "ที่อยู่เดิม: $convertedAddress";
            context.read<ShareData>().final_cus_add = _customerAddress!;
            context.read<ShareData>().selected_address_index =
                0; // ใช้ index แรก
            log("⚠️ ที่อยู่ลูกค้าไม่ตรง → แปลงเป็น: $_customerAddress");
          }
        } else if (cusAddressList.isNotEmpty) {
          // ไม่มีพิกัดจาก Firebase → ใช้ที่อยู่แรกจาก SQL
          final firstAddress = cusAddressList.first;
          _customerAddress =
              "${firstAddress.ca_address}, ${firstAddress.ca_detail}";
          context.read<ShareData>().final_cus_add = _customerAddress!;
          context.read<ShareData>().selected_address_index = 0;
        } else {
          _customerAddress = "ไม่พบที่อยู่ลูกค้า";
          context.read<ShareData>().final_cus_add = _customerAddress!;
        }
      }
    } catch (e) {
      log("❌ LoadCustomerAddress Error: $e");
      _customerAddress = "เกิดข้อผิดพลาดในการโหลดที่อยู่ลูกค้า";
    }
  }

  /// โหลดและเปรียบเทียบที่อยู่ร้าน
  Future<void> _loadRestaurantAddress(String? firebaseResCoordinate) async {
    if (!mounted) return;

    try {
      // โหลดข้อมูลร้านจาก SQL
      final resInfo = await http.get(
        Uri.parse("$url/db/loadResInfo/${widget.res_id}"),
      );

      if (resInfo.statusCode == 200 && mounted) {
        final List<ResInfoResponse> list = (json.decode(resInfo.body) as List)
            .map((e) => ResInfoResponse.fromJson(e))
            .toList();

        if (list.isNotEmpty) {
          final resData = list.first;
          context.read<ShareData>().res_info = resData;

          log("✅ โหลดข้อมูลร้านสำเร็จ: ${resData.res_name}");

          if (firebaseResCoordinate != null &&
              firebaseResCoordinate.isNotEmpty) {
            // เทียบพิกัดร้าน
            if (resData.res_coordinate.trim() == firebaseResCoordinate.trim()) {
              // ✅ พิกัดตรง → แปลงพิกัดปัจจุบันเป็นที่อยู่
              _restaurantAddress =
                  await _getAddressFromLatLng(resData.res_coordinate);
              context.read<ShareData>().final_res_add = _restaurantAddress!;
              log("✅ ที่อยู่ร้านตรง: $_restaurantAddress");
            } else {
              // ❌ พิกัดไม่ตรง → แปลงพิกัดจาก Firebase เป็นที่อยู่
              final convertedAddress =
                  await _getAddressFromLatLng(firebaseResCoordinate);
              _restaurantAddress = "ที่อยู่เดิม: $convertedAddress";
              context.read<ShareData>().final_res_add = _restaurantAddress!;
              log("⚠️ ที่อยู่ร้านไม่ตรง → แปลงเป็น: $_restaurantAddress");
            }
          } else {
            // ไม่มีพิกัดจาก Firebase → ใช้พิกัดจาก SQL
            _restaurantAddress =
                await _getAddressFromLatLng(resData.res_coordinate);
            context.read<ShareData>().final_res_add = _restaurantAddress!;
          }
        }
      }
    } catch (e) {
      log("❌ LoadRestaurantAddress Error: $e");
      _restaurantAddress = "เกิดข้อผิดพลาดในการโหลดที่อยู่ร้าน";
    }
  }

  /// แปลงพิกัด (lat,lng) เป็นที่อยู่
  Future<String> _getAddressFromLatLng(String latlng) async {
    try {
      final parts = latlng.split(',');
      if (parts.length != 2) return "รูปแบบพิกัดไม่ถูกต้อง";

      final lat = double.parse(parts[0].trim());
      final lng = double.parse(parts[1].trim());

      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final address = [
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.postalCode,
        ].where((s) => s != null && s.isNotEmpty).join(' ');

        return address.isNotEmpty ? address : "ไม่สามารถระบุที่อยู่ได้";
      }
      return "ไม่พบที่อยู่";
    } catch (e) {
      log("❌ GetAddressFromLatLng Error: $e");
      return "ไม่สามารถแปลงพิกัดได้";
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _handleBackButton() {
    if (widget.previousPage == 'CusAllOrderPage') {
      Navigator.pop(context);
    } else if (widget.previousPage == 'Cart') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CustomerHomePage()),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("ข้อมูลออเดอร์"),
        automaticallyImplyLeading: widget.previousPage != null,
        leading: widget.previousPage != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _handleBackButton,
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAddressSection(),
            const SizedBox(height: 20),
            _buildOrderSummary(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    final restaurantAddress = _restaurantAddress ?? "กำลังโหลดที่อยู่ร้าน...";
    final customerAddress = _customerAddress ?? "กำลังโหลดที่อยู่ลูกค้า...";

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_sharp, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ตำแหน่งร้าน",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurantAddress,
                        style: TextStyle(
                          color: restaurantAddress.contains("ที่อยู่เดิม")
                              ? Colors.orange
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Divider(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_sharp, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ตำแหน่งลูกค้า",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customerAddress,
                        style: TextStyle(
                          color: customerAddress.contains("ที่อยู่เดิม")
                              ? Colors.orange
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    double finalPrice = 0;

    List<Widget> menuWidgets = widget.mergedMenus.map((menu) {
      final count = menu["count"] ?? 1;
      final menuPrice = (menu["menu_price"] ?? 0).toDouble();
      final options = menu["selectedOptions"] ?? [];
      double optionsTotalPrice = 0;
      for (var opt in options) {
        optionsTotalPrice += (opt["op_price"] ?? 0).toDouble();
      }
      final totalPrice = (menuPrice + optionsTotalPrice) * count;
      finalPrice += totalPrice;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text("${menu["menu_name"]} x$count")),
                Text("${totalPrice.toStringAsFixed(0)} บาท"),
              ],
            ),
            if (options.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: options.map<Widget>((opt) {
                    final opPrice = (opt["op_price"] ?? 0).toDouble();
                    return Text(
                      opPrice > 0
                          ? "- ${opt["op_name"]} (+${opPrice.toStringAsFixed(0)} บาท)"
                          : "- ${opt["op_name"]}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      );
    }).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "สรุปรายการอาหาร",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...menuWidgets,
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("ค่าส่ง",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  "${widget.deliveryFee.toStringAsFixed(0)} บาท",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("รวมทั้งหมด",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  "${(finalPrice + widget.deliveryFee).toStringAsFixed(0)} บาท",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
