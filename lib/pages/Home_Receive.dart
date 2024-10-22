import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_miniproject_app/models/response/GetSendOrder_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetUserSearch_Res.dart';
import 'package:mobile_miniproject_app/pages/Home_Receive.dart';
import 'package:mobile_miniproject_app/pages/OrderInfo.dart';
import 'package:mobile_miniproject_app/pages/Receive_AllMap.dart';
import 'package:provider/provider.dart';
import 'package:mobile_miniproject_app/models/response/GetLotteryNumbers_Res.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/pages/Profile.dart';

class Home_ReceivePage extends StatefulWidget {
  final int selectedIndex;
  final VoidCallback onClose;
  Home_ReceivePage(
      {Key? key, required this.onClose, required this.selectedIndex})
      : super(key: key);

  @override
  State<Home_ReceivePage> createState() => _Home_ReceivePageState();
}

class _Home_ReceivePageState extends State<Home_ReceivePage>
    with SingleTickerProviderStateMixin {
  int send_uid = 0;
  int info_send_uid = 0;
  int info_receive_uid = 0;
  String send_user_name = '';
  String send_user_type = '';
  String send_user_image = '';

  int sender_uid = 0;
  int receiver_uid = 0;
  int order_oid = 0;

  int receive_uid = 0;
  String receive_user_name = '';
  String receive_user_type = '';
  String receive_user_image = '';
  String username = '';
  int wallet = 0;
  int cart_length = 0;
  GetStorage gs = GetStorage();
  String url = '';
  List<GetSendOrder> receive_Orders = [];
  List<GetUserSearchRes> send_user = [];
  List<GetUserSearchRes> receive_user = [];
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

    loadData = loadDataAsync();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
                                    .receive_order_share
                                    .isEmpty)
                                  const Center(
                                    child: Text(
                                      "Please press the Add button below to include the items you wish to ship.",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  )
                                else
                                  ...context
                                      .read<ShareData>()
                                      .receive_order_share
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
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: FilledButton(
                                    onPressed: () {
                                      Get.to(ReceiveAllMapPage(
                                          info_send_uid: receive_uid,
                                          info_receive_uid: receiver_uid,
                                          info_oid: order_oid,
                                          selectedIndex: 1));
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(255,
                                          115, 28, 168), // สีพื้นหลังของปุ่ม
                                      foregroundColor:
                                          Colors.yellow, // สีของข้อความในปุ่ม
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 15), // ระยะห่างภายในปุ่ม
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            12), // ขอบปุ่มโค้งมน
                                      ),
                                      elevation: 5, // เงาของปุ่มเพื่อเพิ่มมิติ
                                    ),
                                    child: Text(
                                      "Show All In One Map",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight
                                              .bold), // ขนาดและน้ำหนักของข้อความ
                                    ),
                                  ),
                                )
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
          // Swipeable indicator
          Positioned(
            left: -80, // Move it slightly off-screen
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (details.delta.dx > 10) {
                  // เปลี่ยนเงื่อนไขให้ตรวจจับการปัดจากซ้ายไปขวา
                  setState(() {
                    _showReceivePage = true;
                  });
                  _animationController.forward();
                }
              },
              child: Container(
                width: 120, // กำหนดความกว้าง
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 255, 222, 78), // สีพื้นหลัง
                  shape: BoxShape.circle, // ทำให้เป็นวงกลม
                ),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 9,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 70),
                      child: Text(
                        'Send',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Receive page
        ],
      ),
    );
  }

  Future<Widget> buildOrderItem(GetSendOrder orders) async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];
    if (orders == null) {
      return Text('Order information is not available');
    }
    // log(url);
    // log(send_uid.toString());
    // log(send_Orders.length.toString());

    if (context.read<ShareData>().listener != null) {
      context.read<ShareData>().listener!.cancel();
      context.read<ShareData>().listener = null;
      log("listener stopped");
    }
    log("Realtime Started!!!!!!!!!!!!!!!!");
    final collectionRef = db.collection("Order_Info");
    context.read<ShareData>().listener = collectionRef.snapshots().listen(
      (snapshot) {
        for (var docChange in snapshot.docChanges) {
          // ตรวจสอบเฉพาะการเปลี่ยนแปลง (modified) เท่านั้น
          if (docChange.type == DocumentChangeType.modified) {
            var data = docChange.doc.data();
            var docId = docChange.doc.id; // ชื่อเอกสารที่มีการเปลี่ยนแปลง

            // แสดง Snackbar เฉพาะเมื่อมีการเปลี่ยนแปลงข้อมูล พร้อมแสดงชื่อเอกสาร
            Get.snackbar(
              "Document: $docId | Status: ${data!['Order_status']}",
              "Order Time: ${data['Order_time_at'].toString()}",
            );
            setState(() {});

            // ตรวจสอบการเปลี่ยนแปลงสถานะใหม่
            if (New_Dv_status != data['Order_status'] ||
                New_Dv_status == null) {
              New_Dv_status = data['Order_status'];
              log("${New_Dv_status}+NEWNEWNENWNEDVVVVVVVVVVVVVVVVSTATATUS (Document: $docId)");
            }
          }
        }
      },
      onError: (error) => log("Listen failed: $error"),
    );

    var result =
        await db.collection('Order_Info').doc("order${orders.oid}").get();
    var data = result.data();

    if (data == null) {
      return Text('Order data not found');
    }

    var Dv_status = data['Order_status'] ?? 0;

    var response =
        await http.get(Uri.parse("$url/db/get_Receive/${orders.se_Uid}"));
    receive_user = getUserSearchResFromJson(response.body);

    sender_uid = orders.se_Uid;
    receiver_uid = orders.re_Uid;
    order_oid = orders.oid;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IntrinsicWidth(
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.location_on,
                      color: Colors.red, size: 14), // ปรับขนาดไอคอน
                  SizedBox(width: 5),
                  Text(receive_user.first.name),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.location_on,
                      color: Color.fromARGB(255, 79, 252, 10),
                      size: 14), // ปรับขนาดไอคอน
                  SizedBox(width: 5),
                  Text(send_user_name),
                ],
              ),
              Padding(
                  padding: const EdgeInsets.only(top: 18, left: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: Dv_status == 1
                            ? Colors.grey
                            : Dv_status == 2
                                ? Colors.yellow
                                : Dv_status == 3
                                    ? Colors.yellow
                                    : Dv_status == 4
                                        ? Colors.purple
                                        : Colors.black, // กำหนดสีตาม dv_Status
                        size: 9,
                      ),
                      SizedBox(width: 5),
                      Text(
                        Dv_status == 1
                            ? 'รอไรเดอร์มารับสินค้า'
                            : Dv_status == 2
                                ? 'ไรเดอร์รับงาน'
                                : Dv_status == 3
                                    ? 'ไรเดอร์รับสินค้าแล้วและกำลังเดินทาง'
                                    : Dv_status == 4
                                        ? 'ไรเดอร์นำส่งสินค้าแล้ว'
                                        : 'สถานะไม่ถูกต้อง', // กำหนดข้อความตาม dv_Status
                        style: TextStyle(
                          fontSize: Dv_status == 3 ? 10 : 15, // กำหนดขนาดฟอนต์
                        ),
                      ),
                    ],
                  )),
            ],
          ),
        ),
        Column(
          children: [
            FilledButton(
              onPressed: () {
                Get.to(() => OrderinfoPage(
                    info_send_uid: orders.se_Uid,
                    info_receive_uid: orders.re_Uid,
                    info_oid: orders.oid,
                    selectedIndex: 1));
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(
                    Color.fromARGB(255, 190, 154, 205)), // สีพื้นหลัง
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0), // ขอบโค้งมน
                  ),
                ),
                padding: WidgetStateProperty.all<EdgeInsets>(
                  EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8), // ปรับลดระยะห่างรอบข้อความและไอคอน
                ),
              ),
              child: Row(
                mainAxisSize:
                    MainAxisSize.min, // ขนาดของ Row จะปรับตามเนื้อหาภายใน
                children: [
                  Text(
                    "Details",
                    style: TextStyle(
                      color: Color.fromARGB(255, 90, 4, 134), // สีข้อความ
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 8), // เพิ่มระยะห่างระหว่างข้อความกับไอคอน
                  Icon(
                    Icons.arrow_forward_ios,
                    color: const Color.fromARGB(255, 90, 4, 134), // สีไอคอน
                    size: 18,
                  ),
                ],
              ),
            )
          ],
        )
      ]),
    );
  }

  Future<void> loadDataAsync() async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];
    log(url);
    log(send_uid.toString());
    log("sddddddddddddddd");
    log(receive_Orders.length.toString());

    var response =
        await http.get(Uri.parse("$url/db/get_Receive_Order/${send_uid}"));
    if (response.statusCode == 200) {
      receive_Orders = getSendOrderFromJson(response.body);
      log(jsonEncode(receive_Orders));
      log("sddddddddddddddd");
      log(receive_Orders.length.toString());

      setState(() {
        context.read<ShareData>().receive_order_share = receive_Orders;
      });
    } else {
      log('Failed to load lottery numbers. Status code: ${response.statusCode}');
    }
  }
}
