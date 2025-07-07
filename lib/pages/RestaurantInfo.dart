import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/CusAddressGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResTypeGetRes.dart';
import 'package:mobile_miniproject_app/pages/Add_Item.dart';
import 'package:mobile_miniproject_app/pages/Profile.dart';
import 'package:mobile_miniproject_app/pages/SearchByCat.dart';
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

  @override
  void initState() {
    super.initState();
    Configuration.getConfig().then((value) {
      url = value['apiEndpoint'];
      LoadCusHome();
      setState(() {});
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
      stars.add(const Icon(Icons.star, color: Colors.orange, size: 20));
    }

    // ดาวครึ่ง
    if (hasHalfStar) {
      stars.add(const Icon(Icons.star_half, color: Colors.orange, size: 20));
    }

    // ดาวว่าง
    for (int i = 0; i < emptyStars; i++) {
      stars.add(const Icon(Icons.star_border, color: Colors.orange, size: 20));
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
      bottomNavigationBar: buildBottomNavigationBar(),
      floatingActionButton: SizedBox(
        height: 80,
        width: 80,
        child: FloatingActionButton(
          onPressed: () => Get.to(() => AddItemPage()),
          backgroundColor: Colors.yellow,
          child: const Icon(Icons.add, size: 50, color: Colors.white),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
              icon: Icon(Icons.favorite), label: 'Favorite'),
          BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Notis'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
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

            // รายละเอียดร้าน (ที่อยู่) พร้อม background สีเขียวและ padding เดียวกับ column
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
            buildRatingStars(matchedRestaurant.res_rating)
          ],
        ),
      ),
    );
  }

  void LoadCusHome() async {
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

      final res_Cat = await http.get(Uri.parse("$url/db/loadCat"));
      if (res_Cat.statusCode == 200) {
        final List<ResTypeGetResponse> list =
            (json.decode(res_Cat.body) as List)
                .map((e) => ResTypeGetResponse.fromJson(e))
                .toList();
        context.read<ShareData>().restaurant_type = list;
      }

      final res_Near = await http.get(Uri.parse("$url/db/loadNearRes/$userId"));
      if (res_Near.statusCode == 200) {
        final List<ResInfoResponse> list = (json.decode(res_Near.body) as List)
            .map((e) => ResInfoResponse.fromJson(e))
            .toList();
        context.read<ShareData>().restaurant_near = list;

        if (mounted) {
          _getAddressFromCoordinates();
        }
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
