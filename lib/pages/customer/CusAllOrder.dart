import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
import 'package:mobile_miniproject_app/pages/customer/Order.dart';
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
  List<Map<String, dynamic>> ordersList = []; // เก็บ order
  List<ResInfoResponse> _restaurantInfo = [];
  Map<int, ResInfoResponse> _restaurantMap = {};

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
        appBar: AppBar(title: Text("คำสั่งซื้อของฉัน")),
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
                      var resInfo = _restaurantMap[order['res_id']];

                      // เรียกโหลดร้านถ้ายังไม่มีใน map
                      if (resInfo == null) {
                        loadRes(order['res_id']);
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
                              builder: (context) => OrderPage(
                                mergedMenus: order['menus'],
                                deliveryFee: order['deliveryFee'],
                                order_id: order['order_id'],
                                order_status: order['Order_status'],
                              ),
                            ),
                          );
                        },
                        child: Card(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          elevation: 3,
                          child: ListTile(
                            title: Text(resInfo != null
                                ? resInfo.res_name
                                : "กำลังโหลด..."),
                            subtitle: Text(
                              "สถานะ: ${order['Order_status'] ?? '-'}\nวันที่: $formattedDate",
                            ),
                            trailing: Text(
                              "ราคารวม: ${order['totalPrice'] ?? '-'} ฿",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    }));
  }

  void LoadAllOrder(BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    try {
      int cus_id = context.read<ShareData>().user_info_send.uid;
      CollectionReference ordersCollection =
          FirebaseFirestore.instance.collection('BP_Order_detail');

      QuerySnapshot snapshot =
          await ordersCollection.where('cus_id', isEqualTo: cus_id).get();

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

  void loadRes(int res_id) async {
    if (_restaurantMap.containsKey(res_id)) return; // โหลดแล้วไม่โหลดซ้ำ

    final res_ResInfo =
        await http.get(Uri.parse("$url/db/loadResInfo/$res_id"));

    if (res_ResInfo.statusCode == 200) {
      final List<ResInfoResponse> list = (json.decode(res_ResInfo.body) as List)
          .map((e) => ResInfoResponse.fromJson(e))
          .toList();
      if (list.isNotEmpty) {
        setState(() {
          _restaurantMap[res_id] = list.first; // เก็บตาม res_id
        });
      }
    }
  }
}
