import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:math' hide log;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/CusInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/CusOrderGetRes.dart';

import 'package:mobile_miniproject_app/pages/restaurant/ResOrder.dart';
import 'package:mobile_miniproject_app/pages/rider/RiderHome.dart';
import 'package:mobile_miniproject_app/pages/rider/RiderOrder.dart';

import 'package:mobile_miniproject_app/pages/rider/RiderHistory.dart';

import 'package:mobile_miniproject_app/pages/rider/RiderProfile.dart';

import 'package:mobile_miniproject_app/pages/customer/CustomerProfile.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';

class RiderHistoryPage extends StatefulWidget {
  RiderHistoryPage({
    super.key,
  });

  @override
  State<RiderHistoryPage> createState() => _RiderHistoryPageState();
}

class _RiderHistoryPageState extends State<RiderHistoryPage> {
  int _selectedIndex = 0;
  late PageController _pageController;
  String url = '';
  bool isLoading = true;
  List<CusOrderGetResponse> ordersList = []; // เก็บ order
  Map<int, CusInfoGetResponse> _customerMap = {};

  @override
  void initState() {
    super.initState();
    Configuration.getConfig().then((value) {
      url = value['apiEndpoint'];
      LoadAllOrder(context);
    });
    _pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("ประวัติการรับออเดอร์"),
          automaticallyImplyLeading: false,
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : ordersList.isEmpty
                ? Center(child: Text("ไม่พบคำสั่งซื้อ"))
                : ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: ordersList.length,
                    itemBuilder: (context, index) {
                      var order = ordersList[index];

                      // ดึงข้อมูลร้านจาก map
                      var cusInfo = _customerMap[order.cusId];

                      // เรียกโหลดร้านถ้ายังไม่มีใน map
                      if (cusInfo == null) {
                        loadCus(order.cusId);
                      }

                      // แปลงวันเวลา
                      DateTime orderDate = order.ordDate;
                      String formattedDate =
                          DateFormat('dd/MM/yyyy เวลา HH:mm น.')
                              .format(orderDate.toLocal());

                      return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResOrderPage(
                                  mergedMenus: order.orlOrderDetail,
                                  deliveryFee: order.ordDevPrice,
                                  order_id: order.ordId,
                                  order_status: order.ordStatus,
                                  previousPage: 'ResOrderPage',
                                ),
                              ),
                            );
                          },
                          child: Card(
                            margin: EdgeInsets.symmetric(vertical: 6),
                            elevation: 3,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ข้อมูลทางซ้าย
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
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 4),
                                        buildStatusBox(order.ordStatus ?? -1),
                                        SizedBox(height: 4),
                                        Text("วันที่: $formattedDate"),
                                      ],
                                    ),
                                  ),

                                  // ปุ่มทางขวา
                                  // แทนที่โค้ดปุ่มทั้งหมด
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end, // จัดฝั่งขวา
                                    children: [
                                      Text(
                                        order.ordRidIncome != null
                                            ? "รายได้ไรเดอร์: ${order.ordRidIncome} ฿"
                                            : "รายได้ไรเดอร์: -",
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ));
                    }));
  }

  Future<void> updateOrderStatus(String docId, int newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('BP_Order_detail')
          .doc('order' + docId)
          .update({'Order_status': newStatus});
      LoadAllOrder(context);
      setState(() {});
    } catch (e) {
      print('อัปเดตสถานะล้มเหลว: $e');
      Fluttertoast.showToast(msg: 'ไม่สามารถอัปเดตสถานะได้');
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
      int rid_id = context.read<ShareData>().user_info_send.uid;
      final rid_ResInfo =
          await http.get(Uri.parse("$url/db/loadRidHisOrder/$rid_id"));
      final List<CusOrderGetResponse> list =
          (json.decode(rid_ResInfo.body) as List)
              .map((e) => CusOrderGetResponse.fromJson(e))
              .toList();

      if (rid_ResInfo.statusCode == 200) {
        ordersList.clear();
        ordersList = list;
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการโหลดคำสั่งซื้อ: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  void loadCus(int cus_id) async {
    if (_customerMap.containsKey(cus_id)) {
      log("ลูกค้าโหลดแล้ว: ${_customerMap[cus_id]?.cus_name}");
      return;
    }

    final res_ResInfo =
        await http.get(Uri.parse("$url/db/get_CusProfile/$cus_id"));

    if (res_ResInfo.statusCode == 200) {
      final List<CusInfoGetResponse> list =
          (json.decode(res_ResInfo.body) as List)
              .map((e) => CusInfoGetResponse.fromJson(e))
              .toList();

      if (list.isNotEmpty) {
        setState(() {
          _customerMap[cus_id] = list.first;
          log("เพิ่มลูกค้าใหม่: cus_id=$cus_id, name=${list.first.cus_name}");
          log("สถานะปัจจุบันของ _customerMap: $_customerMap");
        });
      }
    }
  }
}
