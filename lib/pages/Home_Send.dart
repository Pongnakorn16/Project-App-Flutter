import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_miniproject_app/models/response/GetSendOrder_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetUserSearch_Res.dart';
import 'package:mobile_miniproject_app/pages/Home_Receive.dart';
import 'package:provider/provider.dart';
import 'package:mobile_miniproject_app/models/response/GetCart_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetLotteryNumbers_Res.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/pages/Profile.dart';

class Home_SendPage extends StatefulWidget {
  final int selectedIndex;
  final VoidCallback onClose;
  Home_SendPage({Key? key, required this.onClose, required this.selectedIndex})
      : super(key: key);

  @override
  State<Home_SendPage> createState() => _Home_SendPageState();
}

class _Home_SendPageState extends State<Home_SendPage>
    with SingleTickerProviderStateMixin {
  int send_uid = 0;
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
  List<GetCartRes> all_cart = [];
  List<GetSendOrder> send_Orders = [];
  List<GetUserSearchRes> send_user = [];
  List<GetUserSearchRes> receive_user = [];
  late Future<void> loadData;
  int _selectedIndex = 0;
  bool _showReceivePage = false;
  late AnimationController _animationController;
  late Animation<Offset> _pageSlideAnimation;

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
                          // child: Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //   children: [
                          //     Column(
                          //       children: [Text("Hello")],
                          //     ),
                          //     Column()
                          //   ],
                          // ),
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (context
                                    .read<ShareData>()
                                    .send_order_share
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
                                      .send_order_share
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
          // Swipeable indicator
          Positioned(
            right: -80, // Move it slightly off-screen
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (details.delta.dx < -10) {
                  setState(() {
                    _showReceivePage = true;
                  });
                  _animationController.forward();
                }
              },
              child: Container(
                width: 120, // กำหนดความกว้าง
                decoration: BoxDecoration(
                  color: Colors.purple, // สีพื้นหลัง
                  shape: BoxShape.circle, // ทำให้เป็นวงกลม
                ),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 70),
                      child: Text(
                        'Receive',
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
    log(url);
    log(send_uid.toString());
    log(orders.toString());
    log(send_Orders.length.toString());

    var response =
        await http.get(Uri.parse("$url/db/get_Receive/${orders.re_Uid}"));
    receive_user = getUserSearchResFromJson(response.body);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(
          children: [Text(send_user_name), Text(receive_user.first.name)],
        ),
        Column(
          children: [Text("Detail")],
        )
      ]),
    );
  }

  Widget buildPrizeStatus(int status_prize) {
    String status;
    double fontSize;
    Icon? icon;
    Color textColor = Colors.black;
    Color iconColor = Colors.black;

    if (status_prize == 1) {
      status = 'st';
      fontSize = 21;
      iconColor = Colors.blue;
      icon = Icon(Icons.local_fire_department, color: iconColor, size: 40);
      textColor = Colors.blue;
    } else if (status_prize == 2) {
      status = 'nd';
      fontSize = 19;
    } else if (status_prize == 3) {
      status = 'rd';
      fontSize = 17;
    } else if (status_prize >= 4) {
      status = 'th';
      fontSize = 15;
    } else {
      status = 'unknown';
      fontSize = 15;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "${status_prize}${status}",
          style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: textColor),
        ),
        if (icon != null)
          Padding(padding: const EdgeInsets.only(right: 8.0), child: icon),
      ],
    );
  }

  Widget buildPrizeAmount(int status_prize) {
    String prize;
    if (status_prize == 1) {
      prize = '10,000';
    } else if (status_prize == 2) {
      prize = '5,000';
    } else if (status_prize == 3) {
      prize = '1,000';
    } else if (status_prize == 4) {
      prize = '500';
    } else if (status_prize == 5) {
      prize = '150';
    } else {
      prize = 'unknown';
    }

    return Text(
      "เงินรางวัล $prize บาท",
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    );
  }

  Widget buildNumberCard(String number) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Card(
        color: const Color.fromARGB(255, 255, 255, 255),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> loadDataAsync() async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];
    log(url);
    log(send_uid.toString());

    var response =
        await http.get(Uri.parse("$url/db/get_Send_Order/${send_uid}"));
    if (response.statusCode == 200) {
      send_Orders = getSendOrderFromJson(response.body);
      log(jsonEncode(send_Orders));
      if (context.read<ShareData>().send_order_share.isEmpty) {
        context.read<ShareData>().send_order_share = send_Orders;
        setState(() {});
      }
    } else {
      log('Failed to load lottery numbers. Status code: ${response.statusCode}');
    }

    // var get_cart = await http.get(Uri.parse("$url/db/get_cart/${uid}"));
    // if (get_cart.statusCode == 200) {
    //   all_cart = getCartResFromJson(get_cart.body);
    //   context.read<ShareData>().user_info.cart_length = all_cart.length;
    // } else {
    //   log('Failed to load cart. Status code: ${get_cart.statusCode}');
    // }
  }
}
