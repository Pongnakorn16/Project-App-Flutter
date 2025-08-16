import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_miniproject_app/config/config.dart';
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
                      return GestureDetector(
                        onTap: () {
                          // เมื่อกด Card → ไปหน้า OrderPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderPage(
                                mergedMenus: order['menus'],
                                deliveryFee: order['deliveryFee'],
                                order_id: order['order_id'],
                                order_status: order[
                                    'Order_status'], // ส่ง order id // หรือส่งข้อมูล order ทั้งหมด
                              ),
                            ),
                          );
                        },
                        child: Card(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          elevation: 3,
                          child: ListTile(
                            title: Text("Order ID: ${order['id']}"),
                            subtitle: Text(
                              "สถานะ: ${order['Order_status'] ?? '-'}\nวันที่: ${order['ord_date'] ?? '-'}",
                            ),
                            trailing: Text(
                              "ราคารวม: ${order['total_price'] ?? '-'} ฿",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    },
                  ));
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
}
