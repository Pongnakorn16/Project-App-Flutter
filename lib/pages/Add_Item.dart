import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_miniproject_app/models/response/GetUserSearch_Res.dart';
import 'package:mobile_miniproject_app/pages/Home.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';

class AddItemPage extends StatefulWidget {
  AddItemPage({super.key});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  int uid = 0;
  String User_name = '';
  String User_type = '';
  List<GetUserSearchRes> all_userSearch = [];
  TextEditingController searchCtl = TextEditingController();
  TextEditingController product_nameCtl = TextEditingController();
  TextEditingController product_detailCtl = TextEditingController();
  TextEditingController receive_nameCtl = TextEditingController();

  @override
  void initState() {
    uid = context.read<ShareData>().user_Info.uid;
    User_name = context.read<ShareData>().user_Info.name;
    User_type = context.read<ShareData>().user_Info.user_type;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Container(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(
                          255, 228, 225, 225), // สีพื้นหลังของ TextField
                      borderRadius: BorderRadius.circular(30.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5), // สีของเงา
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset: Offset(0, 3), // การเยื้องของเงา
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: searchCtl,
                      onChanged: (value) {
                        filterSearch(value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search Receiver Phone Number',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none, // ไม่มีขอบ
                        ),
                        filled: true,
                        fillColor: Colors
                            .transparent, // ทำให้พื้นหลังโปร่งใส เนื่องจากใช้สีใน Container แล้ว
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 30, left: 10, right: 10),
                  child: IconButton(
                    icon: Icon(Icons.add_photo_alternate_rounded,
                        color: Color.fromARGB(
                            255, 255, 222, 78)), // ไอคอนที่ต้องการแสดงในปุ่ม
                    iconSize: 90.0, // ขนาดของไอคอน
                    onPressed: () {
                      // การทำงานเมื่อกดปุ่ม
                      print('Icon button pressed');
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(
                          255, 228, 225, 225), // สีพื้นหลังของ TextField
                      borderRadius: BorderRadius.circular(30.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5), // สีของเงา
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset: Offset(0, 3), // การเยื้องของเงา
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: product_nameCtl,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors
                            .transparent, // เนื่องจากเราตั้งสีใน Container แล้ว
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none, // ไม่มีขอบ
                        ), // ใส่ไอคอนโทรศัพท์ที่ด้านซ้าย
                        hintText: 'Product Name', // ใส่ placeholder
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(
                          255, 228, 225, 225), // สีพื้นหลังของ TextField
                      borderRadius: BorderRadius.circular(30.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5), // สีของเงา
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset: Offset(0, 3), // การเยื้องของเงา
                        ),
                      ],
                    ),
                    child: Container(
                      width: 300, // กำหนดความกว้าง
                      height: 100, // กำหนดความสูง
                      child: TextField(
                        controller: product_detailCtl,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors
                              .transparent, // เนื่องจากเราตั้งสีใน Container แล้ว
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none, // ไม่มีขอบ
                          ), // ใส่ไอคอนโทรศัพท์ที่ด้านซ้าย
                          hintText: 'Product Detail', // ใส่ placeholder
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(
                          255, 228, 225, 225), // สีพื้นหลังของ TextField
                      borderRadius: BorderRadius.circular(30.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5), // สีของเงา
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset: Offset(0, 3), // การเยื้องของเงา
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: product_nameCtl,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors
                            .transparent, // เนื่องจากเราตั้งสีใน Container แล้ว
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none, // ไม่มีขอบ
                        ), // ใส่ไอคอนโทรศัพท์ที่ด้านซ้าย
                        hintText: User_name, // ใส่ placeholder
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(
                          255, 228, 225, 225), // สีพื้นหลังของ TextField
                      borderRadius: BorderRadius.circular(30.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5), // สีของเงา
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset: Offset(0, 3), // การเยื้องของเงา
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: receive_nameCtl,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors
                            .transparent, // เนื่องจากเราตั้งสีใน Container แล้ว
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none, // ไม่มีขอบ
                        ), // ใส่ไอคอนโทรศัพท์ที่ด้านซ้าย
                        hintText: 'To', // ใส่ placeholder
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        height: 50,
                        child: FilledButton(
                          onPressed: () {},
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                                Color.fromARGB(255, 255, 222, 78)),
                            foregroundColor:
                                WidgetStateProperty.all(Colors.white),
                            shadowColor:
                                WidgetStateProperty.all(Colors.grey), // สีเงา
                            elevation: WidgetStateProperty.all(
                                5), // ความสูงของเงา (ยิ่งมากยิ่งชัด)
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(30), // ขอบมน
                              ),
                            ),
                          ),
                          child: Text(
                            "Send", // ใช้ตัวแปรโดยตรง
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w400),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: IconButton(
                          icon: Icon(Icons.cancel_outlined,
                              color: Color.fromARGB(255, 139, 15,
                                  188)), // ไอคอนที่ต้องการแสดงในปุ่ม
                          iconSize: 50.0, // ขนาดของไอคอน
                          onPressed: () {
                            Get.to(() => HomePage());
                            print('Icon button pressed');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void filterSearch(String query) async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    var response = await http.get(Uri.parse("$url/db/get_userSearch/${uid}"));
    if (response.statusCode == 200) {
      // all_userSearch = getLotteryNumbersFromJson(response.body);
      all_userSearch = getUserSearchResFromJson(response.body);
      log(all_userSearch.toString());
      for (var lottery in all_userSearch) {
        log('load all_userSearch comlplete. Status code: ${response.statusCode}');
      }
    } else {
      log('Failed to load userSearch numbers. Status code: ${response.statusCode}');
    }

    // setState(() {
    //   if (query.isEmpty) {
    //     filteredLotterys = all_userSearch; // ถ้าช่องค้นหาว่างให้แสดงข้อมูลทั้งหมด
    //   } else {
    //     filteredLotterys = all_userSearch.where((lottery) {
    //       // ตรวจสอบว่าแต่ละตำแหน่งของ numbers ตรงกับ query ที่พิมพ์ทีละตัว
    //       if (query.length <= lottery.numbers.length) {
    //         return lottery.numbers.substring(0, query.length) == query;
    //       }
    //       return false;
    //     }).toList();
    //   }
    // });
  }
}
