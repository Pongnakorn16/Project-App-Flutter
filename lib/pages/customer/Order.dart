import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/CusAddressGetRes.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerHome.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerProfile.dart';
import 'package:mobile_miniproject_app/pages/customer/TopUp.dart';
import 'package:mobile_miniproject_app/shared/firebase_message_service.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';

class OrderPage extends StatefulWidget {
  final List<dynamic> mergedMenus;
  final int deliveryFee;
  final int order_id;
  final int order_status;
  final String? previousPage;

  const OrderPage(
      {Key? key,
      required this.mergedMenus,
      required this.deliveryFee,
      required this.order_id,
      required this.order_status,
      this.previousPage})
      : super(key: key);

  @override
  State<OrderPage> createState() => _OrderPageState();
}

// AnimatedProgressBar
class AnimatedProgressBar extends StatefulWidget {
  final int currentStep; // 0,1,2,3
  final bool loop; // วนเฉพาะสถานะแรก
  const AnimatedProgressBar(
      {Key? key, required this.currentStep, this.loop = false})
      : super(key: key);

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _setAnimation();
    final shareData = context.read<ShareData>();
    _startAnimationIfNeeded();
  }

  void _setAnimation() {
    final endValue =
        (widget.currentStep + 1) / 4; // เปลี่ยนจาก 3 เป็น 4 เพราะมี 4 สถานะ
    _animation = Tween<double>(begin: 0, end: endValue).animate(_controller);
  }

  void _startAnimationIfNeeded() {
    if (widget.loop) {
      _controller.addStatusListener(_loopListener);
      _controller.forward();
    } else {
      _controller.removeStatusListener(_loopListener);
      _controller.forward(from: 0);
    }
  }

  void _loopListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep ||
        oldWidget.loop != widget.loop) {
      _setAnimation();
      _startAnimationIfNeeded();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_loopListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return LinearProgressIndicator(
          value: _animation.value,
          minHeight: 6,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
        );
      },
    );
  }
}

// Main OrderPage State
class _OrderPageState extends State<OrderPage> {
  int _currentStep = 0; // เปลี่ยนจาก -1 เป็น 0
  late Timer _timer;
  String url = '';
  bool isLoading = true;
  String? _address; // เก็บที่อยู่ร้าน
  String? _selectedCustomerAddress;

  @override
  @override
  void initState() {
    super.initState();
    Configuration.getConfig().then((value) {
      url = value['apiEndpoint'];
      LoadCusAdd();
      if (widget.order_status != -1) {
        _currentStep = widget.order_status;
      }
      _getAddressFromCoordinates();

      final myOrderId = "order${widget.order_id}";
      log(myOrderId +
          "aXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXxx");

      final cus_id = context.read<ShareData>().user_info_send.uid;
      OrderNotificationService().listenOrderChanges(context, cus_id,
          (orderId, newStep) {
        if (!mounted) return;
        setState(() {
          _currentStep = newStep; // อัปเดต Progress Bar และสถานะ
        });
      });

      setState(() {});
    });

    // Timer สำหรับ progress bar เฉพาะสถานะแรก
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      if (_currentStep != 0) {
        timer.cancel(); // หยุด timer เมื่อสถานะเปลี่ยน
      }
    });
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
        final place = placemarks.first;
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
    _timer.cancel();
    super.dispose();
  }

  // เพิ่ม method สำหรับจัดการปุ่มกลับ
  void _handleBackButton() {
    if (widget.previousPage == 'CusAllOrderPage') {
      // กลับไปหน้า CusAllOrderPage
      Navigator.pop(context);
    } else if (widget.previousPage == 'Cart') {
      // กลับไปหน้า CustomerHomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CustomerHomePage()),
      );
    } else {
      // default กลับไปหน้าก่อนหน้า
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final customerAdd = context.watch<ShareData>().customer_addresses;

    return Scaffold(
      appBar: AppBar(
        title: const Text("ติดตามสถานะการสั่งซื้อ"),
        automaticallyImplyLeading:
            widget.previousPage != null, // แสดงปุ่มกลับเมื่อมี previousPage
        leading: widget.previousPage != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _handleBackButton(),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildStatusSection(_currentStep),
            const SizedBox(height: 20),
            buildAddressSection(customerAdd),
            const SizedBox(height: 20),
            buildOrderSummary(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildStatusSection(int currentStep) {
    final steps = [
      "รอร้านยืนยัน",
      "กำลังเตรียมอาหาร",
      "กำลังส่ง",
      "ส่งถึงแล้ว"
    ]; // เปลี่ยนจาก "" เป็น "รอร้านยืนยัน"
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0, top: 16, bottom: 12),
          child: Text("สถานะการจัดส่ง",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              top: 25,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: AnimatedProgressBar(
                  currentStep: _currentStep, // ไม่ต้อง +1 แล้วเพราะเริ่มที่ 0
                  loop: _currentStep == 0, // วนเฉพาะสถานะแรก (0)
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatusIcon(Icons.access_time, steps[0],
                    currentStep >= 0), // เปลี่ยน icon และเปลี่ยนเงื่อนไข
                _buildStatusIcon(
                    Icons.store, steps[1], currentStep >= 1), // เปลี่ยนเงื่อนไข
                _buildStatusIcon(Icons.delivery_dining, steps[2],
                    currentStep >= 2), // เปลี่ยนเงื่อนไข
                _buildStatusIcon(
                    Icons.home, steps[3], currentStep >= 3), // เปลี่ยนเงื่อนไข
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusIcon(IconData icon, String label, bool active) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor:
              active ? Color.fromARGB(255, 157, 9, 255) : Colors.grey[300],
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 80,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: active ? Color.fromARGB(255, 248, 191, 2) : Colors.grey,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        )
      ],
    );
  }

  Widget buildAddressSection(List<CusAddressGetResponse> customerAdd) {
    final restaurantAddress = _address ?? "กำลังโหลดที่อยู่ร้าน...";
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
                    const Text("ตำแหน่งร้าน",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
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
                      const Text("ตำแหน่งลูกค้า",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(customerAdd.isNotEmpty
                          ? "${customerAdd[context.read<ShareData>().selected_address_index].ca_address} ${customerAdd[context.read<ShareData>().selected_address_index].ca_detail}"
                          : "กำลังโหลดที่อยู่ลูกค้า..."),
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
    double finalPrice = 0;

    List<Widget> menuWidgets = widget.mergedMenus.map((menu) {
      final count = menu["count"] ?? 1;
      final menuPrice = (menu["menu_price"] ?? 0).toDouble();
      final options = menu["selectedOptions"] ?? [];
      double optionsTotalPrice = 0;
      for (var opt in options) {
        optionsTotalPrice += (opt["op_price"] ?? 0).toDouble();
      }
      final totalPrice = (menuPrice + optionsTotalPrice) * count;
      finalPrice += totalPrice;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text("${menu["menu_name"]} x$count")),
              Text("${totalPrice.toStringAsFixed(0)} บาท"),
            ]),
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
            const Text("สรุปรายการอาหาร",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...menuWidgets,
            const Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("ค่าส่ง",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text("${widget.deliveryFee.toStringAsFixed(0)} บาท",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("รวมทั้งหมด",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  "${(finalPrice + widget.deliveryFee).toStringAsFixed(0)} บาท",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ])
          ],
        ),
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
        isLoading = false;
      });
    }
  }
}
