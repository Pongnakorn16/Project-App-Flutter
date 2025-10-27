import 'dart:convert';
import 'dart:developer';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/CusAddressGetRes.dart';
import 'package:mobile_miniproject_app/models/response/CusInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/CusOrderGetRes.dart';
import 'package:mobile_miniproject_app/models/response/OptionGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
import 'package:mobile_miniproject_app/pages/customer/Order.dart';
import 'package:mobile_miniproject_app/pages/login/login.dart';
import 'package:mobile_miniproject_app/pages/restaurant/ResOrder.dart';
import 'package:mobile_miniproject_app/pages/rider/RiderHistory.dart';
import 'package:mobile_miniproject_app/pages/rider/RiderIncomeSummary.dart';
import 'package:mobile_miniproject_app/pages/rider/RiderMapToRes.dart';
import 'package:mobile_miniproject_app/pages/rider/RiderOrder.dart';
import 'package:mobile_miniproject_app/pages/rider/RiderProfile.dart';
import 'package:mobile_miniproject_app/pages/rider/RiderVerifiPage.dart';
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
  List<CusOrderGetResponse> ordersList = [];
  Map<int, CusInfoGetResponse> _customerMap = {};
  Map<int, ResInfoResponse> _restaurantMap = {};
  Map<int, CusAddressGetResponse> _cusAddMap = {};
  List<CusOrderGetResponse> sqlOrders = [];
  List<Map<String, String>> firebaseOrders = [];
  Position? _currentPosition;
  int RiderVerStatus = 0;
  String vehicleImg = '';
  String driveLicenseImg = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Configuration.getConfig().then((value) async {
      url = value['apiEndpoint'];
      await loadRiderStatus();

      // เช็คสถานะไรเดอร์หลังโหลดข้อมูล
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkRiderVerification();
      });

      _initLocationAndLoadOrders();
    });
    _pageController = PageController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      if (_selectedIndex == 0) {
        _refreshData();
      }
    }
  }

  // ฟังก์ชันเช็คการยืนยันตัวตนไรเดอร์
  void _checkRiderVerification() {
    print('🔍 เช็คสถานะไรเดอร์:');
    print('RiderStatus: $RiderVerStatus');
    print('vehicleImg: "$vehicleImg"');
    print('driveLicenseImg: "$driveLicenseImg"');

    // เช็คทั้ง empty และ null
    bool isVehicleImgEmpty = vehicleImg.isEmpty || vehicleImg == 'null';
    bool isDriveLicenseImgEmpty =
        driveLicenseImg.isEmpty || driveLicenseImg == 'null';

    if (RiderVerStatus == 0 && (isVehicleImgEmpty || isDriveLicenseImgEmpty)) {
      print('✅ แสดง popup ยืนยันตัวตน');
      _showVerificationDialog();
    } else if (RiderVerStatus == 0 &&
        (!isVehicleImgEmpty && !isDriveLicenseImgEmpty)) {
      // เปลี่ยน || → &&
      _showWaitungDialog();
    } else {
      print('❌ ไม่แสดง popup');
    }
  }

  // แสดง popup แจ้งเตือน
  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // ไม่สามารถปิดด้วยการแตะด้านนอกได้
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // ปิดการกดปุ่ม back
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 32),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ยืนยันตัวตนไรเดอร์',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ท่านยังไม่ได้ยืนยันตัวตนไรเดอร์',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'กรุณายืนยันตัวตนก่อนการทำงาน',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // ปิด dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RiderVerificationPage(), // เปลี่ยนตามหน้าจริง
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'ไปยืนยันตัวตน',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWaitungDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // ไม่สามารถปิดด้วยการแตะด้านนอกได้
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // ปิดการกดปุ่ม back
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 32),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ยืนยันตัวตนไรเดอร์',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ท่านได้ส่งรูปยืนยันตัวตนไรเดอร์ไปแล้ว',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'กรุณารอผู้ดูแลระบบทำการตรวจสอบ',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // ปิด dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(), // เปลี่ยนตามหน้าจริง
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'กลับไปยังหน้า Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refreshData() async {
    print("กำลังรีเฟรชข้อมูล...");

    setState(() {
      _customerMap.clear();
      _restaurantMap.clear();
      ordersList.clear();
    });

    await _initLocationAndLoadOrders();
  }

  Future<void> _initLocationAndLoadOrders() async {
    try {
      Position position = await _getCurrentLocation();
      setState(() {
        _currentPosition = position;
      });
      LoadAllOrder(context);
    } catch (e) {
      print("ไม่สามารถดึงตำแหน่งได้: $e");
      Fluttertoast.showToast(msg: "กรุณาเปิด GPS");
      LoadAllOrder(context);
    }
  }

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

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;

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
          _buildOrderPage(),
          RiderHistoryPage(),
          RiderIncomeSummaryPage(),
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
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'ประวัติรับงาน',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.data_thresholding_outlined), label: 'รายได้'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }

  Widget _buildOrderPage() {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ออเดอร์ที่พร้อม",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // เหรียญ D
                    Container(
                      width: 25,
                      height: 25,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amber,
                      ),
                      child: const Center(
                        child: Text(
                          'D',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6), // เว้นระยะระหว่างเหรียญกับตัวเลข
                    Text(
                      NumberFormat('#,###').format(
                          context.read<ShareData>().user_info_send.balance),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
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

                          var cusInfo = _customerMap[order.cusId];
                          var cusAdd = _cusAddMap[order.cusId];
                          var resInfo = _restaurantMap[order.resId];

                          if (cusInfo == null) {
                            loadCus(order.cusId);
                          }

                          if (resInfo == null) {
                            loadRestaurant(order.resId);
                          }

                          DateTime orderDate =
                              order.ordDate; // ไม่ต้อง toLocal()
                          String formattedDate =
                              DateFormat('dd/MM/yyyy เวลา HH:mm น.')
                                  .format(orderDate);

                          double distance = 0.0;
                          String distanceText = "คำนวณระยะทาง...";

                          var firebaseOrder = firebaseOrders.firstWhere(
                            (e) => e['order_id'] == order.ordId.toString(),
                            orElse: () =>
                                {'cusCoordinate': '', 'resCoordinate': ''},
                          );
                          {
                            var cusCoord = parseCoordinates(
                                firebaseOrder['cusCoordinate'] ?? '');
                            var resCoord = parseCoordinates(
                                firebaseOrder['resCoordinate'] ?? '');

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
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RiderOrderPage(
                                      mergedMenus: order.orlOrderDetail,
                                      deliveryFee: order.ordDevPrice,
                                      order_id: order.ordId,
                                      order_status: order.ordStatus,
                                      previousPage: 'RiderOrderPage',
                                    ),
                                  ),
                                );
                                _refreshData();
                              },
                              child: Card(
                                margin: EdgeInsets.symmetric(vertical: 6),
                                elevation: 3,
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "หมายเลขออเดอร์ : ${order.ordId ?? '-'}",
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
                                      if ((order.ordStatus ?? -1) == 1)
                                        SizedBox(
                                          width: 100,
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              await acceptOrder(
                                                  order.ordId.toString());
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      RiderMapToResPage(
                                                    ord_id: order.ordId,
                                                  ),
                                                ),
                                              );
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
        'Rider_coordinate':
            "${_currentPosition!.latitude.toString()},${_currentPosition!.longitude.toString()}",
      });

      final Add_rider =
          await http.put(Uri.parse("$url/db/AddRider/$riderId/$orderId"));

      if (Add_rider.statusCode == 200) {
        LoadAllOrder(context);
        setState(() {});
      } else {
        print('MySQL update failed: ${Add_rider.body}');
        Fluttertoast.showToast(msg: 'อัปเดตสถานะใน MySQL ล้มเหลว');
      }

      Fluttertoast.showToast(msg: 'รับออเดอร์เรียบร้อย');
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
    int userId = context.read<ShareData>().user_info_send.uid;
    setState(() {
      isLoading = true;
    });

    try {
      final rid_balance =
          await http.get(Uri.parse("$url/db/loadRiderbalance/$userId"));
      print('Status code: ${rid_balance.statusCode}');
      print('Response body: ${rid_balance.body}');

      if (rid_balance.statusCode == 200) {
        final data = jsonDecode(rid_balance.body);
        final double balance = (data['balance'] as num).toDouble();
        context.read<ShareData>().user_info_send.balance = balance;
      } else {
        Fluttertoast.showToast(msg: "โหลดยอดเงินไม่สำเร็จ");
      }

      final Rider_All_Order =
          await http.get(Uri.parse("$url/db/loadRiderOrder"));
      if (Rider_All_Order.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(Rider_All_Order.body);
        sqlOrders =
            jsonList.map((e) => CusOrderGetResponse.fromJson(e)).toList();

        setState(() {
          ordersList = sqlOrders;
        });
      }

      CollectionReference ordersCollection =
          FirebaseFirestore.instance.collection('BP_Order_detail');

      QuerySnapshot snapshot = await ordersCollection.get();

      firebaseOrders = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'cusCoordinate': data['Cus_coordinate']?.toString() ?? '',
          'resCoordinate': data['Res_coordinate']?.toString() ?? '',
          'order_id': data['order_id']?.toString() ?? '',
        };
      }).toList();

      if (_currentPosition != null) {
        ordersList = sqlOrders.where((order) {
          var firebaseOrder = firebaseOrders.firstWhere(
            (e) => e['order_id'] == order.ordId.toString(),
            orElse: () => {'resCoordinate': ''},
          );

          var resCoord = parseCoordinates(firebaseOrder['resCoordinate'] ?? '');
          double distanceToRes = calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            resCoord['lat']!,
            resCoord['lng']!,
          );

          return distanceToRes <= 3.0;
        }).toList();
      } else {
        ordersList = sqlOrders;
      }
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

  Future<void> loadRiderStatus() async {
    final rid = context.read<ShareData>().user_info_send.uid;
    try {
      final res_ResInfo =
          await http.get(Uri.parse("$url/db/get_ridStatus/$rid"));

      if (res_ResInfo.statusCode == 200) {
        final data = jsonDecode(res_ResInfo.body);

        if (data is List && data.isNotEmpty) {
          setState(() {
            RiderVerStatus = data[0]['rid_ver_status'] ?? 0;
            vehicleImg = data[0]['rid_vehicle_image']?.toString() ?? '';
            driveLicenseImg =
                data[0]['rid_driv_license_image']?.toString() ?? '';
          });
        }
      }
    } catch (e) {
      print('ไม่สามารถโหลดข้อมูลไรเดอร์: $e');
    }
  }

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
