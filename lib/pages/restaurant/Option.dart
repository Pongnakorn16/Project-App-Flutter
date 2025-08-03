import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/CusAddressGetRes.dart';
import 'package:mobile_miniproject_app/models/response/MenuInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/OptionGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResCatGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResTypeGetRes.dart';
import 'package:mobile_miniproject_app/pages/Add_Item.dart';
import 'package:mobile_miniproject_app/pages/customer/Cart.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerProfile.dart';
import 'package:mobile_miniproject_app/pages/restaurant/Option.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class OptionPage extends StatefulWidget {
  final int menu_id;
  const OptionPage({super.key, required this.menu_id});

  @override
  State<OptionPage> createState() => _HomePageState();
}

class _HomePageState extends State<OptionPage> {
  int _selectedIndex = 0;
  late PageController _pageController;
  String url = '';
  bool isFavorite = false;
  String? _address; // เก็บที่อยู่ที่ได้
  List<ResCatGetResponse> _restaurantCategories = [];
  List<MenuInfoGetResponse> _restaurantMenu = [];
  List<OptionGetResponse> _restaurantOption = [];
  Map<int, int> _selectedMenuCounts = {};
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
      LoadResInfo();
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {});
    });
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topAdd = context.watch<ShareData>().customer_addresses;

    return Scaffold(
      appBar: AppBar(
        title: const Text("รายละเอียดตัวเลือกเพิ่มเติม"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // กดแล้วกลับไปหน้าก่อนหน้า
          },
        ),
      ),
      body: buildMainContent(),
      bottomSheet: _selectedMenuCounts.isNotEmpty
          ? Container(
              height: 60,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "ไปที่ตะกร้า (${_selectedMenuCounts.length} รายการ)",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      // ส่งรายการไปหน้าตะกร้า
                      Get.to(() => CartPage(
                            selectedMenus: selectedMenus,
                            counts: _selectedMenuCounts,
                          ));
                    },
                    child: const Text(
                      "ดูตะกร้า",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget buildMainContent() {
    final Caterogy = context.watch<ShareData>().restaurant_type;
    final AllRes = context.watch<ShareData>().restaurant_all;
    final topAdd = context.watch<ShareData>().customer_addresses;

    // // ถ้าไม่มีพิกัดลูกค้า
    // if (topAdd.isEmpty) {
    //   return const Center(
    //     child: CircularProgressIndicator(strokeWidth: 2),
    //   );
    // }

    // final customer = topAdd[0];

    // // แยกพิกัดร้าน
    // final coordsRes = matchedRestaurant.res_coordinate.split(',');
    // final double resLat = double.parse(coordsRes[0]);
    // final double resLng = double.parse(coordsRes[1]);

    // // แยกพิกัดลูกค้า
    // final coordsCus = customer.ca_coordinate.split(',');
    // final double cusLat = double.parse(coordsCus[0]);
    // final double cusLng = double.parse(coordsCus[1]);

    // // คำนวณระยะทาง
    // double distanceInMeters =
    //     Geolocator.distanceBetween(cusLat, cusLng, resLat, resLng);
    // double distanceInKm = distanceInMeters / 1000;

    // // คำนวณเวลาโดยเงื่อนไขที่ให้มา
    // String deliveryTime;
    // if (distanceInKm <= 1) {
    //   deliveryTime = "10 นาที";
    // } else if (distanceInKm <= 2) {
    //   deliveryTime = "15 นาที";
    // } else if (distanceInKm <= 3) {
    //   deliveryTime = "20 นาที";
    // } else if (distanceInKm <= 4) {
    //   deliveryTime = "25 นาที";
    // } else if (distanceInKm <= 5) {
    //   deliveryTime = "30 นาที";
    // } else {
    //   deliveryTime = "35 นาทีขึ้นไป";
    // }

    List<Widget> categoryCards = _restaurantCategories
        .map((category) {
          final menusInCategory = _restaurantMenu
              .where((menu) => menu.cat_id == category.cat_id)
              .toList();

          if (menusInCategory.isEmpty) {
            return SizedBox.shrink(); // ไม่แสดงหมวดเปล่า
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 20),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // หัวข้อหมวดหมู่
                  Text(
                    category.cat_name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // แสดงเมนูในหมวดนี้
                  Column(
                    children: menusInCategory.map((menu) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // รูปภาพเมนู
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                menu.menu_image,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.fastfood),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // ข้อมูลเมนู
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    menu.menu_name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    menu.menu_des,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "฿ ${menu.menu_price}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            ),
          );
        })
        .where((widget) => widget is! SizedBox)
        .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ระยะทาง:  กม.",
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 5),
          Text(
            "เวลาจัดส่งโดยประมาณ: ",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...categoryCards,
        ],
      ),
    );
  }

  void LoadResInfo() async {
    try {
      int userId = context.read<ShareData>().user_info_send.uid;

      context.read<ShareData>().customer_addresses = [];
      final res_Add = await http.get(Uri.parse("$url/db/loadCusAdd/$userId"));
      if (res_Add.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(res_Add.body);
        final List<CusAddressGetResponse> res_addList =
            jsonResponse.map((e) => CusAddressGetResponse.fromJson(e)).toList();
        if (res_addList.isNotEmpty) {
          context.read<ShareData>().customer_addresses = [res_addList[0]];
        }
      }

      final res_Cat = await http.get(Uri.parse("$url/db/loadCat/${1}"));

      if (res_Cat.statusCode == 200) {
        final List<ResCatGetResponse> list = (json.decode(res_Cat.body) as List)
            .map((e) => ResCatGetResponse.fromJson(e))
            .toList();
        setState(() {
          _restaurantCategories = list;
        });
      }

      var menu_id = widget.menu_id;
      final res_Option =
          await http.get(Uri.parse("$url/db/loadOption/$menu_id"));
      log("Raw JSON from API: ${res_Option.body}");
      if (res_Option.statusCode == 200) {
        final List<OptionGetResponse> list =
            (json.decode(res_Option.body) as List)
                .map((e) => OptionGetResponse.fromJson(e))
                .toList();
        setState(() {
          _restaurantOption = list;
          log("MENUUUUUUUUUUUUUUUUUUUUUUUU" + _restaurantOption.toString());
        });
      }
    } catch (e) {
      log("LoadCusHome Error: $e");
      Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาด โปรดลองใหม่",
          backgroundColor: Colors.red,
          textColor: Colors.white);
    }
  }
}
