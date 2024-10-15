import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:math' hide log;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/GetLotteryNumbers_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetOneUser_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetSendOrder_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetUserSearch_Res.dart';
import 'package:mobile_miniproject_app/pages/Home_Send.dart';
import 'package:mobile_miniproject_app/pages/RiderHome.dart';
import 'package:mobile_miniproject_app/pages/RiderReceive.dart';
import 'package:mobile_miniproject_app/pages/RiderHistory.dart';
import 'package:mobile_miniproject_app/pages/RiderOrderInfo.dart';
import 'package:mobile_miniproject_app/pages/RiderProfile.dart';
import 'package:mobile_miniproject_app/pages/Shop.dart';
import 'package:mobile_miniproject_app/pages/Ticket.dart';
import 'package:mobile_miniproject_app/pages/Profile.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';

class RiderHistoryPage extends StatefulWidget {
  int uid = 0;
  int wallet = 0;
  String name = '';
  int selectedIndex = 0;
  var onClose;
  RiderHistoryPage({
    super.key,
    required this.onClose,
    required this.selectedIndex,
  });

  @override
  State<RiderHistoryPage> createState() => _RiderHistoryPageState();
}

class _RiderHistoryPageState extends State<RiderHistoryPage> {
  int send_uid = 0;
  int info_send_uid = 0;
  int info_receive_uid = 0;
  String send_user_name = '';
  String send_user_type = '';
  String send_user_image = '';

  int receive_uid = 0;
  String receive_user_name = '';
  String receive_user_type = '';
  String receive_user_image = '';
  String username = '';
  int wallet = 0;
  int cart_length = 0;
  GetStorage gs = GetStorage();
  String url = '';
  List<GetSendOrder> rider_Orders = [];
  List<GetUserSearchRes> order_user = [];
  late Future<void> loadData;
  int _selectedIndex = 0;
  bool _showReceivePage = false;
  late AnimationController _animationController;
  late Animation<Offset> _pageSlideAnimation;
  var db = FirebaseFirestore.instance;
  var New_Dv_status;

