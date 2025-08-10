import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/CusAddressGetRes.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerProfile.dart';
import 'package:mobile_miniproject_app/pages/customer/TopUp.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';

class OrderPage extends StatefulWidget {
  final List<Map<String, dynamic>> mergedMenus;

  const OrderPage({Key? key, required this.mergedMenus}) : super(key: key);

  @override
  State<OrderPage> createState() => _CartPageState();
}

class _CartPageState extends State<OrderPage> {
  int _selectedIndex = 1;
  late PageController _pageController;
  String url = '';
  bool isLoading = true;
  String? _address; // เก็บที่อยู่ที่ได้
  String? _selectedCustomerAddress;
  var totalPrice;

  @override
  void initState() {
    super.initState();
    Configuration.getConfig().then((value) {
      url = value['apiEndpoint'];
      LoadCusAdd();
      _getAddressFromCoordinates();
      setState(() {});
    });
    _pageController = PageController();
  }

  void _getAddressFromCoordinates() async {
    final AllRes = context.read<ShareData>().restaurant_all;
    final matchedRestaurant = AllRes.firstWhere(
        (res) => res.res_id == context.read<ShareData>().res_id);

    final coords = matchedRestaurant.res_coordinate.split(',');
    final double lat = double.parse(coords[0]);
    final double lng = double.parse(coords[1]);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;

        setState(() {
          _address =
              "${(place.subLocality ?? '').trim()} ${(place.locality ?? '').trim()} ${(place.administrativeArea ?? '').trim()} ${(place.postalCode ?? '').trim()}";
        });
      }
    } catch (e) {
      print("Error in geocoding: $e");
      setState(() {
        _address = "ไม่พบที่อยู่";
      });
    }
  }

  void _showAddressDialog(List<CusAddressGetResponse> addresses) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("เลือกที่อยู่"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final addr = addresses[index];
                final fullAddress = "${addr.ca_address} ${addr.ca_detail}";
                return ListTile(
                  title: Text(fullAddress),
                  onTap: () {
                    setState(() {
                      _selectedCustomerAddress = fullAddress;
                      context.read<ShareData>().selected_address_index = index;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text("ยกเลิก"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 2) return;
    setState(() => _selectedIndex = index);
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ProfilePage(onClose: () {}, selectedIndex: 1)),
      );
    } else {
      _pageController.animateToPage(
        index > 2 ? index - 1 : index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final customerAdd = context.watch<ShareData>().customer_addresses;

    return Scaffold(
      appBar: AppBar(
        title: const Text("ติดตามสถานะการสั่งซื้อ"),
        automaticallyImplyLeading: false, // ปิดปุ่มย้อนกลับอัตโนมัติ
        // หรือถ้าเคยใส่ leading ให้ลบออกด้วยนะ
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildAddressSection(customerAdd),
            const SizedBox(height: 20),
            buildOrderSummary(),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: buildBottomNavigationBar(),
    );
  }

  Widget buildAddressSection(List<CusAddressGetResponse> customerAdd) {
    final restaurantAddress = _address ?? "กำลังโหลดที่อยู่ร้าน...";
    final customerAddress = customerAdd.isNotEmpty
        ? "${customerAdd[0].ca_address}  ${customerAdd[0].ca_detail}"
        : "กำลังโหลดที่อยู่ลูกค้า...";

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_sharp, color: Colors.red),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ตำแหน่งร้าน",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(restaurantAddress),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Divider(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_sharp, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ตำแหน่งลูกค้า",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        customerAdd.length > 1 &&
                                context
                                        .read<ShareData>()
                                        .selected_address_index ==
                                    1
                            ? "${customerAdd[1].ca_address} ${customerAdd[1].ca_detail}"
                            : "${customerAdd[0].ca_address} ${customerAdd[0].ca_detail}",
                      )
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget buildOrderSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "สรุปรายการอาหาร",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // แสดงรายการเมนู
            ...widget.mergedMenus.map((menu) {
              final count = menu["count"] ?? 1;
              final menuPrice =
                  (menu["menu_price"] ?? 0).toDouble(); // ถ้าเมนูมีราคาด้วย

              // คำนวณราคาตัวเลือก
              final List<dynamic> options = menu["selectedOptions"] ?? [];
              double optionsTotalPrice = 0;
              for (var opt in options) {
                optionsTotalPrice += (opt["op_price"] ?? 0).toDouble();
              }

              totalPrice = (menuPrice + optionsTotalPrice) * count;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ชื่อเมนู + จำนวน
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text("${menu["menu_name"]} x$count")),
                        Text("${totalPrice.toStringAsFixed(0)} บาท"),
                      ],
                    ),

                    // แสดง option ถ้ามี
                    if (options.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: options.map<Widget>((opt) {
                            final opPrice = (opt["op_price"] ?? 0).toDouble();
                            return Text(
                              opPrice > 0
                                  ? "- ${opt["op_name"]} (+${opPrice.toStringAsFixed(0)} บาท)"
                                  : "- ${opt["op_name"]}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              );
            }),

            const Divider(),

            // รวมทั้งหมด
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "รวมทั้งหมด",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "${totalPrice.toStringAsFixed(0)} บาท",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  double calculateTotal() {
    double total = 0;
    for (var menu in widget.mergedMenus) {
      final count = menu["count"] ?? 1;
      final menuPrice = (menu["menu_price"] ?? 0).toDouble();

      final List<dynamic> options = menu["selectedOptions"] ?? [];
      double optionsTotalPrice = 0;
      for (var opt in options) {
        optionsTotalPrice += (opt["price"] ?? 0).toDouble();
      }

      total += (menuPrice + optionsTotalPrice) * count;
    }
    return total;
  }

  Widget buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40.0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2)),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color.fromARGB(255, 115, 28, 168),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        iconSize: 20,
        selectedLabelStyle:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_rounded), label: 'Order'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  void LoadCusAdd() async {
    int userId = context.read<ShareData>().user_info_send.uid;
    try {
      context.read<ShareData>().customer_addresses = [];
      final res_Add = await http.get(Uri.parse("$url/db/loadCusAdd/$userId"));
      if (res_Add.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(res_Add.body);
        final List<CusAddressGetResponse> res_addList =
            jsonResponse.map((e) => CusAddressGetResponse.fromJson(e)).toList();
        if (res_addList.isNotEmpty) {
          context.read<ShareData>().customer_addresses = res_addList;
        }
      }
    } catch (e) {
      log("LoadCusHome Error: $e");
      Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาด โปรดลองใหม่",
          backgroundColor: Colors.red,
          textColor: Colors.white);
    } finally {
      setState(() {
        isLoading = false; // หลังโหลดเสร็จ
      });
    }
  }
}
