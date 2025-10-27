import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/CusOrderGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
import 'package:mobile_miniproject_app/pages/customer/CusMap.dart';
import 'package:mobile_miniproject_app/pages/customer/CusReview.dart';
import 'package:mobile_miniproject_app/pages/customer/Order.dart';
import 'package:mobile_miniproject_app/shared/firebase_message_service.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class CusallorderPage extends StatefulWidget {
  const CusallorderPage({super.key});

  @override
  State<CusallorderPage> createState() => _CusallorderPageState();
}

class _CusallorderPageState extends State<CusallorderPage> {
  int _selectedIndex = 0;
  late PageController _pageController;
  String url = '';
  bool isLoading = true;
  List<CusOrderGetResponse> ordersList = []; // เก็บ order
  List<ResInfoResponse> _restaurantInfo = [];
  Map<int, ResInfoResponse> _restaurantMap = {};

  @override
  void initState() {
    super.initState();
    Configuration.getConfig().then((value) {
      url = value['apiEndpoint'];
      LoadAllOrder(context);
      final cus_id = context.read<ShareData>().user_info_send.uid;
      OrderNotificationService().listenOrderChanges(context, cus_id,
          (orderId, newStep) {
        LoadAllOrder(context);
        if (!mounted) return;
      });
      setState(() {});
    });
    _pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("คำสั่งซื้อของฉัน"),
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
                      var resInfo = _restaurantMap[order.resId];

                      // เรียกโหลดร้านถ้ายังไม่มีใน map
                      if (resInfo == null) {
                        loadRes(order.resId);
                      }

                      // แปลงวันเวลา
                      DateTime orderDate = order.ordDate; // ไม่ต้อง toLocal()
                      String formattedDate =
                          DateFormat('dd/MM/yyyy เวลา HH:mm น.')
                              .format(orderDate);

                      return GestureDetector(
                        onTap: () {
                          if (order.ordStatus == 2) {
                            // ไปหน้าติดตามไรเดอร์
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CusMapPage(
                                  ord_id: order.ordId,
                                ),
                              ),
                            );
                          } else if (order.ordStatus < 2) {
                            // สถานะ 0 หรือ 1 ไปดูรายละเอียดออเดอร์ตามเดิม
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderPage(
                                  mergedMenus: order.orlOrderDetail,
                                  deliveryFee: order.ordDevPrice,
                                  order_id: order.ordId,
                                  order_status: order.ordStatus,
                                  previousPage: 'CusAllOrderPage',
                                ),
                              ),
                            );
                          }
                        },
                        child: Card(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            resInfo != null
                                                ? resInfo.res_name
                                                : "กำลังโหลด...",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          buildStatusBox(order.ordStatus ?? -1),
                                          SizedBox(height: 4),
                                          Text(
                                            "วันที่: $formattedDate",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      "ราคารวม: ${(order.totalOrderPrice as num?)?.toInt() ?? '-'} ฿",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                                // แสดงปุ่มรีวิวเมื่อสถานะเป็น 3
                                if (order.ordStatus == 3)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final didReview =
                                              await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CusReviewPage(
                                                ord_id: order.ordId,
                                              ),
                                            ),
                                          );
                                          ;
                                          if (didReview == true) {
                                            setState(() {
                                              LoadAllOrder(
                                                  context); // โหลดข้อมูลใหม่เพื่อรีเฟรช
                                            });
                                          }
                                        },
                                        icon: Icon(Icons.rate_review, size: 18),
                                        label: Text("รีวิว"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }));
  }

  Widget buildStatusBox(int status) {
    String text = "";
    Color color = Colors.grey;

    switch (status) {
      case 0:
        text = "รอร้านยืนยัน";
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
      int cus_id = context.read<ShareData>().user_info_send.uid;
      final res_ResInfo =
          await http.get(Uri.parse("$url/db/loadCusOrder/$cus_id"));
      final List<CusOrderGetResponse> list =
          (json.decode(res_ResInfo.body) as List)
              .map((e) => CusOrderGetResponse.fromJson(e))
              .toList();

      if (res_ResInfo.statusCode == 200) {
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

  void loadRes(int res_id) async {
    context.read<ShareData>().res_id = res_id;
    if (_restaurantMap.containsKey(res_id)) {
      log("ร้านนี้โหลดแล้ว: ${_restaurantMap[res_id]?.res_name}");
      return;
    }

    final res_ResInfo =
        await http.get(Uri.parse("$url/db/loadResInfo/$res_id"));

    if (res_ResInfo.statusCode == 200) {
      final List<ResInfoResponse> list = (json.decode(res_ResInfo.body) as List)
          .map((e) => ResInfoResponse.fromJson(e))
          .toList();

      if (list.isNotEmpty) {
        setState(() {
          _restaurantMap[res_id] = list.first;
          log("เพิ่มร้านใหม่: res_id=$res_id, name=${list.first.res_name}");
          log("สถานะปัจจุบันของ _restaurantMap: $_restaurantMap");
        });
      }
    }
  }
}
