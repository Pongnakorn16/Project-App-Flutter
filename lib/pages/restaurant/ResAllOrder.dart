import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/CusInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/CusOrderGetRes.dart';
import 'package:mobile_miniproject_app/models/response/OptionGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
import 'package:mobile_miniproject_app/pages/customer/Order.dart';
import 'package:mobile_miniproject_app/pages/restaurant/ResOrder.dart';
import 'package:mobile_miniproject_app/shared/firebase_message_service.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';

class ResAllOrderPage extends StatefulWidget {
  const ResAllOrderPage({super.key});

  @override
  State<ResAllOrderPage> createState() => _HomePageState();
}

class _HomePageState extends State<ResAllOrderPage> {
  int _selectedIndex = 0;
  late PageController _pageController;
  String url = '';
  bool isLoading = true;
  List<CusOrderGetResponse> ordersList = []; // เก็บ order
  Map<int, CusInfoGetResponse> _customerMap = {};
  bool hasSubscribed = false; // ✅ ป้องกัน subscribe ซ้ำ

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    Configuration.getConfig().then((value) {
      url = value['apiEndpoint'];

      // LoadAllOrder ก่อนก็ได้ แต่ subscribe listener ต้องทำแค่ครั้งเดียว
      if (!hasSubscribed) {
        hasSubscribed = true; // ✅ ตั้งก่อน subscribe

        LoadAllOrder(context).then((_) {
          final res_id = context.read<ShareData>().user_info_send.uid;
          List<int> orderIds = ordersList.map((order) => order.ordId).toList();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            OrderNotificationService().listenSpecificOrders(
              context,
              orderIds,
              (orderId, step) {
                if (!mounted) return;

                // โหลด Order ใหม่และรีเฟรช UI
                LoadAllOrder(context).then((_) {
                  setState(() {});
                });
              },
            );
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("คำสั่งซื้อที่สั่งเข้ามา"),
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
                                  if ((order.ordStatus ?? -1) == 0)
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 100,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              updateOrderStatus(
                                                  order.ordId.toString(),
                                                  1); // กำลังเตรียมอาหาร → 1
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 10),
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
                                        SizedBox(height: 6),
                                        SizedBox(
                                          width: 100,
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              await updateOrderStatus(
                                                  order.ordId.toString(),
                                                  -2); // ปฏิเสธ → -2
                                              await RefundCus(
                                                  order.ordId, order.cusId);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                            ),
                                            child: Text(
                                              "ปฏิเสธ",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else if ((order.ordStatus ?? -1) == 1 &&
                                      order.ridId != 0)
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(height: 30),
                                        SizedBox(
                                          width: 100,
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              await updateOrderStatus(
                                                  order.ordId.toString(),
                                                  2); // กำลังส่ง → 2
                                              await cal_ResShareRate(
                                                  order.ordId,
                                                  order.totalOrderPrice
                                                      .toDouble());
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.deepPurple,
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 15),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                            ),
                                            child: Text(
                                              "จัดส่ง",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else if ((order.ordStatus ?? -1) == 1 &&
                                      order.ridId == 0)
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(height: 30),
                                        Text(
                                          "รอไรเดอร์กดรับออเดอร์...",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.orange,
                                            fontWeight: FontWeight.w500,
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
      final change_status = await http
          .put(Uri.parse("$url/db/ChangeOrderStatus/$docId/$newStatus"));

      if (change_status.statusCode == 200) {
        // รีโหลดรายการคำสั่งซื้อ
        LoadAllOrder(context);
        setState(() {});
      } else {
        print('MySQL update failed: ${change_status.body}');
        Fluttertoast.showToast(msg: 'อัปเดตสถานะใน MySQL ล้มเหลว');
      }
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

  Future<void> LoadAllOrder(BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    try {
      int res_id = context.read<ShareData>().user_info_send.uid;
      final res_ResInfo =
          await http.get(Uri.parse("$url/db/loadResOrder/$res_id"));
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

  void loadCus(int cus_id) async {
    if (_customerMap.containsKey(cus_id)) {
      log("ลูกค้าโหลดแล้ว: ${_customerMap[cus_id]?.cus_name}");
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
          log("เพิ่มลูกค้าใหม่: cus_id=$cus_id, name=${list.first.cus_name}");
          log("สถานะปัจจุบันของ _customerMap: $_customerMap");
        });
      }
    }
  }

  Future<void> RefundCus(int ord_id, int cus_id) async {
    log("$ord_id ORDER_ID");
    log("$cus_id CUS_ID");

    try {
      // 1️⃣ ดึงค่า Refund_D-wallet จาก Firebase
      final docRef = FirebaseFirestore.instance
          .collection('BP_Order_detail')
          .doc('order$ord_id');

      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        throw Exception("Order $ord_id not found");
      }

      final data = docSnapshot.data();

      // ✅ ป้องกัน error double -> int
      num totalRefundNum = data?['Refund_D-wallet'] ?? 0;
      int totalRefund = totalRefundNum.round();

      if (totalRefund <= 0) {
        log("No refund to process for order $ord_id");
        return;
      }

      // 2️⃣ ส่งไปอัปเดต balance ของลูกค้า ผ่าน API
      final res_Add = await http.put(
        Uri.parse("$url/db/updateRefundCus_balance"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "total": totalRefund,
          "cus_id": cus_id,
        }),
      );

      if (res_Add.statusCode == 200) {
        log("Refund success: $totalRefund to customer $cus_id");

        // ✅ 3️⃣ ลบฟิลด์ Refund_D-wallet ออกจาก Firebase
        await docRef.update({
          'Refund_D-wallet': FieldValue.delete(),
        });
      } else {
        throw Exception("Server error: ${res_Add.statusCode}");
      }
    } catch (e) {
      log("RefundCus Error: $e");
      throw e;
    }
  }

  Future<void> cal_ResShareRate(int order_id, double totalPrice) async {
    double share_rate = 0;
    double res_income = 0;
    int res_id = context.read<ShareData>().user_info_send.uid;

    try {
      final res_share = await http.get(Uri.parse("$url/db/loadResShare"));
      print('Status code: ${res_share.statusCode}');
      print('Response body: ${res_share.body}');

      if (res_share.statusCode == 200) {
        final data = jsonDecode(res_share.body);
        share_rate = (data['share_rate'] ?? 0).toDouble();
      } else {
        Fluttertoast.showToast(msg: "โหลดยอดเงินไม่สำเร็จ");
      }

      res_income = totalPrice * (share_rate / 100);

      final update_res_income = await http.put(
        Uri.parse("$url/db/updateResIncome"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "ord_id": order_id,
          "res_id": res_id,
          "res_income": res_income,
        }),
      );

      if (update_res_income.statusCode == 200) {
        log("CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC");
      } else {
        throw Exception("Server error: ${update_res_income.statusCode}");
      }
    } catch (e) {
      log("update_cus_balance Error: $e");
      throw e;
    }
  }
}
