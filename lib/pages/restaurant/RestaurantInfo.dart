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
import 'package:mobile_miniproject_app/pages/customer/Cart.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerProfile.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class RestaurantinfoPage extends StatefulWidget {
  final int ResId;
  const RestaurantinfoPage({super.key, required this.ResId});

  @override
  State<RestaurantinfoPage> createState() => _HomePageState();
}

class _HomePageState extends State<RestaurantinfoPage> {
  int _selectedIndex = 0;
  late PageController _pageController;
  String url = '';
  bool isFavorite = false;
  String? _address; // เก็บที่อยู่ที่ได้
  List<ResCatGetResponse> _restaurantCategories = [];
  List<MenuInfoGetResponse> _restaurantMenu = [];
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getAddressFromCoordinates();
      });
    });
    _pageController = PageController();
  }

  void _getAddressFromCoordinates() async {
    final AllRes = context.read<ShareData>().restaurant_all;
    final matchedRestaurant =
        AllRes.firstWhere((res) => res.res_id == widget.ResId);

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

  String calculateDeliveryTime({
    required double customerLat,
    required double customerLng,
    required double restaurantLat,
    required double restaurantLng,
  }) {
    double distanceInMeters = Geolocator.distanceBetween(
      customerLat,
      customerLng,
      restaurantLat,
      restaurantLng,
    );

    double distanceInKm = distanceInMeters / 1000;

    if (distanceInKm <= 1)
      return "10 นาที";
    else if (distanceInKm <= 2)
      return "15 นาที";
    else if (distanceInKm <= 3)
      return "20 นาที";
    else if (distanceInKm <= 4)
      return "25 นาที";
    else if (distanceInKm <= 5)
      return "30 นาที";
    else
      return "35 นาทีขึ้นไป";
  }

  Widget buildRatingStars(double rating) {
    List<Widget> stars = [];

    int fullStars = rating.floor(); // จำนวนดาวเต็ม
    bool hasHalfStar = (rating - fullStars) >= 0.5;
    int emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    // ดาวเต็ม
    for (int i = 0; i < fullStars; i++) {
      stars.add(const Icon(Icons.star, color: Colors.amber, size: 20));
    }

    // ดาวครึ่ง
    if (hasHalfStar) {
      stars.add(const Icon(Icons.star_half, color: Colors.amber, size: 20));
    }

    // ดาวว่าง
    for (int i = 0; i < emptyStars; i++) {
      stars.add(const Icon(Icons.star_border, color: Colors.amber, size: 20));
    }

    // ตัวเลข rating ตามท้าย
    stars.add(const SizedBox(width: 6));
    stars.add(Text(
      "(${rating.toStringAsFixed(1)})",
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ));

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: stars,
    );
  }

  Widget buildMenuItem(MenuInfoGetResponse menu) {
    int count = _selectedMenuCounts[menu.menu_id] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // รูปภาพเมนู
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  menu.menu_image,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.fastfood),
                ),
              ),
              const SizedBox(width: 12),

              // ข้อมูลเมนู
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(menu.menu_name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    Text("${menu.menu_price} บาท",
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),

              // ปุ่ม + / -
              Row(
                children: [
                  if (count > 0)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        setState(() {
                          if (_selectedMenuCounts[menu.menu_id]! > 1) {
                            _selectedMenuCounts[menu.menu_id] =
                                _selectedMenuCounts[menu.menu_id]! - 1;
                          } else {
                            _selectedMenuCounts.remove(menu.menu_id);
                          }
                        });
                      },
                    ),
                  if (count > 0)
                    Text(
                      '$count',
                      style: const TextStyle(fontSize: 16),
                    ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      setState(() {
                        _selectedMenuCounts[menu.menu_id] =
                            (_selectedMenuCounts[menu.menu_id] ?? 0) + 1;
                      });
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
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
        title: const Text("รายละเอียดร้านอาหาร"),
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

  Widget buildCategoryChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.deepPurple, width: 1.5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextButton(
          onPressed: () {
            // TODO: เขียน logic การเลือกเมนูภายในร้าน เช่น filter list
            print("เลือกหมวด: $label");
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            foregroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildMainContent() {
    final Caterogy = context.watch<ShareData>().restaurant_type;
    final AllRes = context.watch<ShareData>().restaurant_all;
    final topAdd = context.watch<ShareData>().customer_addresses;

    final matchedRestaurant =
        AllRes.firstWhere((res) => res.res_id == widget.ResId);

    // ถ้าไม่มีพิกัดลูกค้า
    if (topAdd.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final customer = topAdd[0];

    // แยกพิกัดร้าน
    final coordsRes = matchedRestaurant.res_coordinate.split(',');
    final double resLat = double.parse(coordsRes[0]);
    final double resLng = double.parse(coordsRes[1]);

    // แยกพิกัดลูกค้า
    final coordsCus = customer.ca_coordinate.split(',');
    final double cusLat = double.parse(coordsCus[0]);
    final double cusLng = double.parse(coordsCus[1]);

    // คำนวณระยะทาง
    double distanceInMeters =
        Geolocator.distanceBetween(cusLat, cusLng, resLat, resLng);
    double distanceInKm = distanceInMeters / 1000;

    // คำนวณเวลาโดยเงื่อนไขที่ให้มา
    String deliveryTime;
    if (distanceInKm <= 1) {
      deliveryTime = "10 นาที";
    } else if (distanceInKm <= 2) {
      deliveryTime = "15 นาที";
    } else if (distanceInKm <= 3) {
      deliveryTime = "20 นาที";
    } else if (distanceInKm <= 4) {
      deliveryTime = "25 นาที";
    } else if (distanceInKm <= 5) {
      deliveryTime = "30 นาที";
    } else {
      deliveryTime = "35 นาทีขึ้นไป";
    }

    List<Widget> categoryCards = _restaurantCategories
        .map((category) {
          final menusInCategory = _restaurantMenu
              .where((menu) => menu.cat_id == category.cat_id)
              .toList();

          if (menusInCategory.isEmpty) {
            // ถ้าไม่มีเมนูในหมวดนี้ ไม่ต้องแสดงอะไรเลย
            return SizedBox.shrink();
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
                  Text(
                    category.cat_name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...menusInCategory
                      .map((menu) => buildMenuItem(menu))
                      .toList(),
                ],
              ),
            ),
          );
        })
        .where((widget) => widget is! SizedBox)
        .toList(); // กรอง SizedBox.shrink() ออก

    // ถ้าไม่มี card ไหนเลย แสดงข้อความ "ไม่มีเมนูในร้าน"
    if (categoryCards.isEmpty) {
      categoryCards.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              "ไม่มีเมนูในร้าน",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 10, left: 30, right: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                matchedRestaurant.res_image,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.fastfood, size: 60),
                loadingBuilder: (_, child, loading) {
                  if (loading == null) return child;
                  return const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    matchedRestaurant.res_name,
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    setState(() {
                      isFavorite = !isFavorite;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 5),

            Container(
              child: Text(
                (_address ?? "กำลังโหลดที่อยู่...").trimLeft(),
                style: const TextStyle(
                    fontSize: 15, height: 1.2, letterSpacing: 0),
                textAlign: TextAlign.left,
              ),
            ),

            const SizedBox(height: 10),

            // แถวแสดงระยะทาง + เวลาจัดส่ง
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "ระยะทาง: ${distanceInKm.toStringAsFixed(2)} กม.",
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 15),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: Colors.grey),
                    const SizedBox(
                        width: 4), // เว้นระยะห่างระหว่างไอคอนกับข้อความ
                    Text(
                      "เวลาจัดส่ง: $deliveryTime",
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            buildRatingStars(matchedRestaurant.res_rating),
            const SizedBox(
              height: 10,
            ),
            Text(
              "หมวดหมู่อาหารภายในร้าน",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _restaurantCategories.map((category) {
                  return buildCategoryChip(category.cat_name);
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),
            ...categoryCards,
          ],
        ),
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

      final res_Cat =
          await http.get(Uri.parse("$url/db/loadCat/${widget.ResId}"));

      if (res_Cat.statusCode == 200) {
        final List<ResCatGetResponse> list = (json.decode(res_Cat.body) as List)
            .map((e) => ResCatGetResponse.fromJson(e))
            .toList();
        setState(() {
          _restaurantCategories = list;
        });
      }

      final res_Menu =
          await http.get(Uri.parse("$url/db/loadMenu/${widget.ResId}"));
      log("Raw JSON from API: ${res_Menu.body}");
      if (res_Menu.statusCode == 200) {
        final List<MenuInfoGetResponse> list =
            (json.decode(res_Menu.body) as List)
                .map((e) => MenuInfoGetResponse.fromJson(e))
                .toList();
        setState(() {
          _restaurantMenu = list;
          log("MENUUUUUUUUUUUUUUUUUUUUUUUU" + _restaurantMenu.toString());
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
