import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/CusAddressGetRes.dart';
import 'package:mobile_miniproject_app/models/response/MenuInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResCatGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResTypeGetRes.dart';
import 'package:mobile_miniproject_app/pages/Add_Item.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerProfile.dart';
import 'package:mobile_miniproject_app/pages/customer/TopUp.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class CartPage extends StatefulWidget {
  final List<MenuInfoGetResponse> selectedMenus;
  final Map<int, int> counts;

  const CartPage({
    super.key,
    required this.selectedMenus,
    required this.counts,
  });

  @override
  State<CartPage> createState() => _HomePageState();
}

class _HomePageState extends State<CartPage> {
  int _selectedIndex = 1;
  late PageController _pageController;
  String url = '';
  bool isFavorite = false;
  bool isLoading = true;
  String? _address; // เก็บที่อยู่ที่ได้
  List<ResCatGetResponse> _restaurantCategories = [];
  List<MenuInfoGetResponse> _restaurantMenu = [];
  Map<int, int> _selectedMenuCounts = {};
  String? _selectedCustomerAddress;
  List<MenuInfoGetResponse> get selectedMenus {
    return _restaurantMenu
        .where((menu) => _selectedMenuCounts.containsKey(menu.menu_id))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    Configuration.getConfig().then((value) {
      url = value['apiEndpoint'];
      LoadCusAdd();
      _getAddressFromCoordinates();
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // _getAddressFromCoordinates();
      });
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
    final restaurantAddress = _address.toString();
    final customerAddress = customerAdd.isNotEmpty
        ? customerAdd[0].ca_address + "  " + customerAdd[0].ca_detail
        : "กำลังโหลดที่อยู่...";

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
                    Text(restaurantAddress), // ใช้ค่าจากตัวแปร
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
            ...widget.selectedMenus.map((menu) {
              final count = widget.counts[menu.menu_id] ?? 1;
              final totalPrice = menu.menu_price * count;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text("${menu.menu_name} x$count")),
                    Text("${totalPrice.toStringAsFixed(0)} บาท"),
                  ],
                ),
              );
            }),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "รวมทั้งหมด",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "${calculateTotal().toStringAsFixed(0)} บาท",
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
                        "${context.read<ShareData>().user_info_send.balance} บาท",
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
          if (calculateTotal() >
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
          }
          Fluttertoast.showToast(msg: "ทำการสั่งซื้อเรียบร้อยแล้ว");
        },
        child: const Text(
          "สั่งซื้อ",
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  double calculateTotal() {
    double total = 0;
    for (var menu in widget.selectedMenus) {
      final count = widget.counts[menu.menu_id] ?? 1;
      total += menu.menu_price * count;
    }
    return total;
  }

// เพิ่ม
  String _selectedPayment = "COD";

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
        isLoading = false; // ✅ หลังโหลดเสร็จ
      });
    }
  }
}
