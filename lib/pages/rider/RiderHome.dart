import 'dart:convert';
import 'dart:developer';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart'; // เพิ่มสำหรับตำแหน่ง
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/CusAddressGetRes.dart';
import 'package:mobile_miniproject_app/models/response/CusInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/OptionGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
import 'package:mobile_miniproject_app/pages/customer/Order.dart';
import 'package:mobile_miniproject_app/pages/restaurant/ResOrder.dart';
import 'package:mobile_miniproject_app/pages/rider/RiderHistory.dart';
import 'package:mobile_miniproject_app/pages/rider/RiderOrder.dart';
import 'package:mobile_miniproject_app/pages/rider/RiderProfile.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';

class RiderHomePage extends StatefulWidget {
  const RiderHomePage({super.key});

  @override
  State<RiderHomePage> createState() => _RiderHomePageState();
}

class _RiderHomePageState extends State<RiderHomePage>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late PageController _pageController;
  String url = '';
  bool isLoading = true;
  List<Map<String, dynamic>> ordersList = []; // เก็บ order
  Map<int, CusInfoGetResponse> _customerMap = {};
  Map<int, ResInfoResponse> _restaurantMap = {}; // เพิ่ม map สำหรับร้านอาหาร
  Map<int, CusAddressGetResponse> _cusAddMap = {};
  Position? _currentPosition; // ตำแหน่งปัจจุบัน

  @override
  void initState() {
    super.initState();
    // เพิ่ม observer เพื่อตรวจสอบ app lifecycle
    WidgetsBinding.instance.addObserver(this);

    Configuration.getConfig().then((value) {
      url = value['apiEndpoint'];
      _initLocationAndLoadOrders();
    });
    _pageController = PageController();
  }

  @override
  void dispose() {
    // ลบ observer เมื่อ dispose
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  // ฟังก์ชันจัดการเมื่อ app กลับมา active
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // เมื่อ app กลับมา active ให้รีเฟรชข้อมูล
      if (_selectedIndex == 0) {
        // ถ้าอยู่ที่หน้า Home
        _refreshData();
      }
    }
  }

  // ฟังก์ชันรีเฟรชข้อมูลทั้งหมด
  Future<void> _refreshData() async {
    print("กำลังรีเฟรชข้อมูล...");

    // Clear cache เพื่อให้ข้อมูลอัพเดท
    setState(() {
      _customerMap.clear();
      _restaurantMap.clear();
      ordersList.clear();
    });

    // โหลดข้อมูลใหม่
    await _initLocationAndLoadOrders();
  }

  // ฟังก์ชันรวม: ขอ GPS แล้วโหลดออเดอร์เลย
  Future<void> _initLocationAndLoadOrders() async {
    try {
      Position position = await _getCurrentLocation();
      setState(() {
        _currentPosition = position;
      });
      LoadAllOrder(context); // โหลดออเดอร์หลังจากได้ตำแหน่งแล้ว
    } catch (e) {
      print("ไม่สามารถดึงตำแหน่งได้: $e");
      Fluttertoast.showToast(msg: "กรุณาเปิด GPS");
      LoadAllOrder(context); // fallback โหลดออเดอร์ทั้งหมด
    }
  }

  // ฟังก์ชันขออนุญาตและรับตำแหน่งปัจจุบัน
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw Exception("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permission denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied.");
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  // ฟังก์ชันขออนุญาตและรับตำแหน่งปัจจุบัน
  Future<LatLng> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw Exception("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permission denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied.");
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return LatLng(position.latitude, position.longitude);
  }

  // ฟังก์ชันคำนวณระยะทางระหว่างสองจุด (Haversine formula)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // รัศมีของโลกเป็นกิโลเมตร

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  // ฟังก์ชันแยก coordinate
  Map<String, double> parseCoordinates(String? coordinates) {
    if (coordinates == null || coordinates.isEmpty) {
      return {'lat': 0.0, 'lng': 0.0};
    }

    try {
      List<String> parts = coordinates.split(',');
      if (parts.length >= 2) {
        return {
          'lat': double.parse(parts[0].trim()),
          'lng': double.parse(parts[1].trim())
        };
      }
    } catch (e) {
      print('ไม่สามารถแยก coordinate ได้: $e');
    }

    return {'lat': 0.0, 'lng': 0.0};
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // ถ้าเป็นหน้า Home (index 0) ให้รีเฟรชข้อมูล
    if (index == 0) {
      _refreshData();
    }

    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // ถ้าเป็นหน้า Home (index 0) ให้รีเฟรชข้อมูล
    if (index == 0) {
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          // หน้า Order
          _buildOrderPage(),
          RiderHistoryPage(),
          // หน้า Profile
          RiderProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.motorcycle),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildOrderPage() {
    return Scaffold(
      appBar: AppBar(
        title: Text("ออเดอร์ที่พร้อม"),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        // เพิ่ม Pull-to-refresh
        onRefresh: _refreshData,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : _currentPosition == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("ไม่สามารถรับตำแหน่งได้"),
                      ],
                    ),
                  )
                : ordersList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("ไม่พบออเดอร์ที่พร้อม"),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(8),
                        itemCount: ordersList.length,
                        itemBuilder: (context, index) {
                          var order = ordersList[index];

                          // ดึงข้อมูลลูกค้าจาก map
                          var cusInfo = _customerMap[order['cus_id']];
                          var cusAdd = _cusAddMap[order['cus_id']];
                          var resInfo = _restaurantMap[order['res_id']];

                          // เรียกโหลดลูกค้าถ้ายังไม่มีใน map
                          if (cusInfo == null) {
                            loadCus(order['cus_id']);
                          }

                          // เรียกโหลดร้านถ้ายังไม่มีใน map
                          if (resInfo == null) {
                            loadRestaurant(order['res_id']);
                          }

                          // แปลงวันเวลา
                          var timestamp = order['Order_date'];
                          DateTime orderDate = timestamp != null
                              ? (timestamp as Timestamp).toDate()
                              : DateTime.now();
                          String formattedDate =
                              DateFormat('dd/MM/yyyy HH:mm').format(orderDate);

                          // คำนวณระยะทาง
                          double distance = 0.0;
                          String distanceText = "คำนวณระยะทาง...";

                          if (resInfo != null &&
                              resInfo.res_coordinate.isNotEmpty &&
                              cusAdd != null &&
                              cusAdd.ca_coordinate.isNotEmpty) {
                            var resCoord =
                                parseCoordinates(resInfo.res_coordinate);
                            var cusCoord =
                                parseCoordinates(cusAdd.ca_coordinate);
                            distance = calculateDistance(
                              cusCoord['lat']!,
                              cusCoord['lng']!,
                              resCoord['lat']!,
                              resCoord['lng']!,
                            );
                            distanceText = "${distance.toStringAsFixed(1)} กม.";
                          }

                          return GestureDetector(
                              onTap: () async {
                                // รอให้หน้าใหม่ปิดแล้วค่อยรีเฟรช
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RiderOrderPage(
                                      mergedMenus: order['menus'],
                                      deliveryFee: order['deliveryFee'],
                                      order_id: order['order_id'],
                                      order_status: order['Order_status'],
                                      previousPage: 'RiderOrderPage',
                                    ),
                                  ),
                                );
                                // รีเฟรชข้อมูลเมื่อกลับมา
                                _refreshData();
                              },
                              child: Card(
                                margin: EdgeInsets.symmetric(vertical: 6),
                                elevation: 3,
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .center, // จัดให้ทุกอย่างอยู่กึ่งกลางแนวตั้ง
                                    children: [
                                      // ฝั่งซ้าย (ข้อมูลออเดอร์)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "หมายเลขออเดอร์ : ${order['order_id'] ?? '-'}",
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700]),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              cusInfo != null
                                                  ? "คุณ : ${cusInfo.cus_name}"
                                                  : "กำลังโหลด...",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              resInfo != null
                                                  ? "ร้าน : ${resInfo.res_name}"
                                                  : "กำลังโหลดร้าน...",
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600]),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              "ระยะทาง : $distanceText",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue[600],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text("วันที่: $formattedDate"),
                                          ],
                                        ),
                                      ),

                                      // ฝั่งขวา (ปุ่มรับออเดอร์)
                                      if ((order['Order_status'] ?? -1) == 1)
                                        SizedBox(
                                          width: 100,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              acceptOrder(
                                                  order['order_id'].toString());
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                            ),
                                            child: Text(
                                              "รับออเดอร์",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ));
                        }),
      ),
    );
  }

  Future<void> acceptOrder(String orderId) async {
    try {
      int riderId = context.read<ShareData>().user_info_send.uid;

      await FirebaseFirestore.instance
          .collection('BP_Order_detail')
          .doc('order' + orderId)
          .update({
        'rid_id': riderId,
        'Rider_coordinate':
            "${_currentPosition!.latitude.toString()},${_currentPosition!.longitude.toString()}",
      });

      Fluttertoast.showToast(msg: 'รับออเดอร์เรียบร้อย');
      // รีเฟรชข้อมูลทันทีหลังรับออเดอร์
      _refreshData();
    } catch (e) {
      print('รับออเดอร์ล้มเหลว: $e');
      Fluttertoast.showToast(msg: 'ไม่สามารถรับออเดอร์ได้');
    }
  }

  Widget buildStatusBox(int status) {
    String text = "";
    Color color = Colors.grey;

    switch (status) {
      case 0:
        text = "รอร้านรับออเดอร์";
        color = Colors.orange;
        break;
      case 1:
        text = "ร้านรับออเดอร์แล้ว";
        color = Colors.blue;
        break;
      case 2:
        text = "กำลังจัดส่ง";
        color = Colors.purple;
        break;
      case 3:
        text = "ส่งถึงแล้ว";
        color = Colors.green;
        break;
      default:
        text = "ไม่ทราบสถานะ";
        color = const Color.fromARGB(255, 255, 0, 0);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void LoadAllOrder(BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    try {
      CollectionReference ordersCollection =
          FirebaseFirestore.instance.collection('BP_Order_detail');

      // กรองเงื่อนไข: Order_status = 1 และ rid_id = 0
      QuerySnapshot snapshot = await ordersCollection
          .where('Order_status', isEqualTo: 1)
          .where('rid_id', isEqualTo: 0)
          .get();

      List<Map<String, dynamic>> filteredOrders = [];

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // เพิ่ม order id ลงไปใน map

        // ถ้ามีตำแหน่งปัจจุบัน ให้ตรวจสอบระยะทาง
        if (_currentPosition != null) {
          // ดึงข้อมูลร้านเพื่อตรวจสอบ coordinate
          var resInfo = _restaurantMap[data['res_id']];
          if (resInfo == null) {
            await loadRestaurant(data['res_id']);
            resInfo = _restaurantMap[data['res_id']];
          }

          if (resInfo != null && resInfo.res_coordinate.isNotEmpty) {
            var resCoord = parseCoordinates(resInfo.res_coordinate);
            double distance = calculateDistance(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              resCoord['lat']!,
              resCoord['lng']!,
            );

            // เพิ่มเฉพาะออเดอร์ที่ระยะทางไม่เกิน 3 กิโลเมตร
            if (distance <= 3.0) {
              filteredOrders.add(data);
            }
          } else {
            // ถ้าไม่มี coordinate ก็เพิ่มเข้าไป (กรณี fallback)
            filteredOrders.add(data);
          }
        } else {
          // ถ้าไม่มีตำแหน่งปัจจุบัน ให้แสดงทั้งหมด
          filteredOrders.add(data);
        }
      }

      setState(() {
        ordersList = filteredOrders;
      });
    } catch (e) {
      print('เกิดข้อผิดพลาดในการโหลดคำสั่งซื้อ: $e');
      Fluttertoast.showToast(msg: 'ไม่สามารถโหลดออเดอร์ได้');
    }

    setState(() {
      isLoading = false;
    });
  }

  void loadCus(int cus_id) async {
    if (_customerMap.containsKey(cus_id)) {
      return;
    }

    final res_CusInfo =
        await http.get(Uri.parse("$url/db/get_CusProfile/$cus_id"));

    if (res_CusInfo.statusCode == 200) {
      final List<CusInfoGetResponse> list =
          (json.decode(res_CusInfo.body) as List)
              .map((e) => CusInfoGetResponse.fromJson(e))
              .toList();

      if (list.isNotEmpty) {
        setState(() {
          _customerMap[cus_id] = list.first;
        });
      }
    }

    final res_Add = await http.get(Uri.parse("$url/db/loadCusAdd/$cus_id"));
    if (res_Add.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(res_Add.body);
      final List<CusAddressGetResponse> res_addList =
          jsonResponse.map((e) => CusAddressGetResponse.fromJson(e)).toList();
      if (res_addList.isNotEmpty) {
        _cusAddMap[cus_id] = res_addList.first;
      }
    }
  }

  // ฟังก์ชันโหลดข้อมูลร้านอาหาร
  Future<void> loadRestaurant(int res_id) async {
    if (_restaurantMap.containsKey(res_id)) {
      return;
    }

    try {
      final res_ResInfo =
          await http.get(Uri.parse("$url/db/get_ResProfile/$res_id"));

      if (res_ResInfo.statusCode == 200) {
        final List<ResInfoResponse> list =
            (json.decode(res_ResInfo.body) as List)
                .map((e) => ResInfoResponse.fromJson(e))
                .toList();

        if (list.isNotEmpty) {
          setState(() {
            _restaurantMap[res_id] = list.first;
            context.read<ShareData>().res_info = list.first;
          });
        }
      }
    } catch (e) {
      print('ไม่สามารถโหลดข้อมูลร้าน: $e');
    }
  }
}
