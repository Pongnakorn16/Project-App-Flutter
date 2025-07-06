import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/request/user_login_post_req.dart';
import 'package:mobile_miniproject_app/models/response/CusAddressGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResTypeGetRes.dart';
import 'package:mobile_miniproject_app/pages/Add_Item.dart';
import 'package:mobile_miniproject_app/pages/Home_Receive.dart';
import 'package:mobile_miniproject_app/pages/Home_Send.dart';
import 'package:mobile_miniproject_app/pages/Profile.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class CustomerHomePage extends StatefulWidget {
  CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _HomePageState();
}

class _HomePageState extends State<CustomerHomePage> {
  int _selectedIndex = 0;
  late PageController _pageController;
  String url = '';
  bool isLoading = true;

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
    if (index == 2) return; // index 2 = ช่องว่างตรงกลาง

    setState(() {
      _selectedIndex = index;
    });

    if (index == 4) {
      // Profile Page
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ProfilePage(onClose: () {}, selectedIndex: 1)),
      );
    } else {
      // หน้าอื่น ๆ
      _pageController.animateToPage(
        index > 2 ? index - 1 : index, // ข้ามช่องว่าง
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40.0),
          topRight: Radius.circular(40.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed, // สำคัญ
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color.fromARGB(255, 115, 28, 168),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          iconSize: 20,
          selectedLabelStyle:
              TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.favorite), label: 'Favorite'),
            BottomNavigationBarItem(
                icon: SizedBox.shrink(), label: ''), // ช่องว่าง
            BottomNavigationBarItem(
                icon: Icon(Icons.notifications), label: 'Notis'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final userName = context.read<ShareData>().user_info_send.name;
    var topAdd = context.watch<ShareData>().customer_addresses;
    var Caterogy = context.watch<ShareData>().restaurant_type;
    var NearbyRes = context.watch<ShareData>().restaurant_near;

    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final Categoryfontsize =
        TextStyle(fontSize: 10, fontWeight: FontWeight.bold);

    log(topAdd.toString());

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topAdd.isNotEmpty ? topAdd[0].ca_detail : 'ไม่มีที่อยู่',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  topAdd.isNotEmpty ? topAdd[0].ca_address : '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'ค้นหาร้านอาหาร...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                onChanged: (value) {
                  // ค้นหา
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 20, top: 5),
              child: Text(
                "หมวดหมู่อาหาร",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: Caterogy.map((type) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ElevatedButton(
                        onPressed: () {
                          // ทำอะไรก็ได้เมื่อกดประเภทนี้
                          print({type.type_name});
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: 20, horizontal: 20),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side:
                                BorderSide(color: Colors.deepPurple, width: 2),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.network(
                              type.type_image, // ต้องเป็นลิงก์เต็ม เช่น https://...png
                              width: 35,
                              height: 35,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.fastfood,
                                    size: 30); // fallback ถ้าโหลดรูปไม่ได้
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return SizedBox(
                                  width: 30,
                                  height: 30,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                );
                              },
                            ),
                            SizedBox(height: 10),
                            Text(type.type_name, style: Categoryfontsize),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            ////แสดงเมื่ออยู่ใน ระยะ 5 กม.
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 5),
              child: Text(
                "ร้านใกล้เคียง",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: NearbyRes.map((near) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              print({near.res_name});
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero, // ไม่ให้มีช่องว่างเกิน
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.white,
                              elevation: 3,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                near.res_image,
                                width: 155,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.fastfood, size: 40);
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  );
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Container(
                              width: 155, // เท่ากับความกว้างของปุ่ม
                              alignment: Alignment.centerLeft, // เปลี่ยนตรงนี้
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment
                                    .start, // ปรับตำแหน่งชิดซ้าย
                                children: [
                                  Text(
                                    near.res_name,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  Text(
                                    "ระยะทางที่ห่างจากลูกค้า",
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 10),
              child: Text(
                "ร้านแนะนำ",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: NearbyRes.map((near) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              print({near.res_name});
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero, // ไม่ให้มีช่องว่างเกิน
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.white,
                              elevation: 3,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                //รูปเมนู
                                near.res_image,
                                width: 155,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.fastfood, size: 40);
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  );
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Container(
                              width: 155, // เท่ากับความกว้างของปุ่ม
                              alignment: Alignment.centerLeft, // เปลี่ยนตรงนี้
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment
                                    .start, // ปรับตำแหน่งชิดซ้าย
                                children: [
                                  Text(
                                    "ชื่อเมนู",
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  Text(
                                    near.res_name,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: buildBottomNavigationBar(),
      floatingActionButton: Container(
        height: 80,
        width: 80,
        child: FloatingActionButton(
          onPressed: () {
            Get.to(() => AddItemPage());
            log("ADDD");
          },
          backgroundColor: Colors.yellow,
          child: Icon(Icons.add, size: 50, color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void LoadCusHome() async {
    log("API Endpoint: $url");

    int userId = context.read<ShareData>().user_info_send.uid;

    try {
      var res_Add = await http.get(
        Uri.parse("$url/db/loadCusAdd/$userId"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
      );
      log("SPIDERMAN");
      log(res_Add.body); // log ข้อมูลที่ได้จาก API
      log("Status Code: ${res_Add.statusCode}");

      if (res_Add.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(res_Add.body);
        List<CusAddressGetResponse> res_addList = jsonResponse
            .map((item) => CusAddressGetResponse.fromJson(item))
            .toList();

        if (res_addList.isNotEmpty) {
          var firstAddress = res_addList[0];
          CusAddressGetResponse Cus_add = CusAddressGetResponse();
          Cus_add.ca_id = firstAddress.ca_id;
          Cus_add.ca_coordinate = firstAddress.ca_coordinate;
          Cus_add.ca_address = firstAddress.ca_address;
          Cus_add.ca_detail = firstAddress.ca_detail;
          Cus_add.ca_cus_id = firstAddress.ca_cus_id;

          context.read<ShareData>().customer_addresses = [Cus_add];
          context.read<ShareData>().notifyListeners();
        }

        Fluttertoast.showToast(
          msg: "ประเภทผู้ใช้ไม่ถูกต้อง",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } else {
        // ถ้า status ไม่ใช่ 200 แสดงว่า login fail
        Fluttertoast.showToast(
            msg: "อีเมล หรือ รหัสผ่านไม่ถูกต้อง โปรดลองใหม่อีกครั้ง",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Color.fromARGB(255, 255, 0, 0),
            textColor: Colors.white,
            fontSize: 15.0);
      }

      var res_Cat = await http.get(
        Uri.parse("$url/db/loadCat"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
      );
      log("SPIDERMAN");
      log(res_Cat.body); // log ข้อมูลที่ได้จาก API
      log("Status Code: ${res_Cat.statusCode}");

      if (res_Cat.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(res_Cat.body);
        List<ResTypeGetResponse> res_CatList = jsonResponse
            .map((item) => ResTypeGetResponse.fromJson(item))
            .toList();

        if (res_CatList.isNotEmpty) {
          context.read<ShareData>().restaurant_type = res_CatList;
          setState(() {
            isLoading = false;
          });
        }

        Fluttertoast.showToast(
          msg: "ประเภทผู้ใช้ไม่ถูกต้อง",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } else {
        // ถ้า status ไม่ใช่ 200 แสดงว่า login fail
        Fluttertoast.showToast(
            msg: "อีเมล หรือ รหัสผ่านไม่ถูกต้อง โปรดลองใหม่อีกครั้ง",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Color.fromARGB(255, 255, 0, 0),
            textColor: Colors.white,
            fontSize: 15.0);
      }

      var res_NearRes = await http.get(
        Uri.parse("$url/db/loadNearRes/$userId"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
      );
      log("SPIDERMAN");
      log(res_NearRes.body); // log ข้อมูลที่ได้จาก API
      log("Status Code: ${res_NearRes.statusCode}");

      if (res_NearRes.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(res_NearRes.body);
        List<ResInfoResponse> res_NearResList =
            jsonResponse.map((item) => ResInfoResponse.fromJson(item)).toList();

        if (res_NearResList.isNotEmpty) {
          context.read<ShareData>().restaurant_near = res_NearResList;
          setState(() {
            isLoading = false;
          });
        }

        Fluttertoast.showToast(
          msg: "ประเภทผู้ใช้ไม่ถูกต้อง",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } else {
        // ถ้า status ไม่ใช่ 200 แสดงว่า login fail
        Fluttertoast.showToast(
            msg: "อีเมล หรือ รหัสผ่านไม่ถูกต้อง โปรดลองใหม่อีกครั้ง",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Color.fromARGB(255, 255, 0, 0),
            textColor: Colors.white,
            fontSize: 15.0);
      }
    } catch (err) {
      log("Login Failed:");
      log(err.toString());
      Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาด โปรดลองใหม่",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Color.fromARGB(255, 255, 0, 0),
          textColor: Colors.white,
          fontSize: 15.0);
    }
  }
}
