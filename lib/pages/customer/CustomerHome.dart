import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/CusAddressGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResTypeGetRes.dart';
import 'package:mobile_miniproject_app/pages/Add_Item.dart';
import 'package:mobile_miniproject_app/pages/customer/CusAllOrder.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerProfile.dart';
import 'package:mobile_miniproject_app/pages/restaurant/RestaurantInfo.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _HomePageState();
}

class _HomePageState extends State<CustomerHomePage> {
  int _selectedIndex = 0;
  late PageController _pageController;
  String url = '';
  bool isLoading = true;
  bool isSearching = false;
  String searchQuery = "";
  TextEditingController searchController = TextEditingController();

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
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topAdd = context.watch<ShareData>().customer_addresses;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: _selectedIndex == 0 ? buildHomeAppBar(topAdd) : null,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          // Home Page
          buildHomePage(),
          // Order Page
          CusallorderPage(),
          // Profile Page
          ProfilePage(onClose: () {}, selectedIndex: 2),
        ],
      ),
      bottomNavigationBar: buildBottomNavigationBar(),
    );
  }

  AppBar buildHomeAppBar(dynamic topAdd) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topAdd.isNotEmpty ? topAdd[0].ca_detail : 'ไม่มีที่อยู่',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                    color: Colors.black),
              ),
              const SizedBox(height: 4),
              Text(
                topAdd.isNotEmpty ? topAdd[0].ca_address : '',
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              if (isSearching)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      searchQuery = "";
                      isSearching = false;
                      searchController.clear();
                    });
                  },
                ),
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'ค้นหาร้านอาหาร...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                      isSearching = value.isNotEmpty;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
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
              icon: Icon(Icons.receipt_long), label: 'Order'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget buildHomePage() {
    return isSearching ? buildSearchResultView() : buildMainContent();
  }

  Widget buildSearchResultView() {
    final allRestaurants = context.watch<ShareData>().restaurant_all;
    final topAdd = context.watch<ShareData>().customer_addresses;

    double customerLat = 0.0;
    double customerLng = 0.0;

    if (topAdd.isNotEmpty) {
      final coordsCus = topAdd[0].ca_coordinate.split(',');
      customerLat = double.tryParse(coordsCus[0].trim()) ?? 0.0;
      customerLng = double.tryParse(coordsCus[1].trim()) ?? 0.0;
    }

    final filtered = allRestaurants
        .where(
            (r) => r.res_name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          "ไม่พบร้านที่มีชื่อหรือชื่อเมนูที่ตรงกัน",
          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      );
    }

    double calculateDistance(
        double lat1, double lon1, double lat2, double lon2) {
      const earthRadius = 6371.0;
      final dLat = (lat2 - lat1) * (math.pi / 180);
      final dLon = (lon2 - lon1) * (math.pi / 180);
      final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(lat1 * (math.pi / 180)) *
              math.cos(lat2 * (math.pi / 180)) *
              math.sin(dLon / 2) *
              math.sin(dLon / 2);
      final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
      return earthRadius * c;
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final res = filtered[index];

        final coordsRes = res.res_coordinate.split(',');
        final double resLat = double.tryParse(coordsRes[0].trim()) ?? 0.0;
        final double resLng = double.tryParse(coordsRes[1].trim()) ?? 0.0;

        double distanceKm =
            calculateDistance(customerLat, customerLng, resLat, resLng);

        return ListTile(
          leading: Image.network(res.res_image, width: 50, height: 50),
          title: Text(res.res_name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text("rating: ${res.res_rating.toStringAsFixed(1)}"),
                ],
              ),
              const SizedBox(height: 4),
              Text("ระยะทาง: ${distanceKm.toStringAsFixed(2)} กม."),
            ],
          ),
          onTap: () {
            Get.to(() => RestaurantinfoPage(ResId: res.res_id));
          },
        );
      },
    );
  }

  Widget buildMainContent() {
    final Caterogy = context.watch<ShareData>().restaurant_type;
    final AllRes = context.watch<ShareData>().restaurant_all;
    final NearByRes = context.watch<ShareData>().restaurant_near;
    final Categoryfontsize =
        const TextStyle(fontSize: 10, fontWeight: FontWeight.bold);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // ปุ่มก๋วยเตี๋ยว
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          searchQuery = "ก๋วยเตี๋ยว";
                          searchController.text = "ก๋วยเตี๋ยว";
                          isSearching = true;
                        });
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
                          Image.network(
                            'https://img.icons8.com/?size=100&id=mZg2mwGEJKMd&format=png&color=000000',
                            width: 35,
                            height: 35,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.fastfood, size: 30),
                            loadingBuilder: (_, child, loading) {
                              if (loading == null) return child;
                              return const SizedBox(
                                width: 30,
                                height: 30,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text("ก๋วยเตี๋ยว", style: Categoryfontsize),
                        ],
                      ),
                    ),
                  ),

                  // ปุ่มข้าว
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          searchQuery = "ข้าว";
                          searchController.text = "ข้าว";
                          isSearching = true;
                        });
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
                          Image.network(
                            'https://img.icons8.com/?size=100&id=97436&format=png&color=000000',
                            width: 35,
                            height: 35,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.fastfood, size: 30),
                            loadingBuilder: (_, child, loading) {
                              if (loading == null) return child;
                              return const SizedBox(
                                width: 30,
                                height: 30,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text("ข้าว", style: Categoryfontsize),
                        ],
                      ),
                    ),
                  ),

                  // ปุ่มของหวาน
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          searchQuery = "ของหวาน";
                          searchController.text = "ของหวาน";
                          isSearching = true;
                        });
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
                          Image.network(
                            'https://img.icons8.com/?size=100&id=36142&format=png&color=000000',
                            width: 35,
                            height: 35,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.fastfood, size: 30),
                            loadingBuilder: (_, child, loading) {
                              if (loading == null) return child;
                              return const SizedBox(
                                width: 30,
                                height: 30,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text("ของหวาน", style: Categoryfontsize),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          searchQuery = "ไก่ทอด";
                          searchController.text = "ไก่ทอด";
                          isSearching = true;
                        });
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
                          Image.network(
                            'https://img.icons8.com/?size=100&id=82478&format=png&color=000000',
                            width: 35,
                            height: 35,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.fastfood, size: 30),
                            loadingBuilder: (_, child, loading) {
                              if (loading == null) return child;
                              return const SizedBox(
                                width: 30,
                                height: 30,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text("ไก่ทอด", style: Categoryfontsize),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ร้านใกล้เคียง
          if (NearByRes.isNotEmpty) ...[
            sectionTitle("ร้านใกล้เคียง"),
            horizontalRestaurantScroll(NearByRes),
          ],

          /// ร้านแนะนำ
          sectionTitle("ร้านแนะนำ"),
          horizontalRestaurantScroll(AllRes),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(left: 20, top: 20),
        child: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget horizontalRestaurantScroll(List<ResInfoResponse> data,
      {String? menuLabel}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: data.map((near) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Get.to(() => RestaurantinfoPage(ResId: near.res_id));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        near.res_image,
                        width: 155,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.fastfood, size: 40),
                        loadingBuilder: (_, child, loading) {
                          if (loading == null) return child;
                          return const SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(strokeWidth: 2));
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      width: 155,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (menuLabel != null)
                            Text(menuLabel,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis),
                          Text(near.res_name,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                          if (near.distanceFromCustomer != null &&
                              menuLabel == null)
                            Text(
                              "${near.distanceFromCustomer!.toStringAsFixed(2)} กม.",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: const Color.fromARGB(255, 18, 18, 18)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
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
          context.read<ShareData>().customer_addresses = res_addList;
        }
      }

      final res_all = await http.get(Uri.parse("$url/db/loadAllRes"));
      if (res_all.statusCode == 200) {
        final List<ResInfoResponse> list = (json.decode(res_all.body) as List)
            .map((e) => ResInfoResponse.fromJson(e))
            .toList();
        for (final res in list) {
          log("ร้าน: ${res.res_name}, พิกัด: ${res.res_coordinate}");
        }
        context.read<ShareData>().restaurant_all = list;
      }

      if (context.read<ShareData>().customer_addresses.isNotEmpty) {
        final customerLocationStr =
            context.read<ShareData>().customer_addresses[0].ca_coordinate;
        log("Customer location: $customerLocationStr");
        final List<String> cusSplit = customerLocationStr.split(',');
        final double cusLat = double.parse(cusSplit[0].trim());
        final double cusLng = double.parse(cusSplit[1].trim());

        final allRestaurants = context.read<ShareData>().restaurant_all;
        final List<ResInfoResponse> nearRestaurants = [];
        final Map<ResInfoResponse, double> distanceMap = {};

        for (final res in allRestaurants) {
          final resLocationStr = res.res_coordinate;
          log("ร้านทั้งหมด:\n" +
              allRestaurants
                  .map((res) => "${res.res_name} (${res.res_coordinate})")
                  .join('\n'));

          try {
            final List<String> resSplit = resLocationStr.split(',');
            final double resLat = double.parse(resSplit[0].trim());
            final double resLng = double.parse(resSplit[1].trim());

            final double distance =
                calculateDistance(cusLat, cusLng, resLat, resLng);
            if (distance <= 5.0) {
              res.distanceFromCustomer = distance;
              nearRestaurants.add(res);
              distanceMap[res] = distance;
            }
          } catch (e) {
            log("แปลงพิกัดร้าน ${res.res_name} ผิดพลาด: $e");
          }
        }

        context.read<ShareData>().restaurant_near = nearRestaurants;
      }

      setState(() => isLoading = false);
    } catch (e) {
      log("LoadCusHome Error: $e");
      Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาด โปรดลองใหม่",
          backgroundColor: Colors.red,
          textColor: Colors.white);
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180);
}
