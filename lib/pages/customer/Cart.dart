import 'dart:async';
import 'dart:convert';
import 'dart:developer' show log; // เอาเฉพาะ log
import 'dart:math' hide log;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/request/Order_post_req.dart';
import 'package:mobile_miniproject_app/models/response/CusAddressGetRes.dart';
import 'package:mobile_miniproject_app/models/response/OrderGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerProfile.dart';
import 'package:mobile_miniproject_app/pages/customer/Order.dart';
import 'package:mobile_miniproject_app/pages/customer/TopUp.dart';
import 'package:mobile_miniproject_app/shared/firebase_message_service.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> mergedMenus;
  final int orl_id;

  const CartPage({Key? key, required this.mergedMenus, required this.orl_id})
      : super(key: key);

  @override
  State<CartPage> createState() => _HomePageState();
}

class _HomePageState extends State<CartPage> {
  int _selectedIndex = 1;
  late PageController _pageController;
  String url = '';
  double finalPrice = 0.0;
  bool isLoading = true;
  var totalPrice;
  String? _address; // เก็บที่อยู่ที่ได้
  String? _selectedCustomerAddress;
  double deliveryFee = 0.0;
  String Res_coordinate = '';
  String Cus_coordinate = '';
  int order_id = 0;

  @override
  void initState() {
    super.initState();
    log(widget.mergedMenus.toString() +
        "TESTMERGEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE");
    Configuration.getConfig().then((value) {
      url = value['apiEndpoint'];
      _getAddressFromCoordinates();
      LoadCusAdd();
      final cus_id = context.read<ShareData>().user_info_send.uid;
      OrderNotificationService().listenOrderChanges(context, cus_id,
          (orderId, newStep) {
        if (!mounted) return;
      });
      setState(() {});
    });
    _pageController = PageController();
  }

