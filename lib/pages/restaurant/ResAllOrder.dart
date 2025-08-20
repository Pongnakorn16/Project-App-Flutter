import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/CusInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/OptionGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
import 'package:mobile_miniproject_app/pages/customer/Order.dart';
import 'package:mobile_miniproject_app/pages/restaurant/ResOrder.dart';
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
  List<Map<String, dynamic>> ordersList = []; // เก็บ order
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
                      var cusInfo = _customerMap[order['cus_id']];

                      // เรียกโหลดร้านถ้ายังไม่มีใน map
                      if (cusInfo == null) {
                        loadCus(order['cus_id']);
                      }

                      // แปลงวันเวลา
                      var timestamp = order['Order_date'];
                      DateTime orderDate = timestamp != null
                          ? (timestamp as Timestamp).toDate()
                          : DateTime.now();
                      String formattedDate =
                          DateFormat('dd/MM/yyyy HH:mm').format(orderDate);

                      return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResOrderPage(
                                  mergedMenus: order['menus'],
                                  deliveryFee: order['deliveryFee'],
                                  order_id: order['order_id'],
                                  order_status: order['Order_status'],
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
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 4),
                                        buildStatusBox(
                                            order['Order_status'] ?? -1),
                                        SizedBox(height: 4),
                                        Text("วันที่: $formattedDate"),
                                      ],
                                    ),
                                  ),

                                  // ปุ่มทางขวา
                                  if ((order['Order_status'] ?? -1) == 0)
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 100,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              updateOrderStatus(
                                                  order['order_id'].toString(),
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
                                            onPressed: () {
                                              updateOrderStatus(
                                                  order['order_id'].toString(),
                                                  -2); // ปฏิเสธ → -2
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
                                  else if ((order['Order_status'] ?? -1) == 1)
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(height: 30),
                                        SizedBox(
                                          width: 100,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              updateOrderStatus(
                                                  order['order_id'].toString(),
                                                  2); // กำลังส่ง → 2
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
      int res_id = context.read<ShareData>().user_info_send.uid;
      CollectionReference ordersCollection =
          FirebaseFirestore.instance.collection('BP_Order_detail');

      QuerySnapshot snapshot =
          await ordersCollection.where('res_id', isEqualTo: res_id).get();

      ordersList.clear();

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // เพิ่ม order id ลงไปใน map
        ordersList.add(data);
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