  @override
  void initState() {
    send_uid = context.read<ShareData>().user_info_send.uid;
    send_user_name = context.read<ShareData>().user_info_send.name;
    send_user_type = context.read<ShareData>().user_info_send.user_type;
    send_user_image = context.read<ShareData>().user_info_send.user_image;

    receive_uid = context.read<ShareData>().user_info_send.uid;
    receive_user_name = context.read<ShareData>().user_info_send.name;
    receive_user_type = context.read<ShareData>().user_info_send.user_type;
    receive_user_image = context.read<ShareData>().user_info_send.user_image;
    _selectedIndex = widget.selectedIndex;
    loadData = loadDataAsync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: FutureBuilder(
                      future: loadData,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (context
                                    .read<ShareData>()
                                    .rider_order_share
                                    .isEmpty)
                                  const Center(
                                    child: Text(
                                      "There are no orders at the moment,please wait a moment...",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  )
                                else
                                  ...context
                                      .read<ShareData>()
                                      .rider_order_share
                                      .map((orders) => Card(
                                          elevation: 4.0, // ความลึกเงาของ Card
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                10.0), // กำหนดความโค้งของขอบ
                                          ),
                                          margin: EdgeInsets.all(
                                              8.0), // กำหนดระยะห่าง
                                          child: FutureBuilder(
                                            future: buildOrderItem(
                                                orders), // รอผลลัพธ์จาก Future
                                            builder: (BuildContext context,
                                                AsyncSnapshot<Widget>
                                                    snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                // แสดง loading เมื่อกำลังโหลดข้อมูล
                                                return CircularProgressIndicator();
                                              } else if (snapshot.hasError) {
                                                // แสดงข้อความเมื่อเกิดข้อผิดพลาด
                                                return Text(
                                                    'Error: ${snapshot.error}');
                                              } else if (snapshot.hasData) {
                                                // แสดง Widget เมื่อมีข้อมูล
                                                return snapshot.data!;
                                              } else {
                                                // กรณีที่ไม่มีข้อมูล
                                                return Text(
                                                    'No data available');
                                              }
                                            },
                                          ) // Widget ที่ต้องการแสดงใน Card
                                          ))
                                      .toList(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Receive page
        ],
      ),
      bottomNavigationBar: buildBottomNavigationBar(),
    );
  }

  Widget buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40.0),
          topRight: Radius.circular(40.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40.0),
          topRight: Radius.circular(40.0),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.yellow,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          iconSize: 20,
          selectedLabelStyle:
              TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_edu_outlined), // Icon for the Add button
              label: 'History', // Label for the Add button
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      if (index == 0) {
        // Navigate to Home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => RiderHomePage()), // สมมติว่ามี HomePage
        );
      } else if (index == 1) {
        // Navigate to History page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RiderHistoryPage(
                onClose: () {},
                selectedIndex: 1), // ตั้งค่า selectedIndex เป็น 1
          ),
        );
      } else if (index == 2) {
        // Navigate to Profile page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RiderProfilePage(onClose: () {}, selectedIndex: 2),
          ),
        );
      }
    });
  }

  Future<Widget> buildOrderItem(GetSendOrder orders) async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];
    if (orders == null) {
      return Text('Order information is not available');
    }

    // Your existing listener setup code...

    var result =
        await db.collection('Order_Info').doc("order${orders.oid}").get();
    var data = result.data();

    if (data == null) {
      return Text('Order data not found');
    }

    var Dv_status = data['Order_status'] ?? 0;

    var receive = await http
        .get(Uri.parse("$url/db/get_Order/${orders.se_Uid}/${orders.re_Uid}"));
    var order = json.decode(receive.body);
    var seUser = order['se_user'];
    var reUser = order['re_user'];
    var seUserData = getUserSearchResFromJson(jsonEncode(seUser));
    var reUserData = getUserSearchResFromJson(jsonEncode(reUser));

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        // เปลี่ยนจาก Row เป็น Column
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IntrinsicWidth(
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red, size: 14),
                      SizedBox(width: 5),
                      Text(seUserData.first.name),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          color: Color.fromARGB(255, 79, 252, 10), size: 14),
                      SizedBox(width: 5),
                      Text(reUserData.first.name),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                FilledButton(
                  onPressed: () {
                    Get.to(() => RiderReceivePage(
                        info_send_uid: orders.se_Uid,
                        info_receive_uid: orders.re_Uid,
                        info_oid: orders.oid,
                        selectedIndex: 1));
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(
                        Color.fromARGB(255, 190, 154, 205)),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    padding: WidgetStateProperty.all<EdgeInsets>(
                      EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Detail",
                        style: TextStyle(
                          color: Color.fromARGB(255, 90, 4, 134),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                TextButton(
                  onPressed: () {
                    Get.to(() => RiderOrderinfoPage(
                        info_send_uid: orders.se_Uid,
                        info_receive_uid: orders.re_Uid,
                        info_oid: orders.oid,
                        selectedIndex: 1));
                  },
                  child: Text(orders.p_Name),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> loadDataAsync() async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];
    log(url);
    log(send_uid.toString());
    log("sddddddddddddddd");
    log(rider_Orders.length.toString());

    var response = await http.get(Uri.parse("$url/db/get_Rider_Order"));
    if (response.statusCode == 200) {
      rider_Orders = getSendOrderFromJson(response.body);
      log(jsonEncode(rider_Orders));
      log("sdddddddddddddddxxxxxxxxxxxxxxxxxx");
      log(rider_Orders.length.toString());

      setState(() {
        context.read<ShareData>().rider_order_share = rider_Orders;
      });
    } else {
      log('Failed to load lottery numbers. Status code: ${response.statusCode}');
    }
  }
}