  void _getAddressFromCoordinates() async {
    final AllRes = context.read<ShareData>().restaurant_all;
    final matchedRestaurant = AllRes.firstWhere(
        (res) => res.res_id == context.read<ShareData>().res_id);

    Res_coordinate = matchedRestaurant.res_coordinate;
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
                      Cus_coordinate = addresses[index].ca_coordinate;
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
        title: const Text("ตรวจสอบคำสั่งซื้อ"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
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
            buildPaymentMethod(),
            const SizedBox(height: 20),
            buildPlaceOrderButton(),
          ],
        ),
      ),
    );
  }

  Widget buildAddressSection(List<CusAddressGetResponse> customerAdd) {
    log(_address.toString() + "TEST ResAddresssssss");
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
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () {
                    if (customerAdd.isNotEmpty) {
                      _showAddressDialog(customerAdd);
                    } else {
                      Fluttertoast.showToast(msg: "ไม่พบที่อยู่ของลูกค้า");
                    }
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget buildOrderSummary() {
    finalPrice = 0; // ประกาศตัวแปรเก็บผลรวมใหม่ทุกครั้ง

    List<Widget> menuWidgets = widget.mergedMenus.map((menu) {
      final count = menu["count"] ?? 1;
      final menuPrice = (menu["menu_price"] ?? 0).toDouble();

      final List<dynamic> options = menu["selectedOptions"] ?? [];
      double optionsTotalPrice = 0;
      for (var opt in options) {
        optionsTotalPrice += (opt["op_price"] ?? 0).toDouble();
      }

      final totalPrice = (menuPrice + optionsTotalPrice) * count;

      finalPrice += totalPrice; // บวกราคานี้ลงตัวแปรผลรวม

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text("${menu["menu_name"]} x$count")),
                Text("${totalPrice.toStringAsFixed(0)} บาท"),
              ],
            ),
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
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      );
    }).toList();

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
            ...menuWidgets,
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "ค่าส่ง",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "${deliveryFee.toStringAsFixed(0)} บาท",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "รวมทั้งหมด",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "${(finalPrice + deliveryFee).toStringAsFixed(0)} บาท",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget buildPaymentMethod() {
    final balance = context.read<ShareData>().user_info_send.balance ?? 0;
    final formattedBalance = NumberFormat("#,###").format(balance);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ชำระเงินด้วย D-wallet",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                ListTile(
                  leading: Icon(Icons.account_balance_wallet),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("D-wallet"),
                      Text(
                        "$formattedBalance บาท",
                      ),
                    ],
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("แจ้งเตือน"),
                          content:
                              const Text("คุณต้องการเติม D-wallet หรือไม่"),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => TopupPage()),
                                ).then((_) {
                                  // เมื่อ Pop กลับมา
                                  setState(() {
                                    isLoading = true;
                                    LoadCusAdd();
                                  });
                                });
                              },
                              child: const Text("ใช่"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("ปิด"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget buildPlaceOrderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.deepPurple,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: isLoading
            ? null
            : () async {
                // ป้องกันการกดซ้ำ
                if (finalPrice >
                    context.read<ShareData>().user_info_send.balance) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("จำนวน D-wallet ของคุณไม่เพียงพอ!!!"),
                        content: const Text("คุณต้องการเติม D-wallet หรือไม่"),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => TopupPage()),
                              ).then((_) {
                                setState(() {
                                  isLoading = true;
                                  LoadCusAdd();
                                });
                              });
                            },
                            child: const Text("ใช่"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("ปิด"),
                          ),
                        ],
                      );
                    },
                  );
                  return;
                }

                // แสดง dialog ยืนยันก่อนจะไปหน้า OrderPage
                showConfirmOrderDialog(
                  context,
                  () async {
                    // แสดง loading เฉพาะใน button
                    setState(() {
                      isLoading = true;
                    });

                    final finalest_Price = finalPrice + deliveryFee;

                    try {
                      var model = OrderPostRequest(
                        cus_id: context.read<ShareData>().user_info_send.uid,
                        res_id: context.read<ShareData>().res_id,
                        ord_date: DateTime.now().toString(),
                        ord_dev_price: deliveryFee.toInt(),
                        total_order_price: finalest_Price.toInt(),
                        ord_status: 0,
                      );

                      int current_ord_id = await InsertOrderInfo(model);

                      await update_Ord_id(current_ord_id);

                      await update_cus_balance(finalest_Price);
                      log(widget.mergedMenus.toString() +
                          "saddddddddddddddddddPOASODAPSDPAOPDOPAOPDPAPOSDOAPDO");

                      final counterRef = FirebaseFirestore.instance
                          .collection('BP_Order_detail')
                          .doc('OrderCounter');

                      await FirebaseFirestore.instance
                          .runTransaction((transaction) async {
                        // สร้าง order document โดยตรง
                        final orderRef = FirebaseFirestore.instance
                            .collection('BP_Order_detail')
                            .doc('order$current_ord_id');

                        transaction.set(orderRef, {
                          'order_id': current_ord_id,
                          'Order_status': 0,
                          'Cus_coordinate': Cus_coordinate,
                          'Res_coordinate': Res_coordinate,
                          'Rider_coordinate': "",
                          'Refund_D-wallet': finalest_Price,
                        });
                      });

                      Fluttertoast.showToast(msg: "ทำการสั่งซื้อเรียบร้อยแล้ว");

                      // ไปหน้า OrderPage โดยไม่รอกลับมา
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderPage(
                            mergedMenus: widget.mergedMenus,
                            deliveryFee: deliveryFee.toInt(),
                            order_id: order_id,
                            order_status: -1,
                            previousPage: 'Cart',
                          ),
                        ),
                      );
                    } catch (e) {
                      setState(() {
                        isLoading = false;
                      });
                      Fluttertoast.showToast(msg: "เกิดข้อผิดพลาด: $e");
                    }
                  },
                  widget.mergedMenus,
                );
              },
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                "สั่งซื้อ",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
      ),
    );
  }

  void showConfirmOrderDialog(BuildContext context, VoidCallback onConfirmed,
      List<Map<String, dynamic>> mergMenus) {
    const totalSeconds = 5;
    int secondsLeft = totalSeconds;
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void startTimer() {
              timer = Timer.periodic(const Duration(seconds: 1), (_) {
                if (secondsLeft == 0) {
                  timer?.cancel();
                  Navigator.pop(context); // ปิด dialog
                  onConfirmed(); // ไปหน้า OrderPage
                } else {
                  setState(() {
                    secondsLeft--;
                  });
                }
              });
            }

            if (timer == null) {
              startTimer();
            }

            return AlertDialog(
              title: const Text('ยืนยันการสั่งซื้อ'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ระบบจะดำเนินการในอีก $secondsLeft วินาที'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    width: 50,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: secondsLeft / totalSeconds,
                          strokeWidth: 6,
                          color: Colors.deepPurple,
                          backgroundColor: Colors.grey.shade300,
                        ),
                        Center(child: Text('$secondsLeft')),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.pop(context); // ปิด dialog
                  },
                  child: const Text('ยกเลิก'),
                ),
              ],
            );
          },
        );
      },
    );
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

  double calculateDistanceKm(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // กิโลเมตร
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degree) {
    return degree * pi / 180;
  }

  void calculateDeliveryFee() {
    final AllRes = context.read<ShareData>().restaurant_all;

    if (AllRes.isEmpty) {
      log("❌ restaurant_all ว่างอยู่");
      return;
    }

    ResInfoResponse? matchedRestaurant;
    try {
      matchedRestaurant = AllRes.firstWhere(
        (res) => res.res_id == context.read<ShareData>().res_id,
      );
    } catch (e) {
      matchedRestaurant = null; // ถ้าไม่เจอ
    }

    if (matchedRestaurant == null) {
      log("❌ ไม่เจอร้านที่ res_id ตรงกับ ShareData.res_id");
      return;
    }

    final resCoords = matchedRestaurant.res_coordinate.split(',');
    if (resCoords.length < 2) {
      log("❌ ข้อมูลพิกัดร้านไม่ถูกต้อง: ${matchedRestaurant.res_coordinate}");
      return;
    }
    final double resLat = double.tryParse(resCoords[0]) ?? 0;
    final double resLng = double.tryParse(resCoords[1]) ?? 0;

    final customerAdd = context.read<ShareData>().customer_addresses;
    if (customerAdd.isEmpty) {
      log("❌ ยังไม่มีที่อยู่ลูกค้า");
      return;
    }

    final selectedIndex = context.read<ShareData>().selected_address_index ?? 0;
    if (selectedIndex >= customerAdd.length) {
      log("❌ selected_address_index เกินขอบเขต list");
      return;
    }

    final customerCoords = customerAdd[selectedIndex].ca_coordinate.split(',');
    if (customerCoords.length < 2) {
      log("❌ ข้อมูลพิกัดลูกค้าไม่ถูกต้อง: ${customerAdd[selectedIndex].ca_coordinate}");
      return;
    }
    final double cusLat = double.tryParse(customerCoords[0]) ?? 0;
    final double cusLng = double.tryParse(customerCoords[1]) ?? 0;

    double distance = calculateDistanceKm(resLat, resLng, cusLat, cusLng);

    if (distance <= 5) {
      deliveryFee = 0;
    } else if (distance <= 10) {
      deliveryFee = 15;
    } else {
      deliveryFee = 20;
    }

    setState(() {}); // เพื่อรีเฟรช UI ถ้าต้องแสดงค่าส่ง
  }

  void LoadCusAdd() async {
    int userId = context.read<ShareData>().user_info_send.uid;

    try {
      context.read<ShareData>().customer_addresses = [];
      final cus_Add = await http.get(Uri.parse("$url/db/loadCusAdd/$userId"));
      if (cus_Add.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(cus_Add.body);
        final List<CusAddressGetResponse> cus_addList =
            jsonResponse.map((e) => CusAddressGetResponse.fromJson(e)).toList();
        if (cus_addList.isNotEmpty) {
          context.read<ShareData>().customer_addresses = cus_addList;
          Cus_coordinate = cus_addList.first.ca_coordinate;
          calculateDeliveryFee();
        }
      }

      final cus_balance =
          await http.get(Uri.parse("$url/db/loadCusbalance/$userId"));
      print('Status code: ${cus_balance.statusCode}');
      print('Response body: ${cus_balance.body}');

      if (cus_balance.statusCode == 200) {
        final data = jsonDecode(cus_balance.body);
        final int balance = data['balance'] ?? 0;
        context.read<ShareData>().user_info_send.balance = balance.toDouble();
      } else {
        Fluttertoast.showToast(msg: "โหลดยอดเงินไม่สำเร็จ");
      }
    } catch (e, stack) {
      log("LoadCusHome Error: $e");
      log("STACKTRACE: $stack");
      Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาด โปรดลองใหม่",
          backgroundColor: Colors.red,
          textColor: Colors.white);
    } finally {
      // เซ็ต isLoading = false เฉพาะครั้งแรกที่โหลด
      if (isLoading) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<int> InsertOrderInfo(OrderPostRequest model) async {
    try {
      final res_ordIn = await http.post(
        Uri.parse("$url/db/InsertOrderInfo"),
        headers: {"Content-Type": "application/json"},
        body: OrderPostRequestToJson(model),
      );

      if (res_ordIn.statusCode == 200) {
        final data = json.decode(res_ordIn.body);
        // data['ord_id'] คือค่า ord_id ที่ backend ส่งกลับมา
        return data['ord_id'];
      } else {
        throw Exception("Server error: ${res_ordIn.statusCode}");
      }
    } catch (e) {
      log("Insert: $e");
      throw e; // ส่ง error ต่อไปให้ caller จัดการ
    }
  }

  Future<void> update_Ord_id(int ord_id) async {
    final order_info = await http.put(
      Uri.parse("$url/db/updateOrder/${widget.orl_id}/$ord_id"),
    );

    if (order_info.statusCode == 200) {
      log("HELLO");
    }
  }

  Future<void> update_cus_balance(double d_total) async {
    int cus_id = context.read<ShareData>().user_info_send.uid;
    int total = d_total.toInt(); // ใช้ d_total แทน finalPrice
    context.read<ShareData>().Refund_balance = total;

    try {
      final res_Add = await http.put(
        Uri.parse("$url/db/updateCus_balance"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "total": total,
          "cus_id": cus_id,
        }),
      );

      if (res_Add.statusCode == 200) {
        // อัปเดต balance ใน ShareData
        context.read<ShareData>().user_info_send.balance -= total;
      } else {
        throw Exception("Server error: ${res_Add.statusCode}");
      }
    } catch (e) {
      log("update_cus_balance Error: $e");
      throw e; // ส่ง error ต่อไปให้ caller จัดการ
    }
  }
}
