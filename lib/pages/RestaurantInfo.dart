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
    final NearbyRes = context.watch<ShareData>().restaurant_near;
    final Categoryfontsize =
        const TextStyle(fontSize: 10, fontWeight: FontWeight.bold);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 50),
            child: Column(
              children: [
                // children: NearbyRes.map((Near) {
                //   Image.network(,
                //               width: 35,
                //               height: 35,
                //               errorBuilder: (_, __, ___) =>
                //                   const Icon(Icons.fastfood, size: 30),
                //               loadingBuilder: (_, child, loading) {
                //                 if (loading == null) return child;
                //                 return const SizedBox(
                //                     width: 30,
                //                     height: 30,
                //                     child: CircularProgressIndicator(
                //                         strokeWidth: 2));
                //          }),
                SizedBox(height: 8),
                Text(
                  "หมวดหมู่อาหาร",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // ✅ ปุ่มหมวดหมู่แสดงเป็นแนวนอน
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: Caterogy.map((type) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        Get.to(() => SearchByCatPage(typeId: type.type_id));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                              color: Colors.deepPurple, width: 2),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.network(type.type_image,
                              width: 35,
                              height: 35,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.fastfood, size: 30),
                              loadingBuilder: (_, child, loading) {
                                if (loading == null) return child;
                                return const SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2));
                              }),
                          const SizedBox(height: 10),
                          Text(type.type_name, style: Categoryfontsize)
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
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
