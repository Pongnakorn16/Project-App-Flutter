import 'dart:async';
import 'dart:convert';
import 'dart:developer' show log; // เอาเฉพาะ log
import 'dart:math' hide log;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/CusAddressGetRes.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerProfile.dart';
import 'package:mobile_miniproject_app/pages/customer/Order.dart';
import 'package:mobile_miniproject_app/pages/customer/TopUp.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> mergedMenus;

  const CartPage({Key? key, required this.mergedMenus}) : super(key: key);

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
                                );
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
        onPressed: () {
          if (finalPrice > context.read<ShareData>().user_info_send.balance) {
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
                          MaterialPageRoute(builder: (context) => TopupPage()),
                        );
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
          showConfirmOrderDialog(context, () {
            finalPrice = finalPrice + deliveryFee;
            update_cus_balance(finalPrice);
            Fluttertoast.showToast(msg: "ทำการสั่งซื้อเรียบร้อยแล้ว");
            Get.to(() => OrderPage(
                mergedMenus: widget.mergedMenus, deliveryFee: deliveryFee));
          });
        },
        child: const Text(
          "สั่งซื้อ",
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  void showConfirmOrderDialog(BuildContext context, VoidCallback onConfirmed) {
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
    final matchedRestaurant = AllRes.firstWhere(
        (res) => res.res_id == context.read<ShareData>().res_id);

    final resCoords = matchedRestaurant.res_coordinate.split(',');
    final double resLat = double.parse(resCoords[0]);
    final double resLng = double.parse(resCoords[1]);

    final customerAdd = context.read<ShareData>().customer_addresses;
    if (customerAdd.isNotEmpty) {
      final customerCoords =
          customerAdd[context.read<ShareData>().selected_address_index ?? 0]
              .ca_coordinate
              .split(',');
      final double cusLat = double.parse(customerCoords[0]);
      final double cusLng = double.parse(customerCoords[1]);

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
          calculateDeliveryFee();
        }
      }
      final res_balance =
          await http.get(Uri.parse("$url/db/loadCusbalance/$userId"));
      print('Status code: ${res_balance.statusCode}');
      print('Response body: ${res_balance.body}');

      if (res_balance.statusCode == 200) {
        final data = jsonDecode(res_balance.body);
        final int balance = data['balance'] ?? 0;
        context.read<ShareData>().user_info_send.balance = balance;
      } else {
        Fluttertoast.showToast(msg: "โหลดยอดเงินไม่สำเร็จ");
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

  void update_cus_balance(double d_total) async {
    int cus_id = context.read<ShareData>().user_info_send.uid;
    int total = finalPrice.toInt();

    setState(() {
      isLoading = true;
    });

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
        // ทำอย่างอื่นถ้าต้องการ
      } else {
        // handle error กรณี response ไม่ใช่ 200
        Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาดจาก server",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      log("LoadCusHome Error: $e");
      Fluttertoast.showToast(
        msg: "เกิดข้อผิดพลาด โปรดลองใหม่",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
